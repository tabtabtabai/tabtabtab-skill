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
- **The remote agent does the work on the env — don't SSH in and do it
  yourself.** This is the single most important habit, and the easiest to get
  wrong. For anything that has to happen *on the env* — generate a
  PDF/report/export, convert/build/compress a file, run a script or test
  suite, scaffold or edit code, set something up, install a tool — describe
  the desired outcome to the meta agent with
  `tabtabtab agent kick "<what you want done>"` (or `--project <name>` to scope
  it to one repo) and let it do the work. It has a full shell and **will
  install whatever is missing** (converters, packages, CLIs) on its own, so
  **never pre-check "is X installed?", hunt for a tool, or hand-run the steps
  over `tabtabtab ssh`** — just ask for the result, then collect any file it
  produced with `tabtabtab download`. If you catch yourself about to run
  `tabtabtab ssh ... -- <command>` to accomplish a task, stop and `agent kick`
  it instead.
- **"What's going on in the env?" → ask the meta agent, do NOT SSH in.**
  Same principle for *reading* state: questions like what agents are running,
  what needs attention, what happened in a project, whether a build/deploy/PR
  is okay, "what's the status of X", "is anything stuck", "catch me up" →
  `tabtabtab agent status` (structured overview) or
  `tabtabtab agent kick "<their question>"` (the meta agent investigates across
  every project and replies). It has live cross-project context — sessions,
  worktrees, PRs, attention items, automations — that raw SSH cannot see.
- `tabtabtab ssh` is a **last resort**, used only when the user explicitly
  asks to open a shell on the box themselves. It is not your tool for getting
  work done — the agent is.

## Environments (cloud VMs)

```bash
tabtabtab env create                      # interactive; or pass --name, --git-user-name, --git-user-email
tabtabtab env list --json
tabtabtab env info [--reveal]             # URL, status; --reveal prints the web password
tabtabtab env use <name>                  # set current env
tabtabtab env destroy <name> --yes
tabtabtab ssh [-- <remote command>]       # last resort — to DO work on the env, `agent kick` it; the agent installs what's needed
tabtabtab upload <local paths...> --to <remote path>   # rsync any files to the env
tabtabtab open [opencode|claude|codex|vscode|cursor]   # attach a local editor (interactive)
```

## Upgrading the runtime (IDE / firmware / CLI)

Each env runs three independently versioned components: the **IDE** (`gv_code`,
the agent IDE itself), the **firmware** (`nero`, the on-box runtime), and the
on-box **CLI**. `tabtabtab upgrade` drives the same control plane as the web
"Dev Mode" panel, so you can roll an env forward to the latest release or pin an
exact testable build (e.g. a `…-gv.<sha>` preview published by gv-code/nero).

```bash
tabtabtab upgrade status [--check]                       # show installed/available versions; --check probes the box
tabtabtab upgrade run --available                        # upgrade everything that has an update
tabtabtab upgrade run --ide <version>                    # pin an exact IDE (gv_code) build
tabtabtab upgrade run --firmware <version> --cli <version>   # pin firmware and/or CLI
tabtabtab upgrade run ... --no-wait                      # start the job and return immediately
```

- `--ide`/`--firmware`/`--cli` take an exact version and can be combined; blank
  components are skipped. `--available` upgrades only components reporting an
  update. The command streams job progress and exits non-zero if it fails.
- Use exact versions for **testable** builds (preview/PR versions like
  `1.61.4-gv.normaldb.ea8313736464`); use `--available` for normal releases.

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

## Getting files back (env → local)

The pattern for "make me X and download it" is always **agent produces →
`download`**, never "SSH in and build it myself." Tell the agent to create the
file (it installs any converter/tool it needs), then pull it:

```bash
# user: "turn japan-itinerary.xlsx into a PDF and download it"
tabtabtab agent kick "Convert ~/workspace/trip/japan-itinerary.xlsx to a PDF at \
  ~/workspace/trip/japan-itinerary.pdf. Install whatever converter you need." --watch
tabtabtab download ~/workspace/trip/japan-itinerary.pdf
```

Do **not** `tabtabtab ssh` in to look for libreoffice/pandoc/etc. or run the
conversion yourself — that's the agent's job and it will set up dependencies
on its own.

When a remote agent **produces a file** — a PDF, a build artifact, a report,
an export — it lives in the env's filesystem, not locally. Pull it with
`tabtabtab download` (the symmetric counterpart of `upload`; works on binaries
like PDFs):

```bash
tabtabtab download <remote path...> [--to <local dir>] [--force]
```

```bash
tabtabtab download ~/workspace/app/report.pdf                 # → ./report.pdf
tabtabtab download ~/workspace/app/dist --to ./out            # a whole directory
tabtabtab download ~/a.log ~/b.log --to ./logs --force        # many files, overwrite
```

- Remote paths are absolute or `~`-relative on the env. `--to` defaults to the
  current directory and is created if missing. `--force` overwrites existing
  local files (default: skip existing).

