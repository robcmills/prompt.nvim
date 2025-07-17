local config = require('prompt.config')
local parse = require('prompt.parse')
local provider = require('prompt.provider')
local util = require('prompt.util')

local M = {}

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

  util.add_chat_delineator(current_bufnr, config.model)

  provider.make_openrouter_request({
    messages = messages,
    model = config.model,
    stream = true,
    on_success = function()
      util.add_chat_delineator(current_bufnr, 'user')
      vim.cmd("write")
    end,
    on_delta_content = function(content)
      util.append_to_buffer(current_bufnr, content)
    end,
    on_delta_reasoning = function(reasoning)
      util.append_to_buffer(current_bufnr, reasoning)
    end,
  })
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
  local models_path = provider.get_models_path()

  -- Check if models file exists
  local file = io.open(models_path, "r")
  if not file then
    vim.notify("Models file not found: " .. models_path, vim.log.levels.ERROR)
    return
  end

  local content = file:read("*all")
  file:close()

  -- Parse JSON
  local success, models_data = pcall(vim.json.decode, content)
  if not success then
    vim.notify("Failed to parse models JSON file", vim.log.levels.ERROR)
    return
  end

  if not models_data.data or type(models_data.data) ~= "table" then
    vim.notify("Invalid models file format: missing 'data' array", vim.log.levels.ERROR)
    return
  end

  -- Sort models by created timestamp descending (most recent first)
  table.sort(models_data.data, function(a, b)
    return (a.created or 0) > (b.created or 0)
  end)

  -- Create choices for UI select
  local model_choices = {}
  for _, model in ipairs(models_data.data) do
    if model.id and model.name then
      table.insert(model_choices, {
        id = model.id,
        name = model.name,
        display = model.name
      })
    end
  end

  if #model_choices == 0 then
    vim.notify("No valid models found in models file", vim.log.levels.WARN)
    return
  end

  vim.ui.select(model_choices, {
    prompt = "Select a model:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if not choice then
      return
    end

    config.model = choice.id
    vim.notify("Selected model: " .. choice.name, vim.log.levels.INFO)
  end)
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

return M
