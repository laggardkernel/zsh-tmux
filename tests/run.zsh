#!/usr/bin/env zsh
emulate -L zsh
setopt no_aliases no_global_rcs
# Isolate from the invoking multiplexer/editor environment.
unset TMUX TMUX_PANE TMUX_PLUGIN_MANAGER_PATH TMUX_TMPDIR
unset HERDR_ENV HERDR_PANE_ID HERDR_SOCKET_PATH HERDR_TAB_ID HERDR_WORKSPACE_ID
unset HERDR_BIN_PATH HERDR_ACTIVE_PANE_ID HERDR_ACTIVE_TAB_ID
unset HERDR_ACTIVE_WORKSPACE_ID HERDR_ACTIVE_PANE_CWD
unset EMACS VIM INSIDE_EMACS VSCODE_PID SSH_TTY NO_AUTO_TMUX TERM_PROGRAM

PLUGIN_DIR="${0:A:h:h}"
export PLUGIN_DIR

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/zsh-tmux-test.XXXXXX")"
FAKE_BIN="$TEST_ROOT/bin"
WORKDIR="$TEST_ROOT/sample"
FAKE_LOG="$TEST_ROOT/log"
mkdir -p "$FAKE_BIN" "$WORKDIR"
: > "$FAKE_LOG"
export FAKE_LOG

trap 'rm -rf "$TEST_ROOT"' EXIT

write_fake() {
  local name="$1"
  cat > "$FAKE_BIN/$name" <<'EOF'
#!/bin/sh
name=${0##*/}
printf '%s' "$name" >> "$FAKE_LOG"
for arg in "$@"; do
  printf ' %s' "$arg" >> "$FAKE_LOG"
done
printf '\n' >> "$FAKE_LOG"

case "$name" in
  tmux)
    if [ "$1" = "has-session" ]; then
      if [ -n "$FAKE_TMUX_HAS_SESSION" ]; then
        exit 0
      fi
      exit 1
    fi
    exit 0
    ;;
  md5sum)
    while IFS= read -r _; do
      :
    done
    printf '%s\n' "deadbeefdeadbeef  -"
    exit 0
    ;;
  md5)
    while IFS= read -r _; do
      :
    done
    printf '%s\n' "deadbeefdeadbeef"
    exit 0
    ;;
  herdr)
    if [ "$1" = "status" ] && [ "$2" = "server" ]; then
      if [ -n "$FAKE_HERDR_SERVER_RUNNING" ]; then
        printf '%s\n' '{"status":"running","running":true}'
      else
        printf '%s\n' '{"status":"not_running","running":false}'
      fi
      exit 0
    fi
    exit 0
    ;;
esac
exit 0
EOF
  chmod +x "$FAKE_BIN/$name"
}

write_fake tmux
write_fake herdr
write_fake md5sum
write_fake md5

SESSION_NAME="sample-deadb"
HERDR_STATUS_LOG="herdr status server --json"
HERDR_START_LOG=$'herdr status server --json\nherdr'

clean_env() {
  unset TMUX TMUX_PANE EMACS VIM INSIDE_EMACS VSCODE_PID SSH_TTY NO_AUTO_TMUX TERM_PROGRAM
  unset HERDR_ENV HERDR_PANE_ID HERDR_SOCKET_PATH
  unset FAKE_TMUX_HAS_SESSION FAKE_HERDR_SERVER_RUNNING
  zstyle -d ':prezto:module:tmux'
  zstyle -d ':prezto:module:tmux:auto-start'
  zstyle -d ':prezto:module:tmux:iterm'
  zstyle -d ':prezto:module:tmux:term'
}

plugin_zsh() {
  (
    clean_env
    path=("$FAKE_BIN" /bin /usr/bin)
    export PATH
    export FAKE_LOG
    rehash
    cd "$WORKDIR" || exit 1
    eval "$1"
  )
}

typeset -i passed=0 failed=0

assert_eq() {
  local actual="$1" expected="$2" msg="$3"
  if [[ "$actual" == "$expected" ]]; then
    return 0
  fi
  print -u2 "    expected: ${(q+)expected}"
  print -u2 "    actual:   ${(q+)actual}"
  [[ -n "$msg" ]] && print -u2 "    $msg"
  return 1
}

