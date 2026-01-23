# Exploration: Gamification - Make It Addictive

**Date:** 2026-01-20
**Status:** Brainstorming

---

## Summary

Make Space-Agents feel like a video game. Terminal already feels vintage - lean into NASA mission control vibes with ranks, streaks, and cinematic mission briefings.

**Core insight:** Coding already has natural dopamine hits (tests pass, tasks complete, features ship). The game layer should **amplify** these, not replace them.

---

## Selected Features

### 1. Pilot Ranks

Progression based on lifetime voyage completions:

```
┌─────────────────────────────────────────────────────────────────┐
│  PILOT STATUS                                                   │
├─────────────────────────────────────────────────────────────────┤
│  Rank: Flight Commander ★★★☆☆                                   │
│  Next: Captain (2 voyages to go)                                │
├─────────────────────────────────────────────────────────────────┤
│  Cadet            0 voyages     ☆☆☆☆☆                           │
│  Pilot            1 voyage      ★☆☆☆☆                           │
│  Commander        3 voyages     ★★☆☆☆                           │
│  Flight Commander 5 voyages     ★★★☆☆  ← YOU ARE HERE           │
│  Captain         10 voyages     ★★★★☆                           │
│  Flight Director 25 voyages     ★★★★★                           │
└─────────────────────────────────────────────────────────────────┘
```

**Specialist titles** earned by behavior:

| Title | How to earn |
|-------|-------------|
| Bug Hunter | Clear 50 alerts |
| Architect | Plan 10 voyages |
| Night Owl | 20 objectives after midnight |
| Speed Demon | 10 missions under 1 hour |
| Clean Freak | 50 consecutive airlock passes |
| Marathoner | 100 objectives in one week |
| Perfectionist | Complete voyage with 0 alerts |

---

### 2. Daily Streaks

Complete at least 1 objective per day to maintain streak:

```
┌─────────────────────────────────────────┐
│  🔥 STREAK: 12 days                     │
│  ████████████░░░░░░░░░░░░░░░░░░         │
│  Personal best: 23 days                 │
│                                         │
│  Complete 1 objective today to          │
│  keep your streak alive!                │
└─────────────────────────────────────────┘
```

**Streak mechanics:**
- Minimum 1 objective per calendar day
- Streak counter shows on `/launch`
- Personal best tracked
- HOUSTON reacts to streak events:
  - New streak started: "Back on the horse. Let's build this streak."
  - Streak continuing: "Day 12. You're on fire."
  - Streak lost: "We lost the streak at 23 days. But we'll rebuild."
  - New record: "NEW PERSONAL BEST! 24 days and counting!"

**Streak milestones:**
| Days | Recognition |
|------|-------------|
| 7 | Week Warrior |
| 14 | Fortnight Fighter |
| 30 | Monthly Master |
| 100 | Centurion |
| 365 | Year One |

---

### 3. Mission Briefing Style

Transform `/mission-brief` into cinematic NASA-style briefings:

