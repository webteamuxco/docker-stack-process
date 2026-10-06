#!/bin/sh

set -e

. "$(dirname "$0")/lib/stack-paths.sh"

HOOKS_SOURCE="$STACK_DIR/git-hooks"
HOOKS_TARGET="$(git -C "$TARGET_ROOT" rev-parse --path-format=absolute --git-common-dir)/hooks"

echo "Installing Git hooks into $TARGET_ROOT..."

HOOKS_PATH="$(git -C "$TARGET_ROOT" config --get core.hooksPath || true)"
if [ -n "$HOOKS_PATH" ]; then
    echo "Warning: core.hooksPath is set to '$HOOKS_PATH'."
    echo "Git will not run hooks from $HOOKS_TARGET."
    echo "Use ./init-husky.sh if Husky is used, or run: git config --unset core.hooksPath"
fi

mkdir -p "$HOOKS_TARGET"

for hook in "$HOOKS_SOURCE"/*; do
    [ -f "$hook" ] || continue

    hook_name="$(basename "$hook")"

    {
        printf '%s\n' '#!/bin/sh' '' '# Installed by docker-stack-process (install-hooks.sh)' ''
        stack_hook_body "$hook_name"
    } > "$HOOKS_TARGET/$hook_name"
    chmod +x "$HOOKS_TARGET/$hook_name"

    echo "Installed: $hook_name"
done

echo "Git hooks installed successfully."

stack_env_hint
