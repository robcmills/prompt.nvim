local util = require('prompt.util')
local config = require('prompt.config')

local M = {}

local OPENROUTER_API_KEY = os.getenv('OPENROUTER_API_KEY')
local OPENROUTER_API_V1_CHAT_COMPLETIONS_URL = 'https://openrouter.ai/api/v1/chat/completions'
local OPENROUTER_API_V1_MODELS_URL = 'https://openrouter.ai/api/v1/models'

-- OpenRouter API

---@class Message Message object for conversation
---@field role "user"|"assistant"|"system"|"developer"|"tool" The role of the message sender
---@field content string The content of the message

---@alias OnExit fun(obj: table): nil Callback on exit. obj is vim.SystemCompleted (:h vim.system())
---@alias OnDeltaContent fun(content: string): nil Callback for streaming content deltas
---@alias OnDeltaReasoning fun(reasoning: string): nil Callback for streaming reasoning deltas
---@alias OnSuccess fun(content: string?): nil Callback on successful completion

---@class OpenRouterOpts Options for the OpenRouter API request
---@field model string The model to use for the request
---@field messages Message[] Array of message objects for the conversation
---@field stream boolean Whether to use streaming response
---@field on_delta_content? OnDeltaContent Optional callback for streaming content deltas
---@field on_delta_reasoning? OnDeltaReasoning Optional callback for streaming reasoning deltas
---@field on_exit? OnExit Optional callback on exit
---@field on_success? OnSuccess Optional callback on successful completion. For streaming requests, called with no args. For non-streaming, called with response content string.

---@param opts OpenRouterOpts
---Makes a request to the OpenRouter Chat Completion API
---https://openrouter.ai/docs/api-reference/chat-completion
function M.make_openrouter_request(opts)
  if not OPENROUTER_API_KEY then
    vim.notify("OPENROUTER_API_KEY environment variable not set", vim.log.levels.ERROR)
    return
  end

  local request_body = vim.json.encode({
    model = opts.model,
    messages = opts.messages,
    stream = opts.stream,
  })

  local headers = {
    "Authorization: Bearer " .. OPENROUTER_API_KEY,
    "HTTP-Referer: robcmills.net",
    "X-Title: markdown-prompt.nvim",
    "Content-Type: application/json",
  }

  local curl_args = {
    "-X", "POST",
    "-H", table.concat(headers, " -H "),
    "-d", request_body,
    "--silent", -- Suppress progress output
    "--no-buffer",
    OPENROUTER_API_V1_CHAT_COMPLETIONS_URL
  }

  local buffer = ""

  local function handle_stdout(err, data)
    if err then print('handle_stdout err: ' .. err) end

    if not data then return end

    buffer = buffer .. data

    if opts.stream then
      -- Process complete lines from buffer for streaming
      while true do
        local line_end = string.find(buffer, "\n")
        if not line_end then break end

        local line = string.sub(buffer, 1, line_end - 1)
        buffer = string.sub(buffer, line_end + 1)

        line = vim.trim(line)

        if string.sub(line, 1, 6) == "data: " then
          local json = string.sub(line, 7)
          if json == "[DONE]" then
            return
          end

          local success, parsed = pcall(vim.json.decode, json)

          if not success then
            print('handle_stdout: failed to parse json data: ' .. json)
          elseif parsed.choices and parsed.choices[1] and parsed.choices[1].delta then
            local delta = parsed.choices[1].delta
            if opts.on_delta_content and delta.content and delta.content ~= "" then
              opts.on_delta_content(delta.content)
            end
            if opts.on_delta_reasoning and delta.reasoning and type(delta.reasoning) == "string" then
              opts.on_delta_reasoning(delta.reasoning)
            end
          end
        elseif string.sub(line, 1, 1) == ":" then
          -- Ignore SSE comments
        end
      end
    end
  end

  local function handle_stderr(err, data)
    if err then vim.notify('Handle_stderr err: ' .. err, vim.log.levels.ERROR) end
    if data then vim.notify('Handle_stderr data: ' .. data, vim.log.levels.ERROR) end
  end

  local function on_exit(obj)
    vim.schedule(function()
      if opts.on_exit then opts.on_exit(obj) end

      if obj.code ~= 0 then
        vim.notify("OpenRouter API request failed with exit code: " .. obj.code, vim.log.levels.ERROR)
        return
      end

      if opts.on_success then
        if opts.stream then
          opts.on_success()
        else
          -- For non-streaming requests, parse the JSON response and extract content
          local success, parsed = pcall(vim.json.decode, buffer)
          if success and parsed.choices and parsed.choices[1] and parsed.choices[1].message and parsed.choices[1].message.content then
            opts.on_success(parsed.choices[1].message.content)
          else
            vim.notify(
              "Failed to parse OpenRouter API response: " .. buffer,
              vim.log.levels.ERROR
            )
          end
        end
      end
    end)
  end

  return vim.system({ "curl", unpack(curl_args) }, {
    stdout_buffered = false,
    stderr_buffered = false,
    stdout = handle_stdout,
    stderr = handle_stderr,
  }, on_exit)
