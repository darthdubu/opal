use thiserror::Error;

pub type Result<T> = std::result::Result<T, AiError>;

#[derive(Error, Debug)]
pub enum AiError {
    #[error("Provider not configured: {0}")]
    ProviderNotConfigured(String),

    #[error("Not implemented: {0}")]
    NotImplemented(String),

    #[error("Request failed: {0}")]
    RequestFailed(String),

    #[error("Invalid response: {0}")]
    InvalidResponse(String),

    #[error("Rate limited")]
    RateLimited,

    #[error("Context too large")]
    ContextTooLarge,

    #[error("Unknown error: {0}")]
    Unknown(String),

    #[error(transparent)]
    Http(#[from] reqwest::Error),

    #[error(transparent)]
    Json(#[from] serde_json::Error),
}
