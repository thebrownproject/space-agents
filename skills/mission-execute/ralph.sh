#!/bin/bash
# ============================================================================
# Ralph - Space-Agents Execution Loop
# ============================================================================
# Named after the "Ralph Wiggum Loop" pattern: fresh agent spawned each cycle,
# state persists in SQLite. Agents are compute, not memory.
#
# Usage:
#   ./ralph.sh <mission_id> [--attended]
#
# Exit codes:
#   0 - Mission complete (all objectives done)
#   1 - Mission failed (critical alert)
#   2 - Configuration error (DB missing, mission not found, etc.)
# ============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

# Find project root (directory containing .space-agents)
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
SPACE_AGENTS_DIR="${PROJECT_ROOT}/.space-agents"
DB="${SPACE_AGENTS_DIR}/space-agents.db"
NOTIFICATIONS_FILE="${SPACE_AGENTS_DIR}/notifications"
NOTIFY_SCRIPT="${SPACE_AGENTS_DIR}/scripts/notify.sh"

# Colors for terminal output (attended mode)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ----------------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------------

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        INFO)    echo -e "${BLUE}[$timestamp]${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}[$timestamp]${NC} $message" ;;
        WARNING) echo -e "${YELLOW}[$timestamp]${NC} $message" ;;
        ERROR)   echo -e "${RED}[$timestamp]${NC} $message" ;;
        *)       echo "[$timestamp] $message" ;;
    esac
}

log_capcom() {
    local voyage_id="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local capcom_log="${SPACE_AGENTS_DIR}/missions/active/${voyage_id}/capcom.log"

    # Ensure directory exists
    mkdir -p "$(dirname "$capcom_log")"

    echo "[$timestamp] RALPH: $message" >> "$capcom_log"
}

# ----------------------------------------------------------------------------
# Safety Checks
# ----------------------------------------------------------------------------

check_prerequisites() {
    # Check .space-agents directory exists
    if [[ ! -d "$SPACE_AGENTS_DIR" ]]; then
        log ERROR "Space-Agents directory not found: $SPACE_AGENTS_DIR"
        log ERROR "Run /launch first to initialize Space-Agents"
        exit 2
    fi

    # Check database exists
    if [[ ! -f "$DB" ]]; then
        log ERROR "Database not found: $DB"
        log ERROR "Run /launch first to initialize the database"
        exit 2
    fi

    # Check sqlite3 is available
    if ! command -v sqlite3 &> /dev/null; then
        log ERROR "sqlite3 command not found. Please install SQLite."
        exit 2
    fi

    # Check claude CLI is available
    if ! command -v claude &> /dev/null; then
        log ERROR "claude CLI not found. Please install Claude Code CLI."
        exit 2
    fi
}

check_mission() {
    local mission_id="$1"

    # Check mission exists
    local mission_status
    mission_status=$(sqlite3 "$DB" "SELECT status FROM missions WHERE id = '$mission_id';")

    if [[ -z "$mission_status" ]]; then
        log ERROR "Mission not found: $mission_id"
        exit 2
    fi

    # Check mission is active
    if [[ "$mission_status" != "active" ]]; then
        log ERROR "Mission is not active (status: $mission_status)"
        log ERROR "Only active missions can be executed"
        exit 2
    fi

    log INFO "Mission validated: $mission_id (status: $mission_status)"
}

# ----------------------------------------------------------------------------
# Notification Functions
# ----------------------------------------------------------------------------

send_notification() {
    local title="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Write to notifications file (for in-session pickup via hooks)
    echo "[$timestamp] $title: $message" >> "$NOTIFICATIONS_FILE"

    # Try macOS notification if notify.sh exists
    if [[ -x "$NOTIFY_SCRIPT" ]]; then
        "$NOTIFY_SCRIPT" "$title" "$message" 2>/dev/null || true
    else
        # Fallback: direct osascript if on macOS
        if command -v osascript &> /dev/null; then
            osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
        fi
    fi
}

# ----------------------------------------------------------------------------
# SQLite Query Helpers
# ----------------------------------------------------------------------------

sql_query() {
    sqlite3 "$DB" "$1"
}

sql_query_row() {
    # Returns a single row with pipe-separated values
    sqlite3 -separator '|' "$DB" "$1"
}

# ----------------------------------------------------------------------------
# Objective Management
# ----------------------------------------------------------------------------

get_next_objective() {
    local mission_id="$1"

    # Get next pending objective, ordered by priority (DESC) then created_at (ASC)
    # Returns: id|title|description
    sql_query_row "
        SELECT id, title, description
        FROM objectives
        WHERE mission_id = '$mission_id'
          AND status = 'pending'
        ORDER BY priority DESC, created_at ASC
        LIMIT 1;
    "
}

mark_objective_in_progress() {
    local objective_id="$1"

    sql_query "
        UPDATE objectives
        SET status = 'in_progress'
        WHERE id = '$objective_id';
    "

    sql_query "
        INSERT INTO messages (agent, objective_id, type, content)
        VALUES ('Ralph', '$objective_id', 'started', 'Ralph dispatched Pod for objective');
    "
}

