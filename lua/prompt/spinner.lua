local config = require('prompt.config')
local parse = require('prompt.parse')

local M = {}

---Table to track active spinners by buffer number
---@type table<number, {timer_id: number, char_index: number, line_num: number, col_num: number, original_line: string}|nil>
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

    -- Build the new line content with spinner at the specified position
    local new_line = spinner_data.original_line .. " " .. current_char

    -- Update the line with the spinner
    vim.api.nvim_buf_set_lines(bufnr, spinner_data.line_num, spinner_data.line_num + 1, false, {new_line})

    -- Move to next character
    spinner_data.char_index = (spinner_data.char_index % #config.spinner_chars) + 1
  end

  local timer_id = vim.fn.timer_start(config.spinner_interval, update_spinner, {['repeat'] = -1})

  M.active_spinners[bufnr] = {
    timer_id = timer_id,
    char_index = char_index,
    line_num = line_num,
    col_num = col_num,
    original_line = original_line
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

  -- Restore the original line content
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, spinner_data.line_num, spinner_data.line_num + 1, false, {spinner_data.original_line})
  end

  M.active_spinners[bufnr] = nil
end

return M
