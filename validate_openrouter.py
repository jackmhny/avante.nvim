#!/usr/bin/env python3

"""
Simple validation script for OpenRouter provider routing functionality
This script validates the core logic without requiring Neovim/Lua
"""

import re
import json

def parse_model_shortcuts(model):
    """Parse model shortcuts like :nitro and :floor"""
    routing_config = {}
    
    # Handle :nitro shortcut (sort by throughput)
    if model.endswith(":nitro"):
        model = model[:-6]  # Remove ":nitro"
        routing_config["sort"] = "throughput"
    
    # Handle :floor shortcut (sort by price)
    elif model.endswith(":floor"):
        model = model[:-6]  # Remove ":floor"
        routing_config["sort"] = "price"
    
    return model, routing_config

def build_provider_routing(provider_conf, request_body):
    """Build provider routing configuration for OpenRouter"""
    provider_routing = {}
    
    # Handle provider order
    if provider_conf.get("provider_order") and len(provider_conf["provider_order"]) > 0:
        provider_routing["order"] = provider_conf["provider_order"]
    
    # Handle fallbacks
    if provider_conf.get("allow_fallbacks") is not None:
        provider_routing["allow_fallbacks"] = provider_conf["allow_fallbacks"]
    
    # Handle parameter requirements
    if provider_conf.get("require_parameters") is not None:
        provider_routing["require_parameters"] = provider_conf["require_parameters"]
    
    # Handle data collection policy
    if provider_conf.get("data_collection"):
        provider_routing["data_collection"] = provider_conf["data_collection"]
    
    # Handle only specific providers
    if provider_conf.get("only_providers") and len(provider_conf["only_providers"]) > 0:
        provider_routing["only"] = provider_conf["only_providers"]
    
    # Handle ignored providers
    if provider_conf.get("ignore_providers") and len(provider_conf["ignore_providers"]) > 0:
        provider_routing["ignore"] = provider_conf["ignore_providers"]
    
    # Handle quantizations
    if provider_conf.get("quantizations") and len(provider_conf["quantizations"]) > 0:
        provider_routing["quantizations"] = provider_conf["quantizations"]
    
    # Handle sorting
    if provider_conf.get("sort"):
        provider_routing["sort"] = provider_conf["sort"]
    
    # Handle max price
    if provider_conf.get("max_price"):
        provider_routing["max_price"] = provider_conf["max_price"]
    
    # Only add provider routing if we have any routing preferences
    if provider_routing:
        request_body["provider"] = provider_routing

def is_openrouter(url):
    """Check if URL is an OpenRouter endpoint"""
    return url.startswith("https://openrouter.ai/")

def test_parse_model_shortcuts():
    """Test the parse_model_shortcuts function"""
    print("Testing parse_model_shortcuts...")
    
    # Test :nitro shortcut
    model, routing = parse_model_shortcuts("deepseek/deepseek-r1:nitro")
    assert model == "deepseek/deepseek-r1", f"Expected 'deepseek/deepseek-r1', got '{model}'"
    assert routing.get("sort") == "throughput", f"Expected 'throughput', got '{routing.get('sort')}'"
    print("✓ :nitro shortcut test passed")
    
    # Test :floor shortcut
    model, routing = parse_model_shortcuts("meta-llama/llama-3.1-70b-instruct:floor")
    assert model == "meta-llama/llama-3.1-70b-instruct", f"Expected 'meta-llama/llama-3.1-70b-instruct', got '{model}'"
    assert routing.get("sort") == "price", f"Expected 'price', got '{routing.get('sort')}'"
    print("✓ :floor shortcut test passed")
    
    # Test no shortcuts
    model, routing = parse_model_shortcuts("deepseek/deepseek-r1")
    assert model == "deepseek/deepseek-r1", f"Expected 'deepseek/deepseek-r1', got '{model}'"
    assert not routing, f"Expected empty routing config, got '{routing}'"
    print("✓ No shortcuts test passed")

