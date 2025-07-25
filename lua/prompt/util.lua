local config = require('prompt.config')

local M = {}

---@return string Expanded history directory path
function M.get_history_dir()
  local dir = config.history_dir
  if string.sub(dir, 1, 1) == "~" then
    dir = vim.fn.expand(dir)
  end
  return dir
end

---Ensures the history directory exists, creating it if necessary
function M.ensure_history_dir()
  local dir = M.get_history_dir()
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

---@return string Filename with timestamp format
function M.get_timestamp_filename()
  local timestamp = os.date(config.history_date_format)
  return timestamp .. ".md"
end

---@param bufnr number Buffer number
---@return string Complete buffer content as string
function M.get_buffer_content(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end

---@param bufnr? number Buffer number (defaults to current buffer)
---@return string Last line content or empty string if buffer is empty
function M.get_buffer_last_line(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then
      error("Invalid buffer number: " .. bufnr)
  end
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then return "" end
  local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1]
  return last_line or ""
end

---@param bufnr number Buffer number
---@param text string Text to append to buffer
---Appends text to the end of the buffer. Does not create new lines unless text contains newlines.
function M.append_to_buffer(bufnr, text)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    print('append_to_buffer: buffer not valid')
    return
  end

  if not vim.bo[bufnr].modifiable then
    print('append_to_buffer: buffer not modifiable')
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local text_parts = vim.split(text, "\n")

  if line_count == 0 then
    -- Empty buffer, just set the text parts
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, text_parts)
    return
  end

  -- Get only the last line
  local last_line_idx = line_count - 1
  local last_line = vim.api.nvim_buf_get_lines(bufnr, last_line_idx, last_line_idx + 1, false)[1] or ""

  -- Handle the first part (append to current line)
  if #text_parts > 0 then
    vim.api.nvim_buf_set_lines(bufnr, last_line_idx, last_line_idx + 1, false, { last_line .. text_parts[1] })
  end

  -- Handle remaining parts (each becomes a new line)
  if #text_parts > 1 then
    local new_lines = {}
    for i = 2, #text_parts do
      table.insert(new_lines, text_parts[i])
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, new_lines)
  end
end

---@param text string Input text to sanitize
---@return string Sanitized filename suitable for file system
function M.sanitize_filename(text)
  -- Remove punctuation and convert to lowercase
  local sanitized = string.lower(text)
  -- Replace spaces and other separators with hyphens
  sanitized = string.gsub(sanitized, "[%s%p]+", "-")
  -- Remove multiple consecutive hyphens
  sanitized = string.gsub(sanitized, "-+", "-")
  -- Remove leading and trailing hyphens
  sanitized = string.gsub(sanitized, "^%-+", "")
  sanitized = string.gsub(sanitized, "%-+$", "")
  -- Clip to max length
  if #sanitized > config.max_filename_length then
    sanitized = string.sub(sanitized, 1, config.max_filename_length)
    -- Ensure we don't end with a hyphen
    sanitized = string.gsub(sanitized, "%-+$", "")
  end
  return sanitized
end


return M
