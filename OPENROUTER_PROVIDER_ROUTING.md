# OpenRouter Provider Routing

This document explains the enhanced OpenRouter provider routing functionality in avante.nvim, which allows you to control which AI providers OpenRouter uses behind the scenes and how they are prioritized.

## 🚀 What's New

- **Full OpenRouter Provider Routing Support**: Control which providers OpenRouter uses and in what order
- **Model Shortcuts**: Use `:nitro` and `:floor` shortcuts for quick throughput and price optimization
- **Comprehensive Configuration**: Support for all OpenRouter routing parameters
- **Backward Compatibility**: Works with existing OpenRouter configurations

## 📋 Quick Start

### Basic OpenRouter Configuration

```lua
require('avante').setup({
  provider = "openrouter",
  providers = {
    openrouter = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "deepseek/deepseek-r1",
      -- Add provider routing options here
      provider_order = {"anthropic", "openai"},
      allow_fallbacks = true,
      sort = "price",
    },
  },
})
```

### Using Model Shortcuts

```lua
-- Prioritize throughput
model = "deepseek/deepseek-r1:nitro"

-- Prioritize lowest price  
model = "meta-llama/llama-3.1-70b-instruct:floor"
```

## 🔧 Configuration Options

### Provider Order
Control which providers to try first:
```lua
provider_order = {"anthropic", "openai", "together"}
```

### Fallback Control
```lua
allow_fallbacks = true  -- Allow backup providers (default: true)
```

### Parameter Requirements
```lua
require_parameters = true  -- Only use providers supporting all parameters (default: false)
```

### Data Collection Policy
```lua
data_collection = "deny"  -- "allow" | "deny" (default: "allow")
```

### Provider Filtering
```lua
only_providers = {"anthropic", "openai"}     -- Allow only these providers
ignore_providers = {"unreliable_provider"}  -- Skip these providers
```

### Quantization Filtering
```lua
quantizations = {"int4", "int8"}  -- Filter by quantization levels
```

### Sorting
```lua
sort = "price"  -- "price" | "throughput" | "latency"
```

### Price Limits
```lua
max_price = {
  prompt_tokens = 0.001,
  completion_tokens = 0.003,
}
```

## 📚 Complete Examples

### Cost-Optimized Configuration
```lua
require('avante').setup({
  provider = "openrouter_cheap",
  providers = {
    openrouter_cheap = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "meta-llama/llama-3.1-8b-instruct:floor",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 8192,
      },
      -- Cost optimization
      sort = "price",
      max_price = {
        prompt_tokens = 0.0005,
        completion_tokens = 0.001,
      },
      ignore_providers = {"expensive_provider"},
    },
  },
})
```

### Performance-Optimized Configuration
```lua
require('avante').setup({
  provider = "openrouter_fast",
  providers = {
    openrouter_fast = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "meta-llama/llama-3.1-70b-instruct:nitro",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 16384,
      },
      -- Performance optimization
      only_providers = {"together", "fireworks"},
      allow_fallbacks = false,
      sort = "throughput",
    },
  },
})
```

### Reliability-Focused Configuration
```lua
require('avante').setup({
  provider = "openrouter_reliable",
  providers = {
    openrouter_reliable = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "deepseek/deepseek-r1",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 16384,
      },
      -- Reliability optimization
      provider_order = {"anthropic", "openai", "together"},
      allow_fallbacks = true,
      require_parameters = true,
      data_collection = "deny",
    },
  },
})
```

### Multi-Provider Setup
```lua
require('avante').setup({
  provider = "openrouter",
  providers = {
    -- Default balanced configuration
    openrouter = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "deepseek/deepseek-r1",
      provider_order = {"anthropic", "openai", "together"},
      allow_fallbacks = true,
    },
    
    -- Fast responses for quick tasks
    openrouter_fast = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "meta-llama/llama-3.1-70b-instruct:nitro",
      only_providers = {"together", "fireworks"},
      allow_fallbacks = false,
    },
    
    -- Budget-friendly for large tasks
    openrouter_cheap = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "meta-llama/llama-3.1-8b-instruct:floor",
      sort = "price",
      max_price = {
        prompt_tokens = 0.0005,
        completion_tokens = 0.001,
      },
    },
  },
})
```

## 🔄 Using with Existing OpenAI Provider

You can also use OpenRouter routing with the existing OpenAI provider inheritance:

```lua
require('avante').setup({
  provider = "my_openrouter",
  providers = {
    my_openrouter = {
      __inherited_from = "openai",
      endpoint = "https://openrouter.ai/api/v1",
      api_key_name = "OPENROUTER_API_KEY",
      model = "deepseek/deepseek-r1:nitro",
      -- All OpenRouter routing options work here too
      provider_order = {"anthropic", "openai"},
      sort = "throughput",
    },
  },
})
```

## 🔍 Debugging

Enable debug logging to see provider routing in action:

```lua
require('avante').setup({
  debug = true,  -- Enable debug logging
  -- ... rest of config
})
```

This will log:
- The endpoint being used
- The model being requested  
- The provider routing configuration being sent to OpenRouter

## 🌐 Environment Variables

Set your OpenRouter API key:

```bash
export OPENROUTER_API_KEY="your_openrouter_api_key_here"
```

For scoped keys (recommended):
```bash
export AVANTE_OPENROUTER_API_KEY="your_openrouter_api_key_here"
```

## 📖 Provider Slugs Reference

Common OpenRouter provider slugs:
- `anthropic` - Anthropic (Claude models)
- `openai` - OpenAI (GPT models)
- `together` - Together AI
- `fireworks` - Fireworks AI
- `deepinfra` - DeepInfra
- `deepinfra/turbo` - DeepInfra Turbo endpoint
- `perplexity` - Perplexity AI
- `mistral` - Mistral AI
- `cohere` - Cohere

For the complete list, see [OpenRouter's provider documentation](https://openrouter.ai/docs/provider-routing).

## ⚡ Model Shortcuts

### `:nitro` - Throughput Priority
Appending `:nitro` to any model prioritizes throughput:
```lua
model = "deepseek/deepseek-r1:nitro"
-- Equivalent to: sort = "throughput"
```

### `:floor` - Price Priority  
Appending `:floor` to any model prioritizes lowest price:
```lua
model = "meta-llama/llama-3.1-70b-instruct:floor"
-- Equivalent to: sort = "price"
```

## 🔧 How It Works

1. **Detection**: The system automatically detects OpenRouter endpoints
2. **Shortcut Parsing**: Model shortcuts (`:nitro`, `:floor`) are parsed and applied
3. **Routing Configuration**: Provider routing preferences are built from your config
4. **Request Enhancement**: The `provider` object is added to the request body
5. **OpenRouter Processing**: OpenRouter uses your routing preferences to select providers

## 📝 Notes

- Provider routing only applies to OpenRouter endpoints
- Model shortcuts are automatically parsed and removed from the model name
- If no routing preferences are specified, OpenRouter uses its default load balancing
- The `include_reasoning` parameter is automatically enabled for reasoning model support
- All existing OpenRouter configurations continue to work without changes

## 🤝 Contributing

Found a bug or want to add a feature? Please check the [contributing guidelines](CONTRIBUTING.md) and open an issue or pull request.

## 📄 License

This feature is part of avante.nvim and follows the same license terms.