```
╔═══════════════════════════════════════════════════════════════════╗
║  M I S S I O N   B R I E F I N G                                  ║
╠═══════════════════════════════════════════════════════════════════╣
║  VOYAGE:      MVP                                                 ║
║  MISSION:     MSN-004 Checkout Flow                               ║
║  CLASS:       Feature Implementation                              ║
║  PRIORITY:    High                                                ║
╠═══════════════════════════════════════════════════════════════════╣
║  OBJECTIVES                                                       ║
║  ┌────┬────────────────────────────────────────┬─────────┐        ║
║  │ ID │ Description                            │ Status  │        ║
║  ├────┼────────────────────────────────────────┼─────────┤        ║
║  │ 01 │ Create checkout API endpoint           │ STAGED  │        ║
║  │ 02 │ Build checkout form component          │ STAGED  │        ║
║  │ 03 │ Integrate payment gateway              │ STAGED  │        ║
║  │ 04 │ Add order confirmation email           │ STAGED  │        ║
║  └────┴────────────────────────────────────────┴─────────┘        ║
╠═══════════════════════════════════════════════════════════════════╣
║  RISK ASSESSMENT                                                  ║
║  ⚠ Payment gateway sandbox may have rate limits                   ║
║  ⚠ Email service requires API key configuration                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  ESTIMATED COMPLEXITY: ██████░░░░ Medium                          ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  MISSION STATUS: READY FOR LAUNCH                                 ║
║                                                                   ║
║  [ GO ] [ NO-GO ] [ REQUEST CHANGES ]                             ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## Voyage Complete Screen

End-of-voyage summary with stats and achievements:

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                          🚀                                       ║
║                         /|\                                       ║
║                        / | \                                      ║
║                       /  |  \                                     ║
║                      ────┴────                                    ║
║                                                                   ║
║               V O Y A G E   C O M P L E T E                       ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  VOYAGE: MVP                                                      ║
╠═══════════════════════════════════════════════════════════════════╣
║  MISSION STATS                                                    ║
║  ─────────────────────────────────────────────────────────────    ║
║  Missions:     5/5  ████████████████████ 100%                     ║
║  Objectives:  23/23 ████████████████████ 100%                     ║
║  Duration:     4h 23m                                             ║
║                                                                   ║
║  QUALITY METRICS                                                  ║
║  ─────────────────────────────────────────────────────────────    ║
║  Alerts:       2 triggered, 2 cleared                             ║
║  Issues:       4 found, 3 resolved, 1 deferred                    ║
║  Airlock:      12 passes, 2 failures (86% pass rate)              ║
╠═══════════════════════════════════════════════════════════════════╣
║  ACHIEVEMENTS UNLOCKED                                            ║
║  ─────────────────────────────────────────────────────────────    ║
║  [★] First Voyage      Complete your first voyage                 ║
║  [★] Clean Sweep       5 objectives with no alerts                ║
║  [★] Night Owl         Complete objective after midnight          ║
╠═══════════════════════════════════════════════════════════════════╣
║  PILOT PROGRESSION                                                ║
║  ─────────────────────────────────────────────────────────────    ║
║  Rank: Pilot → Commander                                          ║
║  Voyages: 2 → 3                                                   ║
║  Streak: 🔥 15 days (personal best!)                              ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  HOUSTON: "Outstanding work, Commander. Ready for the next one?"  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## Updated /launch Screen

Incorporate pilot status and streak:

```
┌────────────────────────────────────────────────────────────────┐
│  ███████╗██████╗  █████╗  ██████╗███████╗                      │
│  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝                      │
│  ███████╗██████╔╝███████║██║     █████╗                        │
│  ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝                        │
│  ███████║██║     ██║  ██║╚██████╗███████╗                      │
│  ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝                      │
│           █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗  │
│          ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔════╝  │
│          ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ███████╗  │
│          ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║  │
│          ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████║  │
│          ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝  │
├────────────────────────────────────────────────────────────────┤
│  Pilot: Commander ★★☆☆☆                    🔥 Streak: 15 days  │
├────────────────────────────────────────────────────────────────┤
│            HOUSTON online. All systems nominal.                │
├────────────────────────────────────────────────────────────────┤
│  Project: my-awesome-app                                       │
│  Voyages: 1 active | Missions: 2/5 | Objectives: 8/23          │
│  Alerts: 0 critical | 0 blocker | 1 warning                    │
├────────────────────────────────────────────────────────────────┤
│  ...commands...                                                │
├────────────────────────────────────────────────────────────────┤
│  ACTIVE VOYAGE: MVP                                            │
│  ● MSN-001  Auth system      complete                          │
│  ● MSN-002  User profiles    complete                          │
│  ◐ MSN-003  Shopping cart    active                            │
│  ○ MSN-004  Checkout         staged                            │
│  ○ MSN-005  Payment          staged                            │
│  Progress: ████████░░░░░░░░░░░░ 40%                            │
├────────────────────────────────────────────────────────────────┤
│  BRIEFING                                                      │
│  Last session: Completed shopping cart API endpoints.          │
│  Next up: Cart UI components, then checkout flow.              │
└────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### pilot table

```sql
CREATE TABLE pilot (
    id TEXT PRIMARY KEY DEFAULT 'default',
    callsign TEXT,                          -- Optional nickname
    rank TEXT DEFAULT 'Cadet',

    -- Lifetime stats
    voyages_complete INTEGER DEFAULT 0,
    missions_complete INTEGER DEFAULT 0,
    objectives_complete INTEGER DEFAULT 0,
    alerts_cleared INTEGER DEFAULT 0,
    airlock_passes INTEGER DEFAULT 0,
    airlock_fails INTEGER DEFAULT 0,
    total_time_seconds INTEGER DEFAULT 0,

    -- Streak tracking
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_objective_date TEXT,               -- YYYY-MM-DD for streak calc

    -- Timestamps
    first_launch DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### achievements table

```sql
CREATE TABLE achievements (
    id TEXT PRIMARY KEY,
    pilot_id TEXT DEFAULT 'default',
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,                          -- 'rank', 'streak', 'specialist', 'secret'
    unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pilot_id) REFERENCES pilot(id)
);
```

### Rank calculation

```sql
SELECT
    CASE
        WHEN voyages_complete >= 25 THEN 'Flight Director'
        WHEN voyages_complete >= 10 THEN 'Captain'
        WHEN voyages_complete >= 5 THEN 'Flight Commander'
        WHEN voyages_complete >= 3 THEN 'Commander'
        WHEN voyages_complete >= 1 THEN 'Pilot'
        ELSE 'Cadet'
    END as rank,
    CASE
        WHEN voyages_complete >= 25 THEN 5
        WHEN voyages_complete >= 10 THEN 4
        WHEN voyages_complete >= 5 THEN 3
        WHEN voyages_complete >= 3 THEN 2
        WHEN voyages_complete >= 1 THEN 1
        ELSE 0
    END as stars
