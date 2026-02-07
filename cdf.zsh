if (( ${+functions[_cdf_command]} )); then
  return 0
fi

_cdf_list_rows() {
  local mode="${1:-name}"

  if [[ "$mode" == "size" ]]; then
    command find . -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null \
    | sed 's|^\./||' \
    | while IFS= read -r d; do
        local size_kb size_h hidden tag
        size_kb="$(command du -sk "./$d" 2>/dev/null | awk '{print $1}')"
        [[ -n "$size_kb" ]] || size_kb=0

        if (( size_kb >= 1048576 )); then
          size_h="$(( (size_kb + 524288) / 1048576 ))G"
        elif (( size_kb >= 1024 )); then
          size_h="$(( (size_kb + 512) / 1024 ))M"
        else
          size_h="${size_kb}K"
        fi

        if [[ "$d" == .* ]]; then hidden=1; tag='[hidden]'; else hidden=0; tag='[dir]'; fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$hidden" "$size_kb" "$size_h" "$tag" "$d"
      done \
    | LC_ALL=C sort -t $'\t' -k1,1n -k2,2nr -k5,5
  else
    command find . -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null \
    | sed 's|^\./||' \
    | awk 'BEGIN{OFS="\t"} { if ($0 ~ /^\./) print 1, 0, "-", "[hidden]", $0; else print 0, 0, "-", "[dir]", $0 }' \
    | LC_ALL=C sort -t $'\t' -k1,1n -k5,5
  fi
}

_cdf_fzf_once() {
  local dir="$1"
  local mode="$2"
  local out_file="$3"
  local err_file="$4"
  local preferred_pick="$5"

  local with_nth header
  if [[ "$mode" == "size" ]]; then
    with_nth="3,4,5"
    header=$'Right: enter dir  Left: parent  Enter: confirm+exit  Ctrl-O: toggle sort\nMode: size (slower)'
  else
    with_nth="4,5"
    header=$'Right: enter dir  Left: parent  Enter: confirm+exit  Ctrl-O: toggle sort\nMode: name (fast)'
  fi

  (
    local rows_file="/tmp/cdf-rows.$$.$RANDOM"
    local start_pos=1
    local bind_keys rc

    builtin cd -- "$dir" || exit 1
    _cdf_list_rows "$mode" \
    | awk 'BEGIN{found=0} {found=1; print} END{if(!found) print "9\t0\t-\t[empty]\t__CDF_EMPTY__"}' \
    > "$rows_file"

    if [[ -n "$preferred_pick" ]]; then
      start_pos="$(awk -F $'\t' -v target="$preferred_pick" '$5==target { print NR; exit }' "$rows_file")"
      [[ -n "$start_pos" ]] || start_pos=1
    fi

    bind_keys="start:pos(${start_pos}),load:pos(${start_pos})"

    command env FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf --prompt="cd: $(pwd) > " \
          --height=80% --layout=reverse --border --no-clear \
          --header="$header" \
          --delimiter=$'\t' --with-nth="$with_nth" --nth=5 \
          --expect=enter,right,left,alt-right,alt-left,ctrl-f,ctrl-b,ctrl-o,esc,ctrl-c \
          --bind="$bind_keys" \
          --preview 'p=$(printf %s {} | cut -f5); if [ "$p" = "__CDF_EMPTY__" ]; then printf "(empty directory)\n"; exit 0; fi; command ls -1A -- "$p" 2>/dev/null | head -120' \
          --preview-window=right:55%:noinfo < "$rows_file" >"$out_file"

    rc=$?
    rm -f -- "$rows_file"
    exit $rc
  ) 2>>"$err_file"
}

