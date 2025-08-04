
# Todo

## Bugs/Critical Features

- [x] Refactor filename summary to use static model (not current)
- [x] Add support for reasoning
- [x] Add reasoning delineators
- [x] Enable cancellation of streaming request
  + [x] Ensure request is set to nil on request error
  + [x] When stopping request, check if inside code block and if so, add closing ticks
- [ ] Add tests (all models)
- [x] Add type annotations
- [ ] Add docs (help file)


## Improvements

- [ ] Add sqlite db for storing more data
- [x] Add token counts and costs stats

- [ ] Add `@contexts`
  + https://docs.cursor.com/en/context/@-symbols/overview
  + https://github.com/yetone/avante.nvim/tree/main#mentions

- [x] Refactor default config directory
  ~/.local/share/nvim/prompt/
- [ ] Add initial user message delineator and placeholder text
- [ ] Aesthetics
  + [x] Add animated loading spinner
  + [ ] Add indentation to all message blocks to enable folding
  + [ ] Collapse sequences of empty lines
  + [ ] Add custom markdown formatting
    * [x] delineators (by role)
    * [ ] message blocks
    * [ ] @contexts
- [ ] Update :PromptModelSelect to update models if cache expired
  + ~/.local/share/nvim/prompt/history/2025-07-19T09:19:23-agent-prompt-models-expiry.md
- [x] Add command to manually trigger summary rename
- [ ] Add commands to navigate prompts by delineators (:PromptMessageNext, :PromptMessagePrev)
- [ ] Add command to set config values at runtime (:PromptConfigSet)
- [x] Rename make_openrouter_request to make_chat_completion_request
- [ ] Rename `get_prompt_summary` to `get_prompt_summary_filename`
- [ ] Add more providers support
- [ ] Enable multiple prompts simultaneously (just use files in history_dir, instead of a single shared buffer)
- [ ] Enable sumbitting to multiple models simultaneously?
- [ ] Model picker configurable format (select, filter, sort)
- [ ] Add leaderboard sorting to model picker
- [ ] Gracefully handle failed requests to out-of-date models
- [ ] Add "inline" prompts (meta+k) for code edits
- [ ] Add agent mode?
