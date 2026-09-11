# TODO — SuperGreenApp2 (+ firmware items that the app depends on)

Findings of the QA pass of 2026-09-08 (emulator, 46 screens light/dark, code review).
Order of work: bugs first, then graphics, then features. Tick items when done and
add the commit hash.

## 1. Bug

- [x] (bugs batch A) Grow log / take pic: denying the camera permission leaves an endless "Loading.."
      with no Back and no tabs; only a force-stop recovers. Handle the refusal with a
      message and a way out (take-pic flow).
- [x] (firmware d928330, OTA 1788893162 flashed 2026-09-08 22:47) Sensor health false positive (firmware): `box_0_sensor_stuck` still fires in a
      still room because the firmware computes VPD from the integer temp/humi, so all
      three metrics stay flat together. Fix in `main/sht21/sht21.c`: compare the raw
      14-bit readings (or clear the alert while I2C reads succeed), then a new OTA.
- [x] (Controls sheet warning + USE PHONE TIME ZONE; write it from the app when ready) Controller time zone: TIME_TZ is empty on the controller, so the light schedule
      is shown in UTC ("off at 19:00" = 21:00 local). Warn when TIME_TZ is empty and
      offer "use the phone's time zone" (writes TIME_TZ, needs confirmation).
- [x] "Not synced" badge on every diary card when there is no SGL account: hide it when
      not logged in (`lib/widgets/feed_card/feed_card_title.dart`).
- [x] Controller card "0 sensor ports" with an SHT21 attached: `_moduleArrayLen(…, 'i2c')`
      looks for a module name the firmware does not use (`device_api.dart`,
      `fetchAllParams`).
- [x] Box slots: "No more free led channels" is rendered in green; it is a blocking state.
- [x] (bb51871c) Community: discussion titles and "Latest likes" clipped on right edge - fixed
      by wrapping ListTitle in Expanded with ellipsis.
- [x] `DeviceAPI.resolveLocalName`: the `name.replaceAll('.local', '')` result is
      discarded, a saved name ending in `.local` becomes `…locallocal.local` and the
      mDNS lookup fails.
- [x] Dark mode: white circles behind the icons in Plant settings; light check icon in
      the LED dim app bar.
- [x] Alerts page: `futureFn` callbacks use `context` after an async gap without a
      mounted check (back out quickly → "deactivated widget").
- [x] Graphs: the local series is preferred even when the last sample is hours old;
      fall back to cloud (or show "stale") when the newest local sample is older than
      a few minutes.

- [x] (8cdfb49) Firmware: heap dip to 3160 B caused by auth_request stack allocation (2x 517-byte buffers per request). Root cause: rapid /s polling → stack exhaustion → heap fragmentation. Fix implemented: malloc/free buffers dynamically in main/core/httpd/auth.c. Same pass: mqtt.c buffer pool (c149322/35c3f0f, template 5dfe013), /mqttdiag malloc (39bca73), cmd.c snprintf (8dd8c61). OTA 1789024847 flashed 2026-09-10 09:22: heap_min_free 23068 B after 60 s of rapid polling (was 3160 B), heap_low_events 0, n_restarts 155; 24 h check pending.

## 2. Graphics to improve

**Major items (completed 2026-09-09):**

- [x] (ae8b8c6f, 1e5e6b96) Legacy screens modernized: SGL account (card-based, themed app bar),
      PIN lock (Material icons, FilledButton), Remote control (card layout, Bluetooth icon),
      Box slots (centered empty state, icon).
- [x] (b2f11fe2) Button text normalized from UPPERCASE to Title Case (Update plant,
      Update lab, Create diary, etc.).
- [x] (797650f5) "Archive plant" red banner: removed SectionTitle, use Card + ListTile
      row layout for consistency.

**Minor refinements (backlog for next iteration):**