log_text() {
  local data
  data="$(<"$FAKE_LOG")"
  print -r -- "$data"
}

run_case() {
  local name="$1"
  shift
  : > "$FAKE_LOG"
  if "$@"; then
    print "PASS $name"
    passed+=1
  else
    print "FAIL $name"
    print "  log: ${(q+)$(log_text)}"
    failed+=1
  fi
}

test_default_backend_prefers_herdr() {
  local out
  out="$(plugin_zsh '
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" "" "auto-close should replace/exit the launching shell" || return 1
}

test_tmux_fallback_when_herdr_is_missing() {
  local out rc=0
  command rm -f "$FAKE_BIN/herdr"
  out="$(plugin_zsh '
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')" || rc=1
  write_fake herdr
  (( rc == 0 )) || return 1
  assert_eq "$(log_text)" $'md5sum\ntmux has-session -t '"$SESSION_NAME"$'\ntmux new-session -AD -s '"$SESSION_NAME" || return 1
  assert_eq "$out" "" "auto-close should replace/exit the launching shell" || return 1
}

test_existing_tmux_session_is_not_attached() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend tmux
    export FAKE_TMUX_HAS_SESSION=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" $'md5sum\ntmux has-session -t '"$SESSION_NAME" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

test_herdr_backend_invokes_herdr_only() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    export FAKE_TMUX_HAS_SESSION=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" "" "herdr auto-close should exec" || return 1
}

test_existing_herdr_server_is_not_attached() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    export FAKE_HERDR_SERVER_RUNNING=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "$HERDR_STATUS_LOG" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

test_missing_tmux_is_noop() {
  local out rc=0
  command rm -f "$FAKE_BIN/tmux"
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend tmux
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    print -r -- "fn:${+functions[_zsh_tmux_plugin_run]}"
  ')" || rc=1
  write_fake tmux
  (( rc == 0 )) || return 1
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" $'AFTER_SOURCE\nfn:0' || return 1
}

test_herdr_does_not_require_tmux() {
  local out rc=0
  command rm -f "$FAKE_BIN/tmux"
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')" || rc=1
  write_fake tmux
  (( rc == 0 )) || return 1
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" "" || return 1
}

test_missing_herdr_is_noop() {
  local out rc=0
  command rm -f "$FAKE_BIN/herdr"
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    print -r -- "fn:${+functions[_zsh_tmux_plugin_run]}"
  ')" || rc=1
  write_fake herdr
  (( rc == 0 )) || return 1
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" $'AFTER_SOURCE\nfn:0' || return 1
}

test_herdr_env_blocks_autostart() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    export HERDR_ENV=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    _zsh_tmux_plugin_run
    print AFTER_RUN
  ')"
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" $'AFTER_SOURCE\nAFTER_RUN' || return 1
}

test_no_auto_tmux_suppresses_start() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    export NO_AUTO_TMUX=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

test_tmux_var_suppresses_start() {
  local out
  out="$(plugin_zsh '
    export TMUX=/tmp/tmux-test
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

test_editor_vars_suppress_start() {
  local var out
  for var in EMACS VIM INSIDE_EMACS VSCODE_PID; do
    : > "$FAKE_LOG"
    out="$(plugin_zsh "
      export $var=1
      source \"\$PLUGIN_DIR/init.zsh\"
      print AFTER_SOURCE
    ")"
    assert_eq "$(log_text)" "" "$var should suppress auto-start" || return 1
    assert_eq "$out" "AFTER_SOURCE" "$var should leave the shell" || return 1
  done
}

test_local_autostart_can_be_disabled() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux:auto-start" local no
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

test_remote_autostart_default_off() {
  local out
  out="$(plugin_zsh '
    export SSH_TTY=/dev/pts/0
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

test_remote_autostart_can_be_enabled() {
  local out
  out="$(plugin_zsh '
    export SSH_TTY=/dev/pts/0
    zstyle ":prezto:module:tmux:auto-start" remote yes
    zstyle ":prezto:module:tmux" backend herdr
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" "" || return 1
}

test_herdr_auto_close_off_returns_to_shell() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    zstyle ":prezto:module:tmux" auto-close no
    export NO_AUTO_TMUX=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    _zsh_tmux_plugin_run
    print AFTER_RUN
  ')"
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" $'AFTER_SOURCE\nAFTER_RUN' || return 1
}

test_herdr_auto_close_on_execs() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend herdr
    export NO_AUTO_TMUX=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    _zsh_tmux_plugin_run
    print AFTER_RUN
  ')"
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" "AFTER_SOURCE" "exec should skip AFTER_RUN" || return 1
}

