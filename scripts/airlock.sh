#!/bin/bash
# ============================================================================
# Airlock - Space-Agents test/lint validation gate
# ============================================================================
#
# Called by Pod after Worker/Inspector/Analyst cycle. Runs project-specific
# tests and linting to validate the implementation.
#
# Usage: airlock.sh [PROJECT_ROOT] [OUTPUT_FILE]
#   PROJECT_ROOT - Root directory of the project (default: current directory)
#   OUTPUT_FILE  - File to write output to (default: stdout)
#
# Exit codes:
#   0 - All validations passed
#   1 - One or more validations failed
#
# ============================================================================

set -o pipefail

# Arguments
PROJECT_ROOT="${1:-.}"
OUTPUT_FILE="${2:-/dev/stdout}"

# Resolve to absolute path
PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)

# Output helper - writes to both stdout and output file if different
log() {
    if [[ "$OUTPUT_FILE" == "/dev/stdout" ]]; then
        echo "$1"
    else
        echo "$1" | tee -a "$OUTPUT_FILE"
    fi
}

# Initialize output file if specified
if [[ "$OUTPUT_FILE" != "/dev/stdout" ]]; then
    > "$OUTPUT_FILE"
fi

# Track overall result
RESULT="PASS"
TESTS_RAN=false
LINT_RAN=false

log "=== AIRLOCK VALIDATION ==="
log "Project root: $PROJECT_ROOT"
log "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
log ""

# ============================================================================
# Project Type Detection
# ============================================================================

detect_project_type() {
    local detected=""

    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        detected="node"
    elif [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        detected="rust"
    elif [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/setup.py" ]]; then
        detected="python"
    elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        detected="go"
    elif [[ -f "$PROJECT_ROOT/Makefile" ]]; then
        detected="make"
    elif [[ -f "$PROJECT_ROOT/build.gradle" ]] || [[ -f "$PROJECT_ROOT/build.gradle.kts" ]]; then
        detected="gradle"
    elif [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
        detected="maven"
    else
        detected="unknown"
    fi

    echo "$detected"
}

PROJECT_TYPE=$(detect_project_type)
log "Project type: $PROJECT_TYPE"
log ""

# ============================================================================
# Test Runner
# ============================================================================

run_tests() {
    log "--- Running Tests ---"

    local test_exit=0

    case "$PROJECT_TYPE" in
        node)
            if [[ -f "$PROJECT_ROOT/package.json" ]]; then
                # Check if test script exists
                if grep -q '"test"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
                    cd "$PROJECT_ROOT" && npm test 2>&1 | while IFS= read -r line; do log "$line"; done
                    test_exit=${PIPESTATUS[0]}
                    TESTS_RAN=true
                else
                    log "  [WARN] No test script in package.json"
                    log "  Suggestion: Add a test script (e.g., \"test\": \"jest\" or \"test\": \"vitest\")"
                fi
            fi
            ;;
        rust)
            cd "$PROJECT_ROOT" && cargo test 2>&1 | while IFS= read -r line; do log "$line"; done
            test_exit=${PIPESTATUS[0]}
            TESTS_RAN=true
            ;;
        python)
            # Try pytest first, then unittest
            if command -v pytest &>/dev/null; then
                cd "$PROJECT_ROOT" && pytest 2>&1 | while IFS= read -r line; do log "$line"; done
                test_exit=${PIPESTATUS[0]}
                TESTS_RAN=true
            elif command -v python3 &>/dev/null; then
                cd "$PROJECT_ROOT" && python3 -m pytest 2>&1 | while IFS= read -r line; do log "$line"; done
                test_exit=${PIPESTATUS[0]}
                if [[ $test_exit -ne 0 ]]; then
                    # Fallback to unittest discovery
                    cd "$PROJECT_ROOT" && python3 -m unittest discover 2>&1 | while IFS= read -r line; do log "$line"; done
                    test_exit=${PIPESTATUS[0]}
                fi
                TESTS_RAN=true
            else
                log "  [WARN] Python test runner not found"
            fi
            ;;
        go)
            cd "$PROJECT_ROOT" && go test ./... 2>&1 | while IFS= read -r line; do log "$line"; done
            test_exit=${PIPESTATUS[0]}
            TESTS_RAN=true
            ;;
        make)
            # Check if test target exists
            if grep -q "^test:" "$PROJECT_ROOT/Makefile" 2>/dev/null; then
                cd "$PROJECT_ROOT" && make test 2>&1 | while IFS= read -r line; do log "$line"; done
                test_exit=${PIPESTATUS[0]}
                TESTS_RAN=true
            else
                log "  [WARN] No 'test' target in Makefile"
            fi
            ;;
        gradle)
            cd "$PROJECT_ROOT" && ./gradlew test 2>&1 | while IFS= read -r line; do log "$line"; done
            test_exit=${PIPESTATUS[0]}
            TESTS_RAN=true
            ;;
        maven)
            cd "$PROJECT_ROOT" && mvn test 2>&1 | while IFS= read -r line; do log "$line"; done
            test_exit=${PIPESTATUS[0]}
            TESTS_RAN=true
            ;;
        *)
            log "  [WARN] Unknown project type - skipping tests"
            log "  Suggestion: Add package.json, Cargo.toml, pyproject.toml, go.mod, or Makefile"
            ;;
    esac

    if [[ "$TESTS_RAN" == "true" ]]; then
        if [[ $test_exit -eq 0 ]]; then
            log "  [OK] Tests passed"
        else
            log "  [FAIL] Tests failed (exit code: $test_exit)"
            RESULT="FAIL"
        fi
    else
        log "  [SKIP] No tests configured"
    fi

    log ""
    return $test_exit
}

