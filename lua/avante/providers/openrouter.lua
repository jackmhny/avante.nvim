local Utils = require("avante.utils")
local Providers = require("avante.providers")

---@class AvanteProviderFunctor
local M = {}

M.api_key_name = "OPENROUTER_API_KEY"

---@return string|nil
function M.parse_api_key() return vim.env[M.api_key_name] end

M.role_map = {
  user = "user",
  assistant = "assistant",
}

---@return boolean
function M:is_disable_stream() return false end

---@param tool AvanteLLMTool
---@return AvanteOpenAITool
function M:transform_tool(tool)
  local input_schema_properties, required = Utils.llm_tool_param_fields_to_json_schema(tool.param.fields)
  ---@type AvanteOpenAIToolFunctionParameters
  local parameters = nil
  if not vim.tbl_isempty(input_schema_properties) then
    parameters = {
      type = "object",
      properties = input_schema_properties,
      required = required,
      additionalProperties = false,
    }
  end
  ---@type AvanteOpenAITool
  local res = {
    type = "function",
    ["function"] = {
      name = tool.name,
      description = tool.get_description and tool.get_description() or tool.description,
      parameters = parameters,
    },
  }
  return res
end

---@param opts AvantePromptOptions
---@return table[]
function M:parse_messages(opts)
  -- Inherit message parsing from OpenAI provider
  local openai = require("avante.providers.openai")
  return openai.parse_messages(self, opts)
end

---@param ctx AvanteContext
---@param data_stream string
---@param event_state table
---@param opts table|nil
---@return table|nil
function M:parse_response(ctx, data_stream, event_state, opts)
  -- Inherit response parsing from OpenAI provider
  local openai = require("avante.providers.openai")
  return openai.parse_response(self, ctx, data_stream, event_state, opts)
end

---@param provider_conf AvanteDefaultBaseProvider
---@param request_body table<string, any>
---@return nil
function M.build_provider_routing(provider_conf, request_body)
  ---@type table<string, any>
  local provider_routing = {}

  -- Handle provider order
  if provider_conf.provider_order and #provider_conf.provider_order > 0 then
    provider_routing.order = provider_conf.provider_order
  end

  -- Handle fallbacks
  if provider_conf.allow_fallbacks ~= nil then provider_routing.allow_fallbacks = provider_conf.allow_fallbacks end

  -- Handle parameter requirements
  if provider_conf.require_parameters ~= nil then
    provider_routing.require_parameters = provider_conf.require_parameters
  end

  -- Handle data collection policy
  if provider_conf.data_collection then provider_routing.data_collection = provider_conf.data_collection end

  -- Handle only specific providers
  if provider_conf.only_providers and #provider_conf.only_providers > 0 then
    provider_routing.only = provider_conf.only_providers
  end

  -- Handle ignored providers
  if provider_conf.ignore_providers and #provider_conf.ignore_providers > 0 then
    provider_routing.ignore = provider_conf.ignore_providers
  end

  -- Handle quantizations
  if provider_conf.quantizations and #provider_conf.quantizations > 0 then
    provider_routing.quantizations = provider_conf.quantizations
  end

  -- Handle sorting
  if provider_conf.sort then provider_routing.sort = provider_conf.sort end

  -- Handle max price
  if provider_conf.max_price then provider_routing.max_price = provider_conf.max_price end

  -- Only add provider routing if we have any routing preferences
  if next(provider_routing) ~= nil then request_body.provider = provider_routing end
end

---@param model string
---@return string, table<string, any>
function M.parse_model_shortcuts(model)
  ---@type table<string, any>
  local routing_config = {}

  -- Handle :nitro shortcut (sort by throughput)
  if model:match(":nitro$") then
    model = model:gsub(":nitro$", "")
    routing_config.sort = "throughput"
  end

  -- Handle :floor shortcut (sort by price)
  if model:match(":floor$") then
    model = model:gsub(":floor$", "")
    routing_config.sort = "price"
  end

  return model, routing_config
end

---@param prompt_opts AvantePromptOptions
---@return table<string, any>
function M:parse_curl_args(prompt_opts)
  ---@type AvanteDefaultBaseProvider, table<string, any>
  local provider_conf, request_body = Providers.parse_config(self)
  local disable_tools = provider_conf.disable_tools or false

  ---@type table<string, string>
  local headers = {
    ["Content-Type"] = "application/json",
    ["HTTP-Referer"] = "https://github.com/yetone/avante.nvim",
    ["X-Title"] = "Avante.nvim",
  }

  if Providers.env.require_api_key(provider_conf) then
    local api_key = self.parse_api_key()
    if api_key == nil then
      error("OpenRouter API key is not set, please set it in your environment variable or config file")
    end
    headers["Authorization"] = "Bearer " .. api_key
  end

  -- Parse model shortcuts and apply routing config
  local model, shortcut_routing = M.parse_model_shortcuts(provider_conf.model)
  provider_conf.model = model

  -- Merge shortcut routing with provider config
  for key, value in pairs(shortcut_routing) do
    if provider_conf[key] == nil then provider_conf[key] = value end
  end

  -- Build provider routing configuration
  M.build_provider_routing(provider_conf, request_body)

  -- Enable reasoning for OpenRouter
  request_body.include_reasoning = true

  local use_ReAct_prompt = provider_conf.use_ReAct_prompt == true

  ---@type table<integer, AvanteOpenAITool>|nil
  local tools = nil
  if not disable_tools and prompt_opts.tools and not use_ReAct_prompt then
    tools = {}
    for _, tool in ipairs(prompt_opts.tools) do
      table.insert(tools, self:transform_tool(tool))
    end
  end

  Utils.debug("endpoint", provider_conf.endpoint)
  Utils.debug("model", provider_conf.model)
  Utils.debug("provider routing", request_body.provider)

  return {
    url = Utils.url_join(provider_conf.endpoint, "/chat/completions"),
    proxy = provider_conf.proxy,
    insecure = provider_conf.allow_insecure,
    headers = Utils.tbl_override(headers, self.extra_headers),
    body = vim.tbl_deep_extend("force", {
      model = provider_conf.model,
      messages = self:parse_messages(prompt_opts),
      stream = true,
      stream_options = {
        include_usage = true,
      },
      tools = tools,
    }, request_body),
  }
end

return M
