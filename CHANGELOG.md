# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- Switch to `md5 -r` in case `md5sum` doesn't exist

## [1.1.0] - 2020-09-02

### Added

- Disable aggressive-resize automatically for iTerm2 tmux integration mode

### Changed

- Replace command `md5` with `md5sum` for Linux support
- If session exists, don't attach to it. No force attach anymore.

### Removed

- remove forcing `TERM`, respect `TERM` set by user

## [1.0.0] - 2018-04-21

### Added

- Attach/Create sessions automatically on shell run
- Consistent session name for the same directory
- [Prezto](https://github.com/sorin-ionescu/prezto) custom module support
- `zstyle` settings
- Tmux CONTROL MODE support in iTerm
- Option: Disable auto session creating/attaching
- Option: Support Tmux CONTROL MODE in iTerm
- Option: Custom environment variable `TERM` for `tmux` commands

[Unreleased]: https://github.com/laggardkernel/zsh-tmux/compare/1.1.0...HEAD
[1.1.0]: https://github.com/laggardkernel/zsh-tmux/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/laggardkernel/zsh-tmux/compare/4b9f3373...v1.0.0
