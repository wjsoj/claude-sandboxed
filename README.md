# claude-sandbox

> Run Claude Code in a bubblewrap sandbox, with per-project profiles, SOCKS5 proxy, and a token-burning autopilot.

Each sandbox isolates `$HOME` from the host so plugins, credentials, and session history live inside a named **profile** instead of polluting your real `~/.claude`. Profiles persist between launches (like Chromium profiles), can each route through their own SOCKS5 proxy, and ship with an optional "burn mode" that drives Claude through a Plan-driven multi-agent build loop.

![status](https://img.shields.io/github/v/release/wjsoj/claude-sandboxed?style=flat-square)
![license](https://img.shields.io/github/license/wjsoj/claude-sandboxed?style=flat-square)

## Features

- **Per-profile isolation** — each profile is its own `.claude/` directory under `profiles/<name>/`, with persistent credentials, sessions, plugin state, and a dedicated workspace.
- **Interactive launcher** — running `claude-sandbox` with no arguments opens a colored TUI menu for launch / create / delete / proxy.
- **SOCKS5 proxy per profile** — saves `proxy.conf` next to the profile and bridges via `gost` so Claude's `HTTPS_PROXY` covers every Anthropic call.
- **Permission prompts off by default** — `--dangerously-skip-permissions` is passed automatically; the sandbox boundary already enforces what matters.
- **Workspace auto-clean** — each profile's `workspace/` is wiped on exit so the next session starts fresh.
- **Burn mode** — `--burn` injects a Plan-driven, multi-agent, three-version-rewrite build of a fictional 10-subsystem platform, for stress-testing your subscription tokens.
- **Self-update** — `claude-sandbox update` pulls the latest script from GitHub with syntax check, atomic replace, and automatic backup.

## Requirements

| Tool | Required? | Purpose |
|---|---|---|
| [`bubblewrap`](https://github.com/containers/bubblewrap) | yes | sandbox runtime (`bwrap`) |
| [`claude`](https://docs.claude.com/en/docs/agents-and-tools/claude-code/overview) | yes | Claude Code CLI on `PATH`, **latest version recommended** (burn mode relies on current subagent/`ultrathink` behavior) |
| [`gost`](https://github.com/go-gost/gost) | optional | only needed when a profile sets a SOCKS5 proxy (SOCKS5 → HTTP bridge) |
| `curl` | yes | used by `claude-sandbox update` |

```bash
# Arch
sudo pacman -S bubblewrap
yay -S gost                # AUR, only if you'll use proxies

# Debian / Ubuntu
sudo apt install bubblewrap

# Fedora
sudo dnf install bubblewrap
```

Make sure `claude --version` works in your shell before launching the sandbox — the script copies the host's `claude` binary into the sandbox at runtime.

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

## First-run walkthrough

Burn mode and the proxy bridge both expect a fully-bootstrapped profile (credentials, optional proxy). The cleanest path is **two passes**:

### Pass 1 — bootstrap the profile

```bash
claude-sandbox
```

In the menu:

1. Press `n` to create a new profile, e.g. `work`.
2. (Optional) Press `p` to set its SOCKS5 proxy:
   ```bash
   claude-sandbox proxy work socks5://127.0.0.1:7891
   ```
3. Launch the profile. Inside Claude, run `/login` to do the OAuth flow — tokens land in `profiles/work/.claude/` and survive across sessions.
4. (Optional) `/plugin install ralph-loop` if you plan to use burn mode's iteration wrapper.
5. Exit (`/exit` or `Ctrl-D`). The credentials are now persisted.

> [!TIP]
> If you'd rather seed credentials from your host `~/.claude`, launch with `claude-sandbox work --full` once; this copies plugins and OAuth tokens from the host on first boot, then behaves like a normal profile.

### Pass 2 — go

```bash
claude-sandbox work --burn      # auto-runs the burn task
# or just:
claude-sandbox work             # normal interactive session
```

The menu also offers `🔥 burn mode? [y/N]` after profile selection, so you don't have to remember the flag.

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
claude-sandbox update                       # pull the latest script from GitHub
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

> [!IMPORTANT]
> `profiles/` is in `.gitignore` and is **never** uploaded by `git push` — your credentials, sessions, and proxy URLs stay local.

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

`--burn` injects a self-contained prompt that turns the session into an autonomous engineering team building **DistribuOS** — a fictional cloud platform with 10 subsystems (KV / message queue / service mesh / object store / stream processing / workflow / auth / observability / CLI / SDK in 5 languages).

The runtime shape:

1. **Wave 0** — Claude spawns a `Plan` subagent which writes `PLAN.md` (≥12 000 words) and `WAVES.md` (≥40 parallel waves) into the workspace.
2. **Wave 1+** — Each iteration reads `WAVES.md` and dispatches that wave's subtasks **in parallel** (≥5 concurrent `Agent` tool calls), each prompted with `ultrathink` for maximum thinking budget.
3. **Three-version rewrite** — every file goes through V1 → reviewer agent → V2 → hardener agent → V3, with review reports archived to `reviews/`.
4. **Plan revision** — folded into one of each wave's subtasks (never as a main-thread pause).
5. **Completion gate** — the loop stops only when file-count thresholds and three-version coverage are all satisfied.

> [!WARNING]
> Burn mode is designed to consume *a lot* of subscription tokens. Use it only when that's the explicit goal (stress testing rate limits, validating throughput, etc.). The `--full` mode requires matching plugins to be installed in the host `~/.claude`.

### Prompt design philosophy

The burn prompt is short on motivation and **very** long on procedural guard-rails. The reason is empirical: large agentic loops collapse in predictable ways, and each clause is a counter-pressure to one specific failure mode.

- **Legality preamble** — Claude defaults to refusing "produce 35 000 lines of code" as suspicious. A one-paragraph framing ("sandbox practice; user opted in; outputs are isolated") moves it past the refusal heuristic without lying about what's happening.
- **Plan / Waves / Execute split** — separating *planning* (one `Plan` subagent, one shot, ≥12k words) from *execution* (parallel implementer agents reading the plan) prevents the main thread from re-deliberating mid-build. Plans are write-once + amended; they aren't re-derived each turn.
- **"Main thread emits only tool calls"** — the single biggest token-and-time waste in long agent runs is the model narrating "Wave 3 complete, starting Wave 4…". The prompt makes that explicitly forbidden: between the opening plan and the final report, the main thread is only allowed to emit `Agent` tool calls. Subagent outputs are the status log.
- **`ultrathink` on every subagent prompt** — forces maximum thinking budget on the workers (where quality matters) while keeping the orchestrator cheap.
- **≥5 parallel Agents per wave** — Claude's tool-use is parallel-capable but the model biases toward serial calls. Hard-coding "at least 5 in the same message" is the only reliable way to keep the fan-out wide.
- **Three-version rewrite (V1 → review → V2 → harden → V3)** — a single pass produces shallow code. Forcing an external reviewer agent to write a ≥1500-word critique to disk *before* the next implementer rewrites the file turns "rewrite" into a meaningful operation instead of a paraphrase.
- **Hard numeric thresholds** (≥250 files, ≥35 000 LoC, ≥40 waves) — vague goals ("comprehensive", "production-quality") get satisfied by the model's internal "good enough" heuristic. Concrete file/line floors are checkable and remove the wiggle room.
- **Ambiguity self-resolution + DECISIONS.md** — small naming/design questions are decided autonomously and logged, instead of being escalated to the user. The cost of a "wrong" small decision is far lower than the cost of stalling the wave.

The whole prompt is a worked example of the same pattern: **say what the failure mode is, then write the rule that prevents it, then explain why the rule is the rule.** That's also why it's in mixed Chinese/English — the audience is the model, and bilingual prompts measurably reduce paraphrasing drift on long instruction blocks.

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

## Updating

```bash
claude-sandbox update
```

Pulls the latest script from GitHub, validates it, and replaces the installed copy in place (backup saved to `<path>.bak`). Override the source with `CLAUDE_SANDBOX_UPDATE_URL` if you need a tag or mirror.

## Configuration

| Variable | Purpose |
|---|---|
| `CLAUDE_SANDBOX_HOME` | Where `profiles/` and `.sandbox/` live. Defaults to the script's directory. |
| `CLAUDE_SANDBOX_UPDATE_URL` | Override the source URL used by `claude-sandbox update`. |
| `ANTHROPIC_BASE_URL` | Optional. Seeded into new profiles if set. |
| `ANTHROPIC_AUTH_TOKEN` | Optional. Seeded into new profiles if set. If absent, Claude prompts `/login` on first launch and persists the OAuth token into the profile. |

## Troubleshooting

> [!NOTE]
> **`Error: ANTHROPIC_AUTH_TOKEN not found`** — gone since 1.1.0. New profiles deliberately start credential-free; run `/login` inside the sandbox on first launch and the OAuth credentials are written into the profile.

> [!NOTE]
> **`No prompt provided` from Ralph Loop** — make sure the `ralph-loop` plugin is installed in `~/.claude` and either create the profile with `--full` or run `/plugin install ralph-loop` once inside the sandbox.

> [!NOTE]
> **`gost not found`** — only required when the profile has a `proxy.conf`. Install `gost` or clear the proxy with `claude-sandbox proxy <name> --unset`.

> [!NOTE]
> **Can't find `uv` / `cargo` / other tools** — anything under `~/.local/bin` or `~/.cargo/bin` is auto-mounted read-only. Anywhere else is not visible inside the sandbox.

> [!NOTE]
> **`update` says "downloaded script failed syntax check"** — usually a corporate proxy or a captive portal returning HTML instead of the raw script. Try `curl -I` against the URL by hand, or set `CLAUDE_SANDBOX_UPDATE_URL` to a mirror.
