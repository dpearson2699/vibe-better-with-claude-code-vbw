#!/usr/bin/env bats

load test_helper

setup() {
  setup_temp_dir
  create_test_config
}

teardown() {
  teardown_temp_dir
}

@test "research-persistence: validates Phase 1 RESEARCH.md sections" {
  RESEARCH_FILE="$PROJECT_ROOT/.vbw-planning/phases/01-config-migration/01-RESEARCH.md"

  # Verify file exists
  [ -f "$RESEARCH_FILE" ]

  # Count the 4 required section headers
  FINDINGS_COUNT=$(grep -c "^## Findings$" "$RESEARCH_FILE" || echo 0)
  PATTERNS_COUNT=$(grep -c "^## Relevant Patterns$" "$RESEARCH_FILE" || echo 0)
  RISKS_COUNT=$(grep -c "^## Risks$" "$RESEARCH_FILE" || echo 0)
  RECOMMENDATIONS_COUNT=$(grep -c "^## Recommendations$" "$RESEARCH_FILE" || echo 0)

  # All 4 sections must be present exactly once
  [ "$FINDINGS_COUNT" -eq 1 ]
  [ "$PATTERNS_COUNT" -eq 1 ]
  [ "$RISKS_COUNT" -eq 1 ]
  [ "$RECOMMENDATIONS_COUNT" -eq 1 ]
}

@test "research-warn: JSON schema validation - flag disabled" {
  cd "$TEST_TEMP_DIR"
  run bash "$SCRIPTS_DIR/research-warn.sh" "$TEST_TEMP_DIR/.vbw-planning"
  [ "$status" -eq 0 ]

  # Validate JSON schema: must have check, result, reason keys
  echo "$output" | jq -e 'has("check")'
  echo "$output" | jq -e 'has("result")'
  echo "$output" | jq -e 'has("reason")'
}

@test "research-warn: JSON schema validation - turbo effort" {
  cd "$TEST_TEMP_DIR"
  jq '.v3_plan_research_persist = true | .effort = "turbo"' .vbw-planning/config.json > .vbw-planning/config.json.tmp \
    && mv .vbw-planning/config.json.tmp .vbw-planning/config.json
  run bash "$SCRIPTS_DIR/research-warn.sh" "$TEST_TEMP_DIR/.vbw-planning"
  [ "$status" -eq 0 ]

  # Validate JSON schema
  echo "$output" | jq -e 'has("check")'
  echo "$output" | jq -e 'has("result")'
  echo "$output" | jq -e 'has("reason")'
}

@test "research-warn: JSON schema validation - missing RESEARCH.md" {
  cd "$TEST_TEMP_DIR"
  jq '.v3_plan_research_persist = true | .effort = "balanced"' .vbw-planning/config.json > .vbw-planning/config.json.tmp \
    && mv .vbw-planning/config.json.tmp .vbw-planning/config.json
  mkdir -p "$TEST_TEMP_DIR/phase-dir"
  run bash "$SCRIPTS_DIR/research-warn.sh" "$TEST_TEMP_DIR/phase-dir"
  [ "$status" -eq 0 ]

  # Extract first line (JSON) — stderr warning also captured by run
  JSON_LINE=$(echo "$output" | head -1)
  echo "$JSON_LINE" | jq -e 'has("check")'
  echo "$JSON_LINE" | jq -e 'has("result")'
  echo "$JSON_LINE" | jq -e 'has("reason")'
}

@test "research-warn: JSON schema validation - RESEARCH.md exists" {
  cd "$TEST_TEMP_DIR"
  jq '.v3_plan_research_persist = true | .effort = "thorough"' .vbw-planning/config.json > .vbw-planning/config.json.tmp \
    && mv .vbw-planning/config.json.tmp .vbw-planning/config.json
  mkdir -p "$TEST_TEMP_DIR/phase-dir"
  echo "# Research" > "$TEST_TEMP_DIR/phase-dir/02-01-RESEARCH.md"
  run bash "$SCRIPTS_DIR/research-warn.sh" "$TEST_TEMP_DIR/phase-dir"
  [ "$status" -eq 0 ]

  # Validate JSON schema
  echo "$output" | jq -e 'has("check")'
  echo "$output" | jq -e 'has("result")'
  echo "$output" | jq -e 'has("reason")'
}
