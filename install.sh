#!/usr/bin/env bash
set -euo pipefail

shell_type="auto"
skip_deps=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--shell auto|zsh|bash] [--skip-deps]

Options:
  --shell      Target shell config to update. Default: auto
  --skip-deps  Skip dependency checks and installation
USAGE
}

detect_shell() {
  local candidate

  candidate="$(basename -- "${SHELL:-}")"
  case "$candidate" in
    zsh|bash)
      printf '%s\n' "$candidate"
      return 0
      ;;
  esac

  candidate="$(ps -p "$PPID" -o comm= 2>/dev/null | awk '{print $1}' | sed 's#^-##' | xargs basename 2>/dev/null || true)"
  case "$candidate" in
    zsh|bash)
      printf '%s\n' "$candidate"
      return 0
      ;;
  esac

  printf 'zsh\n'
}

ensure_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    return 0
  fi

  echo "[cdf-fzf-nav] fzf not found. Trying: brew install fzf"

  if ! command -v brew >/dev/null 2>&1; then
    echo "[cdf-fzf-nav] Homebrew not found. Please install Homebrew and rerun." >&2
    return 1
  fi

  brew install fzf

  if ! command -v fzf >/dev/null 2>&1; then
    echo "[cdf-fzf-nav] fzf still not available in PATH after brew install." >&2
    echo "[cdf-fzf-nav] Restart shell and run the installer again." >&2
    return 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell)
      shell_type="${2:-}"
      shift 2
      ;;
    --skip-deps)
      skip_deps=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$shell_type" == "auto" ]]; then
  shell_type="$(detect_shell)"
fi

case "$shell_type" in
  zsh|bash) ;;
  *)
    echo "Unsupported shell: $shell_type (use auto, zsh, or bash)" >&2
    exit 1
    ;;
esac

if [[ "$shell_type" == "bash" ]] && ! command -v zsh >/dev/null 2>&1; then
  echo "[cdf-fzf-nav] bash mode requires zsh runtime for navigator core." >&2
  echo "[cdf-fzf-nav] Please install zsh first." >&2
  exit 1
fi

if (( skip_deps == 0 )); then
  ensure_fzf
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_module="$repo_dir/cdf.zsh"

if [[ ! -f "$source_module" ]]; then
  echo "[cdf-fzf-nav] cdf.zsh not found next to install.sh" >&2
  exit 1
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
install_dir="$config_home/cdf-fzf-nav"
module_file="$install_dir/cdf.zsh"

mkdir -p "$install_dir"
cp "$source_module" "$module_file"

if [[ "$shell_type" == "zsh" ]]; then
  rc_file="$HOME/.zshrc"
  block="$(cat <<'ZSHBLOCK'
# >>> cdf-fzf-nav >>>
typeset -g _CDF_MODULE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cdf-fzf-nav/cdf.zsh"

_cdf_load_module() {
  if (( ${+functions[_cdf_command]} && ${+functions[_cdf_widget]} )); then
    return 0
  fi
  [[ -r "$_CDF_MODULE_FILE" ]] || return 1
  source "$_CDF_MODULE_FILE" || return 1
  (( ${+functions[_cdf_command]} && ${+functions[_cdf_widget]} )) || return 1
}

cdf() {
  _cdf_load_module || return 1
  _cdf_command "$@"
}

_cdf_lazy_widget() {
  emulate -L zsh
  setopt no_aliases no_pipefail no_err_exit no_err_return
  _cdf_load_module || return 0
  _cdf_widget
}

if [[ -o interactive ]]; then
  zle -N _cdf_lazy_widget
  bindkey -M main  "^[c" _cdf_lazy_widget 2>/dev/null || true
  bindkey -M emacs "^[c" _cdf_lazy_widget 2>/dev/null || true
  bindkey -M viins "^[c" _cdf_lazy_widget 2>/dev/null || true
  bindkey -M vicmd "^[c" _cdf_lazy_widget 2>/dev/null || true
  bindkey -M emacs "^[C" _cdf_lazy_widget 2>/dev/null || true
  bindkey -M viins "^[C" _cdf_lazy_widget 2>/dev/null || true
  bindkey -M vicmd "^[C" _cdf_lazy_widget 2>/dev/null || true
  bindkey "^[c" _cdf_lazy_widget
fi
# <<< cdf-fzf-nav >>>
ZSHBLOCK
)"
else
  rc_file="$HOME/.bashrc"
  block="$(cat <<'BASHBLOCK'
# >>> cdf-fzf-nav >>>
cdf() {
  local start_dir target
  start_dir="${1:-$PWD}"
  target="$({
    CDF_START_DIR="$start_dir" zsh -fc '
      source "${XDG_CONFIG_HOME:-$HOME/.config}/cdf-fzf-nav/cdf.zsh" || exit 1
      _cdf_navigate "$CDF_START_DIR" || exit 0
      [[ -n "$_CDF_TARGET_DIR" ]] && print -r -- "$_CDF_TARGET_DIR"
    ' 2>/dev/null
  })" || return 0
  [[ -n "$target" ]] && cd -- "$target"
}

bind -x '"\ec":"cdf"' 2>/dev/null || true
# <<< cdf-fzf-nav >>>
BASHBLOCK
)"
fi

mkdir -p "$(dirname "$rc_file")"
touch "$rc_file"

tmp_file="$(mktemp)"
sed '/^# >>> cdf-fzf-nav >>>$/,/^# <<< cdf-fzf-nav >>>$/d' "$rc_file" > "$tmp_file"
cat "$tmp_file" > "$rc_file"
rm -f "$tmp_file"

printf '\n%s\n' "$block" >> "$rc_file"

echo "[cdf-fzf-nav] Shell detected: $shell_type"
echo "[cdf-fzf-nav] Installed module: $module_file"
echo "[cdf-fzf-nav] Updated rc file: $rc_file"
echo "[cdf-fzf-nav] Done. Open a new terminal, or run: source $rc_file"
