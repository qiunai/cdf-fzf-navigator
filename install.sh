#!/usr/bin/env bash
set -euo pipefail

shell_type="zsh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell)
      shell_type="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: ./install.sh [--shell zsh|bash]

Options:
  --shell   Target shell config to update (default: zsh)
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

case "$shell_type" in
  zsh|bash) ;;
  *)
    echo "Unsupported shell: $shell_type (use zsh or bash)" >&2
    exit 1
    ;;
esac

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
install_dir="$config_home/cdf-fzf-nav"
module_file="$install_dir/cdf.zsh"

mkdir -p "$install_dir"
cp "$(dirname "$0")/cdf.zsh" "$module_file"

if [[ "$shell_type" == "zsh" ]]; then
  rc_file="$HOME/.zshrc"
  block='\
# >>> cdf-fzf-nav >>>\
typeset -g _CDF_MODULE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cdf-fzf-nav/cdf.zsh"\
\
_cdf_load_module() {\
  if (( ${+functions[_cdf_command]} && ${+functions[_cdf_widget]} )); then\
    return 0\
  fi\
  [[ -r "$_CDF_MODULE_FILE" ]] || return 1\
  source "$_CDF_MODULE_FILE" || return 1\
  (( ${+functions[_cdf_command]} && ${+functions[_cdf_widget]} )) || return 1\
}\
\
cdf() {\
  _cdf_load_module || return 1\
  _cdf_command "$@"\
}\
\
_cdf_lazy_widget() {\
  emulate -L zsh\
  setopt no_aliases no_pipefail no_err_exit no_err_return\
  _cdf_load_module || return 0\
  _cdf_widget\
}\
\
if [[ -o interactive ]]; then\
  zle -N _cdf_lazy_widget\
  bindkey -M main  "^[c" _cdf_lazy_widget 2>/dev/null || true\
  bindkey -M emacs "^[c" _cdf_lazy_widget 2>/dev/null || true\
  bindkey -M viins "^[c" _cdf_lazy_widget 2>/dev/null || true\
  bindkey -M vicmd "^[c" _cdf_lazy_widget 2>/dev/null || true\
  bindkey -M emacs "^[C" _cdf_lazy_widget 2>/dev/null || true\
  bindkey -M viins "^[C" _cdf_lazy_widget 2>/dev/null || true\
  bindkey -M vicmd "^[C" _cdf_lazy_widget 2>/dev/null || true\
  bindkey "^[c" _cdf_lazy_widget\
fi\
# <<< cdf-fzf-nav >>>\
'
else
  rc_file="$HOME/.bashrc"
  block='\
# >>> cdf-fzf-nav >>>\
cdf() {\
  local start_dir target\
  start_dir="${1:-$PWD}"\
  target="$(\
    CDF_START_DIR="$start_dir" zsh -fc '\''\
      source "${XDG_CONFIG_HOME:-$HOME/.config}/cdf-fzf-nav/cdf.zsh" || exit 1\
      _cdf_navigate "$CDF_START_DIR" || exit 0\
      [[ -n "$_CDF_TARGET_DIR" ]] && print -r -- "$_CDF_TARGET_DIR"\
    '\'' 2>/dev/null\
  )" || return 0\
  [[ -n "$target" ]] && cd -- "$target"\
}\
\
bind -x '\''"\ec":"cdf"'\'' 2>/dev/null || true\
# <<< cdf-fzf-nav >>>\
'
fi

mkdir -p "$(dirname "$rc_file")"
touch "$rc_file"

tmp_file="$(mktemp)"
sed '/^# >>> cdf-fzf-nav >>>$/,/^# <<< cdf-fzf-nav >>>$/d' "$rc_file" > "$tmp_file"
cat "$tmp_file" > "$rc_file"
rm -f "$tmp_file"

printf '\n%s\n' "$block" >> "$rc_file"

echo "Installed: $module_file"
echo "Updated:   $rc_file"
echo "Next: restart shell or run 'source $rc_file'"
