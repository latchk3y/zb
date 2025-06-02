# zb - Zig-powered directory bookmarker

**zb** is a fast, reliable directory bookmark manager written in Zig. It allows quick navigation to frequently used directories with a simple interface.

### USAGE

| Command                  | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| `zb <bookmark>`          | Jump to bookmarked directory                                               |
| `zb <path>`              | Jump to specified directory                                                |
| `zb -a <name> [path]`    | Add bookmark (current dir if path omitted)                                 |
| `zb -r <name>`           | Remove bookmark                                                            |
| `zb -R`                  | Remove all bookmarks                                                       |
| `zb -l`                  | List all bookmarks with accessibility status                               |
| `zb -p`                  | Prune invalid bookmarks (non-existent directories)                         |
| `zb -h`                  | Show help                                                                  |

### INSTALLATION

In order to be able to build the executable, [you must have zig installed.](https://ziglang.org/download/).

1. Clone this repository and move into the directory:
```bash
git clone https://github.com/latchk3y/zb.git && cd zb
```

2. Run the install script:
```bash
chmod +x install.sh
./install.sh
```

3. Restart your terminal or source your bashrc:
```bash
source ~/.bashrc
```

### EXAMPLE
```bash
# Add bookmark for current directory
zb -a proj

# Add bookmark for specific directory
zb -a docs ~/Documents

# Jump to bookmark
zb proj

# List all bookmarks
zb -l

# Remove bookmark
zb -r proj
```

### KEY FEATURES
- **Fast**: Written in Zig for maximum performance
- **Reliable**: Built-in path validation and error handling
- **Intuitive**: Simple commands with helpful error messages
- **Persistent**: Bookmarks stored in `~/.config/.zb_bookmarks`
- **Shell completion**: Tab-completion for bookmark names (bash/zsh/fish)

### CONTRIBUTION
Getting this particular program to work on Windows is technically possible. However, my primary operating
system is Linux, and my very limited attempts at trying to get this to work on Windows via DeepSeek generation
have resulted in running head-long into the substantial amount of baby-proofing on that operating system.

The core Zig file has already been tested and definitively returns what it's supposed to, alongside with the installation
script moving everything to the appropriate folders, so all that remains is a batch file (run.bat) to make use of these
functions. If you're familiar with how batch files work and think you can make use of the core zig file to do it, please feel
free to get in touch!

### LICENSE
Unlicense - Do whatever you want with this code. No warranties, no restrictions.
