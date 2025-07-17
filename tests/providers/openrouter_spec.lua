local openrouter = require("avante.providers.openrouter")

describe("OpenRouter Provider", function()
  describe("parse_model_shortcuts", function()
    it("should parse :nitro shortcut", function()
      local model, routing = openrouter.parse_model_shortcuts("deepseek/deepseek-r1:nitro")
      assert.are.equal("deepseek/deepseek-r1", model)
      assert.are.equal("throughput", routing.sort)
    end)

    it("should parse :floor shortcut", function()
      local model, routing = openrouter.parse_model_shortcuts("meta-llama/llama-3.1-70b-instruct:floor")
      assert.are.equal("meta-llama/llama-3.1-70b-instruct", model)
      assert.are.equal("price", routing.sort)
    end)

    it("should return original model if no shortcuts", function()
      local model, routing = openrouter.parse_model_shortcuts("deepseek/deepseek-r1")
      assert.are.equal("deepseek/deepseek-r1", model)
      assert.are.same({}, routing)
    end)
  end)

  describe("build_provider_routing", function()
    it("should build provider routing object with all options", function()
      local provider_conf = {
        provider_order = {"anthropic", "openai"},
        allow_fallbacks = false,
        require_parameters = true,
        data_collection = "deny",
        only_providers = {"anthropic"},
        ignore_providers = {"bad_provider"},
        quantizations = {"int4", "int8"},
        sort = "price",
        max_price = {
          prompt_tokens = 0.001,
          completion_tokens = 0.002,
        },
      }
      local request_body = {}

      openrouter.build_provider_routing(provider_conf, request_body)

      assert.are.same({
        order = {"anthropic", "openai"},
        allow_fallbacks = false,
        require_parameters = true,
        data_collection = "deny",
        only = {"anthropic"},
        ignore = {"bad_provider"},
        quantizations = {"int4", "int8"},
        sort = "price",
        max_price = {
          prompt_tokens = 0.001,
          completion_tokens = 0.002,
        },
      }, request_body.provider)
    end)

    it("should not add provider routing if no options are set", function()
      local provider_conf = {}
      local request_body = {}

      openrouter.build_provider_routing(provider_conf, request_body)

      assert.is_nil(request_body.provider)
    end)

    it("should only add configured options", function()
      local provider_conf = {
        provider_order = {"anthropic"},
        sort = "throughput",
      }
      local request_body = {}

      openrouter.build_provider_routing(provider_conf, request_body)

      assert.are.same({
        order = {"anthropic"},
        sort = "throughput",
      }, request_body.provider)
    end)
  end)
end)