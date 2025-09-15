<img alt="prompt.nvim logo.png" src="assets/logo.png" />

Prompt any language model directly from markdown files.

![promt.nvim demo.gif](assets/demo.gif)

## Features

- **Markdown-based prompts**: Write prompts in markdown files with automatic conversation parsing
- **Multiple models**: Uses OpenRouter API with access to various language models
- **Model selection**: Easy switching between different AI models
- **Streaming responses**: Real-time streaming of AI responses with support for reasoning output
- **Conversation history**: Automatic saving and loading of prompt conversations
- **Smart file management**: Automatic filename generation with AI-powered summaries
- **Split window support**: Open prompts in any window. They're just markdown files.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'robcmills/prompt.nvim',
  config = function()
    require('prompt').setup({
      -- Optional configuration (see Configuration section)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'robcmills/prompt.nvim',
  config = function()
    require('prompt').setup()
  end
}
```

## Prerequisites

1. **OpenRouter API Key**: Get your API key from [OpenRouter](https://openrouter.ai/)
2. **Environment Variable**: Set the `OPENROUTER_API_KEY` environment variable:
   ```bash
   export OPENROUTER_API_KEY="your-api-key-here"
   ```

## Dependencies

- `curl` is the only _required_ dependency.

### Optional Dependencies

- [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) this will greatly improve the aesthetics, especially the _code block syntax highlighting_.


## Quick Start

1. Create a new prompt file:
   ```vim
   :PromptNew
   ```

2. Write your prompt in the markdown file that opens

3. Submit your prompt to the AI:
   ```vim
   :PromptSubmit
   ```

4. AI response will be streamed directly into the file

### Conversation Format

The plugin uses a simple delineator format to separate messages:

```markdown
What is your favorite emoji? Respond with only the emoji character.

█ ● openrouter/horizon-beta: █

🙂

█ $ usage: █

Tokens: 19 prompt + 10 completion = 29 total | Cost: $0.0000

█ ○ user: █

What emoji best represents you?

█ ● openrouter/horizon-beta: █

🤝

█ $ usage: █

Tokens: 36 prompt + 11 completion = 47 total | Cost: $0.0000

█ ○ user: █
```

## Commands


| Command | Description |
|---------|-------------|
| `:PromptHistory` | Browse and open previous prompt conversations |
| `:PromptModelGet` | Display the currently selected model |
| `:PromptModelSelect` | Choose from available AI models |
| `:PromptModelsUpdate` | Update the list of available models from OpenRouter |
| `:PromptNew` | Create a new timestamped prompt file |
| `:PromptSplit` | Open a new prompt in a vertical split |
| `:PromptStop` | Stops any request streaming into current buffer |
| `:PromptSubmit` | Submit the current prompt to the AI model |


## Configuration

```lua
require('prompt').setup({
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
  model = "anthropic/claude-sonnet-4",
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
})
```

### History Management

- All conversations are automatically saved to your history directory
- Use `:PromptHistory` to browse and reopen previous conversations
- Files are automatically renamed with AI-generated summaries

### Use Telescope to search history

If you have [Telescope](https://github.com/nvim-telescope/telescope.nvim) installed, you can use it to search your history with previews:

```lua
:lua require('telescope.builtin').find_files({ cwd = '~/.local/share/nvim/prompt/history', find_command = { "bash", "-c", "ls -1 *.md | sort -r" } })
```

## Development Status

This plugin is under active development.
See [TODO.md](TODO.md) for planned features and improvements.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.
