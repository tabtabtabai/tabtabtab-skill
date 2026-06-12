---
name: tabtabtab
description: Control tabtabtab (ttt) cloud dev environments with the official `tabtabtab` CLI. Use when the user wants to create or manage a tabtabtab VM/environment, add a repository to one, upload files, SSH in, create webhooks, kick off or talk to remote agents (including the meta agent), set up automations/scheduled jobs on tabtabtab, or check what their remote agents are doing.
---

# tabtabtab

The `tabtabtab` CLI controls the tabtabtab platform: cloud dev environments
("envs") that each run the tabtabtab agent IDE at `https://<env>.tabtabtab.app`.
Through it you can drive the remote machine end to end — create envs, put
repos on them, start and steer agent runs, watch their output live, manage
webhooks, and ask the meta agent to build automations.

## Setup and auth

```bash
tabtabtab auth login        # browser OAuth — have the USER run this, not you
tabtabtab env list --json   # check auth + see envs
tabtabtab env use <name>    # set the current env (avoids --env on every call)
```

- If `env list` fails with "Unauthorized", ask the user to run
  `tabtabtab auth login` themselves. Never run interactive login for them.
- If the CLI exits with "New tabtabtab version detected", run the upgrade
  command it prints, then retry.
- Every env-scoped command accepts `--env <name>` to override the current env.
- Agent/webhook commands (`tabtabtab agent --help`) need a recent CLI. If the
  group is missing, upgrade: `pip install --upgrade tabtabtab` (or the
  equivalent for how it was installed).

## Ground rules for agents

- Pass `--json` whenever you parse output (supported on: `env list`,
  `repo list`, `repo env list`, `agent list/kick/send/tail/last/status`,
  `webhook list/create`, `runtime previews`, `profile *`).
- You are in a non-TTY shell: commands that confirm will refuse without
  `--yes`; pass it only when the user explicitly asked for the destructive
  action (`env destroy`, `webhook revoke`, `repo env rm`).
- After `env create`, the command itself polls until ready (a few minutes).
- Always show the user the session URL printed by `agent kick`/`agent send`
  so they can open the run in the browser.

## Environments (cloud VMs)

```bash
tabtabtab env create                      # interactive; or pass --name, --git-user-name, --git-user-email
tabtabtab env list --json
tabtabtab env info [--reveal]             # URL, status; --reveal prints the web password
tabtabtab env use <name>                  # set current env
tabtabtab env destroy <name> --yes
tabtabtab ssh [-- <remote command>]       # SSH in (keys handled automatically)
tabtabtab upload <local paths...> --to <remote path>   # rsync any files to the env
tabtabtab open [opencode|claude|codex|vscode|cursor]   # attach a local editor (interactive)
```

## Repositories

```bash
tabtabtab repo add <git-url-or-local-dir> [--yes]   # register + clone onto the env
tabtabtab repo list --json                          # includes sync status
tabtabtab repo sync [--repo <name>]
tabtabtab repo env list --repo <name> [--reveal]    # repo secrets / env vars
tabtabtab repo env add KEY=VALUE --repo <name> [--secret]
```

## Remote agent control

This is the core power: run and steer agents on the env from here.

```bash
tabtabtab agent kick "<prompt>"                     # prompt the META AGENT (see below)
tabtabtab agent kick "<prompt>" --project <name>    # fresh session in one project
tabtabtab agent kick "<prompt>" --watch             # ...and stream output here until idle
tabtabtab agent list --json                         # recent sessions: id, project, busy/idle
tabtabtab agent tail <session-id> [--follow]        # read a session; --follow streams until idle
tabtabtab agent last <session-id>                   # just the last assistant reply (script-friendly)
tabtabtab agent send <session-id> "<message>" [--queue] [--watch]   # follow-up on an existing session
tabtabtab agent abort <session-id>                  # cancel a running session
tabtabtab agent status                              # all projects: what's running, attention items, PRs, automations
```

- Session IDs accept unique prefixes (`ses_195d9f` works).
- `agent send` on a busy session fails unless you pass `--queue`, which
  delivers the message when the current run finishes.
- Typical loop for delegated work: `kick --json` → note `sessionID` → do other
  things → `agent tail <id>` / `agent last <id>` to collect the result.
- Use `--watch` when the user wants to see the run as it happens; use the
  async loop when the task is long.

## The meta agent

`agent kick` without `--project` talks to the env's **meta agent** — the
persistent orchestrator for the whole machine (one durable session; your
prompts join its ongoing conversation). It is the right target for anything
beyond a single repo. Ask it in plain English to:

- **Create automations (crons):** scheduled recurring prompts — once, daily,
  weekdays, weekly, or raw RRULE, any timezone, targeting itself or any
  project. `tabtabtab agent kick "Every weekday at 9am Europe/London, review open PRs across my projects and post a digest"`
- **Run durable jobs:** long-lived tracked work with an end state and periodic
  background checks. `tabtabtab agent kick "Create a durable job: land PR #42 in my-app — keep rebasing and re-running CI until it merges"`
- **Orchestrate workers:** plan multi-repo changes, spawn agent sessions in
  project worktrees, answer their permission requests, report back.
- **Manage the machine:** create projects and worktrees, summarize what needs
  attention (`tabtabtab agent status` is the read-only view of this).

Routing rule: task inside one repo → `--project <name>`; scheduling,
automations, multi-repo work, monitoring, or questions about the env → meta
agent (no `--project`).

## Webhooks (let external systems start agent runs)

```bash
tabtabtab webhook create <name> [--project <name>]   # default target: the meta agent; full URL shown once
tabtabtab webhook list --json                        # URLs masked; add --reveal for the full secrets
tabtabtab webhook revoke <name-or-id> --yes
```

POSTing JSON to a webhook URL starts an agent run (project webhooks get a
fresh git worktree per call):

```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"message": "Nightly: update deps and open a PR if tests pass"}' \
  https://<env>.tabtabtab.app/webhooks/<token>
```

The URL **is** the credential — treat it like a secret, hand it to CI/GitHub
Actions/Zapier/alerting, and revoke it when no longer needed. The POST body
also accepts `attachments` (≤5 base64 data-URL files, ≤50MB total — png,
jpeg, webp, gif, txt, md, json, zip, csv).

## Recipes

**Stand up a working env from nothing:**
```bash
tabtabtab env create --name demo-box --git-user-name "Ada" --git-user-email ada@example.com
tabtabtab env use demo-box
tabtabtab repo add https://github.com/acme/app.git --yes
tabtabtab agent kick "Explore the app repo and summarize the architecture" --project app --watch
```

**Delegate work and collect it later:**
```bash
tabtabtab agent kick "Fix the flaky tests in api/ and push a branch" --project app --json   # → sessionID
# ... later ...
tabtabtab agent last ses_<id>
```

**Send context files, then act on them:**
```bash
tabtabtab upload design.md --to ~/workspace/app/
tabtabtab agent kick "Implement the spec in design.md" --project app
```

**Wire an external trigger:** `tabtabtab webhook create ci-failures --project app --json` → give the `url` to the alerting system; each POST becomes an agent run in a fresh worktree.

**Set up a recurring automation:** `tabtabtab agent kick "Create an automation: every day at 7am, pull main in app, run the test suite, and open an issue if anything fails"` — then verify with `tabtabtab agent status`.

**Check on everything:** `tabtabtab agent status` → running sessions, attention items, pending PRs, automations across all projects.
