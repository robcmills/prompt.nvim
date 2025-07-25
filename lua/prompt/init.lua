local commands = require('prompt.commands')
local config = require('prompt.config')
local core = require('prompt.core')

local M = {}

M.create_commands = commands.create_commands
M.get_model = core.get_model
M.load_prompt_history = core.load_prompt_history
M.new_prompt = core.new_prompt
M.select_model = core.select_model
M.split_prompt = core.split_prompt
M.submit_prompt = core.submit_prompt
M.update_models = core.update_models

---@param opts? table Configuration options to merge with defaults
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  M.create_commands()
end

return M