mark_objective_complete() {
    local objective_id="$1"

    sql_query "
        UPDATE objectives
        SET status = 'complete', completed_at = CURRENT_TIMESTAMP
        WHERE id = '$objective_id';
    "
}

mark_objective_failed() {
    local objective_id="$1"
    local reason="$2"

    sql_query "
        UPDATE objectives
        SET status = 'failed'
        WHERE id = '$objective_id';
    "

    sql_query "
        INSERT INTO messages (agent, objective_id, type, content)
        VALUES ('Ralph', '$objective_id', 'failed', '$reason');
    "
}

get_mission_info() {
    local mission_id="$1"

    # Returns: mission_title|voyage_id|voyage_title
    sql_query_row "
        SELECT m.title, v.id, v.title
        FROM missions m
        JOIN voyages v ON m.voyage_id = v.id
        WHERE m.id = '$mission_id';
    "
}

check_mission_complete() {
    local mission_id="$1"

    # Count remaining pending or in_progress objectives
    local remaining
    remaining=$(sql_query "
        SELECT COUNT(*)
        FROM objectives
        WHERE mission_id = '$mission_id'
          AND status IN ('pending', 'in_progress');
    ")

    [[ "$remaining" -eq 0 ]]
}

mark_mission_complete() {
    local mission_id="$1"

    sql_query "
        UPDATE missions
        SET status = 'complete'
        WHERE id = '$mission_id';
    "
}

check_critical_alerts() {
    local mission_id="$1"

    # Check for any active critical (severity 0) alerts for this mission's objectives
    local critical_count
    critical_count=$(sql_query "
        SELECT COUNT(*)
        FROM alerts a
        JOIN objectives o ON a.objective_id = o.id
        WHERE o.mission_id = '$mission_id'
          AND a.severity = 0
          AND a.status = 'active';
    ")

    [[ "$critical_count" -gt 0 ]]
}

# ----------------------------------------------------------------------------
# Alert Management
# ----------------------------------------------------------------------------

create_alert() {
    local severity="$1"
    local objective_id="$2"
    local source="$3"
    local description="$4"

    # Generate next alert ID
    local next_num
    next_num=$(sql_query "SELECT COALESCE(MAX(CAST(SUBSTR(id, 5) AS INTEGER)), 0) + 1 FROM alerts;")
    local alert_id
    alert_id=$(printf "ALT-%03d" "$next_num")

    # Escape single quotes in description
    local safe_description="${description//\'/\'\'}"

    sql_query "
        INSERT INTO alerts (id, severity, objective_id, source, description, status)
        VALUES ('$alert_id', $severity, '$objective_id', '$source', '$safe_description', 'active');
    "

    log WARNING "Alert created: $alert_id (severity $severity) - $description"
}

# ----------------------------------------------------------------------------
# Pod Spawning
# ----------------------------------------------------------------------------

spawn_pod() {
    local objective_id="$1"
    local objective_title="$2"
    local objective_description="$3"
    local voyage_id="$4"

    log INFO "Spawning Pod for objective: $objective_title"

    # Build the prompt for Pod
    # Pod receives objective context and orchestrates Worker/Inspector/Analyst
    local pod_prompt
    pod_prompt=$(cat <<EOF
You are a Pod - a fresh spacecraft launched to execute ONE objective.

## Objective Assignment

**Objective ID:** $objective_id
**Title:** $objective_title
**Description:**
$objective_description

## Environment

**Project Root:** $PROJECT_ROOT
**Space-Agents Root:** $SPACE_AGENTS_DIR
**Database:** $DB

## Your Mission

1. Load any additional context from mission files
2. Dispatch Worker to implement
3. Dispatch Inspector to verify requirements
4. Dispatch Analyst to review code quality
5. Run Airlock validation (if airlock.sh exists)
6. Report completion via exit code

## Exit Codes

- Exit 0: Objective complete (success)
- Exit 1: Objective failed (blocker - try next objective)
- Exit 2: Critical failure (halt Ralph loop)

## Important

You are fresh - you have no memory of previous objectives.
All state comes from SQLite and files. Query the database for context.
Stay focused on this single objective. Do not scope-creep.

Begin execution.
EOF
)

    # Spawn Pod via claude CLI
    # Using -p for print mode (non-interactive)
    # Pod agent prompt is in agents/pod.md
    local pod_agent="${PROJECT_ROOT}/agents/pod.md"
    local exit_code=0

    if [[ -f "$pod_agent" ]]; then
        # Use Pod agent system prompt
        echo "$pod_prompt" | claude -p --system-prompt "$(cat "$pod_agent")" --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Task" 2>&1 || exit_code=$?
    else
        # Fallback: run without custom system prompt
        log WARNING "Pod agent not found at $pod_agent, using default"
        echo "$pod_prompt" | claude -p --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Task" 2>&1 || exit_code=$?
    fi

    return $exit_code
}

# ----------------------------------------------------------------------------
# Main Execution Loop
# ----------------------------------------------------------------------------

main() {
    local mission_id="${1:-}"
    local attended_mode="${2:-}"

    # Validate arguments
    if [[ -z "$mission_id" ]]; then
        echo "Usage: ralph.sh <mission_id> [--attended]"
        echo ""
        echo "Options:"
        echo "  mission_id   The ID of the mission to execute"
        echo "  --attended   Run in attended mode with full output"
        exit 2
    fi

    # Run prerequisites
    check_prerequisites
    check_mission "$mission_id"

    # Get mission info for logging
    local mission_info
    mission_info=$(get_mission_info "$mission_id")
    local mission_title voyage_id voyage_title
    IFS='|' read -r mission_title voyage_id voyage_title <<< "$mission_info"

    log INFO "============================================"
    log INFO "RALPH LOOP STARTING"
    log INFO "============================================"
    log INFO "Voyage: $voyage_title ($voyage_id)"
    log INFO "Mission: $mission_title ($mission_id)"
    log INFO "============================================"

    log_capcom "$voyage_id" "Ralph loop starting for mission: $mission_id"

    local iteration=0
    local max_iterations=100  # Safety limit

    # Main execution loop
    while true; do
        iteration=$((iteration + 1))

        # Safety: prevent infinite loops
        if [[ $iteration -gt $max_iterations ]]; then
            log ERROR "Max iterations ($max_iterations) reached. Halting."
            create_alert 0 "" "Ralph" "Max iterations reached - possible infinite loop"
            send_notification "Space-Agents" "Ralph halted: max iterations reached"
            exit 1
        fi

        log INFO "--- Iteration $iteration ---"

        # Check for critical alerts before continuing
        if check_critical_alerts "$mission_id"; then
            log ERROR "Critical alert detected. Halting Ralph loop."
            log_capcom "$voyage_id" "Ralph halted: critical alert detected"
            send_notification "Space-Agents CRITICAL" "Mission halted due to critical alert"
            exit 1
        fi

        # Get next pending objective
        local objective_row
        objective_row=$(get_next_objective "$mission_id")

        # Check if queue is empty
        if [[ -z "$objective_row" ]]; then
            log INFO "No pending objectives remaining"

            # Check if mission is complete
            if check_mission_complete "$mission_id"; then
                mark_mission_complete "$mission_id"
                log SUCCESS "============================================"
                log SUCCESS "MISSION COMPLETE: $mission_title"
                log SUCCESS "============================================"
                log_capcom "$voyage_id" "Mission complete: $mission_id"
                send_notification "Space-Agents" "Mission complete: $mission_title"
                exit 0
            else
                # Some objectives may be in failed state
                log WARNING "No pending objectives, but mission not fully complete"
                log WARNING "Check failed objectives and alerts"
                log_capcom "$voyage_id" "Ralph stopped: no pending objectives, some may have failed"
                send_notification "Space-Agents" "Mission stalled: check failed objectives"
                exit 1
            fi
        fi

        # Parse objective data
        local objective_id objective_title objective_description
        IFS='|' read -r objective_id objective_title objective_description <<< "$objective_row"

        log INFO "Selected objective: $objective_title ($objective_id)"
        log_capcom "$voyage_id" "Starting objective: $objective_id - $objective_title"

        # Mark objective as in progress
        mark_objective_in_progress "$objective_id"

        # Spawn Pod for this objective
        local pod_exit_code=0
        spawn_pod "$objective_id" "$objective_title" "$objective_description" "$voyage_id" || pod_exit_code=$?

        # Handle Pod exit code
        case $pod_exit_code in
            0)
                # Success
                log SUCCESS "Pod completed objective: $objective_title"
                mark_objective_complete "$objective_id"
                log_capcom "$voyage_id" "Objective complete: $objective_id"
                ;;
            1)
                # Blocker - objective failed, but try next
                log WARNING "Pod reported blocker for: $objective_title"
                mark_objective_failed "$objective_id" "Pod reported blocker"
                create_alert 1 "$objective_id" "Pod" "Objective failed with blocker"
                log_capcom "$voyage_id" "Objective failed (blocker): $objective_id"
                log INFO "Continuing to next objective..."
                ;;
            2)
                # Critical - halt the loop
                log ERROR "Pod reported CRITICAL failure for: $objective_title"
                mark_objective_failed "$objective_id" "Pod reported critical failure"
                create_alert 0 "$objective_id" "Pod" "Critical failure - Ralph loop halted"
                log_capcom "$voyage_id" "CRITICAL: Ralph halted at objective $objective_id"
                send_notification "Space-Agents CRITICAL" "Mission halted: $objective_title"
                exit 1
                ;;
            *)
                # Unknown exit code - treat as blocker
                log WARNING "Pod exited with unexpected code: $pod_exit_code"
                mark_objective_failed "$objective_id" "Pod exited with code $pod_exit_code"
                create_alert 1 "$objective_id" "Pod" "Unexpected exit code: $pod_exit_code"
                log_capcom "$voyage_id" "Objective failed (exit $pod_exit_code): $objective_id"
                log INFO "Continuing to next objective..."
                ;;
        esac

        # Brief pause between iterations (prevents hammering)
        sleep 2
    done
}

# ----------------------------------------------------------------------------
# Entry Point
# ----------------------------------------------------------------------------

main "$@"
