use crate::report::{ExitReason, Infeasibility, Question, TokenUsage};

pub struct AdapterResult {
    pub exit_reason: ExitReason,
    pub turns: u32,
    pub token_usage: Option<TokenUsage>,
    pub notes: Option<String>,
    pub questions: Option<Vec<Question>>,
    pub infeasibility: Option<Infeasibility>,
}

/// Common interface for CLI adapters (claude, codex, gemini, cursor-agent).
pub trait Adapter {
    /// Check the CLI binary exists in PATH. Returns Err → exit 2.
    fn locate(&self) -> Result<(), String>;
    /// Build the CLI invocation args from ticket context.
    fn build_invocation(&self, ticket_path: &str) -> Vec<String>;
    /// Spawn the CLI in the workspace, stream stdout, return result.
    fn run(&self, workspace: &str, invocation: &[String]) -> Result<AdapterResult, String>;
}

/// Map VOICE_CLI string to an adapter. Returns Err → exit 2 if unknown.
pub fn resolve(cli: &str) -> Result<Box<dyn Adapter>, String> {
    match cli {
        "claude" => Err("claude adapter: not yet implemented".into()),
        "codex" => Err("codex adapter: not yet implemented".into()),
        "gemini" => Err("gemini adapter: not yet implemented (TBD in spec)".into()),
        "cursor-agent" => Err("cursor-agent adapter: not yet implemented (TBD in spec)".into()),
        other => Err(format!("unknown VOICE_CLI value: {other}")),
    }
}
