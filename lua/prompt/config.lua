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
}

return M
