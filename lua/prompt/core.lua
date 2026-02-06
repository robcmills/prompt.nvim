local config = require('prompt.config')
local parse = require('prompt.parse')
local provider = require('prompt.provider')
local spinner = require('prompt.spinner')
local util = require('prompt.util')

local M = {}

---Table to track active requests by buffer number
---@type table<number, vim.SystemObj|nil>
local active_requests = {}

---Submits the current buffer content as a prompt to the API
function M.submit_prompt()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local buffer_content = util.get_buffer_content(current_bufnr)

  if buffer_content == "" then
    vim.notify("Buffer is empty.", vim.log.levels.WARN)
    return
  end

  local messages = parse.parse_messages_from_chat_buffer(buffer_content)

  if #messages == 0 then
    vim.notify("No valid messages found in buffer.", vim.log.levels.WARN)
    return
  end

  -- filter out usage messages
  messages = vim.tbl_filter(function(message)
    return message.role ~= "usage"
  end, messages)

  -- determine if the current prompt buffer has a summary already
  -- or is only a datetime filename
  local current_filename = vim.fn.expand("%:t")
  local datetime_filename = util.get_timestamp_filename()
  if string.len(current_filename) == string.len(datetime_filename) then
    -- Get first user message for summary
    local first_user_message = nil
    for _, message in ipairs(messages) do
      if message.role == "user" then
        first_user_message = message.content
        break
      end
    end

    if first_user_message then
      M.rename_prompt_summary(current_bufnr, first_user_message)
    end
  end

  parse.add_chat_delineator(current_bufnr, config.model)

  spinner.start_spinner(current_bufnr)

  local request = provider.make_chat_completion_request({
    max_tokens = config.max_tokens,
    messages = messages,
    model = config.model,
    stream = true,
    usage = { include = true },
    on_delta_content = function(content)
      vim.schedule(function()
        if parse.is_inside_reasoning_block(current_bufnr) then
          parse.add_chat_delineator(current_bufnr, config.model)
        end
        util.append_to_buffer(current_bufnr, content)
      end)
    end,
    on_delta_reasoning = function(reasoning)
      vim.schedule(function()
        if not parse.is_inside_reasoning_block(current_bufnr) then
          parse.add_chat_delineator(current_bufnr, "reasoning")
        end
        util.append_to_buffer(current_bufnr, reasoning)
      end)
    end,
    on_exit = function(obj)
      vim.schedule(function()
        spinner.stop_spinner(current_bufnr)
        if obj.code ~= 0 then
          util.append_to_buffer(current_bufnr, "\nPrompt request failed.")
        end
        active_requests[current_bufnr] = nil
        parse.add_chat_delineator(current_bufnr, 'user')
        vim.cmd("write")
      end)
    end,
    on_usage = function(usage)
      vim.schedule(function()
        if config.render_usage then
          local usage_summary = config.render_usage(usage)
          parse.add_chat_delineator(current_bufnr, 'usage')
          util.append_to_buffer(current_bufnr, usage_summary)
        end
      end)
    end,
  })

  -- Store request object for potential cancellation
  if request then
    active_requests[current_bufnr] = request
  end
end

---Shows a picker to select and load a prompt from history
function M.load_prompt_history()
  util.ensure_history_dir()
  local history_dir = util.get_history_dir()

  -- Get list of markdown files in history directory
  local files = vim.fn.globpath(history_dir, "*.md", false, true)

  if #files == 0 then
    vim.notify("No prompt history found in " .. history_dir, vim.log.levels.INFO)
    return
  end

  -- Extract just the filenames for display
  local file_choices = {}
  for _, filepath in ipairs(files) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    table.insert(file_choices, {
      filename = filename,
      filepath = filepath,
      display = filename
    })
  end

  -- Sort by filename (which includes timestamp) in descending order (newest first)
  table.sort(file_choices, function(a, b)
    return a.filename > b.filename
  end)

  vim.ui.select(file_choices, {
    prompt = "Select a prompt from history:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if not choice then return end
    vim.cmd("e " .. choice.filepath)
    parse.add_highlights(vim.api.nvim_get_current_buf())
  end)
end

---Prints the currently selected model
function M.get_model()
  print(config.model)
end

---Updates the cached models list from the API
function M.update_models()
  provider.update_models()
end

---Shows a picker to select from available models
function M.select_model()
  local function callback(models)
    vim.schedule(function()
      if models == nil or #models == 0 then
        vim.notify("No valid models found in models file", vim.log.levels.WARN)
        return
      end

      vim.ui.select(models, {
        prompt = "Select a model:",
        format_item = function(item)
          return item.display
        end,
      }, function(choice)
        if not choice then return end
        config.model = choice.id
        vim.notify("Selected model: " .. choice.name, vim.log.levels.INFO)
      end)
    end)
  end

  provider.get_models_list(callback)
end

---Creates a new prompt file in the current window
function M.new_prompt()
  util.ensure_history_dir()
  local new_filename = util.get_timestamp_filename()
  local new_filepath = util.get_history_dir() .. new_filename

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].buftype = ''
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].filetype = "markdown"
  vim.bo[bufnr].buflisted = true
  vim.api.nvim_buf_set_name(bufnr, new_filepath)
  vim.api.nvim_win_set_buf(0, bufnr)

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("write")
    vim.cmd("startinsert")
  end)
