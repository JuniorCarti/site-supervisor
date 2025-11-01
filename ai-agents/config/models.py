#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pydantic import BaseSettings, validator
from enum import Enum
import os

class ModelProvider(str, Enum):
    OPENAI = "openai"
    AZURE_OPENAI = "azure_openai"
    ANTHROPIC = "anthropic"
    LOCAL = "local"

class ModelConfig(BaseSettings):
    # Model Provider
    provider: ModelProvider = ModelProvider.OPENAI
    
    # OpenAI Configuration
    openai_api_key: str = ""
    openai_model: str = "gpt-4"
    openai_base_url: str = "https://api.openai.com/v1"
    
    # Model Parameters
    temperature: float = 0.1
    max_tokens: int = 2000
    timeout: int = 30
    
    # Application Settings
    flask_env: str = "development"
    flask_host: str = "0.0.0.0"
    flask_port: int = 5000
    agent_memory_path: str = "./agent_memory.json"
    log_level: str = "INFO"
    
    # Security
    api_key: str = "default-api-key-change-in-production"
    webhook_secret: str = "default-webhook-secret-change-me"
    
    # n8n Configuration
    n8n_base_url: str = "http://localhost:5678"
    n8n_api_key: str = "default-n8n-key"
    n8n_webhook_url: str = "http://localhost:5678/webhook/site-supervisor"
    
    @validator("openai_api_key")
    def validate_openai_key(cls, v):
        if not v:
            raise ValueError("OPENAI_API_KEY must be set in .env file")
        if not v.startswith("sk-"):
            raise ValueError("OPENAI_API_KEY must start with 'sk-'")
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = False

# Global configuration instance
config = ModelConfig()