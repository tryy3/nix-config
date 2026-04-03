# zsh-deep-autocd.plugin.zsh
# When cd-ing into a directory that contains only a single subdirectory (no files),
# automatically dive deeper until reaching a directory with files or multiple entries.

function _zsh_deep_autocd_chpwd() {
  local dir="$PWD"
  while true; do
    local -a all_entries dirs files
    all_entries=("$dir"/*(N))
    dirs=("$dir"/*(N/))
    files=("$dir"/*(.N))

    # Stop if there are files, no entries, or more than one entry
    if [[ ${#files[@]} -gt 0 || ${#all_entries[@]} -eq 0 || ${#all_entries[@]} -gt 1 ]]; then
      break
    fi

    # Exactly one entry and it's a directory — dive deeper
    if [[ ${#dirs[@]} -eq 1 ]]; then
      dir="${dirs[1]}"
    else
      break
    fi
  done

  if [[ "$dir" != "$PWD" ]]; then
    builtin cd "$dir"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _zsh_deep_autocd_chpwd
