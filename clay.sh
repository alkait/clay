# clay — disposable Claude Code playgrounds
#
# Works in zsh and bash. Source this file from your shell config:
#   source /path/to/clay.sh
#
# External commands are invoked via 'command' throughout: interactive shells
# expand aliases inside function bodies when this file is sourced, so a user
# alias like ls=eza or rm='rm -i' would otherwise get baked in and break the
# script. 'claude' is deliberately left bare so an alias for it still works.

_clay_encode() {
  # Claude Code keys conversation history by absolute path with every
  # non-alphanumeric character replaced by '-' (~/.claude/projects/<encoded>).
  printf '%s' "$1" | command sed 's/[^A-Za-z0-9]/-/g'
}

_clay_dirs() {
  # Print clay-managed dirs under $1, most recently used first. The .clay
  # marker is touched on every session start/resume, so its mtime tracks last
  # use; the dir's own mtime doesn't (edits inside subdirs never bump it).
  local root="$1" d
  local found=()
  while IFS= read -r d; do
    case "${d##*/}" in
      play-*) found+=("$d") ;;
      *) [[ -e "$d/.clay" ]] && found+=("$d") ;;
    esac
  done < <(command find "$root" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
  [[ ${#found[@]} -eq 0 ]] && return 1
  local keys=()
  for d in "${found[@]}"; do
    if [[ -e "$d/.clay" ]]; then keys+=("$d/.clay"); else keys+=("$d"); fi
  done
  command ls -dt "${keys[@]}" | command sed 's|/\.clay$||'
}

_clay_pick() {
  # Interactively pick a kept (renamed) playground under $1; prints the
  # chosen path. Timestamped play-* dirs are resumed via -c or by name.
  local root="$1" d sel
  local names=()
  while IFS= read -r d; do
    case "${d##*/}" in play-*) ;; *) names+=("${d##*/}") ;; esac
  done < <(_clay_dirs "$root")
  if [[ ${#names[@]} -eq 0 ]]; then
    echo "clay: no kept playgrounds in $root ('clay -r NAME' keeps one)" >&2
    return 1
  fi
  if [[ ${#names[@]} -eq 1 ]]; then
    printf '%s/%s\n' "$root" "${names[@]}"
    return 0
  fi
  local PS3="playground #: "
  select sel in "${names[@]}"; do
    [[ -n "$sel" ]] && { printf '%s/%s\n' "$root" "$sel"; return 0; }
    echo "clay: invalid choice" >&2
  done
  return 1
}

clay() {
  local root="${CLAY_ROOT:-$HOME/clay}"
  root="${root%/}"

  local cont="" pick="" rename="" list="" prune="" del="" move=""
  while [[ "$1" == -* ]]; do
    case "$1" in
      -c|--continue) cont=1; shift ;;
      -cl|--pick)    cont=1; pick=1; shift ;;
      -l|--list)     list=1; shift ;;
      -r|--rename)
        [[ -z "$2" || "$2" == -* ]] && { echo "clay: $1 requires a value" >&2; return 1; }
        rename="$2"; shift 2 ;;
      -m|--move)
        [[ -z "$2" || "$2" == -* ]] && { echo "clay: $1 requires a value" >&2; return 1; }
        move="$2"; shift 2 ;;
      -d|--delete)
        [[ -z "$2" || "$2" == -* ]] && { echo "clay: $1 requires a value" >&2; return 1; }
        del="$2"; shift 2 ;;
      --prune)       prune=1; shift ;;
      -h|--help)
        command cat <<'EOF'
usage: clay [options]

Start a Claude Code session in a fresh, disposable playground directory.

options:
  -c, --continue [NAME]  resume the last-used playground, or NAME
  -cl, --pick            pick a kept playground to resume from a menu
  -r, --rename NAME      keep the current playground: rename it to NAME
                         and migrate its Claude Code conversation history
  -d, --delete NAME      delete playground NAME and its conversation
                         history (asks for confirmation first)
  -m, --move DEST        move the current playground to DEST (anywhere,
                         not just CLAY_ROOT) and migrate its conversation
                         history; resume there with 'claude --continue'
  -l, --list             list playgrounds, most recent first
      --prune            delete all unnamed playgrounds; renamed (kept)
                         ones are never touched
  -h, --help             show this help

environment:
  CLAY_ROOT              where playgrounds live (default: ~/clay)
