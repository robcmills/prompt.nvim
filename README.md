<img alt="prompt.nvim logo.png" src="assets/logo.png" />

Prompt language models directly from markdown files.

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
● user:
What is the capital of France?

● anthropic/claude-sonnet-4:
The capital of France is Paris.

● user:
Tell me more about its history.
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
  history_date_format = "%Y-%m-%dT%H:%M:%S", -- for timestamped filenames
  history_dir = "~/.local/share/nvim/prompt/history/",
  icons = {
    assistant = "●",
    reasoning = "∴",
    user = "○",
  },
  max_filename_length = 75,
  model = "anthropic/claude-sonnet-4",
  models_path = "~/.local/share/nvim/prompt/models.json",
  spinner_chars = { "⠋", "⠙", "⠸", "⠴", "⠦", "⠇" },
  spinner_interval = 150,
})
```

### History Management

- All conversations are automatically saved to your history directory
- Use `:PromptHistory` to browse and reopen previous conversations
- Files are automatically renamed with AI-generated summaries

## Development Status

This plugin is under active development. Expect major breaking changes.
See [TODO.md](TODO.md) for planned features and improvements.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.
