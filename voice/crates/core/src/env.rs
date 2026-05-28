use std::env;

/// Env vars set by Harmony when spawning Voice (see CONTRACT.md).
pub struct VoiceEnv {
    pub ticket_path: String,
    pub workspace: String,
    pub cli: String,
    pub report_path: String,
    pub run_id: String,
}

#[derive(Debug)]
pub struct EnvError(pub String);

impl std::fmt::Display for EnvError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "env error: {}", self.0)
    }
}

impl VoiceEnv {
    /// Read all required env vars. Returns Err (exit code 2) if any are missing.
    pub fn from_env() -> Result<Self, EnvError> {
        let get = |key: &str| {
            env::var(key).map_err(|_| EnvError(format!("{key} is not set")))
        };
        Ok(Self {
            ticket_path: get("VOICE_TICKET_PATH")?,
            workspace: get("VOICE_WORKSPACE")?,
            cli: get("VOICE_CLI")?,
            report_path: get("VOICE_REPORT_PATH")?,
            run_id: get("VOICE_RUN_ID")?,
        })
    }
}
