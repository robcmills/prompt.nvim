---@alias HighlightGroup "delineator_icon"|"delineator_line"|"delineator_role"|"delineator_spinner"
---@alias Role "assistant"|"reasoning"|"usage"|"user"

---@class PromptConfig
---@field highlight_groups table<HighlightGroup, vim.api.keyset.highlight>
---@field highlight_groups_by_role table<Role, table<HighlightGroup, vim.api.keyset.highlight>>
---@field history_date_format string
---@field history_dir string
---@field icons table<Role, string>
---@field max_filename_length number
---@field max_tokens number
---@field model string
---@field models_path string
---@field render_usage? function(usage: UsageResponse): string If omitted, will not render usage stats
---@field spinner_chars string[]
---@field spinner_interval number -- milliseconds
---@field spinner_timeout number -- number of intervals, so duration = interval * timeout ms

---@class PromptConfig
local M = {
  highlight_groups = {
    delineator_spinner = { link = "ErrorMsg" },
  },
  highlight_groups_by_role = {
    assistant = {
      delineator_icon = { fg = "cyan" },
      delineator_line = { link = "DiagnosticVirtualTextInfo" },
      delineator_role = {},
    },
    reasoning = {
      delineator_icon = {},
      delineator_line = { link = "DiagnosticVirtualTextHint" },
      delineator_role = {},
    },
    usage = {
      delineator_icon = {},
      delineator_line = { link = "DiffAdd" },
      delineator_role = {},
    },
    user = {
      delineator_icon = { fg = "orange" },
      delineator_line = { link = "DiagnosticVirtualTextWarn" },
      delineator_role = {},
    },
  },
  history_date_format = "%Y-%m-%dT%H:%M:%S",
  history_dir = "~/.local/share/nvim/prompt/history/",
  icons = {
    assistant = "●",
    reasoning = "∴",
    usage = "$",
    user = "○",
  },
  max_filename_length = 75,
  max_tokens = 32000,
  model = "openai/gpt-5",
  models_path = "~/.local/share/nvim/prompt/models.json",
  render_usage = function(usage)
    return string.format(
      "Tokens: %d prompt + %d completion = %d total | Cost: $%.4f",
      usage.prompt_tokens,
      usage.completion_tokens,
      usage.total_tokens,
      usage.cost
    )
  end,
  spinner_chars = { "⠋", "⠙", "⠸", "⠴", "⠦", "⠇" },
  spinner_interval = 150,
  spinner_timeout = 1000,
}

function M.setup_highlight_groups()
  for role, groups in pairs(M.highlight_groups_by_role) do
    for group_name, attrs in pairs(groups) do
      local hl_name = "Prompt" .. role:gsub("^%l", string.upper) .. group_name:gsub("^%l", string.upper):gsub("_(%l)", function(c) return c:upper() end)
      vim.api.nvim_set_hl(0, hl_name, attrs)
    end
  end
end

return M
