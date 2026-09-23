#!/bin/bash
input=$(cat)
MODEL=$(jq -r '.model.display_name // "?"' <<<"$input")
EFFORT=$(jq -r '.effort.level // empty' <<<"$input")
PCT=$(jq -r '.context_window.used_percentage // 0' <<<"$input" | cut -d. -f1)
SIZE=$(jq -r '.context_window.context_window_size // 0' <<<"$input")

if   [ "$PCT" -ge 80 ]; then C='\033[31m'
elif [ "$PCT" -ge 50 ]; then C='\033[33m'
else C='\033[32m'; fi

if [ "$SIZE" -ge 1000000 ] && [ $((SIZE % 1000000)) -eq 0 ]; then SIZE_STR="$((SIZE/1000000))M"
else SIZE_STR="$((SIZE/1000))k"; fi

printf '%b\n' "[$MODEL${EFFORT:+ · $EFFORT}] ${C}${PCT}%\033[0m of $SIZE_STR"
