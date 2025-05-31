#!/bin/bash

# Configuration
INSTALL_DIR="$HOME/.config/zig-bookmarker"
BIN_NAME="zb"
SCRIPT_NAME="run.sh"
BASHRC="$HOME/.bashrc"

# Step 1: Compile the program
echo "Step 1/5: Compiling the program..."
if zig build -Doptimize=ReleaseSafe; then
    echo "✅ Successfully compiled the program"
else
    echo "❌ Failed to compile the program"
    exit 1
fi

# Step 2: Create installation directory and copy executable
echo -e "\nStep 2/5: Setting up installation directory..."
mkdir -p "$INSTALL_DIR"
if cp zig-out/bin/"$BIN_NAME" "$INSTALL_DIR"/; then
    echo "✅ Copied executable to $INSTALL_DIR"
else
    echo "❌ Failed to copy executable"
    exit 1
fi

# Step 3: Copy the shell script
echo -e "\nStep 3/5: Copying shell script..."
if cp src/"$SCRIPT_NAME" "$INSTALL_DIR"/; then
    chmod +x "$INSTALL_DIR"/"$SCRIPT_NAME"
    echo "✅ Copied and made executable: $SCRIPT_NAME"
else
    echo "❌ Failed to copy shell script"
    exit 1
fi

# Step 4: Add to bashrc
echo -e "\nStep 4/5: Adding to $BASHRC..."
MARKER="# zig-bookmarker configuration"
CONFIG="\n$MARKER\nzb() {\n    source $INSTALL_DIR/$SCRIPT_NAME \"\$@\"\n}\n"

if grep -qF "$MARKER" "$BASHRC"; then
    echo "ℹ️  Configuration already exists in $BASHRC"
else
    echo -e "$CONFIG" >> "$BASHRC"
    echo "✅ Added configuration to $BASHRC"
fi

# Step 5: Set up completion
echo -e "\nStep 5/5: Setting up completion..."
COMPLETION="\n# zb command completion\n_zb_completion() {\n    local cur=\${COMP_WORDS[COMP_CWORD]}\n    if [[ \${#COMP_WORDS[@]} -eq 2 ]]; then\n        COMPREPLY=(\$(compgen -W \"-a -r -R -l -p -h\" -- \"\$cur\"))\n    else\n        local bookmarks\n        bookmarks=\$($INSTALL_DIR/$BIN_NAME -l | awk -F': ' '{print \$1}')\n        COMPREPLY=(\$(compgen -W \"\$bookmarks\" -- \"\$cur\"))\n    fi\n}\ncomplete -F _zb_completion zb"

if grep -qF "_zb_completion" "$BASHRC"; then
    echo "ℹ️  Completion already set up in $BASHRC"
else
    echo -e "$COMPLETION" >> "$BASHRC"
    echo "✅ Added tab completion to $BASHRC"
fi

# Final instructions
echo -e "\n🎉 Installation complete!"
echo -e "To start using zb, either:"
echo -e "1. Restart your terminal, or"
echo -e "2. Run: source $BASHRC\n"

echo "You can then use commands like:"
echo "  zb -a work ~/projects    # Add bookmark"
echo "  zb work                   # Jump to bookmark"
echo "  zb -l                     # List bookmarks"