FROM pilot WHERE id = 'default';
```

### Streak update logic

```sql
-- On objective complete, check and update streak
UPDATE pilot SET
    current_streak = CASE
        WHEN last_objective_date = date('now', '-1 day') THEN current_streak + 1
        WHEN last_objective_date = date('now') THEN current_streak
        ELSE 1
    END,
    longest_streak = MAX(longest_streak,
        CASE
            WHEN last_objective_date = date('now', '-1 day') THEN current_streak + 1
            WHEN last_objective_date = date('now') THEN current_streak
            ELSE 1
        END
    ),
    last_objective_date = date('now')
WHERE id = 'default';
```

---

## Achievement Definitions

### Rank Achievements
| ID | Title | Description | Trigger |
|----|-------|-------------|---------|
| rank_pilot | Pilot | Earn your wings | Complete 1 voyage |
| rank_commander | Commander | Taking command | Complete 3 voyages |
| rank_flight_commander | Flight Commander | Seasoned veteran | Complete 5 voyages |
| rank_captain | Captain | Master of the mission | Complete 10 voyages |
| rank_flight_director | Flight Director | Legend status | Complete 25 voyages |

### Streak Achievements
| ID | Title | Description | Trigger |
|----|-------|-------------|---------|
| streak_week | Week Warrior | 7 day streak | 7 consecutive days |
| streak_fortnight | Fortnight Fighter | 14 day streak | 14 consecutive days |
| streak_month | Monthly Master | 30 day streak | 30 consecutive days |
| streak_100 | Centurion | 100 day streak | 100 consecutive days |

### Specialist Achievements
| ID | Title | Description | Trigger |
|----|-------|-------------|---------|
| bug_hunter | Bug Hunter | Squash 'em all | Clear 50 alerts |
| architect | Architect | Master planner | Plan 10 voyages |
| night_owl | Night Owl | Burning midnight oil | 20 objectives after midnight |
| speed_demon | Speed Demon | Fast and flawless | 10 missions under 1 hour |
| clean_freak | Clean Freak | Pristine code | 50 consecutive airlock passes |
| perfectionist | Perfectionist | Zero defects | Complete voyage with 0 alerts |

### Secret Achievements
| ID | Title | Description | Trigger |
|----|-------|-------------|---------|
| first_blood | First Blood | It begins | Complete first objective |
| apollo_13 | Houston, We Have a Problem | Name a voyage 'Apollo 13' | Easter egg |
| night_launch | Night Launch | Launch after midnight | First objective after midnight |

---

## HOUSTON Personality Lines

### Streak Events
```
# Streak started
"Back in the saddle. Let's build this streak."

# Streak continuing
"Day {n}. Consistent effort wins the race."
"Day {n}. You're locked in."

# Streak milestone
"Week one complete. You're building something here."
"Two weeks strong. This is how legends are made."

# Streak lost
"The streak ends at {n} days. But every legend has a comeback story."

# New personal best
"NEW RECORD: {n} days! You've outdone yourself."
```

### Rank Promotions
```
# Pilot
"Congratulations, Pilot. You've earned your wings."

# Commander
"Commander status achieved. Your leadership is noted."

# Flight Commander
"Flight Commander. You're becoming a force to reckon with."

# Captain
"Captain on deck. The missions bow to your expertise."

# Flight Director
"Flight Director. You've reached the pinnacle. Legendary status."
```

### Mission Events
```
# Mission complete
"Mission complete. Excellent work out there."
"That's how it's done. Mission success."

# Voyage complete
"Voyage complete. Outstanding performance from start to finish."

# Alert cleared
"Alert cleared. Crisis averted."

# Airlock pass
"Airlock nominal. Clean code confirmed."

# Airlock fail
"Airlock breach. We'll need to address this before proceeding."
```

---

## Implementation Priority

### Phase 1: Foundation
1. Add `pilot` and `achievements` tables to schema
2. Update `/launch` to show rank and streak
3. Implement streak tracking on objective complete

### Phase 2: Visual Polish
1. Update `/mission-brief` with cinematic format
2. Create voyage complete screen
3. Add HOUSTON personality lines

### Phase 3: Achievements
1. Implement achievement unlock logic
2. Add achievement notifications
3. Create `/achievements` command to view all

---

## Future Ideas (Parked)

- **Sound effects** - Terminal beeps on events
- **Themes** - Unlock color schemes (green phosphor, amber, etc.)
- **Leaderboards** - Compare across projects/machines
- **Seasonal events** - Limited time achievements
- **ASCII art unlocks** - Earn art for milestones

---

## Open Questions

1. **Callsign** - Should `/install` ask for a pilot callsign?
2. **Cross-project stats** - Share pilot table across projects or per-project?
3. **Achievement notifications** - Inline or separate banner?

---

HOUSTON: "This is going to be fun."
