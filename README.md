# Claude Code Sandboxed

使用 bubblewrap 在沙箱环境中运行 Claude Code，保护系统文件安全的同时保持工作区完全可读写。

## 特性

- 🔒 隔离系统文件，防止意外修改
- ✅ 工作区完全可读写，保留所有工作记录
- 🛠️ 自动挂载用户工具（uv, cargo, npm 等）
- 🧹 自动清理临时文件
- 💾 可选的会话历史保存功能
- 🔑 从环境变量或配置文件读取 API 凭证

## 依赖

- `bubblewrap` - 沙箱运行时
- `claude` - Claude Code CLI
- `jq` - JSON 处理（可选，用于配置解析）

### 安装依赖

**Arch Linux:**
```bash
sudo pacman -S bubblewrap jq
```

**Ubuntu/Debian:**
```bash
sudo apt install bubblewrap jq
```

**Fedora:**
```bash
sudo dnf install bubblewrap jq
```

## 一键安装

### 国际用户

```bash
curl -fsSL https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandboxed -o ~/.local/bin/claude-sandbox && chmod +x ~/.local/bin/claude-sandbox
```

### 中国大陆用户（推荐）

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandboxed -o ~/.local/bin/claude-sandbox && chmod +x ~/.local/bin/claude-sandbox
```

安装完成后，直接使用 `claude-sandbox` 命令即可。


## 使用方法

### 基本用法

```bash
# 在当前目录启动沙箱化的 Claude Code
claude-sandbox

# 使用提示词
claude-sandbox -p "帮我初始化一个 Python 项目"

# 保存会话历史
claude-sandbox --save -p "创建一个 React 组件"
```

### 选项

- `--save` - 保存会话历史到 `.sandbox/output-时间戳.jsonl`
- `--with-skills` - 加载 Claude Code 技能
- `--with-plugins` - 加载 Claude Code 插件
- `--full` - 同时加载技能和插件

### API 配置

脚本会按以下优先级读取 API 配置：

1. 环境变量：`ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN`
2. 配置文件：`~/.claude/settings.json` 中的 `env` 字段

**使用环境变量：**
```bash
export ANTHROPIC_BASE_URL="https://api.anthropic.com"
export ANTHROPIC_AUTH_TOKEN="your_token_here"
claude-sandbox
```

## 沙箱隔离说明

### 可读写区域
- `/workspace` - 当前工作目录（完全可读写）

### 只读区域
- `/usr`, `/etc` - 系统文件
- `/usr/local/bin` - 用户工具（uv, cargo 等）
- `/home/sandbox/.local` - Claude Code 二进制文件
- `/home/sandbox/.claude` - Claude Code 配置（临时）

### 隔离的命名空间
- 进程命名空间（PID）
- IPC 命名空间
- UTS 命名空间

### 共享资源
- 网络命名空间（用于 API 访问）
- 用户命名空间（避免权限问题）

## 目录结构

运行后会在工作区创建 `.sandbox/` 目录：

```
.sandbox/
├── output-20260310-123456.jsonl  # 会话历史（使用 --save 时）
└── temp-*                         # 临时文件（自动清理）
```

## 工作原理

1. 创建临时目录存储 Claude Code 配置和二进制文件
2. 使用 bubblewrap 创建隔离的沙箱环境
3. 挂载工作区为可读写，系统文件为只��
4. 运行 Claude Code
5. 退出时自动清理临时文件，可选保存会话历史

## 故障排除

### 找不到 uv/cargo 等工具

确保工具安装在以下位置之一：
- `~/.local/bin`
- `~/.cargo/bin`
- `/usr/bin`

### API 认证失败

检查环境变量或 `~/.claude/settings.json` 中的配置：
```bash
echo $ANTHROPIC_AUTH_TOKEN
```

### 权限错误

确保脚本有执行权限：
```bash
chmod +x ~/.local/bin/claude-sandbox
```

## 许可证

MIT

## 贡献

欢迎提交 Issue 和 Pull Request！
