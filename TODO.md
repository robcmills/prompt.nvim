
## Todo

- [ ] Update :PromptModelSelect to update models if cache expired
- [ ] Add better reasoning formatting
- [ ] Add support for adding `@files`
- [ ] Add ability to include `@diagnostics`
- [ ] Add custom markdown formatting (delineators, files)
- [ ] Add support for thinking models
  + [x] Gemini 2.5
- [ ] Gracefully handle failed requests to out-of-date models
- [ ] Refactor delineators to use static hidden <!-- html comments -->
- [ ] Add custom labels
  assistant_label = "[● %s:]",
  reasoning_label = "[∴ reasoning:]",
  user_label = "[○ user:]",
- [ ] Refactor default config directory
  ~/.config/nvim/prompt/
- [ ] Refactor filename summary to use static model (not current)
- [ ] Add command to manually trigger summary rename
- [ ] Rename make_openrouter_request to make_chat_completion_request
- [ ] Add more providers support
- [ ] Add sqlite db for storing more data
- [ ] Add token counts and costs stats
- [ ] Enable multiple prompts simultaneously (just use files in history_dir,
  instead of a single shared buffer)
- [ ] Model picker configurable format (select), filter, sort
- [ ] Add leaderboard sorting to model picker
- [ ] Enable cancellation of streaming request
- [ ] UI
- [ ] Tests (all models)
- [ ] docs (help file)
- [ ] Add "inline" prompts (meta+k) for code edits
- [ ] Add agent mode?
