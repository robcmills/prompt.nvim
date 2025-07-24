local config = require('prompt.config')
local parse = require('prompt.parse')
local provider = require('prompt.provider')
local util = require('prompt.util')

local M = {}

-- Table to track active requests by buffer number
local active_requests = {}

function M.submit_prompt()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local original_filepath = vim.api.nvim_buf_get_name(current_bufnr)
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
      vim.cmd("write")
      local callback = function(summary_filename)
        local new_filepath = vim.fs.joinpath(util.get_history_dir(), summary_filename)
        local success, err = pcall(vim.fn.rename, original_filepath, new_filepath)
        if not success then
          vim.notify("Error renaming prompt file: " .. err, vim.log.levels.ERROR)
          return
        end
        vim.api.nvim_buf_set_name(current_bufnr, new_filepath)
        vim.cmd("write!")
      end
      provider.get_prompt_summary(current_filename, first_user_message, callback)
    end
  end

  parse.add_chat_delineator(current_bufnr, config.model)

  local request = provider.make_openrouter_request({
    messages = messages,
    model = config.model,
    stream = true,
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
        if obj.code ~= 0 then
          util.append_to_buffer(current_bufnr, "\nPrompt request failed.")
        end
        active_requests[current_bufnr] = nil
        parse.add_chat_delineator(current_bufnr, 'user')
        vim.cmd("write")
      end)
    end,
  })

  -- Store request object for potential cancellation
  if request then
    active_requests[current_bufnr] = request
  end
end

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
    if not choice then
      return
    end

    vim.cmd("e " .. choice.filepath)
  end)
end

function M.get_model()
  print(config.model)
end

function M.update_models()
  provider.update_models()
end

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

function M.split_prompt()
  vim.cmd("vsplit")
  vim.cmd("wincmd L")
  M.new_prompt()
end

function M.stop_prompt()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local request = active_requests[current_bufnr]

  if not request then
    vim.notify("No active request found for current buffer", vim.log.levels.WARN)
  else
    request:kill()
    active_requests[current_bufnr] = nil
    util.append_to_buffer(current_bufnr, "\nPrompt request cancelled")
    vim.notify("Prompt request cancelled", vim.log.levels.INFO)
  end
end

return M
