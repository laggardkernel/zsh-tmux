# ZSH-tmux

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A ZSH plugin for tmux with features of:
- Create/Attach sessions automatically
- Consistent session name for the same directory
- Options to
    - Disable auto session creating/attaching
    - Kill shell automatically once u detach from a tmux session

## Installation

### [Zplugin](https://github.com/zdharma/zplugin)

The only ZSH plugin manager solves the time-consuming init for `nvm`, `nodenv`, `pyenv`, `rvm`, `rbenv`, `thefuck`, `fasd`, etc, with its amazing async [Turbo Mode](https://github.com/zdharma/zplugin#turbo-mode-zsh--53).

```zsh
# add it into your .zshrc
zplugin ice pick'init.zsh'
zplugin light laggardkernel/zsh-tmux
```

Update the plugin with

```zsh
$ zplg update laggardkernel/zsh-tmux
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

## Usage
Automatically attach to an existing tmux session, or create a session once the plugin is enabled. Disable auto attaching/creating with

```zsh
# add it into .zshrc
NO_AUTO_TMUX=1
```

Enable auto session creating/attaching for Tmux CONTROL MODE in iTerm with

```zsh
zstyle ":prezto:module:tmux:iterm" integrate "yes" # default off
```

## Todo

- [ ] Length customization for hash suffix in session name

## License

The MIT License (MIT)

Copyright (c) 2019 laggardkernel