end

---Renames the given buffer with appended summary of prompt
---@param bufnr number Buffer number to rename
---@param prompt? string Prompt content to summarize. If not provided, will use current buffer content.
function M.rename_prompt_summary(bufnr, prompt)
  local original_filename = vim.fn.expand("%:t")
  local original_filepath = vim.api.nvim_buf_get_name(bufnr)

  if not prompt then prompt = util.get_buffer_content(bufnr) end

  if prompt == "" then
    vim.notify("Prompt is empty", vim.log.levels.WARN)
    return
  end

  vim.cmd("write")

  local callback = function(summary_filename)
    vim.schedule(function()
      local new_filepath = vim.fs.joinpath(util.get_history_dir(), summary_filename)
      local success, err = pcall(vim.fn.rename, original_filepath, new_filepath)
      if not success then
        vim.notify("Error renaming prompt file: " .. err, vim.log.levels.ERROR)
        return
      end
      vim.api.nvim_buf_set_name(bufnr, new_filepath)
      vim.cmd("write!")
    end)
  end

  provider.get_prompt_summary_filename(original_filename, prompt, callback)
end

---Creates a vertical split and opens a new prompt
function M.split_prompt()
  vim.cmd("vsplit")
  vim.cmd("wincmd L")
  M.new_prompt()
end

---Generates a commit message from the current git diff and inserts it at cursor
function M.generate_commit_message()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  local function request_commit_message(diff)
    vim.notify("Generating commit message...", vim.log.levels.INFO)

    local messages = {
      { role = "system", content = config.commit_message_system_prompt },
      { role = "user", content = diff },
    }

    provider.make_chat_completion_request({
      messages = messages,
      model = config.commit_message_model,
      stream = false,
      on_success = function(response)
        if not response.choices or not response.choices[1]
          or not response.choices[1].message or not response.choices[1].message.content then
          vim.notify("Failed to extract commit message from response", vim.log.levels.ERROR)
          return
        end

        local commit_message = vim.trim(response.choices[1].message.content)
        local lines = vim.split(commit_message, "\n")
        local row = cursor_pos[1] - 1 -- 0-indexed
        vim.api.nvim_buf_set_lines(current_bufnr, row, row, false, lines)
      end,
    })
  end

  vim.system({ "git", "diff" }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.notify("git diff failed: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
      end

      local diff = vim.trim(obj.stdout or "")
      if diff ~= "" then
        request_commit_message(diff)
        return
      end

      -- No unstaged changes, try staged changes
      vim.system({ "git", "diff", "--cached" }, { text = true }, function(staged_obj)
        vim.schedule(function()
          if staged_obj.code ~= 0 then
            vim.notify("git diff --cached failed: " .. (staged_obj.stderr or ""), vim.log.levels.ERROR)
            return
          end

          local staged_diff = vim.trim(staged_obj.stdout or "")
          if staged_diff == "" then
            vim.notify("No unstaged or staged changes found.", vim.log.levels.WARN)
            return
          end

          request_commit_message(staged_diff)
        end)
      end)
    end)
  end)
end

---Stops any active request for the current buffer
function M.stop_prompt()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local request = active_requests[current_bufnr]

  spinner.stop_spinner(current_bufnr)

  if not request then
    vim.notify("No active request found for current buffer", vim.log.levels.WARN)
  else
    request:kill(9)
    active_requests[current_bufnr] = nil
    -- If we are in a code block, add closing ticks to prevent broken syntax highlighting
    if parse.is_inside_code_block(current_bufnr) then
      util.append_to_buffer(current_bufnr, "\n```\n")
    end
    util.append_to_buffer(current_bufnr, "\nPrompt request cancelled")
    vim.notify("Prompt request cancelled", vim.log.levels.INFO)
  end
end

return M
