---
description: Run a tabtabtab action — envs, repos, webhooks, uploads, or remote agents (kick/tail/send/status)
argument-hint: "<what you want, e.g. 'create an env called demo' or 'kick the agent on demo to fix the tests and watch it'>"
---

The user wants to do something on the tabtabtab platform: $ARGUMENTS

Use the `tabtabtab` skill (the official `tabtabtab` CLI) to do it. Check auth
first with `tabtabtab env list --json`; if unauthorized, ask the user to run
`tabtabtab auth login`. Prefer `--json` output, and when you start or message
an agent session, show the user the session URL.
