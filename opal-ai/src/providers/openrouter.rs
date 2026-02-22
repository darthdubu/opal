use crate::context::Context;
use crate::error::{AiError, Result};
use crate::providers::AiProvider;
use crate::types::{Message, Response};
use async_trait::async_trait;

pub struct OpenRouterProvider {
    api_key: String,
    default_model: String,
    client: reqwest::Client,
}

impl OpenRouterProvider {
    pub fn new(api_key: String, default_model: String) -> Self {
        Self {
            api_key,
            default_model,
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl AiProvider for OpenRouterProvider {
    fn name(&self) -> &str {
        "openrouter"
    }

    async fn complete(
        &self,
        _context: &Context,
        _messages: Vec<Message>,
    ) -> Result<Response> {
        Err(AiError::NotImplemented("OpenRouter integration pending".to_string()))
    }
}
