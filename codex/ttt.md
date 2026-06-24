# tabtabtab (ttt) — remote-control cloud dev environments

Use the official `tabtabtab` CLI to manage tabtabtab cloud
environments and to run and steer remote agents on them.

Rules:
- Pass `--json` whenever you parse output.
- Check auth with `tabtabtab env list --json`. On "Unauthorized", ask the user
  to run `tabtabtab auth login` (interactive browser flow) — never run it
  yourself. If the CLI demands an upgrade, run the command it prints.
- Set the working env once with `tabtabtab env use <name>`; or pass
  `--env <name>` per command.
- Non-TTY shell: destructive commands (`env destroy`, `webhook revoke`)
  refuse without `--yes`; pass it only when the user explicitly asked.
- The remote agent does work ON the env — don't SSH in and do it yourself.
  To generate/convert/build a file, run a script, install a tool, or set
  something up, `tabtabtab agent kick "<desired outcome>"` (or `--project p`)
  and let the agent do it — it has a full shell and installs whatever's
  missing on its own. Never pre-check "is X installed?" or hand-run steps over
  `tabtabtab ssh`. Then pull any produced file with `tabtabtab download`.
- "What's going on in the env?" (status, what's running, what needs attention,
  is X stuck, catch me up) → `tabtabtab agent status` or `tabtabtab agent kick
  "<their question>"` (meta agent), never SSH — it has cross-project context
  SSH lacks. `tabtabtab ssh` is a last resort, only when the user explicitly
  asks to open a shell themselves.

Commands:
- Envs: `tabtabtab env create|list|info|use|destroy`, `tabtabtab ssh`,
  `tabtabtab upload <files> --to <path>` (local→env), `tabtabtab download
  <remote paths...> [--to <local dir>] [--force]` (env→local; use this to pull
  agent-produced files like PDFs/build outputs, binary-safe).
- Repos: `tabtabtab repo add <git-url> --yes`, `repo list --json`,
  `repo sync`, `repo env list|add|rm` (secrets).
- Upgrades: `tabtabtab upgrade status [--check]` shows installed/available IDE
  (`gv_code`), firmware (`nero`), and CLI versions; `tabtabtab upgrade run
  --available` rolls forward everything with an update, or pin exact (incl.
  testable `…-gv.<sha>`) builds with `--ide|--firmware|--cli <version>`.
- Agents: `tabtabtab agent kick "<prompt>" [--project p] [--watch] [--json]`
  starts a run — meta agent by default, fresh project session with
  `--project`. `agent list`, `agent tail <id> [--follow]`, `agent last <id>`,
  `agent send <id> "<msg>" [--queue]`, `agent abort <id>`, `agent status`.
  Session IDs accept unique prefixes. Always show the user the session URL.
- Webhooks: `tabtabtab webhook create <name> [--project p] --json` returns a
  secret URL (shown once). One no-auth endpoint behind it does both prompting
  and upload in a single POST: `POST <url>` `{"message":"<prompt>",
  "attachments":[{"type":"file","name":"x.md","contentType":"text/markdown",
  "data":"data:text/markdown;base64,<b64>"}]}` — each POST starts a new agent
  run (fresh worktree for project targets) and returns `{sessionID,
  sessionUrl, ...}`. Attachments: ≤5 files, ≤50MB, types png/jpeg/webp/gif/
  txt/md/json/zip/csv only. `webhook list` masks URLs (`--reveal` for full
  secrets), `webhook revoke <name> --yes`. Treat URLs as credentials.

The meta agent (kick without `--project`) orchestrates the whole machine: ask
it in plain English to create scheduled automations/crons (daily, weekdays,
weekly, RRULE), run durable tracked jobs (e.g. babysit CI until merged), spawn
workers across projects, or report status. Route single-repo tasks with
`--project`; everything cross-cutting — and every question about the state of
the environment — goes to the meta agent, not SSH.
