use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ExitReason {
    Completed,
    Failed,
    HardAbort,
    Infeasible,
    NeedsInput,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenUsage {
    pub input: u64,
    pub output: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_read: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileChange {
    pub path: String,
    pub additions: u32,
    pub deletions: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Question {
    pub id: String,
    pub prompt: String,
    pub kind: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Infeasibility {
    pub reason: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub missing_prerequisites: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub suggested_spec_changes: Option<String>,
}

/// JSON run report written to VOICE_REPORT_PATH on exit (schema: score.run-report/v1).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunReport {
    pub schema: String,
    pub run_id: String,
    pub ticket_id: String,
    pub cli: String,
    pub exit_reason: ExitReason,
    pub started_at: String,
    pub finished_at: String,
    pub duration_seconds: u64,
    pub turns: u32,
    pub files_changed: Vec<FileChange>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token_usage: Option<TokenUsage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notes: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub evidence: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detected_clis: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub questions: Option<Vec<Question>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub infeasibility: Option<Infeasibility>,
}

impl RunReport {
    pub const SCHEMA: &'static str = "score.run-report/v1";
}
