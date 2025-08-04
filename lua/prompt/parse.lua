local config = require('prompt.config')
local util = require('prompt.util')

local CODE_BLOCK_OPEN_PATTERN = "^```(%S+)$"
local CODE_BLOCK_CLOSE_PATTERN = "^```$"
local DELINEATOR_ROLE_PATTERN = "^█ [^%s]+ ([%w%-/:%.]+): █$" -- parse role from delineator
local MESSAGE_DELINEATOR = "█ %s %s: █" -- █ icon role: █

local M = {}

---@param bufnr number Buffer number
---@param role string Role for the chat delineator (user, assistant, reasoning, etc.)
function M.add_chat_delineator(bufnr, role)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    print('add_chat_delineator: buffer not valid')
    return
  end

  local icon
  if role == "usage" then
    icon = config.icons.usage
  elseif role == "user" then
    icon = config.icons.user
  elseif role == "reasoning" then
    icon = config.icons.reasoning
  else
    icon = config.icons.assistant
  end
  local delineator = string.format(MESSAGE_DELINEATOR, icon, role)
  local is_last_line_empty = util.get_buffer_last_line(bufnr) == ""
  local prefix = is_last_line_empty and "" or "\n"
  local new_content = prefix .. delineator .. "\n\n"
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(new_content, "\n"))

  M.add_highlights(bufnr)
end

---@param args {bufnr: number, icon: string, linenr: number, role: string}
function M.add_delineator_highlights(args)
  local line = vim.api.nvim_buf_get_lines(args.bufnr, args.linenr, args.linenr + 1, false)[1]
  if line == nil or line == "" then
    vim.notify("add_delineator_highlights: line is empty", vim.log.levels.ERROR)
    return
  end
  local line_end = string.len(line)
  local icon_start, icon_end = string.find(line, args.icon, 1, true)
  if icon_start == nil or icon_end == nil then
    vim.notify("add_delineator_highlights: icon not found", vim.log.levels.ERROR)
    return
  end
  local role_start, role_end = string.find(line, args.role, 1, true)
  if role_start == nil or role_end == nil then
    vim.notify("add_delineator_highlights: role not found", vim.log.levels.ERROR)
    return
  end

  config.setup_highlight_groups()

  local role_capitalized = (args.role == 'usage' or args.role == 'user' or args.role == 'reasoning')
    and args.role:gsub("^%l", string.upper)
    or 'Assistant'
  vim.api.nvim_buf_add_highlight(args.bufnr, -1, "Prompt" .. role_capitalized .. "DelineatorLine", args.linenr, 0, line_end)
  vim.api.nvim_buf_add_highlight(args.bufnr, -1, "Prompt" .. role_capitalized .. "DelineatorIcon", args.linenr, icon_start - 1, icon_end)
  vim.api.nvim_buf_add_highlight(args.bufnr, -1, "Prompt" .. role_capitalized .. "DelineatorRole", args.linenr, role_start - 1, role_end)
end

---@param bufnr number Buffer number to check
---@return boolean True if last line is inside a code block
function M.is_inside_code_block(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("is_inside_code_block: buffer not valid", vim.log.levels.ERROR)
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return false
  end

  -- Start from the last line and work backwards
  for i = line_count, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if not line then return false end
    if string.match(line, CODE_BLOCK_CLOSE_PATTERN) then return false end
    if string.match(line, CODE_BLOCK_OPEN_PATTERN) then return true end
  end

  return false
end

---@param bufnr number Buffer number to check
---@return boolean True if last line is inside a reasoning block
function M.is_inside_reasoning_block(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("is_inside_reasoning_block: buffer not valid", vim.log.levels.ERROR)
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return false
  end

  -- Start from the last line and work backwards
  for i = line_count, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if not line then return false end
    local role = string.match(line, DELINEATOR_ROLE_PATTERN)
    if role == "reasoning" then return true end
    if role ~= nil and role ~= "" then return false end
  end

  return false
end

---@param buffer_content string Content of the chat buffer
---@return Message[] Array of parsed messages
function M.parse_messages_from_chat_buffer(buffer_content)
  local messages = {}

  local lines = vim.split(buffer_content, "\n")
  local current_message = {
    role = "user", -- default role for first message
    content = ""
  }
  local content_lines = {}

  for _, line in ipairs(lines) do
    local role = string.match(line, DELINEATOR_ROLE_PATTERN)
    if role and role ~= "reasoning" then
      -- Save current message if it has content
      if #content_lines > 0 then
        current_message.content = vim.trim(table.concat(content_lines, "\n"))
        if current_message.content ~= "" then
          table.insert(messages, current_message)
        end
      end

      -- Start new message
      if not vim.tbl_contains({"usage", "user", "assistant", "system", "developer", "tool"}, role) then
        role = "assistant"
      end

      current_message = { role = role, content = "" }
      content_lines = {}
    else
      -- Add line to current message content
      table.insert(content_lines, line)
    end
  end

  -- Add final message if it has content
  if #content_lines > 0 then
    current_message.content = vim.trim(table.concat(content_lines, "\n"))
    if current_message.content ~= "" then
      table.insert(messages, current_message)
    end
  end

  return messages
end

---@param bufnr number Buffer number to check
---@return {line: number, col: number}|nil Line and column where spinner should appear, or nil if no delineator found
function M.getSpinnerLocation(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return nil
  end

  -- Start from the last line and work backwards to find the last model delineator
  for i = line_count, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if not line then return nil end

    local role = string.match(line, DELINEATOR_ROLE_PATTERN)
    if role and role ~= "" and role ~= "reasoning" and role ~= "user" and role ~= "tool" then
      -- Found a model role delineator, return line and column (length of line + 2)
      return {
        line = i - 1, -- 0-indexed line number
        col = string.len(line) + 2
      }
    end
  end

  return nil
end

---Add custom prompt highlights to given buffer
---@param bufnr number Buffer number to add highlights to
function M.add_highlights(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return
  end

  -- Iterate through all lines and add highlights to delineator lines
  for i = 0, line_count do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if line then
      local role = string.match(line, DELINEATOR_ROLE_PATTERN)
      if role then
        local icon
        if role == "usage" then
          icon = config.icons.usage
        elseif role == "user" then
          icon = config.icons.user
        elseif role == "reasoning" then
          icon = config.icons.reasoning
        else
          icon = config.icons.assistant
        end
        M.add_delineator_highlights({ bufnr = bufnr, linenr = i, icon = icon, role = role })
      end
    end
  end
end

return M
