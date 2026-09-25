# Agent Notes

This repo is normally used from WSL1. Codex sandboxed command launch may fail because WSL1 cannot provide the user namespaces required by bubblewrap.

Do not spend time retrying failed sandboxed write/edit commands. For workspace file edits or other necessary commands that fail with the WSL1 bubblewrap/user namespace error, rerun with escalation and explain that the escalation is only to bypass the WSL1 sandbox launcher issue. After seeing this specific sandbox error once in a session, use escalation directly for the same kind of necessary edit/test/run command instead of probing the sandbox again.

WSL2 is not available for this environment because local networking/security behavior differs from WSL1.

## Session handoff

At the start of each session, read `.codex/session-state.md` if it exists and
use it to restore the current objective and working context. Confirm its claims
against the worktree before making changes because the note may be stale.

After meaningful milestones, and before ending a work session, update
`.codex/session-state.md` with the current objective, completed work, modified
files, verification performed, decisions, known issues, and concrete next
steps. Keep it concise and never store credentials or other secrets there.
