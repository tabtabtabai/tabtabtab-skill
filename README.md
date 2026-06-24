# tabtabtab-skill — drive tabtabtab from Claude Code & Codex

A skill/plugin that teaches Claude Code and Codex to remote-control the
[tabtabtab](https://tabtabtab.ai) platform through the official
[`tabtabtab` CLI](https://pypi.org/project/tabtabtab/): create cloud dev
environments, put repositories on them, start and steer remote agents (watch
their output live in your terminal), manage webhooks, and have the meta agent
build automations — all by just asking your local agent.

```
you ── Claude Code / Codex ── tabtabtab CLI ──► api.tabtabtab.ai          (auth, envs, repos)
                                          └──► <your-env>.tabtabtab.app   (agents, webhooks, meta agent)
```

> Ask your local agent things like:
> - *"create a tabtabtab env called demo-box and put acme/app on it"*
> - *"kick off an agent on demo-box to fix the failing tests, and watch it"*
> - *"what are my remote agents doing right now?"*
> - *"set up a weekday-9am automation that reviews open PRs and posts a digest"*
> - *"create a webhook for app that our alerting system can call"*

## What's in the box

| Piece | Path | What it does |
|---|---|---|
| Claude Code plugin | `.claude-plugin/` + `skills/` + `commands/` | Skill + `/ttt` slash command |
| Codex prompt | `codex/ttt.md` | `/ttt` custom prompt for Codex CLI |
| Installer | `install.sh` | Installs the CLI + skill + prompt |

The CLI itself is the first-party [`tabtabtab` package on PyPI](https://pypi.org/project/tabtabtab/) —
this repo adds no second CLI, just the agent-facing skill around it.

## Install

**Everything at once:**

```bash
git clone https://github.com/tabtabtabai/tabtabtab-skill.git
cd tabtabtab-skill && ./install.sh
```

**Claude Code, as a plugin:**

```
/plugin marketplace add tabtabtabai/tabtabtab-skill
/plugin install tabtabtab@tabtabtab
```

**Just the CLI:** `pip install tabtabtab` (or `uv tool install tabtabtab`, or
`curl -fsSL https://tabtabtab.ai/install.sh | sh`).

> The `agent` and `webhook` command groups need a recent CLI. If
> `tabtabtab agent --help` errors, upgrade: `pip install --upgrade tabtabtab`.

## Quickstart

```bash
tabtabtab auth login                  # browser OAuth
tabtabtab env create --name demo-box --git-user-name "Ada" --git-user-email ada@example.com
tabtabtab env use demo-box
tabtabtab repo add https://github.com/acme/app.git --yes

tabtabtab agent kick "Run the test suite and fix any failures" --project app --watch
# streams the remote agent's output right here until it finishes
```

## The command surface (what the skill teaches your agent)

### Environments
`env create / list / info / use / destroy`, `ssh`, `upload <files> --to <path>`
(rsync — any file type or size), `open` (attach a local editor).

### Upgrades
`upgrade status [--check]` (installed/available IDE, firmware, and CLI
versions), `upgrade run --available` (roll forward everything with an update),
`upgrade run --ide/--firmware/--cli <version>` (pin an exact release or a
testable `…-gv.<sha>` build). Same control plane as the web "Dev Mode" panel.

### Repositories
`repo add <git-url>` (registers + clones onto the env), `repo list`,
`repo sync`, `repo env list/add/rm` (per-repo secrets).

### Remote agents — the fun part
| Command | What it does |
|---|---|
| `agent kick "<prompt>"` | Prompt the **meta agent** (the env's orchestrator) |
| `agent kick "<prompt>" --project app` | Fresh agent session in one project |
| `agent kick ... --watch` | Stream the run in your terminal until idle |
| `agent list` | Recent sessions with busy/idle state |
| `agent tail <id> [--follow]` | Read (or live-stream) a session's messages |
| `agent last <id>` | Just the final assistant reply — script-friendly |
| `agent send <id> "<msg>" [--queue]` | Follow up on an existing session |
| `agent abort <id>` | Cancel a run |
| `agent status` | Everything at a glance: runs, attention items, PRs, automations |

Session IDs accept unique prefixes. Everything supports `--json`.

### The meta agent
`agent kick` without `--project` reaches the env's persistent meta agent,
which orchestrates the whole machine. Ask it in plain English to create
**automations** (cron-scheduled prompts — daily/weekdays/weekly/RRULE),
run **durable jobs** (tracked long-running work with background checks, e.g.
"keep rebasing PR #42 until CI passes and it merges"), spawn **workers**
across repos, or create projects and worktrees.

### Webhooks
`webhook create <name> [--project app]` returns a secret URL; every JSON POST
to it starts an agent run (project targets get a fresh git worktree per call):

```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"message": "CI failed on main — investigate and open a fix PR"}' \
  https://demo-box.tabtabtab.app/webhooks/<token>
```

`webhook list` (URLs masked; `--reveal` for the full secrets) and
`webhook revoke` manage them. The URL is the credential.

## Security notes

- CLI credentials live in `~/.config/gv/config.json` (mode 0600).
- Webhook URLs are bearer credentials — revoke any you no longer need.
- `env info --reveal` prints a real password; don't paste it into logs.

## License

[MIT](LICENSE)
