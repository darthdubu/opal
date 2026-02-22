pub mod context;
pub mod error;
pub mod providers;
pub mod types;

pub use context::Context;
pub use error::{AiError, Result};
pub use providers::{AiProvider, ProviderConfig};
pub use types::{Message, MessageRole, Request, Response};

use async_trait::async_trait;

#[async_trait]
pub trait AiHarness: Send + Sync {
    async fn complete(&self,
        context: &Context,
        messages: Vec<Message>,
    ) -> Result<Response>;
    
    async fn stream_complete(&self,
        context: &Context,
        messages: Vec<Message>,
    ) -> Result<Box<dyn futures::Stream<Item = Result<String>> + Send>>;
}
