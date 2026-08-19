# cltmp — disposable Claude Code scratch sessions
#
# Works in zsh and bash. Source this file from your shell config:
#   source /path/to/cltmp.zsh

cltmp() {
  local root="${CLTMP_ROOT:-$HOME/Downloads}"

  if [[ "$1" == "--prune" ]]; then
    local days="${2:-14}" pruned=""
    local d
    while IFS= read -r d; do
      pruned=1
      printf 'cltmp: removing %s\n' "$d"
      rm -rf "$d"
    done < <(find "$root" -maxdepth 1 -type d -name 'scratch-*' -mtime +"$days")
    [[ -z "$pruned" ]] && echo "cltmp: nothing older than $days days to prune"
    return 0
  fi

  local model="" effort="" cont="" safe=""
  while [[ "$1" == -* ]]; do
    case "$1" in
      -c|--continue) cont=1; shift ;;
      -s|--safe)     safe=1; shift ;;
      -m|--model)
        [[ -z "$2" ]] && { echo "cltmp: $1 requires a value" >&2; return 1; }
        model="$2"; shift 2 ;;
      -e|--effort)
        [[ -z "$2" ]] && { echo "cltmp: $1 requires a value" >&2; return 1; }
        effort="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'
usage: cltmp [options] [name]

Start a Claude Code session in a fresh, disposable directory.

options:
  -c, --continue      resume the most recent scratch session
  -s, --safe          keep Claude Code's normal permission prompts
  -m, --model NAME    model to use (case-insensitive)
  -e, --effort LEVEL  reasoning effort
      --prune [DAYS]  delete scratch dirs older than DAYS (default 14)
  -h, --help          show this help

environment:
  CLTMP_ROOT          where scratch dirs live (default: ~/Downloads)
EOF
        return 0 ;;
      *) echo "cltmp: unknown option $1" >&2; return 1 ;;
    esac
  done

  local args=()
  [[ -z "$safe" ]] && args+=(--dangerously-skip-permissions)
  if [[ -n "$model" ]]; then
    model=$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')
    args+=(--model "$model")
  fi
  [[ -n "$effort" ]] && args+=(--effort "$effort")

  if [[ -n "$cont" ]]; then
    local last
    last=$(find "$root" -maxdepth 1 -type d -name 'scratch-*' -exec ls -dt {} + 2>/dev/null | head -n1)
    if [[ -z "$last" ]]; then
      echo "cltmp: no scratch session found to continue" >&2
      return 1
    fi
    cd "$last" && claude --continue "${args[@]}"
    return
  fi

  local name="${1:-scratch-$(date +%Y%m%d-%H%M)}"
  local dir="$root/$name"
  mkdir -p "$dir" && cd "$dir" && claude "${args[@]}"
}