# ============================================================================
# Lint Runner
# ============================================================================

run_lint() {
    log "--- Running Lint ---"

    local lint_exit=0

    case "$PROJECT_TYPE" in
        node)
            if [[ -f "$PROJECT_ROOT/package.json" ]]; then
                # Check for lint script first
                if grep -q '"lint"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
                    cd "$PROJECT_ROOT" && npm run lint 2>&1 | while IFS= read -r line; do log "$line"; done
                    lint_exit=${PIPESTATUS[0]}
                    LINT_RAN=true
                # Fallback to direct eslint
                elif [[ -f "$PROJECT_ROOT/node_modules/.bin/eslint" ]]; then
                    cd "$PROJECT_ROOT" && ./node_modules/.bin/eslint . 2>&1 | while IFS= read -r line; do log "$line"; done
                    lint_exit=${PIPESTATUS[0]}
                    LINT_RAN=true
                # Check for biome
                elif [[ -f "$PROJECT_ROOT/node_modules/.bin/biome" ]]; then
                    cd "$PROJECT_ROOT" && ./node_modules/.bin/biome check . 2>&1 | while IFS= read -r line; do log "$line"; done
                    lint_exit=${PIPESTATUS[0]}
                    LINT_RAN=true
                else
                    log "  [WARN] No lint script or eslint/biome found"
                    log "  Suggestion: Add a lint script or install eslint"
                fi
            fi
            ;;
        rust)
            cd "$PROJECT_ROOT" && cargo clippy -- -D warnings 2>&1 | while IFS= read -r line; do log "$line"; done
            lint_exit=${PIPESTATUS[0]}
            LINT_RAN=true
            ;;
        python)
            # Try ruff first (fast), then flake8
            if command -v ruff &>/dev/null; then
                cd "$PROJECT_ROOT" && ruff check . 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            elif command -v flake8 &>/dev/null; then
                cd "$PROJECT_ROOT" && flake8 . 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            elif command -v python3 &>/dev/null; then
                # Try running via python module
                cd "$PROJECT_ROOT" && python3 -m ruff check . 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                if [[ $lint_exit -ne 0 ]]; then
                    cd "$PROJECT_ROOT" && python3 -m flake8 . 2>&1 | while IFS= read -r line; do log "$line"; done
                    lint_exit=${PIPESTATUS[0]}
                fi
                LINT_RAN=true
            else
                log "  [WARN] No Python linter found (ruff/flake8)"
                log "  Suggestion: Install ruff (pip install ruff)"
            fi
            ;;
        go)
            if command -v golangci-lint &>/dev/null; then
                cd "$PROJECT_ROOT" && golangci-lint run 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            else
                # Fallback to go vet
                cd "$PROJECT_ROOT" && go vet ./... 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            fi
            ;;
        make)
            # Check if lint target exists
            if grep -q "^lint:" "$PROJECT_ROOT/Makefile" 2>/dev/null; then
                cd "$PROJECT_ROOT" && make lint 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            else
                log "  [WARN] No 'lint' target in Makefile"
            fi
            ;;
        gradle)
            # Check for spotless or checkstyle
            if grep -q "spotless" "$PROJECT_ROOT/build.gradle"* 2>/dev/null; then
                cd "$PROJECT_ROOT" && ./gradlew spotlessCheck 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            elif grep -q "checkstyle" "$PROJECT_ROOT/build.gradle"* 2>/dev/null; then
                cd "$PROJECT_ROOT" && ./gradlew checkstyleMain 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            else
                log "  [WARN] No linter configured in Gradle"
            fi
            ;;
        maven)
            # Try checkstyle if configured
            if grep -q "checkstyle" "$PROJECT_ROOT/pom.xml" 2>/dev/null; then
                cd "$PROJECT_ROOT" && mvn checkstyle:check 2>&1 | while IFS= read -r line; do log "$line"; done
                lint_exit=${PIPESTATUS[0]}
                LINT_RAN=true
            else
                log "  [WARN] No linter configured in Maven"
            fi
            ;;
        *)
            log "  [SKIP] Unknown project type - skipping lint"
            ;;
    esac

    if [[ "$LINT_RAN" == "true" ]]; then
        if [[ $lint_exit -eq 0 ]]; then
            log "  [OK] Lint passed"
        else
            log "  [FAIL] Lint failed (exit code: $lint_exit)"
            RESULT="FAIL"
        fi
    else
        log "  [SKIP] No linter configured"
    fi

    log ""
    return $lint_exit
}