**Get the remote path first.** The agent usually states where it wrote the
file; if not, ask it: `tabtabtab agent send <session-id> "What's the absolute
path of the file you created?"` then `tabtabtab agent last <session-id>`.
Project files live under that project's worktree (the session's directory).

After downloading, tell the user the local path (and, in Claude Code, you can
then read/preview the file).

> Fallback if your CLI predates `download` (added in the agent/webhook release):
> `tabtabtab ssh --env <env> -- cat /abs/path/report.pdf > report.pdf` is
> binary-safe; for a directory, `tabtabtab ssh --env <env> -- tar czf - -C
> /abs/path/dir . > dir.tgz`. Upgrade with `pip install --upgrade tabtabtab`.

## The meta agent

`agent kick` without `--project` talks to the env's **meta agent** — the
persistent orchestrator for the whole machine (one durable session; your
prompts join its ongoing conversation). It is the right target for anything
beyond a single repo. Ask it in plain English to:

- **Tell you what's going on (the default for any "status" question):** it sees
  every project, running session, worktree, PR, and automation at once. Use
  `tabtabtab agent status` for the structured snapshot, or
  `tabtabtab agent kick "What's happening across my projects? Anything stuck or
  needing me?"` for a narrative answer. This is what to reach for instead of
  SSHing in to look around.
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
automations, multi-repo work, monitoring, or **any question about the state of
the environment** → meta agent (no `--project`), never SSH.

## Webhooks (let external systems start agent runs)

```bash
tabtabtab webhook create <name> [--project <name>]   # default target: the meta agent; full URL shown once
tabtabtab webhook list --json                        # URLs masked; add --reveal for the full secrets
tabtabtab webhook revoke <name-or-id> --yes
```

The URL **is** the credential — treat it like a secret, hand it to CI/GitHub
Actions/Zapier/alerting, and revoke it when no longer needed.

### How a created webhook's URL actually works

There is exactly **one endpoint** behind the secret URL, and it does both the
prompting and the file upload in a single call — there is no separate upload
API:

```
POST https://<env>.tabtabtab.app/webhooks/<token>
Content-Type: application/json
(no auth header — the <token> in the path is the credential)

{
  "message": "<the prompt for the agent>",          // optional
  "attachments": [ ...up to 5 files... ]             // optional
}
```

Every POST **starts a new agent run** and returns immediately (fire-and-forget):
- `--project` webhook → a fresh git worktree + new session in that project.
- meta webhook → a turn on the persistent meta agent.

**Prompting API** = the `message` field. It becomes the agent's prompt verbatim.
If you omit it but send attachments, the agent gets a default "files received"
prompt; omit everything and the raw JSON is handed to the agent. So for useful
work, always send `message`.

**File-upload API** = the `attachments` array, inline in the same POST. Each
entry:

```json
{
  "type": "file",                       // "file" or "image"
  "name": "report.md",                  // filename (1–255 chars)
  "contentType": "text/markdown",       // must be one of the allowed types below
  "data": "data:text/markdown;base64,<BASE64>"   // a base64 data URL; its media type MUST equal contentType
}
```

- Limits: **≤5 attachments, ≤50MB total.**
- Allowed `contentType`s only: `image/png`, `image/jpeg`, `image/webp`,
  `image/gif`, `text/plain`, `text/markdown`, `application/json`,
  `application/zip`, `text/csv`. Anything else is rejected — zip it, or use
  `tabtabtab upload` (scp, no type/size limit) for the file and just reference
  its path in `message`.
- Uploaded files land in the session workspace at
  `.attachments/incoming-webhook/<webhook-name>/att-<n>-<filename>`, and the
  agent's prompt automatically gets an "Attached files:" list of those paths,
  so it knows where to find them.

**Response** (JSON) — keep `sessionUrl` to watch or reference the run:

```json
{
  "ok": true, "authenticated": true,
  "webhookId": "...", "sessionID": "ses_...", "messageID": "msg_...",
  "sessionUrl": "https://<env>.tabtabtab.app/<...>/session/ses_...",
  "target": { "type": "project", "value": "<projectId>" },   // or {"type":"meta","value":"meta"}
  "echo": { "message": "...", "attachments": [ {name, path, contentType, size}, ... ] }
}
```

Prompt only:

```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"message": "Nightly: update deps and open a PR if tests pass"}' \
  https://<env>.tabtabtab.app/webhooks/<token>
```

Prompt + a file (build the base64 data URL inline):

```bash
B64=$(base64 < notes.md | tr -d '\n')
curl -X POST -H 'Content-Type: application/json' \
  -d "$(printf '{"message":"Act on the attached notes.","attachments":[{"type":"file","name":"notes.md","contentType":"text/markdown","data":"data:text/markdown;base64,%s"}]}' "$B64")" \
  https://<env>.tabtabtab.app/webhooks/<token>
```

To send a follow-up to the *same* session a webhook started (instead of a new
run each time), grab the `sessionID` from the response and use
`tabtabtab agent send <sessionID> "<message>"`.

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
