# claude-sandbox

> Run Claude Code in a bubblewrap sandbox, with per-project profiles, SOCKS5 proxy, and a token-burning autopilot.

Each sandbox isolates `$HOME` from the host so plugins, credentials, and session history live inside a named **profile** instead of polluting your real `~/.claude`. Profiles persist between launches (like Chromium profiles), can each route through their own SOCKS5 proxy, and ship with an optional "burn mode" that drives Claude through a Plan-driven multi-agent build loop.

![status](https://img.shields.io/github/v/release/wjsoj/claude-sandboxed?style=flat-square)
![license](https://img.shields.io/github/license/wjsoj/claude-sandboxed?style=flat-square)

## Features

- **Per-profile isolation** — each profile is its own `.claude/` directory under `profiles/<name>/`, with persistent credentials, sessions, plugin state, and a dedicated workspace.
- **Interactive launcher** — running `claude-sandbox` with no arguments opens a colored TUI menu with numeric selection for launch / create / delete / proxy.
- **SOCKS5 proxy per profile** — saves `proxy.conf` next to the profile and bridges via `gost` so Claude's `HTTPS_PROXY` covers every Anthropic call.
- **Permission prompts off by default** — `--dangerously-skip-permissions` is passed automatically; the sandbox boundary already enforces what matters.
- **Workspace auto-clean** — each profile's `workspace/` is wiped on exit so the next session starts fresh.
- **Burn mode** — `--burn` injects a Plan-driven, multi-agent, three-version-rewrite build of a fictional 10-subsystem platform, wrapped in [Ralph Loop](https://github.com/ghuntley/ralph) x80, for stress-testing your subscription tokens.

## Requirements

| Tool | Required? | Purpose |
|---|---|---|
| [`bubblewrap`](https://github.com/containers/bubblewrap) | yes | sandbox runtime |
| [`claude`](https://docs.claude.com/en/docs/agents-and-tools/claude-code/overview) | yes | Claude Code CLI on `PATH` |
| [`gost`](https://github.com/go-gost/gost) | optional | only needed when a profile sets a SOCKS5 proxy |

```bash
# Arch
sudo pacman -S bubblewrap
yay -S gost                # AUR, only if you'll use proxies

# Debian / Ubuntu
sudo apt install bubblewrap

# Fedora
sudo dnf install bubblewrap
```

## Install

Pick one:

```bash
# International
curl -fsSL https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandbox \
  -o ~/.local/bin/claude-sandbox && chmod +x ~/.local/bin/claude-sandbox

# China mainland (mirror)
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandbox \
  -o ~/.local/bin/claude-sandbox && chmod +x ~/.local/bin/claude-sandbox
```

Arch users can also `makepkg -si` against the included `PKGBUILD`.

## Quick start

```bash
claude-sandbox
```

That's it. The menu walks you through creating a profile, optionally bootstrapping it from your host's `~/.claude`, and optionally setting a proxy. On first launch Claude itself will run `/login` inside the sandbox and the OAuth tokens are persisted into the profile.

```
╭──────────────────────────────────────────╮
│  Claude Sandbox                          │
│  sandboxed Claude Code w/ profiles       │
╰──────────────────────────────────────────╯

Profiles
   1) work                socks5://127.0.0.1:7891
   2) personal

Actions
  n) new profile           d) delete profile
  p) set proxy             e) ephemeral (no profile)
  q) quit

  > 1
  🔥 burn mode? [y/N]
```

## Usage

```bash
claude-sandbox                              # interactive menu
claude-sandbox <profile>                    # use or create a profile
claude-sandbox <profile> --full             # bootstrap from ~/.claude on first launch
claude-sandbox <profile> --burn             # auto-start the Plan-driven burn task
claude-sandbox --no-menu                    # one-shot ephemeral sandbox, no menu
claude-sandbox ls                           # list profiles
claude-sandbox rm <profile>                 # delete a profile
claude-sandbox proxy <profile>              # show current proxy
claude-sandbox proxy <profile> <url>        # set SOCKS5 proxy
claude-sandbox proxy <profile> --unset      # clear it
claude-sandbox <profile> -- <claude args>   # forward extra args to claude
```

## Profiles

Profiles live in `<install-dir>/profiles/<name>/`. Override with `CLAUDE_SANDBOX_HOME=/some/path` if you want a global location.

```
profiles/<name>/
├── .claude/              # plugins, credentials, session history, todos
├── .claude.json          # claude config
├── proxy.conf            # optional, single-line "socks5://..."
└── workspace/            # mounted into the sandbox as /workspace, wiped on exit
```

> [!NOTE]
> The `workspace/` directory is the only writable area inside the sandbox. It's wiped automatically after each session so each run starts clean. If you want results to survive, copy them out before exiting (or write them somewhere else and bind-mount it).

## Proxy

Claude Code uses Node's `undici`, which only understands HTTP proxies. The sandbox bridges SOCKS5 → HTTP via a per-launch `gost` process:

```
claude → http://127.0.0.1:<bridge>  ← injected as HTTPS_PROXY
       → gost                        ← started by claude-sandbox
       → socks5://<your-upstream>    ← from profile's proxy.conf
```

Set or change it any time:

```bash
claude-sandbox proxy work socks5://127.0.0.1:7891
claude-sandbox proxy work socks5://user:pass@example.com:1080
claude-sandbox proxy work --unset
```

> [!TIP]
> If you also run Clash in TUN mode, point the profile's proxy at Clash's own SOCKS5 port (e.g. `socks5://127.0.0.1:7891`) — Clash's policy rules then decide the upstream route, no double-proxying.

To verify a profile actually routes through the proxy, inside the sandbox run:

```bash
echo "$HTTPS_PROXY"                # should print http://127.0.0.1:<port>
curl -s https://api.ipify.org      # egress IP should match the proxy
```

## Burn mode

`--burn` injects a self-contained prompt that turns the session into an autonomous engineering team:

1. **Wave 0** — Claude spawns a `Plan` subagent which writes `PLAN.md` (12 000+ words) and `WAVES.md` (40+ parallel waves) into the workspace.
2. **Wave 1+** — Each iteration reads `WAVES.md` and dispatches that wave's subtasks **in parallel** (≥5 concurrent `Agent` tool calls), each prompted with `ultrathink` for maximum thinking budget.
3. **Three-version rewrite** — every file goes through V1 → reviewer agent → V2 → hardener agent → V3, with review reports archived to `reviews/`.
4. **Plan revision** — every 5 waves a fresh `Plan` subagent re-evaluates progress and appends a mid-course correction to `PLAN.md`.
5. **Completion gate** — the whole loop is wrapped in `ralph-loop` (max 80 iterations) and won't emit its `<promise>` until file-count thresholds and three-version coverage are all satisfied.

Project scope is **DistribuOS**, a fictional cloud platform with 10 subsystems (KV / message queue / service mesh / object store / stream processing / workflow / auth / observability / CLI / SDK in 5 languages).

> [!WARNING]
> Burn mode is designed to consume *a lot* of subscription tokens. Use it only when that's the explicit goal (stress testing rate limits, validating throughput, etc.). The Ralph Loop and `--full` mode require the matching plugins to be installed in the host `~/.claude`.

## Sandbox boundaries

| Path | Access | Notes |
|---|---|---|
| `/workspace` | rw | bound to `profiles/<name>/workspace/`, wiped on exit |
| `/home/sandbox/.claude` | rw | bound to `profiles/<name>/.claude/`, persistent |
| `/home/sandbox/.claude.json` | rw | bound to `profiles/<name>/.claude.json` |
| `/usr`, `/etc` | ro | host system, read-only |
| `/usr/local/bin` | ro | mirrors host `~/.local/bin` |
| `/home/sandbox/.cargo/bin` | ro | mirrors host `~/.cargo/bin` |
| `/home`, `/tmp` | tmpfs | discarded on exit |

Isolated namespaces: PID, IPC, UTS. Network is shared so the proxy bridge on `127.0.0.1` works.

## Configuration

| Variable | Purpose |
|---|---|
| `CLAUDE_SANDBOX_HOME` | Where `profiles/` and `.sandbox/` live. Defaults to the script's directory. |
| `ANTHROPIC_BASE_URL` | Optional. Seeded into new profiles if set. |
| `ANTHROPIC_AUTH_TOKEN` | Optional. Seeded into new profiles if set. If absent, Claude prompts `/login` on first launch and persists the OAuth token into the profile. |

## Troubleshooting

> [!NOTE]
> **`Error: ANTHROPIC_AUTH_TOKEN not found`** — this message is gone in 1.1.0. New profiles deliberately start credential-free; Claude's `/login` flow runs inside the sandbox on first launch and writes the OAuth credentials into the profile.

> [!NOTE]
> **`No prompt provided` from Ralph Loop** — make sure the `ralph-loop` plugin is installed in `~/.claude` and either create the profile with `--full` or run `/plugin install ralph-loop` once inside the sandbox.

> [!NOTE]
> **`gost not found`** — only required when the profile has a `proxy.conf`. Install `gost` or clear the proxy with `claude-sandbox proxy <name> --unset`.

> [!NOTE]
> **Can't find `uv` / `cargo` / other tools** — anything under `~/.local/bin` or `~/.cargo/bin` is auto-mounted read-only. Anywhere else is not visible inside the sandbox.
