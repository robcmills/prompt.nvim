
## Todo

- [ ] Add better reasoning formatting
- [ ] Add custom markdown formatting (delineators, files)
- [ ] Add support for thinking models
  + [x] Gemini 2.5
- [ ] Add custom labels
  assistant_label = "[● %s:]",
  reasoning_label = "[∴ reasoning:]",
  user_label = "[○ user:]",
- [ ] Refactor default config directory
  ~/.config/nvim/prompt/
- [ ] Add command to update models
- [ ] Refactor filename summary to use static model (not current)
- [ ] Add command to manually trigger summary rename
- [ ] Add more providers support
- [ ] Add token counts and costs stats
- [ ] Add sqlite db for storing more data
- [ ] Enable multiple prompts simultaneously (just use files in history_dir,
  instead of a single shared buffer)
- [ ] Model picker configurable format (select), filter, sort
- [ ] Add leaderboard sorting to model picker
- [ ] Add support for attaching files
- [ ] Enable cancellation of streaming request
- [ ] UI
- [ ] Tests (all models)
- [ ] docs (help file)
- [ ] Add "inline" prompts (meta+k) for code edits
- [ ] Add agent mode?
