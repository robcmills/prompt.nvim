local config = require('prompt.config')
local parse = require('prompt.parse')

local M = {}

---Table to track active spinners by buffer number
---@type table<number, {timer_id: number, char_index: number, line_num: number, col_num: number, original_line: string, last_content_length: number} | nil>
M.active_spinners = {}

---Starts a spinner for the given buffer after the last model delineator
---@param bufnr number Buffer number
function M.start_spinner(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Stop any existing spinner for this buffer
  M.stop_spinner(bufnr)

  -- Get the location where the spinner should appear
  local location = parse.getSpinnerLocation(bufnr)
  if not location then
    return
  end

  local line_num = location.line
  local col_num = location.col

  -- Get the original line content to preserve it
  local original_line = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)[1] or ""

  local char_index = 1

  local function update_spinner()
    if not vim.api.nvim_buf_is_valid(bufnr) or not M.active_spinners[bufnr] then
      M.active_spinners[bufnr] = nil
      return
    end

    local spinner_data = M.active_spinners[bufnr]
    if not spinner_data then
      return
    end

    local current_char = config.spinner_chars[spinner_data.char_index]
    local new_content = " " .. current_char

    -- Calculate positions
    local start_row = spinner_data.line_num
    local start_col = string.len(spinner_data.original_line)
    local end_row = spinner_data.line_num
    local end_col = start_col + (spinner_data.last_content_length or 0) -- Replace previous spinner content
    vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { new_content })
    vim.api.nvim_buf_add_highlight(bufnr, -1, "PromptDelineatorSpinner", start_row, start_col, start_col + string.len(new_content))

    -- Store the length of content we just added for next iteration
    spinner_data.last_content_length = string.len(new_content)

    -- Move to next character
    spinner_data.char_index = (spinner_data.char_index % #config.spinner_chars) + 1
  end

  local timer_id = vim.fn.timer_start(config.spinner_interval, update_spinner, {['repeat'] = 25})

  M.active_spinners[bufnr] = {
    char_index = char_index,
    col_num = col_num,
    last_content_length = 0,
    line_num = line_num,
    original_line = original_line,
    timer_id = timer_id,
  }
end

---Stops the spinner for the given buffer
---@param bufnr number Buffer number
function M.stop_spinner(bufnr)
  local spinner_data = M.active_spinners[bufnr]
  if not spinner_data then
    return
  end

  -- Stop the timer
  vim.fn.timer_stop(spinner_data.timer_id)

  -- Remove the spinner content without destroying highlight groups on the rest of the line
  if vim.api.nvim_buf_is_valid(bufnr) then
    local start_row = spinner_data.line_num
    local start_col = string.len(spinner_data.original_line)
    local end_row = spinner_data.line_num
    local end_col = start_col + (spinner_data.last_content_length or 0)
    vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {""})
  end

  M.active_spinners[bufnr] = nil
end

return M