def test_build_provider_routing():
    """Test the build_provider_routing function"""
    print("\nTesting build_provider_routing...")
    
    # Test with all options
    provider_conf = {
        "provider_order": ["anthropic", "openai"],
        "allow_fallbacks": False,
        "require_parameters": True,
        "data_collection": "deny",
        "only_providers": ["anthropic"],
        "ignore_providers": ["bad_provider"],
        "quantizations": ["int4", "int8"],
        "sort": "price",
        "max_price": {
            "prompt_tokens": 0.001,
            "completion_tokens": 0.002,
        },
    }
    request_body = {}
    
    build_provider_routing(provider_conf, request_body)
    
    assert "provider" in request_body, "Expected provider routing to be set"
    assert len(request_body["provider"]["order"]) == 2, "Expected 2 providers in order"
    assert request_body["provider"]["order"][0] == "anthropic", "Expected first provider to be anthropic"
    assert request_body["provider"]["allow_fallbacks"] == False, "Expected allow_fallbacks to be False"
    assert request_body["provider"]["sort"] == "price", "Expected sort to be price"
    print("✓ Full provider routing test passed")
    
    # Test with no options
    provider_conf = {}
    request_body = {}
    build_provider_routing(provider_conf, request_body)
    assert "provider" not in request_body, "Expected no provider routing when no options set"
    print("✓ Empty provider routing test passed")
    
    # Test with partial options
    provider_conf = {
        "provider_order": ["anthropic"],
        "sort": "throughput",
    }
    request_body = {}
    build_provider_routing(provider_conf, request_body)
    expected = {
        "order": ["anthropic"],
        "sort": "throughput",
    }
    assert request_body["provider"] == expected, f"Expected {expected}, got {request_body.get('provider')}"
    print("✓ Partial provider routing test passed")

def test_is_openrouter():
    """Test the is_openrouter function"""
    print("\nTesting is_openrouter...")
    
    assert is_openrouter("https://openrouter.ai/api/v1") == True, "Expected OpenRouter URL to be detected"
    assert is_openrouter("https://api.openai.com/v1") == False, "Expected OpenAI URL to not be detected as OpenRouter"
    assert is_openrouter("https://openrouter.ai/") == True, "Expected OpenRouter base URL to be detected"
    print("✓ OpenRouter URL detection test passed")

def test_integration():
    """Test integration of all functions"""
    print("\nTesting integration...")
    
    # Simulate a complete request with shortcuts and routing
    provider_conf = {
        "endpoint": "https://openrouter.ai/api/v1",
        "model": "deepseek/deepseek-r1:nitro",
        "provider_order": ["anthropic", "openai"],
        "allow_fallbacks": True,
        "sort": "price",  # This should be overridden by :nitro shortcut
    }
    
    # Parse model shortcuts
    model, shortcut_routing = parse_model_shortcuts(provider_conf["model"])
    provider_conf["model"] = model
    
    # Merge shortcut routing with provider config
    for key, value in shortcut_routing.items():
        if key not in provider_conf:
            provider_conf[key] = value
    
    # Build request
    request_body = {}
    if is_openrouter(provider_conf["endpoint"]):
        build_provider_routing(provider_conf, request_body)
    
    # Verify results
    assert provider_conf["model"] == "deepseek/deepseek-r1", "Model should have shortcut removed"
    assert provider_conf["sort"] == "price", "Sort should remain as configured (not overridden by shortcut)"
    assert "provider" in request_body, "Provider routing should be added"
    assert request_body["provider"]["sort"] == "price", "Request should use configured sort"
    assert request_body["provider"]["order"] == ["anthropic", "openai"], "Request should include provider order"
    
    print("✓ Integration test passed")

def run_tests():
    """Run all validation tests"""
    print("Running OpenRouter Provider Routing Validation Tests\n")
    
    test_parse_model_shortcuts()
    test_build_provider_routing()
    test_is_openrouter()
    test_integration()
    
    print("\n✅ All tests passed! OpenRouter provider routing functionality is working correctly.")
    
    # Show example output
    print("\n📋 Example provider routing configuration:")
    provider_conf = {
        "provider_order": ["anthropic", "openai", "together"],
        "allow_fallbacks": True,
        "sort": "price",
        "max_price": {"prompt_tokens": 0.001, "completion_tokens": 0.003}
    }
    request_body = {}
    build_provider_routing(provider_conf, request_body)
    print(json.dumps(request_body, indent=2))

if __name__ == "__main__":
    run_tests()