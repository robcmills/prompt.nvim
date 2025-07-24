
# Todo

## Bugs/Critical Features

- [x] Refactor filename summary to use static model (not current)
- [x] Add support for reasoning
- [x] Add reasoning delineators
- [ ] Enable cancellation of streaming request
  + [x] Ensure request is set to nil on request error
  + [ ] When stopping request, check if inside code block and if so, add closing ticks
- [ ] Gracefully handle failed requests to out-of-date models
- [ ] Add tests (all models)
- [ ] Add docs (help file)


## Improvements

- [ ] Refactor default config directory
  ~/.config/nvim/prompt/
- [ ] Pretty
  + [ ] Add indentation to all message blocks to enable folding
  + [ ] Collapse sequences of empty lines
  + [ ] Add custom markdown formatting (delineators, @mentions, reasoning)
  + [ ] Add better reasoning formatting (highlight delineator line)
- [ ] Add type annotations
- [ ] Update :PromptModelSelect to update models if cache expired
  + ~/.local/share/nvim/prompt_history/2025-07-19T09:19:23-agent-prompt-models-expiry.md
- [ ] Add support for adding `@mentions`
  + https://github.com/yetone/avante.nvim/tree/main#mentions
- [ ] Add command to manually trigger summary rename
- [ ] Rename make_openrouter_request to make_chat_completion_request
- [ ] Add more providers support
- [ ] Add sqlite db for storing more data
- [ ] Add token counts and costs stats
- [ ] Enable multiple prompts simultaneously (just use files in history_dir,
  instead of a single shared buffer)
- [ ] Model picker configurable format (select, filter, sort)
- [ ] Add leaderboard sorting to model picker
- [ ] UI
- [ ] Add "inline" prompts (meta+k) for code edits
- [ ] Add agent mode?