# ============================================================================
# Type Checking (Optional Enhancement)
# ============================================================================

run_typecheck() {
    log "--- Running Type Check ---"

    local type_exit=0
    local typecheck_ran=false

    case "$PROJECT_TYPE" in
        node)
            # Check for TypeScript
            if [[ -f "$PROJECT_ROOT/tsconfig.json" ]]; then
                if [[ -f "$PROJECT_ROOT/node_modules/.bin/tsc" ]]; then
                    cd "$PROJECT_ROOT" && ./node_modules/.bin/tsc --noEmit 2>&1 | while IFS= read -r line; do log "$line"; done
                    type_exit=${PIPESTATUS[0]}
                    typecheck_ran=true
                elif command -v tsc &>/dev/null; then
                    cd "$PROJECT_ROOT" && tsc --noEmit 2>&1 | while IFS= read -r line; do log "$line"; done
                    type_exit=${PIPESTATUS[0]}
                    typecheck_ran=true
                fi
            fi
            ;;
        python)
            # Check for mypy config
            if [[ -f "$PROJECT_ROOT/mypy.ini" ]] || [[ -f "$PROJECT_ROOT/pyproject.toml" ]] && grep -q "mypy" "$PROJECT_ROOT/pyproject.toml" 2>/dev/null; then
                if command -v mypy &>/dev/null; then
                    cd "$PROJECT_ROOT" && mypy . 2>&1 | while IFS= read -r line; do log "$line"; done
                    type_exit=${PIPESTATUS[0]}
                    typecheck_ran=true
                fi
            fi
            ;;
    esac

    if [[ "$typecheck_ran" == "true" ]]; then
        if [[ $type_exit -eq 0 ]]; then
            log "  [OK] Type check passed"
        else
            log "  [FAIL] Type check failed (exit code: $type_exit)"
            RESULT="FAIL"
        fi
    else
        log "  [SKIP] No type checker configured"
    fi

    log ""
    return $type_exit
}

# ============================================================================
# Main Execution
# ============================================================================

# Run all validations
run_tests
run_lint
run_typecheck

# ============================================================================
# Final Result
# ============================================================================

log "=== RESULT: $RESULT ==="

if [[ "$RESULT" == "PASS" ]]; then
    exit 0
else
    exit 1
fi
