local core = require('prompt.core')
local parse = require('prompt.parse')

local M = {}

---Creates all the user commands for the prompt plugin
function M.create_commands()
  local command = vim.api.nvim_create_user_command

  command("PromptCommitMessage", function()
    core.generate_commit_message()
  end, { desc = "Generate a commit message from git diff and insert at cursor" })

  command("PromptHighlight", function()
    parse.add_highlights(vim.api.nvim_get_current_buf())
  end, { desc = "Add Prompt highlights to current buffer" })

  command("PromptHistory", function()
    core.load_prompt_history()
  end, { desc = "Select and load from prompt history" })

  command("PromptModelGet", function()
    core.get_model()
  end, { desc = "Print current model" })

  command("PromptModelSelect", function()
    core.select_model()
  end, { desc = "Select model" })

  command("PromptModelsUpdate", function()
    core.update_models()
  end, { desc = "Update available models list" })

  command("PromptNew", function()
    core.new_prompt()
  end, { desc = "Create a new markdown prompt file" })

  command("PromptRenameSummary", function()
    local bufnr = vim.api.nvim_get_current_buf()
    core.rename_prompt_summary(bufnr)
  end, { desc = "Rename current prompt file with appended summary" })

  command("PromptSplit", function()
    core.split_prompt()
  end, { desc = "Split the current window vertically and open a new prompt" })

  command("PromptStop", function()
    core.stop_prompt()
  end, { desc = "Cancel any request currently streaming into the current buffer" })

  command("PromptSubmit", function()
    core.submit_prompt()
  end, { desc = "Submit chat buffer with parsed messages to model API" })
end

return M
