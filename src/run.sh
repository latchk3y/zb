#!/bin/bash

# Get output from Zig program
if ! OUTPUT=$(~/.config/zig-bookmarker/zb "$@" 2>&1); then
    # If zb failed, print the error message
    echo "$OUTPUT" >&2
    return 1
fi

# For list/show help commands, just display output
case $1 in
    -l|-h|--help|"")
        echo "$OUTPUT"
        return
        ;;
esac

# For other commands, try to cd if we got a directory
if [ -n "$OUTPUT" ]; then
    if [ "$OUTPUT" != "." ]; then
        # Extract just the path (in case there's extra info)
        DIR=$(echo "$OUTPUT" | awk '{print $1}')
        if cd "$DIR"; then
            bls  # Your custom ls command
        else
            echo "Failed to cd to: $DIR" >&2
            return 1
        fi
    fi
fi

