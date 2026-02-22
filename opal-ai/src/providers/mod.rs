use crate::context::Context;
use crate::error::Result;
use crate::types::{Message, Request, Response};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[async_trait]
pub trait AiProvider: Send + Sync {
    fn name(&self) -> &str;
    
    async fn complete(
        &self,
        context: &Context,
        messages: Vec<Message>,
    ) -> Result<Response>;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderConfig {
    pub provider_type: ProviderType,
    pub api_key: Option<String>,
    pub base_url: Option<String>,
    pub default_model: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ProviderType {
    Ollama,
    OpenRouter,
    OpenAi,
    Anthropic,
}

pub mod ollama;
pub mod openrouter;

pub use ollama::OllamaProvider;
pub use openrouter::OpenRouterProvider;