end

---@param callback fun(models: table[]?) Callback function with models list or nil on error
---Curls OpenRouter API to get list of available models
---https://openrouter.ai/docs/api-reference/list-available-models
function M.get_models_list(callback)
  local models_path = M.get_models_path()

  local file = io.open(models_path, "r")
  if not file then
    vim.notify("Models file not found, fetching from API...", vim.log.levels.INFO)
    M.update_models(function(success)
      vim.schedule(function()
        if not success then return end
        M.get_models_list(callback)
      end)
    end)
    return
  end

  local content = file:read("*all")
  file:close()

  local success, models_data = pcall(vim.json.decode, content)
  if not success then
    vim.notify("Failed to parse models JSON file", vim.log.levels.ERROR)
    callback(nil)
    return
  end

  if not models_data.data or type(models_data.data) ~= "table" then
    vim.notify("Invalid models file format: missing 'data' array", vim.log.levels.ERROR)
    callback(nil)
    return
  end

  table.sort(models_data.data, function(a, b)
    return (a.created or 0) > (b.created or 0)
  end)

  local models = {}
  for _, model in ipairs(models_data.data) do
    if model.id and model.name then
      table.insert(models, {
        id = model.id,
        name = model.name,
        display = model.name
      })
    end
  end

  callback(models)
end

---@return string Expanded path to models file
function M.get_models_path()
  local path = config.models_path
  if string.sub(path, 1, 1) == "~" then
    path = vim.fn.expand(path)
  end
  return path
end

local SUMMARY_MODEL = 'google/gemini-2.5-flash'
local SUMMARY_PROMPT = [[
Summarize the following Prompt in a single, very short title.
Format it for a filename, in kebab-case, no spaces, and no punctuation.
Respond with only the title and nothing else.

<Prompt>
%s
</Prompt>
]]

---@param filename string Original filename (util.get_timestamp_filename)
---@param prompt string Prompt content to summarize
---@param callback? fun(summary: string) Optional callback with generated summary appended to filename
---Curls OpenRouter API to generate a filename suitable summary of the prompt
function M.get_prompt_summary_filename(filename, prompt, callback)
  local messages = {
    { role = "user", content = string.format(SUMMARY_PROMPT, prompt) }
  }

  local function on_success(summary)
    if not summary then
      vim.notify("Failed to generate prompt summary", vim.log.levels.ERROR)
      return
    end

    local sanitized_summary = util.sanitize_filename(summary)

    if sanitized_summary == "" then
      vim.notify("Generated summary is empty, keeping original filename", vim.log.levels.WARN)
      return
    end

    local base_name = string.gsub(filename, "%.md$", "")
    local new_filename = base_name .. "-" .. sanitized_summary .. ".md"

    if callback then callback(new_filename) end
  end

  M.make_openrouter_request({
    messages = messages,
    model = SUMMARY_MODEL,
    stream = false,
    on_success = on_success
  })
end

---@param callback? fun(success: boolean) Optional callback with success status
---Curls OpenRouter API to get list of available models and updates cached models file
function M.update_models(callback)
  if not OPENROUTER_API_KEY then
    vim.notify("OPENROUTER_API_KEY environment variable not set", vim.log.levels.ERROR)
    if callback then callback(false) end
    return
  end

  local models_path = M.get_models_path()

  local headers = {
    "Authorization: Bearer " .. OPENROUTER_API_KEY,
    "HTTP-Referer: prompt.nvim",
    "X-Title: prompt.nvim",
  }

  local curl_args = {
    "-X", "GET",
    "-H", table.concat(headers, " -H "),
    "--silent",
    OPENROUTER_API_V1_MODELS_URL
  }

  local buffer = ""

  local function handle_stdout(err, data)
    if err then print('handle_stdout err: ' .. err) end
    if data then
      buffer = buffer .. data
    end
  end

  local function handle_stderr(err, data)
    if err then print('handle_stderr err: ' .. err) end
    if data then print('handle_stderr data: ' .. data) end
  end

  local function on_exit(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.notify("Failed to fetch models from OpenRouter API (exit code: " .. obj.code .. ")", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      -- Validate JSON response
      local success = pcall(vim.json.decode, buffer)
      if not success then
        vim.notify("Failed to parse models response from OpenRouter API", vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      -- Write to models file
      local file = io.open(models_path, "w")
      if not file then
        vim.notify("Failed to open models file for writing: " .. models_path, vim.log.levels.ERROR)
        if callback then callback(false) end
        return
      end

      file:write(buffer)
      file:close()

      vim.notify("Models file updated successfully: " .. models_path, vim.log.levels.INFO)
      if callback then callback(true) end
    end)
  end

  vim.system({ "curl", unpack(curl_args) }, {
    stdout_buffered = false,
    stderr_buffered = false,
    stdout = handle_stdout,
    stderr = handle_stderr,
  }, on_exit)
end

return M
