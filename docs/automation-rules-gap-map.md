# Automation And Rules: As-Is vs To-Be

## Scope
This document maps what already exists in SuperGreenApp2 for automation/remote control, and what is still missing to support a generic "if-this-then-that" greenhouse automation engine.

## What Already Exists

1. Remote command path for devices:
- `DeviceHelper.updateIntParam` / `updateStringParam` send commands either:
  - locally via HTTP to device, or
  - remotely via websocket signed commands.
- Source: `lib/data/api/device/device_helper.dart`
- Remote transport: `lib/data/api/backend/devices/websocket.dart`

2. Box schedule automation (preset-based):
- VEG/BLOOM/AUTO presets with on/off hour-minute are persisted in `BoxSettings`.
- Applying schedule writes device timer params and stores feed entry metadata.
- Sources:
  - `lib/pages/feeds/home/common/settings/box_settings.dart`
  - `lib/pages/feed_entries/feed_schedule/form/feed_schedule_form_bloc.dart`

3. Ventilation control logic:
- Ventilation params support references to temp/timer/humidity and writes device params.
- Source: `lib/pages/feed_entries/feed_ventilation/form/feed_ventilation_form_bloc.dart`

4. Light control:
- Per-light dimming writes live params and can save/cancel changes.
- Source: `lib/pages/feed_entries/feed_light/form/feed_light_form_bloc.dart`

5. Checklist rule-like conditions:
- Condition types exist: metric, timer, after_card, after_phase.
- Source: `lib/data/rel/checklist/conditions.dart`

6. Checklist action system:
- Action types exist: webpage, card, buy_product, message.
- Source: `lib/data/rel/checklist/actions.dart`

## Key Gap (Important)

There is no generic automation action that directly controls actuators from checklist rules.

Current checklist actions are guidance/user-workflow actions, not actuator commands. In `ChecklistAction`, no action type maps to device parameter writes.

Practical result:
- You have automation in specific verticals (schedule, ventilation, light flows).
- You have condition-based reminders/checklist tasks.
- You do not yet have one unified rule engine where any condition can trigger any device command with policy controls.

## Additional Gaps To Address

1. No unified rule entity:
- No dedicated table/model for generic automation rules (trigger + action + guard rails + priority + cooldown + scope).

2. No conflict resolution layer:
- If multiple automations target same param, there is no shared priority/override policy.

3. No deterministic safety guard rails:
- Missing global constraints (min/max hard limits, deadbands/hysteresis, anti-thrashing cooldowns) at one central layer.

4. No end-to-end automation audit:
- Manual actions are logged in feed/checklists, but automatic actuator decisions are not centralized as a single execution log.

## Recommended Architecture (Incremental)

1. Keep existing features:
- Keep schedule/ventilation/light flows and checklist UX.
- Reuse existing `DeviceHelper` command path.

2. Add an automation core (new module):
- `AutomationRule` model (scope, enabled, trigger JSON, action JSON, priority, cooldown, hysteresis, safety profile).
- `AutomationExecution` log (rule id, evaluated at, matched, action sent, result/error, source metric snapshot).

3. Add first actuator action types:
- `set_int_param`
- `set_string_param`
- `set_hour_min_params`
- optional `set_mode` wrappers for common device patterns.

4. Add trigger primitives:
- threshold in/out range with duration
- cron/time window
- metric delta/rate
- boolean composition (AND/OR) for two conditions in v1.1

5. Add conflict policy:
- Priority + lock window + "last writer wins" fallback with explicit warning.

## Suggested Rollout

### Milestone 1 (Low risk)
- Introduce DB schema for automation rules/executions.
- Add evaluator service (read-only dry-run mode) with logs only.
- No actuator writes yet.

### Milestone 2 (Controlled writes)
- Enable actuator actions for one domain first (example: ventilation target param).
- Add cooldown and hard limits.
- Add execution log view in app.

### Milestone 3 (Generalization)
- Expand to light and timer actions.
- Add import path from existing schedule presets to generated rules.
- Add optional backend sync for rules.

## Why This Is The Safest Direction

It avoids rewriting existing stable flows and builds a composable layer on top of known command paths (`DeviceHelper` + websocket/local fallback). This gives immediate value while keeping rollout and rollback controlled.
