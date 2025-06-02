#!/bin/bash

# Detect OS and set paths
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows configuration
	# Be aware that currently, because there is no run.bat, this will very likely
	# result in a substantial error. You've been warned.
    INSTALL_DIR="$APPDATA/zig-bookmarker"
    BIN_NAME="zb.exe"
    SCRIPT_NAME="run.bat"
    PROFILE="$USERPROFILE/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
else
    INSTALL_DIR="$HOME/.config/zig-bookmarker"
    BIN_NAME="zb"
    SCRIPT_NAME="run.sh"
    BASHRC="$HOME/.bashrc"
fi

echo "Step 1/5: Compiling the program..."
if zig build -Doptimize=ReleaseSafe; then
    echo "✅ Successfully compiled the program"
else
    echo "❌ Failed to compile the program"
    return 1
fi

echo -e "\nStep 2/5: Setting up installation directory..."
mkdir -p "$INSTALL_DIR"
if cp zig-out/bin/"$BIN_NAME" "$INSTALL_DIR"/; then
    echo "✅ Copied executable to $INSTALL_DIR"
    
    # Windows-specific: Add to PATH
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            setx PATH "%PATH%;$INSTALL_DIR" > /dev/null 2>&1
            echo "✅ Added $INSTALL_DIR to system PATH"
        else
            echo "ℹ️  PATH already contains $INSTALL_DIR"
        fi
    fi
else
    echo "❌ Failed to copy executable"
    return 1
fi

echo -e "\nStep 3/5: Copying shell script..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows batch script
	cat << 'EOF' > "$INSTALL_DIR/zb.ps1"
	function zb {
		$result = & "$env:APPDATA\zig-bookmarker\zb.exe" @args
		if ($LASTEXITCODE -ne 0) {
			Write-Error $result
			return
		}
		
		if ($args[0] -in '-h','--help','-l','--list') {
			$result
			return
		}
		
		try {
			Set-Location $result
			"Jumped to: $result"
		} catch {
			Write-Error "Failed to cd to: $result"
		}
	}
	EOF
    echo "✅ Created Windows batch script"
else
    if cp src/"$SCRIPT_NAME" "$INSTALL_DIR"/; then
        chmod +x "$INSTALL_DIR"/"$SCRIPT_NAME"
        echo "✅ Copied and made executable: $SCRIPT_NAME"
    else
        echo "❌ Failed to copy shell script"
        return 1
    fi
fi

echo -e "\nStep 4/5: Configuring shell integration..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # PowerShell profile configuration
    mkdir -p "$(dirname "$PROFILE")"
    MARKER="# zig-bookmarker configuration"
    CONFIG="\n$MARKER\nfunction zb {\n    & $INSTALL_DIR/$SCRIPT_NAME @args\n}\n"
    
    if Select-String -Path "$PROFILE" -Pattern "$MARKER" -Quiet; then
        echo "ℹ️  Configuration already exists in PowerShell profile"
    else
        echo -e "$CONFIG" >> "$PROFILE"
        echo "✅ Added configuration to PowerShell profile"
    fi
else
    MARKER="# zig-bookmarker configuration"
    CONFIG="\n$MARKER\nzb() {\n    source $INSTALL_DIR/$SCRIPT_NAME \"\$@\"\n}\n"

    if grep -qF "$MARKER" "$BASHRC"; then
        echo "ℹ️  Configuration already exists in $BASHRC"
    else
        echo -e "$CONFIG" >> "$BASHRC"
        echo "✅ Added configuration to $BASHRC"
    fi
fi

echo -e "\nStep 5/5: Setting up completion..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # PowerShell completion
    COMPLETION="\n# zb command completion\nRegister-ArgumentCompleter -CommandName zb -ScriptBlock {\n    param(\$wordToComplete)\n    $INSTALL_DIR/$BIN_NAME -l | ForEach-Object {\n        if (\$_ -match '^(\w+):') {\n            \$matches[1]\n        }\n    } | Where-Object { \$_ -like \"\$wordToComplete*\" } | ForEach-Object {\n        [System.Management.Automation.CompletionResult]::new(\$_, \$_, 'ParameterValue', \$_)\n    }\n}"
    
    if Select-String -Path "$PROFILE" -Pattern "Register-ArgumentCompleter" -Quiet; then
        echo "ℹ️  Completion already set up in PowerShell profile"
    else
        echo -e "$COMPLETION" >> "$PROFILE"
        echo "✅ Added tab completion to PowerShell profile"
    fi
else
    COMPLETION="\n# zb command completion\n_zb_completion() {\n    local cur=\${COMP_WORDS[COMP_CWORD]}\n    if [[ \${#COMP_WORDS[@]} -eq 2 ]]; then\n        COMPREPLY=(\$(compgen -W \"-a -r -R -l -p -h\" -- \"\$cur\"))\n    else\n        local bookmarks\n        bookmarks=\$($INSTALL_DIR/$BIN_NAME -l | awk -F': ' '{print \$1}')\n        COMPREPLY=(\$(compgen -W \"\$bookmarks\" -- \"\$cur\"))\n    fi\n}\ncomplete -F _zb_completion zb"

    if grep -qF "_zb_completion" "$BASHRC"; then
        echo "ℹ️  Completion already set up in $BASHRC"
    else
        echo -e "$COMPLETION" >> "$BASHRC"
        echo "✅ Added tab completion to $BASHRC"
    fi
fi

echo -e "\n🎉 Installation complete!"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo -e "To start using zb:"
    echo -e "1. Restart your PowerShell terminal"
    echo -e "2. Test with: zb -l"
else
    echo -e "To start using zb, either:"
    echo -e "1. Restart your terminal, or"
    echo -e "2. Run: source $BASHRC"
fi

echo -e "\nUsage examples:"
echo "  zb -a work ~/projects    # Add bookmark"
echo "  zb work                   # Jump to bookmark"
echo "  zb -l                     # List bookmarks"