EOF
        return 0 ;;
      *) echo "clay: unknown option $1" >&2; return 1 ;;
    esac
  done

  if [[ -n "$del" ]]; then
    [[ -n "$1" ]] && { echo "clay: unexpected argument $1" >&2; return 1; }
    local target="$root/$del"
    if [[ ! -d "$target" ]]; then
      echo "clay: no playground named '$del' in $root" >&2
      return 1
    fi
    # Only delete playgrounds: unnamed play-* dirs or kept ones carrying the
    # .clay marker. Anything else under $root is not ours to remove.
    case "$del" in
      play-*) ;;
      *) [[ -e "$target/.clay" ]] || { echo "clay: $target is not a clay playground" >&2; return 1; } ;;
    esac
    local hist="$HOME/.claude/projects/$(_clay_encode "$target")"
    if [[ -d "$hist" ]]; then
      printf 'clay: delete %s and its conversation history? [y/N] ' "$target"
    else
      printf 'clay: delete %s? [y/N] ' "$target"
    fi
    local reply=""
    read -r reply
    case "$reply" in
      y|Y|yes|YES) ;;
      *) echo "clay: aborted"; return 1 ;;
    esac
    # Don't leave the shell sitting in a deleted directory. Compare physical
    # paths so a symlinked CLAY_ROOT still matches.
    local tgtp
    tgtp=$(cd "$target" 2>/dev/null && pwd -P)
    case "$(pwd -P)/" in "$tgtp"/*) cd "$root" || return 1 ;; esac
    command rm -rf "$target" || return 1
    [[ -d "$hist" ]] && command rm -rf "$hist"
    echo "clay: deleted $target"
    return 0
  fi

  if [[ -n "$prune" ]]; then
    [[ -n "$1" ]] && { echo "clay: --prune takes no arguments" >&2; return 1; }
    # Only delete dirs clay itself created (play-* name AND .clay marker);
    # renamed (kept) playgrounds are never touched.
    local pruned="" marker d
    while IFS= read -r marker; do
      d="${marker%/.clay}"
      case "${d##*/}" in play-*) ;; *) continue ;; esac
      pruned=1
      printf 'clay: removing %s\n' "$d"
      command rm -rf "$d"
    done < <(command find "$root" -mindepth 2 -maxdepth 2 -name '.clay' 2>/dev/null)
    [[ -z "$pruned" ]] && echo "clay: nothing to prune"
    return 0
  fi

  if [[ -n "$list" ]]; then
    local listing d n
    listing=$(_clay_dirs "$root") || { echo "clay: no sessions found in $root"; return 0; }
    while IFS= read -r d; do
      n="${d##*/}"
      case "$n" in
        play-*) printf '%s\n' "$n" ;;
        *)         printf '%-28s (kept)\n' "$n" ;;
      esac
    done <<< "$listing"
    return 0
  fi

  if [[ -n "$rename" ]]; then
    case "$rename" in
      play-*) echo "clay: pick a name not starting with 'play-' (those get pruned)" >&2; return 1 ;;
      # Restrict to a charset that round-trips through the history-key
      # encoding unambiguously (and can't be '.', '..', or a hidden dir).
      [!A-Za-z0-9]*|*[!A-Za-z0-9._-]*)
        echo "clay: name must start with a letter or digit and use only letters, digits, '.', '_', '-'" >&2
        return 1 ;;
    esac
    local cur="$PWD"
    # A playground is a dir directly under $root that is either an unnamed
    # play-* dir or a kept one (carries the .clay marker) — so kept
    # playgrounds can be renamed again. Compare physical paths so a
    # symlinked or trailing-slash CLAY_ROOT still matches the directory
    # we're actually in.
    if [[ "$(cd "${cur%/*}" 2>/dev/null && pwd -P)" != "$(cd "$root" 2>/dev/null && pwd -P)" ]] ||
       [[ "${cur##*/}" != play-* && ! -e "$cur/.clay" ]]; then
      echo "clay: run this from the top level of a playground" >&2
      return 1
    fi
    local dest="$root/$rename"
    [[ -e "$dest" ]] && { echo "clay: $dest already exists" >&2; return 1; }
    local hist="$HOME/.claude/projects"
    local oldenc newenc
    oldenc=$(_clay_encode "$cur")
    newenc=$(_clay_encode "$dest")
    if [[ -e "$hist/$newenc" ]]; then
      echo "clay: history for $dest already exists in $hist; pick another name" >&2
      return 1
    fi
    command mv "$cur" "$dest" || return 1
    cd "$dest" || return 1
    command touch "$dest/.clay"
    if [[ -d "$hist/$oldenc" ]]; then
      if command mv "$hist/$oldenc" "$hist/$newenc"; then
        echo "clay: renamed to $dest (conversation history migrated)"
      else
        echo "clay: renamed to $dest, but history migration FAILED — 'claude --continue' may start fresh" >&2
      fi
    else
      echo "clay: renamed to $dest (no conversation history found to migrate)"
    fi
    return 0
  fi

  if [[ -n "$move" ]]; then
    [[ -n "$1" ]] && { echo "clay: unexpected argument $1" >&2; return 1; }
    local cur="$PWD"
    # Same playground check as -r: a play-* dir or a kept one, directly
    # under $root.
    if [[ "$(cd "${cur%/*}" 2>/dev/null && pwd -P)" != "$(cd "$root" 2>/dev/null && pwd -P)" ]] ||
       [[ "${cur##*/}" != play-* && ! -e "$cur/.clay" ]]; then
      echo "clay: run this from the top level of a playground" >&2
      return 1
    fi
    local dest="$move"
    [[ "$dest" != /* ]] && dest="$cur/$dest"
    # mv semantics: an existing directory means "move into it, keeping the
    # current name".
    [[ -d "$dest" ]] && dest="$dest/${cur##*/}"
    case "$dest/" in "$cur"/*)
      echo "clay: destination is inside the playground itself" >&2; return 1 ;;
    esac
    local destbase="${dest##*/}" destdir="${dest%/*}"
    [[ -z "$destdir" ]] && destdir=/
    case "$destbase" in
      play-*) echo "clay: pick a name not starting with 'play-' (those get pruned)" >&2; return 1 ;;
      # Same round-trip-safe charset as -r, since the name feeds the
      # history-key encoding.
      [!A-Za-z0-9]*|*[!A-Za-z0-9._-]*)
        echo "clay: name must start with a letter or digit and use only letters, digits, '.', '_', '-'" >&2
        return 1 ;;
    esac
    command mkdir -p "$destdir" || return 1
    # Canonicalize the parent (logical, matching what $PWD will be after
    # the cd below — that's the path Claude Code keys history by).
    destdir=$(cd "$destdir" 2>/dev/null && pwd) || { echo "clay: cannot resolve $destdir" >&2; return 1; }
    dest="${destdir%/}/$destbase"
    [[ -e "$dest" ]] && { echo "clay: $dest already exists" >&2; return 1; }
    local hist="$HOME/.claude/projects"
    local oldenc newenc
    oldenc=$(_clay_encode "$cur")
    newenc=$(_clay_encode "$dest")
    if [[ -e "$hist/$newenc" ]]; then
      echo "clay: history for $dest already exists in $hist; pick another destination" >&2
      return 1
    fi
    command mv "$cur" "$dest" || return 1
    cd "$dest" || return 1
    # Keep the marker only while it lives under $root; a playground that
    # graduated elsewhere no longer needs clay's tracking.
    if [[ "$(cd "$destdir" 2>/dev/null && pwd -P)" == "$(cd "$root" 2>/dev/null && pwd -P)" ]]; then
      command touch "$dest/.clay"
    else
      command rm -f "$dest/.clay"
    fi
    if [[ -d "$hist/$oldenc" ]]; then
      if command mv "$hist/$oldenc" "$hist/$newenc"; then
        echo "clay: moved to $dest (conversation history migrated; resume with 'claude --continue')"
      else
        echo "clay: moved to $dest, but history migration FAILED — 'claude --continue' may start fresh" >&2
      fi
    else
      echo "clay: moved to $dest (no conversation history found to migrate)"
    fi
    return 0
  fi

  if [[ -n "$cont" ]]; then
    local target
    if [[ -n "$1" ]]; then
      target="$root/$1"
      if [[ ! -d "$target" ]]; then
        echo "clay: no playground named '$1' in $root" >&2
        return 1
      fi
    elif [[ -n "$pick" ]]; then
      target=$(_clay_pick "$root") || return 1
    else
      target=$(_clay_dirs "$root" | command head -n1)
      if [[ -z "$target" ]]; then
        echo "clay: no playgrounds found in $root" >&2
        return 1
      fi
    fi
    cd "$target" || return
    command touch "$target/.clay" 2>/dev/null  # record last use; adopts pre-marker dirs
    claude --dangerously-skip-permissions --continue
    return
  fi

  if [[ -n "$1" ]]; then
    echo "clay: unexpected argument $1" >&2
    return 1
  fi

  local base="$root/play-$(command date +%Y%m%d-%H%M%S)" dir n=0
  command mkdir -p "$root" || return 1
  dir="$base"
  # Plain mkdir so a same-second invocation gets a numbered suffix instead
  # of silently sharing the directory (as mkdir -p would).
  until command mkdir "$dir" 2>/dev/null; do
    [[ -e "$dir" ]] || { echo "clay: cannot create $dir" >&2; return 1; }
    n=$((n+1)); dir="$base-$n"
  done
  command touch "$dir/.clay" && cd "$dir" && claude --dangerously-skip-permissions
}
