# Agent Notes

This repo is normally used from WSL1. Codex sandboxed command launch may fail because WSL1 cannot provide the user namespaces required by bubblewrap.

Do not spend time retrying failed sandboxed write/edit commands. For workspace file edits or other necessary commands that fail with the WSL1 bubblewrap/user namespace error, rerun with escalation and explain that the escalation is only to bypass the WSL1 sandbox launcher issue.

WSL2 is not available for this environment because local networking/security behavior differs from WSL1.
