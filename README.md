# ttt-skill — tabtabtab from Claude Code & Codex

A CLI + agent skill for the [tabtabtab](https://tabtabtab.ai) platform
(gv-code). Install it into Claude Code or Codex and your local agent can
create cloud VMs, put repositories on them, wire up webhooks, upload files,
and kick off remote tabtabtab agents — straight from your terminal.

```
you (Claude Code / Codex)
  └─ ttt CLI ──────────────► api.tabtabtab.ai          (auth, VMs, repos)
              └────────────► <your-vm>.tabtabtab.ai    (webhooks, uploads, agent kickoff)
```

## What's in the box

| Piece | Path | What it does |
|---|---|---|
| `ttt` CLI | `bin/ttt` | Single-file Python 3.9+ CLI, zero dependencies |
| Claude Code plugin | `.claude-plugin/` + `skills/` + `commands/` | Skill + `/ttt` slash command |
| Codex prompt | `codex/ttt.md` | `/ttt` custom prompt for Codex CLI |
| Installer | `install.sh` | Sets up all of the above |

## Install

**Everything at once (CLI + Claude skill + Codex prompt):**

```bash
git clone https://github.com/tabtabtabai/ttt-skill.git
cd ttt-skill && ./install.sh
```

**Claude Code, as a plugin** (instead of the raw skill):

```
/plugin marketplace add tabtabtabai/ttt-skill
/plugin install tabtabtab@tabtabtab
```

**Just the CLI:**

```bash
curl -fsSL https://raw.githubusercontent.com/tabtabtabai/ttt-skill/main/bin/ttt -o ~/.local/bin/ttt
chmod +x ~/.local/bin/ttt
```

Requires Python 3.9+ (preinstalled on macOS and most Linux distros).

## Quickstart

```bash
ttt login                       # opens your browser (OAuth)
ttt vm create demo-box          # provision a cloud dev VM (~few minutes)
ttt vm get demo-box --json      # poll until .status == "ready"

ttt repo add https://github.com/acme/app.git --vm demo-box   # clone repo onto the VM
ttt kick demo-box "Run the test suite and fix any failures" --project app
# → prints a sessionUrl you can open to watch the agent work
```

Or from inside Claude Code / Codex, just ask:

> /ttt create a vm called demo-box and add my acme/app repo to it

## Commands

### Auth
| Command | Notes |
|---|---|
| `ttt login` / `ttt logout` | Browser OAuth (PKCE). Tokens stored in `~/.config/ttt/config.json` |
| `ttt whoami` | Current user |

Headless/CI: set `TTT_API_TOKEN` (or `GV_API_TOKEN`) instead of logging in.

### VMs
| Command | Notes |
|---|---|
| `ttt vm list` | All your environments |
| `ttt vm create <name>` | `--size regular\|large`, git identity defaults from local git config |
| `ttt vm get <name>` | Full record (status, step, URL, IP) |
| `ttt vm delete <name>` | Confirmation prompt; `--yes` to skip |
| `ttt vm restart <name>` | `--mode ide\|instance\|hard` |
| `ttt vm password <name>` | Reveal web-UI credentials |
| `ttt vm ssh <name> [cmd]` | SSH in (fetches the key automatically) |
| `ttt vm cp <name> <files...>` | scp files/dirs to the VM — any type, any size |

### Repositories
| Command | Notes |
|---|---|
| `ttt repo add <git-url> --vm <name>` | Registers + clones onto the VM; `--branch`, `--path`, `--name` |
| `ttt repo list` | Includes sync status |
| `ttt repo sync <name>` | Re-run the sync job |
| `ttt repo github --vm <name>` | GitHub repos the VM's GitHub connection can see |

Private repos need the VM's GitHub connection authorized once via the gv-code
web UI (`https://<vm>.tabtabtab.ai`).

### Webhooks
| Command | Notes |
|---|---|
| `ttt webhook create <name> --vm <vm> [--project p]` | Returns a secret URL |
| `ttt webhook list --vm <vm>` | URLs + valid project targets |
| `ttt webhook revoke <name-or-id> --vm <vm>` | Kill a leaked/old URL |

POSTing JSON to a webhook URL starts a fresh agent session on the VM (in a
new git worktree for project targets):

```bash
curl -X POST https://demo-box.tabtabtab.ai/webhooks/<token> \
  -H 'Content-Type: application/json' \
  -d '{"message": "Nightly: update deps and open a PR if tests pass"}'
```

No other auth needed — the URL **is** the credential. Perfect for GitHub
Actions, cron, Zapier, alerting systems, etc.

### Agent kickoff & file upload
| Command | Notes |
|---|---|
| `ttt kick <vm> "<prompt>"` | Starts a remote agent session, prints `sessionUrl`. `--project`, `--file` (repeatable) |
| `ttt upload <vm> <files...>` | Puts files into the agent workspace. `--message` adds context |

Webhook-based uploads accept ≤5 files / ≤50MB total of
png, jpeg, webp, gif, txt, md, json, zip, csv. Anything else: `ttt vm cp`.

Without `--project`, `kick` talks to the VM's **meta agent** — the
orchestrator for the whole machine. Ask it in plain English to:

- create **automations** (scheduled/recurring prompts: daily, weekdays,
  weekly, or RRULE — targeting itself or any project)
- run **durable jobs** (tracked long-running work with background checks,
  e.g. "keep rebasing PR #42 and re-running CI until it merges")
- **orchestrate workers** across multiple repos, create projects/worktrees,
  and report what's running and what needs attention

```bash
ttt kick demo-box "Every weekday at 9am, review open PRs across my projects and post a digest"
```

Every command supports `--json` for machine-readable output (what the agent
skills use).

## Feature status

Implemented entirely against the existing tabtabtab API — no backend changes:

- ✅ VM create / list / delete / restart / SSH
- ✅ Add repositories (clone onto a VM)
- ✅ Webhook create / list / revoke
- ✅ File upload (webhook attachments + scp)
- ✅ Kick off remote agents with a prompt

Needs platform-side work before this CLI can support it (tracked upstream):

- ⏳ Long-lived API keys / personal access tokens (today: browser OAuth only,
  so fully headless first-time setup isn't possible)
- ⏳ Webhook management on the control plane (today: managed per-VM, and the
  VM must be `ready`)
- ⏳ Arbitrary-type / >50MB uploads over HTTPS (today: scp covers it)

## Security notes

- OAuth tokens live in `~/.config/ttt/config.json` (mode 0600); SSH keys are
  cached in `~/.config/ttt/keys/` (mode 0600).
- Webhook URLs are bearer credentials. Revoke any URL you no longer need.
- `ttt vm password` prints a real credential — don't paste it into logs.

## Development

`bin/ttt` is intentionally one file with no dependencies. Lint/test:

```bash
python3 -m py_compile bin/ttt
./bin/ttt --help
```

PRs welcome.

## License

[MIT](LICENSE)
