# cdf-fzf-navigator

![cdf-fzf-navigator cover](./assets/cover.svg)

一个基于 `fzf` 的目录导航器：`Alt+C` 打开目录树，左右键前进/后退，回车一次确认并直接切换目录。

## 项目背景与功能

### 为什么有这个项目
- 多项目并行时，目录层级很深，`cd` + `ls` 的重复操作很耗时。
- 目录里经常中英文混合，手敲路径成本高，且容易输错。
- 需要更接近“文件管理器心智”的终端交互：前进、后退、预览、确认。

### 它能实现什么功能
- `Alt+C` 唤起交互式目录导航。
- 右键进入子目录，左键返回父目录。
- 回车一次确认，直接 `cd` 到目标目录。
- `Esc` / `Ctrl+C` 随时退出。
- 右侧预览仅显示文件名列表，减少噪音。
- 列表默认普通目录在前、隐藏目录在后；`Ctrl+O` 可切换名称/体积排序。
- 返回上级时自动定位到刚才进入的目录项。

## 一次性配置方法（可直接贴给 AI）

复制这一句给 AI 即可（短链接版）：

```text
Fetch and follow instructions from https://raw.githubusercontent.com/qiunai/cdf-fzf-navigator/refs/heads/main/.codex/INSTALL.md
```

可选（更稳）：把链接换成固定 commit 的 raw 地址，避免后续文档变更影响安装行为。

## 详细安装步骤

### 1) 前置需求
- `zsh` 或 `bash`（推荐 `zsh`）
- `fzf`
- macOS 下推荐安装 `Homebrew`（用于自动安装依赖）

> `install.sh` 会自动检测 shell，并在缺少 `fzf` 时尝试执行 `brew install fzf`。

### 2) 文件放置

```bash
TARGET_DIR="$HOME/.local/src/cdf-fzf-navigator"
git clone https://github.com/qiunai/cdf-fzf-navigator.git "$TARGET_DIR"
cd "$TARGET_DIR"
```

### 3) 配置 shell 启动文件（自动）

```bash
bash install.sh --shell auto
```

安装脚本会：
- 复制核心文件到 `${XDG_CONFIG_HOME:-$HOME/.config}/cdf-fzf-nav/cdf.zsh`
- 自动写入 `~/.zshrc` 或 `~/.bashrc`
- 使 `cdf` 和 `Alt+C` 在每次打开终端时都可直接使用

生效方式：
```bash
# zsh
source ~/.zshrc

# bash
source ~/.bashrc
```

## 使用说明
- `Alt+C`：打开目录导航
- `→`：进入子目录
- `←`：返回父目录
- `Enter`：确认并切换目录
- `Esc` / `Ctrl+C`：退出
- `Ctrl+O`：切换排序模式（名称 / 目录体积）

## 示例目录结构（通用示例）

```text
cdf-fzf-navigator/
├── .codex/
│   └── INSTALL.md
├── assets/
│   └── cover.svg
├── cdf.zsh
├── install.sh
├── README.md
└── LICENSE
```

## 许可证

本项目使用 [MIT License](./LICENSE)。
