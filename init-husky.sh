#!/usr/bin/env bash

set -e

. "$(dirname "$0")/lib/stack-paths.sh"

GIT_HOOKS_DIR="$STACK_DIR/git-hooks"
HUSKY_DIR="$TARGET_ROOT/.husky"

echo "================================"
echo " Initialize Husky git hooks"
echo "================================"

if [ ! -d "$GIT_HOOKS_DIR" ]; then
    echo "No git-hooks directory found."
    exit 0
fi

if [ ! -d "$HUSKY_DIR" ]; then
    echo "Husky directory not found: $HUSKY_DIR"
    exit 1
fi

for hook in "$GIT_HOOKS_DIR"/*; do
    [ -f "$hook" ] || continue

    hook_name="$(basename "$hook")"
    husky_hook="$HUSKY_DIR/$hook_name"
    marker="# docker-stack-process: $hook_name"

    if [ ! -f "$husky_hook" ]; then
        {
            printf '%s\n' '#!/usr/bin/env sh' '' "$marker"
            stack_hook_body "$hook_name"
        } > "$husky_hook"
        chmod +x "$husky_hook"

        echo "Created: $hook_name"
        continue
    fi

    if grep -Fqx "$marker" "$husky_hook"; then
        echo "Already registered: $hook_name"
        continue
    fi

    {
        printf '\n%s\n' "$marker"
        stack_hook_body "$hook_name"
    } >> "$husky_hook"

    echo "Registered: $hook_name"
done

echo "================================"
echo " Husky hooks initialized"
echo "================================"

stack_env_hint
