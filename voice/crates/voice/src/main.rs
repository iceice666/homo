use std::process::ExitCode;
use voice_core::env::{EnvError, VoiceEnv};

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();

    if args.iter().any(|a| a == "--help" || a == "-h") {
        print_help();
        return ExitCode::SUCCESS;
    }
    if args.iter().any(|a| a == "--version") {
        println!("voice {}", env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }

    let env = match VoiceEnv::from_env() {
        Ok(e) => e,
        Err(EnvError(msg)) => {
            eprintln!("voice: {msg}");
            return ExitCode::from(2);
        }
    };

    // TODO: install SIGTERM handler → write partial report + exit 5
    // TODO: resolve adapter → set up worktree → run → write report → exit per result
    eprintln!(
        "voice: run={} ticket={} cli={} — not yet implemented",
        env.run_id, env.ticket_path, env.cli
    );
    ExitCode::from(2)
}

fn print_help() {
    println!(
        "voice — per-ticket agent harness

USAGE:
    voice [OPTIONS]

OPTIONS:
    -h, --help     Print this message
    --version      Print version

ENV VARS (set by Harmony, see CONTRACT.md):
    VOICE_TICKET_PATH    Absolute path to the ticket YAML
    VOICE_WORKSPACE      Absolute path to the git worktree
    VOICE_CLI            Adapter: claude | codex | gemini | cursor-agent
    VOICE_REPORT_PATH    Where voice writes the run report JSON
    VOICE_RUN_ID         Run ID string

EXIT CODES:
    0  completed   → ticket → reviewing
    1  failed      → retry with backoff; then → blocked
    2  hard-abort  → blocked, no retry
    3  infeasible  → specced, no retry
    4  needs-input → awaiting_input, no retry
    5  cancelled   → ready reset (SIGTERM response)"
    );
}
