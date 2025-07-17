# OpenRouter Provider Routing

This document explains how to use OpenRouter's provider routing features with avante.nvim to control which AI providers OpenRouter uses behind the scenes and how they are prioritized.

## Overview

OpenRouter allows you to route requests to the best available providers for your model. By default, requests are load balanced across the top providers to maximize uptime. With avante.nvim's OpenRouter integration, you can customize how your requests are routed using various configuration options.

## Basic Configuration

### Using the Built-in OpenRouter Provider

```lua
require('avante').setup({
  provider = "openrouter",
  providers = {
    openrouter = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "deepseek/deepseek-r1",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 16384,
      },
      -- Provider routing configuration (see below)
    },
  },
})
```

### Using OpenRouter with OpenAI Provider Inheritance

```lua
require('avante').setup({
  provider = "my_openrouter",
  providers = {
    my_openrouter = {
      __inherited_from = "openai",
      endpoint = "https://openrouter.ai/api/v1",
      api_key_name = "OPENROUTER_API_KEY",
      model = "deepseek/deepseek-r1",
      -- Provider routing configuration (see below)
    },
  },
})
```

## Provider Routing Configuration

### Provider Order

Specify which providers OpenRouter should try in order:

```lua
providers = {
  openrouter = {
    -- ... other config
    provider_order = {"anthropic", "openai", "together"},
  },
}
```

### Fallback Control

Control whether to allow backup providers when the primary is unavailable:

```lua
providers = {
  openrouter = {
    -- ... other config
    allow_fallbacks = true, -- default: true
  },
}
```

### Parameter Requirements

Only use providers that support all parameters in your request:

```lua
providers = {
  openrouter = {
    -- ... other config
    require_parameters = true, -- default: false
  },
}
```

### Data Collection Policy

Control whether to use providers that may store data:

```lua
providers = {
  openrouter = {
    -- ... other config
    data_collection = "deny", -- "allow" | "deny", default: "allow"
  },
}
```

### Provider Filtering

#### Allow Only Specific Providers

```lua
providers = {
  openrouter = {
    -- ... other config
    only_providers = {"anthropic", "openai"},
  },
}
```

#### Ignore Specific Providers

```lua
providers = {
  openrouter = {
    -- ... other config
    ignore_providers = {"provider_to_avoid"},
  },
}
```

### Quantization Filtering

Filter providers by quantization levels:

```lua
providers = {
  openrouter = {
    -- ... other config
    quantizations = {"int4", "int8"},
  },
}
```

### Provider Sorting

Sort providers by different criteria:

```lua
providers = {
  openrouter = {
    -- ... other config
    sort = "price", -- "price" | "throughput" | "latency"
  },
}
```

### Maximum Price

Set maximum pricing constraints:

```lua
providers = {
  openrouter = {
    -- ... other config
    max_price = {
      prompt_tokens = 0.001,
      completion_tokens = 0.002,
    },
  },
}
```

## Model Shortcuts

OpenRouter supports convenient shortcuts that can be appended to model names:

### Nitro Shortcut (Throughput Priority)

```lua
providers = {
  openrouter = {
    -- ... other config
    model = "deepseek/deepseek-r1:nitro", -- Prioritizes throughput
  },
}
```

This is equivalent to setting `sort = "throughput"`.

### Floor Shortcut (Price Priority)

```lua
providers = {
  openrouter = {
    -- ... other config
    model = "deepseek/deepseek-r1:floor", -- Prioritizes lowest price
  },
}
```

This is equivalent to setting `sort = "price"`.

## Complete Example

Here's a comprehensive example showing various routing configurations:

```lua
require('avante').setup({
  provider = "openrouter",
  providers = {
    openrouter = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "deepseek/deepseek-r1",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 16384,
      },
      -- Provider routing configuration
      provider_order = {"anthropic", "openai", "together"},
      allow_fallbacks = true,
      require_parameters = false,
      data_collection = "allow",
      ignore_providers = {"unreliable_provider"},
      sort = "price",
      max_price = {
        prompt_tokens = 0.001,
        completion_tokens = 0.003,
      },
    },
    
    -- Alternative configuration for high-throughput tasks
    openrouter_fast = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "meta-llama/llama-3.1-70b-instruct:nitro",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 16384,
      },
      only_providers = {"together", "fireworks"},
      allow_fallbacks = false,
    },
    
    -- Configuration for cost-sensitive tasks
    openrouter_cheap = {
      endpoint = "https://openrouter.ai/api/v1",
      model = "meta-llama/llama-3.1-8b-instruct:floor",
      timeout = 30000,
      context_window = 128000,
      extra_request_body = {
        temperature = 0.75,
        max_completion_tokens = 8192,
      },
      sort = "price",
      max_price = {
        prompt_tokens = 0.0005,
        completion_tokens = 0.001,
      },
    },
  },
})
```

## Environment Variables

Make sure to set your OpenRouter API key:

```bash
export OPENROUTER_API_KEY="your_openrouter_api_key_here"
```

Or if using a custom provider name:

```bash
export AVANTE_OPENROUTER_API_KEY="your_openrouter_api_key_here"
```

## Provider Slugs

For a complete list of valid provider names to use in the API, refer to the [OpenRouter provider schema](https://openrouter.ai/docs/provider-routing#json-schema-for-provider-preferences).

Common provider slugs include:
- `anthropic`
- `openai`
- `together`
- `fireworks`
- `deepinfra`
- `perplexity`
- `mistral`
- `cohere`

## Targeting Specific Provider Endpoints

Some providers offer multiple endpoints (e.g., default and turbo). You can target specific endpoints by using the exact provider slug:

```lua
providers = {
  openrouter = {
    -- ... other config
    provider_order = {"deepinfra/turbo", "anthropic", "openai"},
    allow_fallbacks = false,
  },
}
```

## Debugging

To debug provider routing, enable debug logging:

```lua
require('avante').setup({
  -- ... other config
  debug = true,
})
```

This will log information about:
- The endpoint being used
- The model being requested
- The provider routing configuration being sent to OpenRouter

## Notes

- Provider routing configurations are only applied when using OpenRouter endpoints
- Model shortcuts (`:nitro`, `:floor`) are automatically parsed and applied
- If no routing preferences are specified, OpenRouter uses its default load balancing strategy
- The `include_reasoning` parameter is automatically enabled for OpenRouter to support reasoning models