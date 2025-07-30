---@alias HighlightGroup "delineator_icon"|"delineator_line"|"delineator_role"|"delineator_spinner"
---@alias Role "assistant"|"reasoning"|"user"

---@class PromptConfig
---@field history_date_format string
---@field history_dir string
---@field icons table<Role, string>
---@field max_filename_length number
---@field model string
---@field models_path string
---@field spinner_chars string[]
---@field spinner_interval number
---@field highlight_groups table<HighlightGroup, vim.api.keyset.highlight>

---@class PromptConfig
local M = {
  highlight_groups = {
    delineator_icon = { fg = "cyan" },
    delineator_line = { link = "DiagnosticVirtualTextInfo" },
    delineator_role = {},
    delineator_spinner = { link = "ErrorMsg" },
  },
  history_date_format = "%Y-%m-%dT%H:%M:%S",
  history_dir = "~/.local/share/nvim/prompt/history/",
  icons = {
    assistant = "●",
    reasoning = "∴",
    user = "○",
  },
  max_filename_length = 75,
  model = "anthropic/claude-sonnet-4",
  models_path = "~/.local/share/nvim/prompt/models.json",
  spinner_chars = { "⠋", "⠙", "⠸", "⠴", "⠦", "⠇" },
  spinner_interval = 150,
}

function M.setup_highlight_groups()
  for group_name, attrs in pairs(M.highlight_groups) do
    local hl_name = "Prompt" .. group_name:gsub("^%l", string.upper):gsub("_(%l)", function(c) return c:upper() end)
    vim.api.nvim_set_hl(0, hl_name, attrs)
  end
end

return M
