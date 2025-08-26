# Upsie

A utility written in Zig that takes the best of `uptime` and `uname -a` and displays it in a beautiful way.

![screenshot](img/upsie.png)

`upsie` displays:
* The current hostname.
* The current Linux kernel version (use `-l` to display the full Linux kernel version).
* The current architecture (like `x86_64`).
* The current uptime, neatly formatted.

The intended to use it to put it in ie. `~/.zshrc`, `~/.bashrc`, `~/.bash_profile` or `~/.config/fish/fish.config` so that it runs when a user logs in.

### General info

* License: BSD-3
* Version: 0.0.1
