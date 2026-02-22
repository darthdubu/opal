use crate::context::Context;
use crate::error::{AiError, Result};
use crate::providers::AiProvider;
use crate::types::{Message, MessageRole, Request, Response, Usage};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

pub struct OllamaProvider {
    base_url: String,
    default_model: String,
    client: reqwest::Client,
}

impl OllamaProvider {
    pub fn new(default_model: String) -> Self {
        Self {
            base_url: "http://localhost:11434".to_string(),
            default_model,
            client: reqwest::Client::new(),
        }
    }

    pub fn with_base_url(mut self, url: String) -> Self {
        self.base_url = url;
        self
    }
}

#[async_trait]
impl AiProvider for OllamaProvider {
    fn name(&self) -> &str {
        "ollama"
    }

    async fn complete(
        &self,
        context: &Context,
        messages: Vec<Message>,
    ) -> Result<Response> {
        let context_str = context.to_prompt_context();
        
        let system_msg = Message {
            role: MessageRole::System,
            content: format!(
                "You are Opal AI, a helpful terminal assistant.\n\nContext:\n{}",
                context_str
            ),
        };
        
        let mut all_messages = vec![system_msg];
        all_messages.extend(messages);
        
        let ollama_messages: Vec<OllamaMessage> = all_messages
            .into_iter()
            .map(|m| OllamaMessage {
                role: match m.role {
                    MessageRole::System => "system".to_string(),
                    MessageRole::User => "user".to_string(),
                    MessageRole::Assistant => "assistant".to_string(),
                },
                content: m.content,
            })
            .collect();
        
        let request = OllamaRequest {
            model: self.default_model.clone(),
            messages: ollama_messages,
            stream: false,
        };
        
        let url = format!("{}/api/chat", self.base_url);
        
        let response = self
            .client
            .post(&url)
            .json(&request)
            .send()
            .await
            .map_err(|e| AiError::Http(e))?;
        
        if !response.status().is_success() {
            let status = response.status();
            let text = response.text().await.unwrap_or_default();
            return Err(AiError::RequestFailed(format!(
                "Ollama request failed: {} - {}",
                status, text
            )));
        }
        
        let ollama_response: OllamaResponse = response
            .json()
            .await
            .map_err(|e| AiError::Json(e))?;
        
        Ok(Response {
            content: ollama_response.message.content,
            model: ollama_response.model,
            usage: None,
        })
    }
}

#[derive(Debug, Serialize)]
struct OllamaRequest {
    model: String,
    messages: Vec<OllamaMessage>,
    stream: bool,
}

#[derive(Debug, Serialize)]
struct OllamaMessage {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct OllamaResponse {
    model: String,
    message: OllamaMessage,
}
