---
name: airlock
description: "Run test and lint validation gate. Use after implementation to verify code quality, or invoke directly with /airlock to run project tests and linting."
---

# /airlock - Validation Gate

Run project-specific tests and linting to validate implementation quality. The Airlock is the quality gate that code must pass through before an objective is considered complete.

---

## Purpose

The Airlock validates code changes by running:
1. **Tests** - Project test suite (npm test, cargo test, pytest, etc.)
2. **Lint** - Code style and quality checks (eslint, clippy, ruff, etc.)
3. **Type checking** - Static type analysis where configured (tsc, mypy)

---

## When to Use

### For Pods (Automated Invocation)

The Pod invokes Airlock after the Worker/Inspector/Analyst cycle completes. If Airlock fails, the Pod should:
1. Parse the failure output
2. Create a blocker alert if tests/lint fail
3. Return the objective to Worker for fixes

### For Users (Direct Invocation)

Run `/airlock` directly to:
- Verify code before committing
- Check project health
- Debug CI failures locally

---

## Instructions

When `/airlock` is invoked, execute the airlock validation script.

### Step 1: Determine Project Root

Use the current working directory as the project root, or accept an optional path argument.

### Step 2: Run Validation

Execute the airlock script:

```bash
bash airlock.sh [PROJECT_ROOT] [OUTPUT_FILE]
```

The script:
1. Detects project type (Node, Rust, Python, Go, etc.)
2. Runs appropriate test command
3. Runs appropriate lint command
4. Runs type checking if configured
5. Reports PASS or FAIL

### Step 3: Interpret Results

**Exit code 0 (PASS):**
```
=== RESULT: PASS ===
```
All validations passed. Code is clear to proceed.

**Exit code 1 (FAIL):**
```
=== RESULT: FAIL ===
```
One or more validations failed. Review output for details.

---

## Supported Project Types

The Airlock automatically detects and validates these project types:

| Type | Detection | Test Command | Lint Command | Type Check |
|------|-----------|--------------|--------------|------------|
| **Node.js** | `package.json` | `npm test` | `npm run lint` / eslint / biome | `tsc --noEmit` |
| **Rust** | `Cargo.toml` | `cargo test` | `cargo clippy` | (built-in) |
| **Python** | `pyproject.toml` / `setup.py` | `pytest` / unittest | `ruff` / `flake8` | `mypy` |
| **Go** | `go.mod` | `go test ./...` | `golangci-lint` / `go vet` | (built-in) |
| **Make** | `Makefile` | `make test` | `make lint` | - |
| **Gradle** | `build.gradle` | `./gradlew test` | spotless / checkstyle | - |
| **Maven** | `pom.xml` | `mvn test` | checkstyle | - |

---

## Pod Integration

When the Pod invokes Airlock after the Worker/Inspector/Analyst cycle:

### On PASS

```
Pod: Airlock validation passed. Objective complete.
     Updating status to 'complete' in SQLite.
```

### On FAIL

```
Pod: Airlock validation FAILED.
     Creating blocker alert: ALT-XXX
     Returning objective to Worker for fixes.
```

The Pod should:
1. Parse the Airlock output to identify specific failures
2. Create a blocker-level alert (severity 1) in SQLite
3. Provide the failure details to Worker for the next iteration

---

## Direct Invocation Examples

### Run validation in current directory

```
User: /airlock
```

### Expected output

```
=== AIRLOCK VALIDATION ===
Project root: /path/to/project
Timestamp: 2026-01-16 14:30:00
Project type: node

--- Running Tests ---
  > jest
  PASS  src/auth/jwt.test.ts
  Tests: 5 passed
  [OK] Tests passed

--- Running Lint ---
  > eslint .
  [OK] Lint passed

--- Running Type Check ---
  > tsc --noEmit
  [OK] Type check passed

=== RESULT: PASS ===
```

---

## Error Handling

### Unknown project type

If the Airlock cannot detect the project type:
```
Project type: unknown
[WARN] Unknown project type - skipping tests
[SKIP] No tests configured
[SKIP] No linter configured
=== RESULT: PASS ===
```

The Airlock passes with warnings when no validation tools are configured. This allows new projects to proceed while recommending setup.

### Missing tools

If required tools (pytest, eslint, etc.) are not installed:
```
[WARN] Python test runner not found
[WARN] No Python linter found (ruff/flake8)
Suggestion: Install ruff (pip install ruff)
```

The Airlock logs warnings and suggestions but does not fail due to missing tooling.

### Test/lint failures

Failures are clearly marked with exit codes:
```
[FAIL] Tests failed (exit code: 1)
[FAIL] Lint failed (exit code: 1)
=== RESULT: FAIL ===
```

---

## Alert Severity Reference

When Airlock fails, the Pod should create alerts with these severities:

| Failure Type | Severity | Alert Example |
|--------------|----------|---------------|
| Tests fail | 1 (blocker) | `Airlock: 3 tests failed in jwt.test.ts` |
| Lint fail | 2 (warning) | `Airlock: 5 lint errors found` |
| Type check fail | 2 (warning) | `Airlock: Type error in auth/jwt.ts:42` |
| Multiple failures | 1 (blocker) | `Airlock: Tests and lint both failed` |

---

Airlock ready. All systems nominal.