test_iterm_cc_is_tmux_only() {
  local out
  out="$(plugin_zsh '
    export TERM_PROGRAM=iTerm.app
    zstyle ":prezto:module:tmux" backend tmux
    zstyle ":prezto:module:tmux:iterm" integrate yes
    export NO_AUTO_TMUX=1
    source "$PLUGIN_DIR/init.zsh"
    _zsh_tmux_plugin_run
    print AFTER_RUN
  ')"
  assert_eq "$(log_text)" $'tmux setw -g aggressive-resize off\nmd5sum\ntmux has-session -t '"$SESSION_NAME"$'\ntmux -CC new-session -AD -s '"$SESSION_NAME" || return 1
  assert_eq "$out" "" "iTerm auto-close execs tmux" || return 1

  : > "$FAKE_LOG"
  out="$(plugin_zsh '
    export TERM_PROGRAM=iTerm.app
    zstyle ":prezto:module:tmux" backend herdr
    zstyle ":prezto:module:tmux:iterm" integrate yes
    export NO_AUTO_TMUX=1
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    _zsh_tmux_plugin_run
    print AFTER_RUN
  ')"
  assert_eq "$(log_text)" "$HERDR_START_LOG" || return 1
  assert_eq "$out" "AFTER_SOURCE" "herdr must not receive -CC and should exec" || return 1
}

test_unknown_backend_fails_closed() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend screen
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
    print -r -- "fn:${+functions[_zsh_tmux_plugin_run]}"
  ')"
  assert_eq "$(log_text)" "" || return 1
  assert_eq "$out" $'AFTER_SOURCE\nfn:0' || return 1
}

test_tmux_auto_close_off_keeps_shell() {
  local out
  out="$(plugin_zsh '
    zstyle ":prezto:module:tmux" backend tmux
    zstyle ":prezto:module:tmux" auto-close no
    source "$PLUGIN_DIR/init.zsh"
    print AFTER_SOURCE
  ')"
  assert_eq "$(log_text)" $'md5sum\ntmux has-session -t '"$SESSION_NAME"$'\ntmux new-session -AD -s '"$SESSION_NAME" || return 1
  assert_eq "$out" "AFTER_SOURCE" || return 1
}

run_case "default backend prefers Herdr" test_default_backend_prefers_herdr
run_case "tmux is fallback when Herdr is missing" test_tmux_fallback_when_herdr_is_missing
run_case "existing tmux session is not attached" test_existing_tmux_session_is_not_attached
run_case "herdr backend invokes herdr only" test_herdr_backend_invokes_herdr_only
run_case "existing herdr server is not attached" test_existing_herdr_server_is_not_attached
run_case "missing tmux is a no-op" test_missing_tmux_is_noop
run_case "herdr backend does not require tmux" test_herdr_does_not_require_tmux
run_case "missing herdr is a no-op" test_missing_herdr_is_noop
run_case "HERDR_ENV=1 blocks herdr auto-start and run" test_herdr_env_blocks_autostart
run_case "NO_AUTO_TMUX suppresses start" test_no_auto_tmux_suppresses_start
run_case "TMUX suppresses start" test_tmux_var_suppresses_start
run_case "editor variables suppress start" test_editor_vars_suppress_start
run_case "local auto-start can be disabled" test_local_autostart_can_be_disabled
run_case "remote auto-start defaults to off" test_remote_autostart_default_off
run_case "remote auto-start can enable herdr" test_remote_autostart_can_be_enabled
run_case "herdr auto-close=no returns to the shell" test_herdr_auto_close_off_returns_to_shell
run_case "herdr auto-close execs herdr" test_herdr_auto_close_on_execs
run_case "iTerm -CC is tmux-only" test_iterm_cc_is_tmux_only
run_case "unknown backend fails closed" test_unknown_backend_fails_closed
run_case "tmux auto-close=no keeps the shell" test_tmux_auto_close_off_keeps_shell

print
print "$passed passed, $failed failed"
(( failed == 0 ))
