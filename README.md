# zsh-tmux

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Auto start a multiplexer session once the shell is launched. Herdr is preferred when installed, with tmux as the fallback. With tmux, sessions are named `directory-hash` so the same directory maps to a stable name; if that session already exists, the plugin does not attach to it. Herdr uses its own persistent default session plus directory-based workspaces; if that server is already running, the plugin does not attach to it.

## Features

- Creating sessions automatically on shell run
- Consistent tmux session name for the same directory
- Herdr preferred when installed, with tmux as the fallback; either backend can be selected explicitly
- Options to
    - Disable auto session creating
    - Kill the launching shell automatically once you detach (`auto-close`)
    - Enable Tmux CONTROL MODE in iTerm (tmux only)

## Installation

### [Zinit](https://github.com/zdharma/zinit)

The only ZSH plugin manager solves the time-consuming init for `nvm`, `nodenv`, `pyenv`, `rvm`, `rbenv`, `thefuck`, `fasd`, etc, with its amazing async [Turbo Mode](https://zdharma.org/zinit/wiki/INTRODUCTION/#turbo_mode_zsh_53).

```zsh
# add it into your .zshrc
zinit ice pick'init.zsh'
zinit light laggardkernel/zsh-tmux
```

Update the plugin with

```zsh
$ zinit update laggardkernel/zsh-tmux
```

### [Prezto](https://github.com/sorin-ionescu/prezto)

The only framework does **optimizations** in plugins with sophisticated coding skill:
- [Refreshing `.zcompdump` every 20h](https://github.com/sorin-ionescu/prezto/blob/4abbc5572149baa6a5e7e38393a4b2006f01024f/modules/completion/init.zsh#L31-L41)
- [Compiling `.zcompdump` as bytecode in the background](https://github.com/sorin-ionescu/prezto/blob/4abbc5572149baa6a5e7e38393a4b2006f01024f/runcoms/zlogin#L9-L15)
- [Caching init script for fasd](https://github.com/sorin-ionescu/prezto/blob/4abbc5572149baa6a5e7e38393a4b2006f01024f/modules/fasd/init.zsh#L22-L36)
- Saving `*env` startup time with [`init - --no-rehash` for `rbenv`, `pyenv`, `nodenv`](https://github.com/sorin-ionescu/prezto/blob/4abbc5572149baa6a5e7e38393a4b2006f01024f/modules/python/init.zsh#L22)
- [Removing the horribly time-consuming `brew command` from `command-not-found`](https://github.com/sorin-ionescu/prezto/blob/4abbc5572149baa6a5e7e38393a4b2006f01024f/modules/command-not-found/init.zsh)

```zsh
mkdir -p ${ZDOTDIR:-$HOME}/.zprezto/contrib &>/dev/null
git clone git@github.com:laggardkernel/zsh-tmux.git ${ZDOTDIR:-$HOME}/.zprezto/contrib/zsh-tmux

# or use HTTPS instead
git clone https://github.com/laggardkernel/zsh-tmux.git ${ZDOTDIR:-$HOME}/.zprezto/contrib/zsh-tmux
```

## Settings
### Backend
Herdr is preferred when the style is unset and installed. tmux is used when Herdr is unavailable. Select a backend explicitly when needed:

```zsh
# Prefer Herdr explicitly
zstyle ':prezto:module:tmux' backend herdr

# Use tmux explicitly
zstyle ':prezto:module:tmux' backend tmux
```

Herdr is launched as bare `herdr` only when the default server is not running. The plugin does not pass tmux `directory-hash` names, `-CC`, or a `TERM` override to Herdr. Set this style before loading the plugin. Unknown backend values are ignored.

### Auto Start
Automatically create a session once the plugin is enabled. These settings apply to both tmux and Herdr. Disable auto creating with

```zsh
# disable automatic start (auto-start is on by default)
# the name is kept for compatibility and also applies to Herdr
NO_AUTO_TMUX=1

# setting for local terminal only
zstyle ':prezto:module:tmux:auto-start' local 'no' # default 'yes'

# setting for remote terminal only
zstyle ':prezto:module:tmux:auto-start' remote 'no' # default 'no'
```

For tmux, if a session with the generated `directory-hash` name already exists, the plugin does not attach to it.

For Herdr, if `herdr status server` reports the default server as running, the plugin does not attach. Nested Herdr launches are skipped when `HERDR_ENV=1` (set inside Herdr-managed panes). On SSH, the plugin runs `herdr` on the remote host; it does not use `herdr --remote`.

### Auto Close
Exit the launching shell when the multiplexer client ends. Enabled by default.

```zsh
zstyle ':prezto:module:tmux' auto-close 'no' # default 'yes'
```

With Herdr, enabled `auto-close` replaces the shell with `herdr` (`exec`), so the shell ends when you detach. Disabled `auto-close` runs `herdr` in the current shell and returns to that shell after detach.

### iTerm Integration
Enable auto session creating support for Tmux CONTROL MODE in iTerm with

```zsh
zstyle ":prezto:module:tmux:iterm" integrate "yes" # default 'no'
```

iTerm control mode is tmux-only. Herdr never receives `-CC` and does not change tmux `aggressive-resize`.

## Todo

- [ ] Length customization for hash suffix in session name

## License

The MIT License (MIT)

Copyright (c) 2026 laggardkernel
