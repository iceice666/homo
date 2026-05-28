use std::process::Command;

/// Create a fresh git worktree reset to HEAD.
pub fn add(project_root: &str, ticket_id: &str, worktree_path: &str) -> Result<(), String> {
    let status = Command::new("git")
        .args(["worktree", "add", worktree_path, "HEAD"])
        .current_dir(project_root)
        .status()
        .map_err(|e| e.to_string())?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("git worktree add failed for ticket {ticket_id}"))
    }
}

/// Remove a git worktree (force to handle dirty state).
pub fn remove(project_root: &str, worktree_path: &str) -> Result<(), String> {
    let status = Command::new("git")
        .args(["worktree", "remove", "--force", worktree_path])
        .current_dir(project_root)
        .status()
        .map_err(|e| e.to_string())?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("git worktree remove failed for {worktree_path}"))
    }
}
