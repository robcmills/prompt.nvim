---@class PromptConfig
---@field history_date_format string
---@field history_dir string
---@field icons table<string, string>
---@field max_filename_length number
---@field model string
---@field models_path string
---@field spinner_chars string[]
---@field spinner_interval number
local M = {
  history_date_format = "%Y-%m-%dT%H:%M:%S",
  history_dir = "~/.local/share/nvim/prompt_history/",
  icons = {
    assistant = "●",
    reasoning = "∴",
    user = "○",
  },
  max_filename_length = 75,
  model = "anthropic/claude-sonnet-4",
  models_path = "~/.local/share/nvim/prompt_models.json",
  spinner_chars = { "⠋", "⠙", "⠸", "⠴", "⠦", "⠇" },
  spinner_interval = 150,
}

return M