_cdf_navigate() {
  emulate -L zsh
  setopt no_aliases no_pipefail no_err_exit no_err_return

  local start_dir="$1"
  [[ -d "$start_dir" ]] || return 1

  local dir
  dir="$(builtin cd -- "$start_dir" 2>/dev/null && pwd -P)" || return 1
  local next_dir
  local mode="name"
  local out_file="/tmp/cdf-out.$$.$RANDOM"
  local err_file="/tmp/cdf-nav.err.log"
  local fzf_rc key row pick line1 line2
  local preferred_pick parent_dir child_name dir_key
  typeset -gA _CDF_LAST_PICK
  _CDF_TARGET_DIR=""

  : >> "$err_file"

  while true; do
    : >| "$out_file"
    dir_key="$(builtin cd -- "$dir" 2>/dev/null && pwd -P)" || dir_key="$dir"
    preferred_pick="${_CDF_LAST_PICK[$dir_key]}"
    fzf_rc=0
    _cdf_fzf_once "$dir" "$mode" "$out_file" "$err_file" "$preferred_pick" || fzf_rc=$?

    line1="$(sed -n '1p' "$out_file")"
    line2="$(sed -n '2p' "$out_file")"
    line1="${line1//$'\r'/}"
    line2="${line2//$'\r'/}"

    case "$line1" in
      enter|right|left|alt-right|alt-left|ctrl-f|ctrl-b|ctrl-o|esc|ctrl-c)
        key="$line1"
        row="$line2"
        ;;
      *)
        key=""
        row="$line1"
        ;;
    esac

    pick="${row##*$'\t'}"
    if (( fzf_rc != 0 )); then
      case "$key" in
        left|alt-left|ctrl-b)
          child_name="${dir##*/}"
          parent_dir="$(builtin cd -- "$dir/.." 2>/dev/null && pwd -P)" || parent_dir="$dir"
          _CDF_LAST_PICK[$parent_dir]="$child_name"
          dir="$parent_dir"
          continue
          ;;
        esc|ctrl-c)
          rm -f -- "$out_file"
          return 130
          ;;
        "")
          if (( fzf_rc == 130 )); then
            rm -f -- "$out_file"
            return 130
          fi
          continue
          ;;
        *)
          continue
          ;;
      esac
    fi

    case "$key" in
      ctrl-o)
        if [[ "$mode" == "size" ]]; then mode="name"; else mode="size"; fi
        ;;
      left|alt-left|ctrl-b)
        child_name="${dir##*/}"
        parent_dir="$(builtin cd -- "$dir/.." 2>/dev/null && pwd -P)" || parent_dir="$dir"
        _CDF_LAST_PICK[$parent_dir]="$child_name"
        dir="$parent_dir"
        ;;
      right|alt-right|ctrl-f)
        [[ "$pick" == "__CDF_EMPTY__" ]] && continue
        [[ -n "$pick" ]] || continue
        _CDF_LAST_PICK[$dir_key]="$pick"
        next_dir="$(builtin cd -- "${dir%/}/$pick" 2>/dev/null && pwd -P)" || continue
        dir="$next_dir"
        ;;
      enter|"")
        if [[ -n "$pick" && "$pick" != "__CDF_EMPTY__" ]]; then
          next_dir="$(builtin cd -- "${dir%/}/$pick" 2>/dev/null && pwd -P)" || continue
          dir="$next_dir"
        fi
        _CDF_TARGET_DIR="$dir"
        rm -f -- "$out_file"
        return 0
        ;;
      esc|ctrl-c)
        rm -f -- "$out_file"
        return 130
        ;;
      *)
        continue
        ;;
    esac
  done
}

_cdf_command() {
  emulate -L zsh
  setopt no_aliases no_pipefail no_err_exit no_err_return

  local base="${1:-$PWD}"
  [[ -d "$base" ]] || base="$HOME"

  _cdf_navigate "$base" || return 0
  [[ -n "$_CDF_TARGET_DIR" ]] && builtin cd -- "$_CDF_TARGET_DIR"
}

_cdf_widget() {
  emulate -L zsh
  setopt no_aliases no_pipefail no_err_exit no_err_return

  zle -I 2>/dev/null || true

  local start_dir="$PWD"
  _cdf_navigate "$PWD"
  local nav_status=$?

  if (( nav_status == 0 )) && [[ -n "$_CDF_TARGET_DIR" ]]; then
    zle push-line 2>/dev/null || true
    BUFFER="builtin cd -- ${(q)_CDF_TARGET_DIR}"
    CURSOR=${#BUFFER}
    zle accept-line
    _CDF_TARGET_DIR=""
    return 0
  else
    builtin cd -- "$start_dir" 2>/dev/null || true
  fi

  zle -I 2>/dev/null || true
  zle -R 2>/dev/null || true
  zle reset-prompt 2>/dev/null || true
}
