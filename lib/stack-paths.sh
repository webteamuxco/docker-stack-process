# Shared by install-hooks.sh and init-husky.sh. Sourced, not executed.
#
# Sets:
#   STACK_DIR    absolute path of the stack
#   TARGET_ROOT  absolute path of the repository that receives the hooks:
#                the superproject when the stack is a submodule,
#                otherwise the repository containing the stack
#   STACK_PATH   stack path relative to TARGET_ROOT ("." when the stack is the root)

STACK_DIR="$(cd "$(dirname "$0")" && pwd -P)"

TARGET_ROOT="$(git -C "$STACK_DIR" rev-parse --show-superproject-working-tree)"
if [ -z "$TARGET_ROOT" ]; then
    TARGET_ROOT="$(git -C "$STACK_DIR" rev-parse --show-toplevel)"
fi
TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd -P)"

case "$STACK_DIR" in
    "$TARGET_ROOT")
        STACK_PATH="."
        ;;
    "$TARGET_ROOT"/*)
        STACK_PATH="${STACK_DIR#"$TARGET_ROOT"/}"
        ;;
    *)
        echo "Error: $STACK_DIR is not inside $TARGET_ROOT." >&2
        exit 1
        ;;
esac

# Prints the hook body that runs git-hooks/<name> from the target repository.
# The hook is skipped (not failed) when the stack is missing, e.g. submodule not initialized.
stack_hook_body() {
    printf '%s\n' \
        "stack_hook=\"\$(git rev-parse --show-toplevel)/$STACK_PATH/git-hooks/$1\"" \
        "if [ -f \"\$stack_hook\" ]; then" \
        "    sh \"\$stack_hook\" \"\$@\"" \
        "else" \
        "    echo \"docker-stack-process: \$stack_hook not found, hook skipped (run: git submodule update --init).\" >&2" \
        "fi"
}

# Prints the STACK_PROJECT_ROOT value to set in the target repository .env,
# so that manual "docker compose" runs analyze the target repository.
# Compose resolves it relative to docker/<tool>/ inside the stack.
stack_env_hint() {
    [ "$STACK_PATH" = "." ] && return 0

    rel="../.."
    old_ifs="$IFS"
    IFS=/
    for _ in $STACK_PATH; do
        rel="$rel/.."
    done
    IFS="$old_ifs"

    echo ""
    echo "The stack is installed in '$STACK_PATH'."
    echo "For manual 'docker compose' runs, add this line to $TARGET_ROOT/.env:"
    echo ""
    echo "    STACK_PROJECT_ROOT=$rel"
}
