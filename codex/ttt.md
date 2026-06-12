# tabtabtab (ttt) — cloud dev environments

Use the `ttt` CLI to manage tabtabtab (gv-code) cloud dev environments and to
kick off remote agents. It is a single-file Python 3 CLI with no dependencies.

Rules:
- Pass `--json` whenever you parse output.
- Check auth with `ttt whoami --json`. If not logged in, ask the user to run
  `ttt login` (interactive browser flow) — do not run it yourself.
- VM names: 3-30 chars, lowercase letters/numbers/hyphens.
- `vm delete` / `repo delete` are destructive; only pass `--yes` when the user
  explicitly asked.
- After `ttt vm create <name>`, poll `ttt vm get <name> --json` until
  `.status == "ready"` (takes a few minutes).

Commands:
- `ttt vm list|create|get|delete|restart|password|ssh|cp` — VM lifecycle, SSH,
  and scp file copy (`vm cp` handles any file type/size).
- `ttt repo add <git-url> --vm <name>` — clone a repository onto a VM;
  `ttt repo list --json` shows sync status.
- `ttt webhook list|create|revoke --vm <name>` — secret webhook URLs that
  start an agent session when POSTed `{"message": "..."}`. Treat URLs as
  credentials. `--project <name>` targets a project; default is the meta agent.
- `ttt kick <vm> "<prompt>" [--project p] [--file f]` — start a remote agent
  session; always show the returned `sessionUrl` to the user.
  Without `--project` the prompt goes to the VM's **meta agent**, which
  orchestrates the whole VM: it can create scheduled automations/crons (once,
  daily, weekdays, weekly, RRULE), durable tracked jobs with background checks
  (e.g. babysit CI until merged), spawn worker agents across projects, create
  projects/worktrees, and report status. Route single-repo tasks with
  `--project`; route scheduling, automation, multi-repo, monitoring, or
  VM-level requests to the meta agent in plain English.
- `ttt upload <vm> <files...>` — upload files into the agent workspace
  (max 5 files / 50MB; png, jpeg, webp, gif, txt, md, json, zip, csv —
  otherwise use `ttt vm cp`).
