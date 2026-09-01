#
# Copyright 2026, laggardkernel and the zsh-tmux contributors
# SPDX-License-Identifier: MIT

#
# Authors:
#   laggardkernel <laggardkernel@gmail.com>
#

# Select the multiplexer backend. An explicit backend is honored; otherwise Herdr
# is preferred and tmux is the fallback.
function _zsh_tmux_plugin_select_backend() {
  local backend configured_backend
  if zstyle -s ':prezto:module:tmux' backend configured_backend; then
    backend="$configured_backend"
    if [[ "$backend" != tmux && "$backend" != herdr ]]; then
      return 1
    fi
  elif (( $+commands[herdr] )); then
    backend=herdr
  elif (( $+commands[tmux] )); then
    backend=tmux
  else
    return 1
  fi
  print -r -- "$backend"
}

_zsh_tmux_backend="$(_zsh_tmux_plugin_select_backend)" || {
  unfunction _zsh_tmux_plugin_select_backend
  unset _zsh_tmux_backend
  return
}

# Return if the selected multiplexer is not available.
if (( ! $+commands[$_zsh_tmux_backend] )); then
  unfunction _zsh_tmux_plugin_select_backend
  unset _zsh_tmux_backend
  return
fi

# Herdr launch path. Start the native default session only when no server is running.
function _zsh_tmux_plugin_run_herdr() {
  # Herdr sets HERDR_ENV=1 in managed panes and blocks nested launches.
  [[ "${HERDR_ENV:-}" == 1 ]] && return

  # Skip if the default Herdr server is already running.
  local herdr_status
  herdr_status="$(command herdr status server --json 2>/dev/null)" || herdr_status=""
  if [[ "$herdr_status" == *'"running":true'* ]]; then
    return
  fi

  local -a herdr_cmd
  herdr_cmd=(command herdr)

  if zstyle -T ":prezto:module:tmux" auto-close; then
    exec $herdr_cmd
  else
    $herdr_cmd
  fi
}

# Wrapper function for tmux.
function _zsh_tmux_plugin_run_tmux() {
  local -a tmux_cmd
  tmux_cmd=(command tmux)

  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
    zstyle -t ":prezto:module:tmux:iterm" integrate; then
    # revert aggressive-resize set by tmux-sensible
    tmux setw -g aggressive-resize off
    tmux_cmd+=(-CC)
  fi

  local _tmux_session
  local _tmux_session_hash
  # name session as <directory>-<hash>
  _tmux_session="$(pwd)" && _tmux_session="${_tmux_session##*/}"
  # TODO: remove illegal characters with regex
  _tmux_session="${_tmux_session// /_}"; _tmux_session="${_tmux_session//./_}"; _tmux_session="${_tmux_session//:/_}"

  if (( $+commands[md5sum] )); then
    _tmux_session_hash="$(pwd|md5sum)" \
      && _tmux_session_hash="${_tmux_session_hash% -}"
  elif (( $+commands[md5] )); then
    _tmux_session_hash="$(pwd|md5 -r)"
  fi
  _tmux_session_hash="${_tmux_session_hash:0:5}"

  _tmux_session="${_tmux_session}-${_tmux_session_hash}" && unset _tmux_session_hash

  # set -x
  local return_val
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
    zstyle -t ":prezto:module:tmux:iterm" integrate; then
    if zstyle -T ":prezto:module:tmux" auto-close; then
      if ! tmux has-session -t "$_tmux_session" &>/dev/null; then
        exec $tmux_cmd new-session -AD -s "$_tmux_session"
      fi
    else
      if ! tmux has-session -t "$_tmux_session" &>/dev/null; then
        $tmux_cmd new-session -AD -s "$_tmux_session"
      fi
    fi
  else
    if ! tmux has-session -t "$_tmux_session" &>/dev/null; then
      if return_val=$($tmux_cmd new-session -AD -s "$_tmux_session"); then
        zstyle -T ":prezto:module:tmux" auto-close && exit
      else
        [[ "$return_val" = *exited* ]] && exit
      fi
    fi
  fi
  # set +x
}

function _zsh_tmux_plugin_run() {
  local backend
  backend="$(_zsh_tmux_plugin_select_backend)" || return
  case "$backend" in
    herdr) _zsh_tmux_plugin_run_herdr ;;
    tmux)  _zsh_tmux_plugin_run_tmux ;;
  esac
}

if [[ -z "$NO_AUTO_TMUX" ]] && \
  [[ -z "$TMUX" && -z "$EMACS" && -z "$VIM" && -z "$INSIDE_EMACS" && -z "$VSCODE_PID" ]] && \
  { [[ "$_zsh_tmux_backend" != herdr ]] || [[ "${HERDR_ENV:-}" != 1 ]]; } && ( \
  ( [[ -n "$SSH_TTY" ]] && zstyle -t ':prezto:module:tmux:auto-start' remote ) ||
  ( [[ -z "$SSH_TTY" ]] && zstyle -T ':prezto:module:tmux:auto-start' local ) \
); then
  export NO_AUTO_TMUX=1 # disable auto tmux connection in sub-shells
  _zsh_tmux_plugin_run
fi

unset _zsh_tmux_backend
