---
description: Run a tabtabtab (gv-code) action — VMs, repos, webhooks, uploads, or kick off a remote agent
argument-hint: "<what you want to do, e.g. 'create a vm called demo' or 'kick off the agent on demo to fix the tests'>"
---

The user wants to do something on the tabtabtab platform: $ARGUMENTS

Use the `tabtabtab` skill (the `ttt` CLI) to do it. Check auth first with
`ttt whoami --json`; if not logged in, ask the user to run `ttt login`.
Prefer `--json` output, and when you start an agent session, show the user
the returned `sessionUrl`.
