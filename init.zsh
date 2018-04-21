#
# Copyright 2019, laggardkernel and the zsh-tmux contributors
# SPDX-License-Identifier: MIT

#
# Authors:
#   laggardkernel <laggardkernel@gmail.com>
#

# Return if requirements are not found.
if (( ! $+commands[tmux] )); then
  return
fi

# Wrapper function for tmux.
function _zsh_tmux_plugin_run() {
  local -a tmux_cmd
  tmux_cmd=(command tmux)

  # Determine if the terminal supports 256 colors
  local default_term
  if [[ "${terminfo[colors]}" == "256" ]]; then
    zstyle -g default_term ":prezto:module:tmux:term" with_256color 2>/dev/null
    default_term="${default_term:-screen-256color}"
  else
    zstyle -g default_term ":prezto:module:tmux:term" without_256color 2>/dev/null
    default_term="${default_term:-screen}"
  fi

  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
    zstyle -t ":prezto:module:tmux:iterm" integrate; then
    tmux_cmd+=(-CC)
  fi

  local _tmux_session
  local _tmux_session_hash
  # name session as <directory>-<hash>
  _tmux_session="$(pwd)" && _tmux_session="${_tmux_session##*/}"
  # TODO: remove illegal characters with regex
  _tmux_session="${_tmux_session// /_}"; _tmux_session="${_tmux_session//./_}"; _tmux_session="${_tmux_session//:/_}"

  _tmux_session_hash="$(pwd|md5)" && _tmux_session_hash="${_tmux_session_hash:0:5}"

  _tmux_session="${_tmux_session}-${_tmux_session_hash}" && unset _tmux_session_hash

  # set -x
  local return_val
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
    zstyle -t ":prezto:module:tmux:iterm" integrate; then
    zstyle -T ":prezto:module:tmux" auto-close && \
    TERM="$default_term" exec $tmux_cmd new-session -AD -s "$_tmux_session" ||
    TERM="$default_term" $tmux_cmd new-session -AD -s "$_tmux_session"
  else
    return_val=$(TERM="$default_term" $tmux_cmd new-session -AD -s "$_tmux_session") && \
    { zstyle -T ":prezto:module:tmux" auto-close && exit } || \
    { [[ "$return_val" = *exited* ]] && exit }
  fi
  # set +x
}

if [[ -z "$NO_AUTO_TMUX" ]] && \
  [[ -z "$TMUX" && -z "$EMACS" && -z "$VIM" && -z "$INSIDE_EMACS" && -z "$VSCODE_PID" ]] && ( \
  ( [[ -n "$SSH_TTY" ]] && zstyle -t ':prezto:module:tmux:auto-start' remote ) ||
  ( [[ -z "$SSH_TTY" ]] && zstyle -T ':prezto:module:tmux:auto-start' local ) \
); then
  export NO_AUTO_TMUX=1 # disable auto tmux connection in sub-shells
  _zsh_tmux_plugin_run
fi
