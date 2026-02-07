# cdf-fzf-navigator

一个基于 `fzf` 的目录导航器：支持 `Alt+C` 呼出目录树，用左右键前进/后退，用回车一次确认并直接切换目录。

## 项目背景与功能

### 为什么有这个项目
- 传统 `cd` + `ls` 在多层目录中来回跳转效率低。
- `fzf` 默认 `Alt+C` 更偏“单次选择”，难以连续左右导航。
- 需要一个可持续前进/后退、可记忆上次选择位置、可直接确认进入的交互式目录导航方案。

### 它能实现什么功能
- `Alt+C` 打开目录导航面板（`zsh`）。
- 右键进入子目录，左键返回父目录。
- 回车一次确认并直接 `cd` 到当前目录（无需二次回车）。
- `Esc`/`Ctrl+C` 立即退出导航。
- 右侧预览仅显示文件名列表，减少冗余信息。
- 目录列表默认：普通目录在前、隐藏目录在后；支持 `Ctrl+O` 切换名称/体积排序。
- 返回上一层时自动定位到刚才进入的目录项。

## 一次性配置方法（可直接贴给 AI）

把下面这段 Prompt 整段复制给你的 AI 终端助手即可：

```text
请在我的终端中自动完成 cdf-fzf-navigator 的安装与配置，要求：
1) 使用这个仓库：https://github.com/qiunai/cdf-fzf-navigator
2) 执行：
   - git clone https://github.com/qiunai/cdf-fzf-navigator.git ~/.local/src/cdf-fzf-navigator
   - cd ~/.local/src/cdf-fzf-navigator
   - bash install.sh --shell zsh
3) 安装完成后执行：source ~/.zshrc
4) 最后帮我做一次验证：
   - 按 Alt+C 是否能打开目录树
   - 右键是否进入子目录
   - 左键是否返回父目录
   - 回车是否一次性进入目录
5) 如果我当前是 bash，请改为执行：bash install.sh --shell bash，并执行 source ~/.bashrc
```

## 详细安装步骤

### 1) 前置需求
- `zsh`（推荐）或 `bash`
- `fzf`（必须）
- 常见基础命令：`find`、`sed`、`awk`、`du`、`ls`

参考安装：
```bash
# macOS (Homebrew)
brew install fzf
```

### 2) 文件放置

```bash
git clone https://github.com/qiunai/cdf-fzf-navigator.git ~/.local/src/cdf-fzf-navigator
cd ~/.local/src/cdf-fzf-navigator
```

安装脚本会把核心文件放到：
- `${XDG_CONFIG_HOME:-$HOME/.config}/cdf-fzf-nav/cdf.zsh`

### 3) 配置启动文件（Bash 或 .zshrc）

#### zsh（推荐）
```bash
bash install.sh --shell zsh
source ~/.zshrc
```

#### bash
```bash
bash install.sh --shell bash
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
├── cdf.zsh
├── install.sh
├── README.md
└── LICENSE
```

## 许可证

本项目使用 [MIT License](./LICENSE)。
