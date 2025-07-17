local openai = require("avante.providers.openai")

describe("OpenAI Provider with OpenRouter", function()
  describe("parse_model_shortcuts", function()
    it("should parse :nitro shortcut", function()
      local model, routing = openai.parse_model_shortcuts("deepseek/deepseek-r1:nitro")
      assert.are.equal("deepseek/deepseek-r1", model)
      assert.are.equal("throughput", routing.sort)
    end)

    it("should parse :floor shortcut", function()
      local model, routing = openai.parse_model_shortcuts("meta-llama/llama-3.1-70b-instruct:floor")
      assert.are.equal("meta-llama/llama-3.1-70b-instruct", model)
      assert.are.equal("price", routing.sort)
    end)

    it("should return original model if no shortcuts", function()
      local model, routing = openai.parse_model_shortcuts("deepseek/deepseek-r1")
      assert.are.equal("deepseek/deepseek-r1", model)
      assert.are.same({}, routing)
    end)
  end)

  describe("build_provider_routing", function()
    it("should build provider routing object", function()
      local provider_conf = {
        provider_order = { "anthropic", "openai" },
        allow_fallbacks = false,
        sort = "price",
      }
      local request_body = {}

      openai.build_provider_routing(provider_conf, request_body)

      assert.are.same({
        order = { "anthropic", "openai" },
        allow_fallbacks = false,
        sort = "price",
      }, request_body.provider)
    end)
  end)

  describe("is_openrouter", function()
    it("should detect OpenRouter URLs", function()
      assert.is_true(openai.is_openrouter("https://openrouter.ai/api/v1"))
      assert.is_false(openai.is_openrouter("https://api.openai.com/v1"))
    end)
  end)
end)