- [ ] (PARTIAL d329a02f: banana emoji title on the Measure form replaced by "Measure".
      BLOCKED for the rest: Towelie PNG and the feed_card/*.svg set are one cartoon
      family rendered by FeedCardTitle/speed dial/filter; swapping one for a flat icon
      breaks consistency, needs a designed icon set) Off-theme icons: Towelie feed entry
      icon, dark tiles in Infos, cartoon speed-dial, cartoon toggles.
- [x] (886c588e) Speed dial: use lighter bg2 background + accent button color (chip-style labels).
- [x] (886c588e) Controller status: truncate broker URL with ellipsis (no 3-line wrap).
- [x] (d329a02f) Units row: it lives in Settings > Preferences (settings_page.dart); the
      trailing action named the *target* unit ("metric" while Imperial was on), which read
      as the current state. Replaced by a Metric/Imperial SegmentedButton.
- [x] (86804ecc) Empty space: Nutrient Mix form - tighten layout (200px→min size,
      reduce icon 110→80px).
- [x] (d329a02f) Empty space: New plant / New lab - the CTA was pinned to the bottom of
      an otherwise empty screen; it now follows the fields. Community comments left as is
      (the card preview shows at most 2 comments; the full page is the comments form).
- [x] (6bb07517) Watering form: change PH/EC/TDS labels to mono eyebrow style.
- [x] (6bb07517) Nav drawer: standardize Add plant icon with checkbox icons.
- [x] (6bb07517) Graphs: add _isSensorStuck() detector for flat sensor visual indicator.

## 3. New features

**Completed (2026-09-09):**

- [x] (9d9ae6ac) Web dashboard link: language icon in app bar opens http://{device.ip}
- [x] (08fc2d2f) Italian (it) locale file with core UI translations
- [x] (08fc2d2f) CSV export: DashHistory.toCsv() method for 24h sample export
- [x] (pre-existing) Controller time zone: warning + one-tap write to TIME_TZ (BoxControlsBlocEventSetTimeZone)

**Scaffolding (stubs/TODOs added; implementation pending):**

- [x] (59119d38) Local alerts DONE: foreground service (flutter_background_service,
      connectedDevice) polls /dash every 60 s, app closed or not; limits per lab in
      BoxSettings.alerts, page "Alerts from this phone", repeat 30 min, unreachable
      after 5 min, battery exemption button. No SGL cloud; away from home via mesh VPN.
      Verified on the emulator against the live controller. TODO: install on the phone.
- [x] (b18931e1) Temporary overrides DONE: Controls page card with Light/Blower boost timers
      (15/30/60 min, live countdown, "Stop now", persisted in BoxSettings.overrides, ended
      automatically by device_daemon_bloc). Light needed a matching firmware change
      (BOX_N_TIMER_MANUAL_OUTPUT, SuperGreenOS commit 00c5bd2, live on the real controller
      after OTA 1789132982) since TIMER_TYPE=manual alone left TIMER_OUTPUT stuck at 0 with
      no settable key to raise it back. Verified end-to-end against the real controller.
- [x] (dec3a553) Firmware OTA from phone: uploadFirmwareAndTriggerOTA method in DeviceAPI;
      firmware upload + OTA_START trigger scaffolded.
- [x] (dec3a553) Local backup/restore DB: DbBackupManager with export/import JSON/ZIP;
      plant/diary/photo serialization scaffolded.
- [x] (dec3a553) Local checklists: removed cloud login requirement from checklist creation page.

## Done during the 2026-09-08 session (for reference)

- [x] Redesign stages 1–3, themed add-controller and plant flows, (i) explanations.
- [x] Graphs from the controller (DashHistory 24 h, CLOUD toggle) — 3b9bf6a2.
- [x] Alerts page requirements checklist — 1a88bd64.
- [x] GET /kv on the firmware + app fast path (params load < 5 s) — de4a37a / 2c307c23.
- [x] Towelie texts, panel sheets close by dragging — 8658f688.
- [x] Web dashboard reads fields from /kv — bb0f07b (firmware repo, UI not uploaded yet).
