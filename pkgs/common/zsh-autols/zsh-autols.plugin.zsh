# zsh-autols.plugin.zsh
# Automatically run ls when changing directories

function _zsh_autols_chpwd() {
  ls
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _zsh_autols_chpwd
