# Claude Code Sandboxed

Secure wrapper for Claude Code that restricts file system access to the current workspace using bubblewrap.

## Why?

When Claude Code runs in bypass permissions mode, it can access your entire file system. This wrapper sandboxes it to only access:
- Current workspace directory
- Essential Claude config files

## Installation

### Arch Linux (AUR)

```bash
# Build and install
makepkg -si
```

### Other Linux

```bash
# Install bubblewrap
sudo apt install bubblewrap  # Ubuntu/Debian
sudo dnf install bubblewrap  # Fedora

# Install script
sudo install -m755 claude-sandboxed /usr/local/bin/
```

## Usage

```bash
# Basic usage (only credentials + settings)
claude-sandboxed

# With skills
claude-sandboxed --with-skills

# With plugins
claude-sandboxed --with-plugins

# Full mode (skills + plugins)
claude-sandboxed --full

# Pass arguments normally
claude-sandboxed -c "fix the bug"
```

## What's Mounted?

**Always**:
- `.credentials.json` - Authentication
- `settings.json` - Configuration

**Optional**:
- `skills/` - With `--with-skills`
- `plugins/` - With `--with-plugins`

**Never**:
- Your home directory
- System files (read-only)
- Other projects

## Performance

Zero overhead - bubblewrap uses Linux namespaces, not virtualization.
