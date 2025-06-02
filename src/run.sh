#!/bin/bash

if ! OUTPUT=$(~/.config/zig-bookmarker/zb "$@" 2>&1); then
    echo "$OUTPUT" >&2
    return 1
fi

case $1 in
    -l|-h|--help|"")
        echo "$OUTPUT"
        return
        ;;
esac

if [ -n "$OUTPUT" ]; then
    if [ "$OUTPUT" != "." ]; then
        DIR=$(echo "$OUTPUT" | awk '{print $1}')
        if cd "$DIR"; then
			clear && ls
		else
            echo "Failed to cd to: $DIR" >&2
            return 1
        fi
    fi
fi

