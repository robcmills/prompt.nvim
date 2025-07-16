# prompt.nvim

<img src="logo.png" alt="prompt.nvim logo" width="100">

A Neovim plugin that enables seamless interaction with language models directly from markdown files. Create, manage, and submit prompts to various AI models through a simple, intuitive interface.

## Features

- **Markdown-based prompts**: Write prompts in markdown files with automatic conversation formatting
- **Multiple AI providers**: Support for OpenRouter API with access to various language models
- **Streaming responses**: Real-time streaming of AI responses with support for reasoning output
- **Conversation history**: Automatic saving and loading of prompt conversations
- **Smart file management**: Automatic filename generation with AI-powered summaries
- **Model selection**: Easy switching between different AI models
- **Split window support**: Open prompts in vertical splits for better workflow

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

4. The AI response will be streamed directly into your file with proper formatting

## Commands

| Command | Description |
|---------|-------------|
| `:PromptNew` | Create a new timestamped prompt file |
| `:PromptSplit` | Open a new prompt in a vertical split |
| `:PromptSubmit` | Submit the current prompt to the AI model |
| `:PromptHistory` | Browse and open previous prompt conversations |
| `:PromptModelGet` | Display the currently selected model |
| `:PromptModelSelect` | Choose from available AI models |

## Configuration

The plugin comes with sensible defaults, but you can customize it:

```lua
require('prompt').setup({
  -- Default model to use
  model = "anthropic/claude-sonnet-4",
  
  -- Format for chat message delineators
  chat_delineator = "● %s:",
  
  -- Directory for storing prompt history
  history_dir = "~/.local/share/nvim/prompt_history/",
  
  -- Path to models JSON file
  models_path = "~/.local/share/nvim/prompt_models.json",
  
  -- Date format for history filenames
  history_date_format = "%Y-%m-%dT%H:%M:%S",
  
  -- Maximum length for auto-generated filenames
  max_filename_length = 75,
})
```

## Usage

### Basic Workflow

1. **Create a new prompt**: Use `:PromptNew` to create a new markdown file
2. **Write your prompt**: Type your question or request in the file
3. **Submit**: Use `:PromptSubmit` to send your prompt to the AI
4. **Continue the conversation**: Add more messages and submit again

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

### Model Selection

1. Use `:PromptModelSelect` to see available models
2. Models are fetched from OpenRouter and cached locally
3. The selection is remembered for the current session

### History Management

- All conversations are automatically saved to your history directory
- Use `:PromptHistory` to browse and reopen previous conversations
- Files are automatically renamed with AI-generated summaries

## Advanced Features

### Streaming Support

The plugin supports real-time streaming of responses, including:
- Regular content streaming
- Reasoning output for models that support it (like Claude)

### Smart File Naming

When you submit a prompt from a timestamped file, the plugin:
1. Generates a summary of your first message
2. Automatically renames the file with the summary
3. Maintains the original timestamp prefix

### Split Window Workflow

Use `:PromptSplit` to open a new prompt in a vertical split, perfect for:
- Comparing different prompts
- Working on multiple conversations simultaneously
- Reference while writing new prompts

## Troubleshooting

### Common Issues

1. **API Key not found**: Ensure `OPENROUTER_API_KEY` is set in your environment
2. **Models not loading**: Check your internet connection and API key validity
3. **File permissions**: Ensure the history directory is writable

### Debug Information

The plugin provides error messages through Neovim's notification system. Check `:messages` for detailed error information.

## Development Status

This plugin is under active development. See [TODO.md](TODO.md) for planned features and improvements.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.