local config = require('prompt.config')

local M = {}

function M.parse_messages_from_chat_buffer(buffer_content)
  local messages = {}
  local delineator_pattern = "^" .. string.gsub(config.chat_delineator, "%%s", "(.+)") .. "$"

  -- Split content by lines for processing
  local lines = vim.split(buffer_content, "\n")
  local current_message = {
    role = "user", -- default role for first message
    content = ""
  }
  local content_lines = {}

  for _, line in ipairs(lines) do
    -- Check if this line matches the delineator pattern
    local role_match = string.match(line, delineator_pattern)
    if role_match then
      -- Save current message if it has content
      if #content_lines > 0 then
        current_message.content = vim.trim(table.concat(content_lines, "\n"))
        if current_message.content ~= "" then
          table.insert(messages, current_message)
        end
      end

      -- Start new message
      local role = vim.trim(role_match)
      -- Validate role
      if not vim.tbl_contains({"user", "assistant", "system", "developer", "tool"}, role) then
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

return M
