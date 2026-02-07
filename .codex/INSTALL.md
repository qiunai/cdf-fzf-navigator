# cdf-fzf-navigator: AI Install Instructions

Follow these instructions exactly to install or update `cdf-fzf-navigator` for the current user.

## Source

- GitHub repo: `https://github.com/qiunai/cdf-fzf-navigator`
- Clone path (fixed): `"$HOME/.local/src/cdf-fzf-navigator"`
- This instruction link should stay unchanged and always track latest from `main`.

## Required behavior

1. Detect shell:
   - First read `basename "$SHELL"`.
   - If not `zsh` or `bash`, inspect parent process shell.
   - If still unknown, default to `zsh`.
2. Ensure dependencies:
   - Check `git` is available.
   - Check `fzf` via `command -v fzf`.
   - If `fzf` is missing, run `brew install fzf`.
   - If `brew` is missing and `fzf` is missing, stop and report clearly.
3. Clone or update repository:
   - Repo URL: `https://github.com/qiunai/cdf-fzf-navigator.git`
   - Always sync target dir to latest `origin/main` (not just current local state):
     - If `"$HOME/.local/src/cdf-fzf-navigator/.git"` exists and remote `origin` matches repo URL:
       - `git -C "$HOME/.local/src/cdf-fzf-navigator" fetch origin main --prune`
       - `git -C "$HOME/.local/src/cdf-fzf-navigator" checkout -B main origin/main`
       - `git -C "$HOME/.local/src/cdf-fzf-navigator" reset --hard origin/main`
       - `git -C "$HOME/.local/src/cdf-fzf-navigator" clean -fd`
     - If target exists but is not this repo, move it aside with timestamp suffix, then clone fresh.
     - If target does not exist, clone fresh.
4. Run installer:
   - `cd "$HOME/.local/src/cdf-fzf-navigator"`
   - `bash install.sh --shell auto`
5. Apply configuration immediately:
   - If shell is `zsh`: `source ~/.zshrc`
   - If shell is `bash`: `source ~/.bashrc`
6. Verify and report:
   - Confirm `cdf` function is available (`type cdf`).
   - Explain that interactive keys (`Alt+C`, arrows, `Enter`) should now work in a new terminal session.
   - Return a concise summary of what was installed/updated.

## Command template (execute with shell-safe checks)

```bash
set -euo pipefail

REPO_URL="https://github.com/qiunai/cdf-fzf-navigator.git"
TARGET_DIR="$HOME/.local/src/cdf-fzf-navigator"
SHELL_NAME="$(basename "${SHELL:-}")"
if [[ "$SHELL_NAME" != "zsh" && "$SHELL_NAME" != "bash" ]]; then
  PARENT_SHELL="$(ps -p "$PPID" -o comm= 2>/dev/null | awk '{print $1}' | sed 's#^-##' | xargs basename 2>/dev/null || true)"
  if [[ "$PARENT_SHELL" == "zsh" || "$PARENT_SHELL" == "bash" ]]; then
    SHELL_NAME="$PARENT_SHELL"
  else
    SHELL_NAME="zsh"
  fi
fi

command -v git >/dev/null
if ! command -v fzf >/dev/null 2>&1; then
  command -v brew >/dev/null 2>&1 || { echo "fzf missing and Homebrew not found"; exit 1; }
  brew install fzf
fi

if [[ -d "$TARGET_DIR/.git" ]]; then
  CURRENT_ORIGIN="$(git -C "$TARGET_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$CURRENT_ORIGIN" == "$REPO_URL" ]]; then
    git -C "$TARGET_DIR" fetch origin main --prune
    git -C "$TARGET_DIR" checkout -B main origin/main
    git -C "$TARGET_DIR" reset --hard origin/main
    git -C "$TARGET_DIR" clean -fd
  else
    mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
else
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
bash install.sh --shell auto

if [[ "$SHELL_NAME" == "zsh" ]]; then
  source "$HOME/.zshrc"
else
  source "$HOME/.bashrc"
fi

type cdf
echo "cdf-fzf-navigator installed. Open a new terminal and press Alt+C to verify interactive navigation."
```
