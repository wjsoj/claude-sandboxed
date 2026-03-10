# Claude Sandbox

Run Claude Code in a sandboxed environment using bubblewrap. Protects system files while keeping your workspace fully readable and writable.

## Features

- 🔒 Isolate system files from accidental modifications
- ✅ Full read/write access to workspace
- 🛠️ Auto-mount user tools (uv, cargo, npm, etc.)
- 🧹 Automatic cleanup of temporary files
- 💾 Optional session history export
- 🔑 Read API credentials from environment or config file

## Dependencies

- `bubblewrap` - Sandbox runtime
- `claude` - Claude Code CLI

### Install Dependencies

**Arch Linux:**
```bash
sudo pacman -S bubblewrap
```

**Ubuntu/Debian:**
```bash
sudo apt install bubblewrap
```

**Fedora:**
```bash
sudo dnf install bubblewrap
```

## Quick Install

### International Users

```bash
curl -fsSL https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandbox -o ~/.local/bin/claude-sandbox && chmod +x ~/.local/bin/claude-sandbox
```

### China Mainland Users (Recommended)

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandbox -o ~/.local/bin/claude-sandbox && chmod +x ~/.local/bin/claude-sandbox
```

After installation, use the `claude-sandbox` command directly.

## Usage

### Basic Usage

```bash
# Launch sandboxed Claude Code in current directory
claude-sandbox

# Use with prompt
claude-sandbox -p "Initialize a Python project"

# Save session history
claude-sandbox --save -p "Create a React component"
```

### Options

- `--save` - Save session history to `.sandbox/output-timestamp.jsonl`
- `--with-skills` - Load Claude Code skills
- `--with-plugins` - Load Claude Code plugins
- `--full` - Load both skills and plugins

### API Configuration

The script reads API configuration in the following priority:

1. Environment variables: `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`
2. Config file: `env` field in `~/.claude/settings.json`

**Using environment variables:**
```bash
export ANTHROPIC_BASE_URL="https://api.anthropic.com"
export ANTHROPIC_AUTH_TOKEN="your_token_here"
claude-sandbox
```

## Sandbox Isolation

### Read/Write Areas
- `/workspace` - Current working directory (fully writable)

### Read-Only Areas
- `/usr`, `/etc` - System files
- `/usr/local/bin` - User tools (uv, cargo, etc.)
- `/home/sandbox/.local` - Claude Code binary
- `/home/sandbox/.claude` - Claude Code config (temporary)

### Isolated Namespaces
- Process namespace (PID)
- IPC namespace
- UTS namespace

### Shared Resources
- Network namespace (for API access)
- User namespace (avoid permission issues)

## Directory Structure

After running, a `.sandbox/` directory is created in the workspace:

```
.sandbox/
├── output-20260310-123456.jsonl  # Session history (with --save)
└── temp-*                         # Temporary files (auto-cleaned)
```

## How It Works

1. Create temporary directory for Claude Code config and binary
2. Use bubblewrap to create isolated sandbox environment
3. Mount workspace as read/write, system files as read-only
4. Run Claude Code
5. Auto-cleanup temporary files on exit, optionally save session history

## Troubleshooting

### Cannot find uv/cargo/other tools

Ensure tools are installed in one of these locations:
- `~/.local/bin`
- `~/.cargo/bin`
- `/usr/bin`

### API authentication failed

Check environment variables or `~/.claude/settings.json`:
```bash
echo $ANTHROPIC_AUTH_TOKEN
```

### Permission errors

Ensure the script has execute permission:
```bash
chmod +x ~/.local/bin/claude-sandbox
```

## License

MIT

## Contributing

Issues and Pull Requests are welcome!
