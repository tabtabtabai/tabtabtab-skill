---
name: tabtabtab
description: Manage tabtabtab (gv-code / ttt) cloud dev environments with the `ttt` CLI. Use when the user wants to create/list/delete a tabtabtab VM, add a repository to one, create a webhook, upload files to a VM, SSH into a VM, or kick off a remote agent on tabtabtab/gv-code with a prompt.
---

# tabtabtab

`ttt` is a CLI for the tabtabtab platform (also called gv-code). Every user
"VM" (environment) is a cloud machine running the gv-code agent IDE at
`https://<vm-name>.tabtabtab.ai`. The CLI handles auth, VM lifecycle,
repository setup, webhooks, file uploads, and starting agent sessions.

If `ttt` is not on PATH, it lives at `bin/ttt` in this plugin's repo
(https://github.com/tabtabtabai/ttt-skill); it is a single Python 3.9+ file
with no dependencies.

## Ground rules

- Always pass `--json` when you need to parse output.
- Auth: run `ttt whoami --json` first. If it fails with "Not logged in",
  ask the user to run `ttt login` themselves (it opens a browser); do not run
  interactive login on their behalf. A token in `TTT_API_TOKEN`/`GV_API_TOKEN`
  also works.
- VM names: 3-30 chars, lowercase letters/numbers/hyphens. Users can have at
  most 5 VMs.
- Destructive commands (`vm delete`, `repo delete`) prompt for confirmation;
  pass `--yes` only when the user explicitly asked for the deletion.
- VM provisioning takes a few minutes. After `vm create`, poll
  `ttt vm get <name> --json` until `.status == "ready"` (every ~30s).

## Commands

### Account
```bash
ttt login                 # interactive browser OAuth — have the USER run this
ttt whoami --json         # check auth / current user
```

### VMs
```bash
ttt vm list --json
ttt vm create <name> [--git-name "Ada" --git-email ada@example.com] [--size regular|large]
ttt vm get <name> --json              # full record incl. status/step
ttt vm delete <name> [--yes]
ttt vm restart <name> --mode ide|instance|hard
ttt vm password <name> --json         # web login creds for https://<name>.tabtabtab.ai
ttt vm ssh <name> [command...]        # interactive or one-shot remote command
ttt vm cp <name> <files...> [--remote-path ~/uploads/]   # scp, any file type/size
```

### Repositories (clone a git repo onto a VM)
```bash
ttt repo list --json
ttt repo add <git-url> --vm <name> [--name app] [--branch main] [--path /home/user/app]
ttt repo sync <name>                  # re-run the clone/sync job
ttt repo github --vm <name> --json    # repos visible to the VM's GitHub connection
```
`repo add` requires a git remote URL. Private GitHub repos need the VM's
GitHub connection set up first (the user does this in the gv-code web UI).
After adding, sync status appears in `ttt repo list --json` (`syncStatus`).

### Webhooks (HTTP endpoints that start an agent session when POSTed to)
```bash
ttt webhook list --vm <name> --json     # includes full secret URLs + valid project targets
ttt webhook create <hook-name> --vm <name> [--project <project>]
ttt webhook revoke <hook-name-or-id> --vm <name>
```
- Default target is the VM's **meta agent** (can work across all projects).
- `--project` targets a specific project; valid values come from the
  `targets` array in `webhook list --json` (only GitHub-cloned projects qualify).
- The webhook URL is a secret (`https://<vm>.tabtabtab.ai/webhooks/<token>`).
  Anyone with it can start agent sessions — treat it like a credential. This
  is what you give to CI, GitHub Actions, Zapier, etc.
- Calling a webhook: `POST` JSON `{"message": "...", "attachments": [...]}`
  with no extra auth. Response includes `sessionUrl`.

### Kick off an agent / upload files
```bash
ttt kick <vm> "Fix the failing tests in my-app" [--project my-app] [--file report.md]
ttt upload <vm> notes.md data.csv [--project my-app] [--message "context docs"]
```
- `kick` starts a remote agent session with the prompt and prints the
  `sessionUrl` — always show that URL to the user so they can watch the run.
- Both reuse (or create) a webhook named `ttt-cli` on the VM.
- Webhook attachments: max 5 files / 50MB total, types limited to
  png, jpeg, webp, gif, txt, md, json, zip, csv. For anything else use
  `ttt vm cp` (scp over SSH, no limits).

## The meta agent

When `kick` runs without `--project`, the prompt goes to the VM's **meta
agent** — the orchestrator that manages the whole VM, not just one repo. It is
much more capable than a single project agent, so route requests like these to
it (plain English prompts; it has its own tools for all of this):

- **Automations (crons):** create/pause/inspect scheduled recurring prompts —
  once, daily, weekdays, weekly, or raw RRULE, with timezone — targeting the
  meta agent itself or any project on the VM.
  `ttt kick demo-box "Every weekday at 9am, check open PRs across my projects and Slack me a digest"`
- **Durable jobs:** long-lived tracked work with an end state and periodic
  background checks (e.g. babysit CI, watch a deploy until healthy).
  `ttt kick demo-box "Create a durable job: land PR #42 in my-app — keep rebasing and re-running CI until it's merged"`
- **Worker orchestration:** plan multi-repo work, spawn agent sessions in
  project worktrees, answer their permission requests, report progress.
  `ttt kick demo-box "Start workers to bump lodash in all three repos and open PRs"`
- **Projects & worktrees:** create new projects, manage worktrees.
- **Status:** `ttt kick demo-box "Status: what's running, what needs my attention?"`

Rule of thumb: a task *inside one repo* → `--project <name>`; anything about
scheduling, automations, multiple projects, monitoring, or the VM itself →
meta agent (no `--project`). Webhooks created with no `--project` likewise
target the meta agent, so external systems (CI, alerts) can feed it events
that it handles or fans out to projects.

## Recipes

**Spin up a VM and put a repo on it:**
```bash
ttt vm create demo-box
# poll until ready:
ttt vm get demo-box --json   # .status == "ready"
ttt repo add https://github.com/acme/app.git --vm demo-box
ttt kick demo-box "Explore the app repo and summarize the architecture" --project app
```

**Give an external system a trigger:** `ttt webhook create ci-hook --vm demo-box --project app --json`, then hand the returned `url` to the external system. Each POST starts a fresh agent session in a new worktree.

**Send local work to the cloud agent:** `ttt upload demo-box design.md --message "spec for the next task"`, then `ttt kick demo-box "Implement the spec in design.md" --project app`.

**Set up an automation:** `ttt kick demo-box "Create an automation: every day at 7am Europe/London, pull main in the app project, run the test suite, and open an issue if anything fails"` — the meta agent creates and manages the schedule on the VM.
