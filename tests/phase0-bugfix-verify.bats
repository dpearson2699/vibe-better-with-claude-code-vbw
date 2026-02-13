#!/usr/bin/env bats

load test_helper

setup() {
  setup_temp_dir
}

teardown() {
  teardown_temp_dir
}

# =============================================================================
# Bug #2: No destructive git commands in session-start.sh
# =============================================================================

@test "session-start.sh contains no destructive git commands" {
  # Destructive patterns: git reset --hard, git checkout ., git restore ., git clean -f/-fd
  run grep -E 'git (reset --hard|checkout \.|restore \.|clean -f)' "$SCRIPTS_DIR/session-start.sh"
  [ "$status" -eq 1 ]  # grep returns 1 = no matches found
}

@test "session-start.sh marketplace sync uses safe merge" {
  # Must use --ff-only (safe merge) and git diff --quiet (dirty-check guard)
  grep -q '\-\-ff-only' "$SCRIPTS_DIR/session-start.sh"
  grep -q 'git diff --quiet' "$SCRIPTS_DIR/session-start.sh"
}
