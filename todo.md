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

- [x] (8cdfb49) Firmware: heap dip to 3160 B caused by auth_request stack allocation (2x 517-byte buffers per request). Root cause: rapid /s polling → stack exhaustion → heap fragmentation. Fix implemented: malloc/free buffers dynamically in main/core/httpd/auth.c. Same pass: mqtt.c buffer pool (c149322/35c3f0f, template 5dfe013), /mqttdiag malloc (39bca73), cmd.c snprintf (8dd8c61). OTA 1789024847 flashed 2026-09-10 09:22: heap_min_free 23068 B after 60 s of rapid polling (was 3160 B), heap_low_events 0, n_restarts 155. Superseded by the single-KV-mutex fix (d5df41a, OTA 1789111856): live check on 2026-09-14 shows 70.7 h uptime, heap_free 65996 B, heap_min_free 31788 B, heap_low_events 0 - 24 h verdict PASS, no further monitoring needed.

- [x] (fw cf49064, app 64a950c9) **CRITICAL, was live on the controller** Light boost turned
      into "lights off forever" after a reboot. `BOX_N_TIMER_TYPE` is `_NVS` (persisted) but the
      `BOX_N_TIMER_MANUAL_OUTPUT` added for the boost was only `_HTTP_RW` and reset to 0
      (`config_gen/config/SuperGreenOS/Controllers/timer.cue`). Reboot mid-boost (and the
      2026-09-08 power incident proves reboots happen) = restart in `TIMER_TYPE=manual` with
      output 0, schedule overridden, lights dark indefinitely. Worse, expiry was enforced only
      by the phone (`BoxOverridesHelper.checkExpired`), so a phone that is off or off-network
      meant a boost that never ends. Our own Block B defect.
      Fixed in firmware: `BOX_N_TIMER_MANUAL_OUTPUT` removed, replaced by `BOX_N_TIMER_BOOST_S`
      - a RAM-only (deliberately not `_NVS`) countdown that `timer_task` runs down against
      `esp_timer_get_time()`. The boost only overrides `TIMER_OUTPUT`; `TIMER_TYPE` is never
      touched, so there is no state to restore and no way to end up stuck, and a reboot simply
      drops the boost. Values are clamped to 0..3600 s in `on_set_box_timer_boost_s`.
      OTA 1789397410 flashed 2026-09-14 16:54 (restart #159). Live verification: 30 s boost
      counted 30 -> 0 on its own with `TIMER_TYPE` unchanged at 1; writing 0 cancels
      immediately; 5000 -> clamped to 3600; negative/overflowing values land on 0 (no boost).

- [ ] Add controller → "Already running": the SEARCH CONTROLLER button does not react to what
      you type. `existing_device_page.dart:176` gates `onPressed` on
      `_nameController.value.text != ''`, but nothing listens to that controller, so the button
      keeps whatever enabled state the last rebuild gave it - type an address and the search
      never starts. Found 2026-09-15 while testing on the emulator: had to insert the device
      row into the app db by hand to get past it. Fix: a listener on the text controller (or
      `ValueListenableBuilder`) so the button rebuilds on every keystroke.

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

- [x] Off-theme icons: the whole feed "action icon" family (feed_card/*.svg, the plant_infos
      phase icons used as icons, the small Towelie card-header icon) now renders stock Material
      `Icons.*`. FeedEntryIcons became Map<String, IconData>, and FeedCardTitle / IconCheckbox /
      the two speed dials / discussions / checklist widgets render `Icon(...)` instead of
      SvgPicture/Image.asset. The illustrated Towelie mascot artwork is untouched (brand identity,
      not an icon). Verified on the emulator in light + dark: caught two things analyze could not —
      the four hand-written speed-dial children on a light `surface` background rendered white-on-white
      (the package defaults the icon to white), and their labels were white-on-white in dark mode;
      both fixed with explicit `context.sgl.ink` / `labelBackgroundColor`.
      Still String/SVG-based, deliberately out of scope: SectionTitle, FeedFormParamLayout and
      PlantInfosWidget share a different SVG set across 27 files (settings, add_device, product forms).
      Minor: Fimming and Cloning both map to Icons.content_cut; differentiate if it ever bothers.
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
- [x] (Block C) Charts migrated from the discontinued community_charts_flutter to fl_chart:
      time_series_api.dart's Metric stayed library-independent, only its Series wrapper became
      a plain MetricSeries; box_app_bar_metrics_page.dart's TimeSeriesChart became a LineChart
      with the same tap-to-inspect/vertical-marker/metric-strip-toggle behavior; SglChartPalette
      lost its charts.Color conversion helper. Verified on the emulator (demo chart renders with
      axes, gridlines and colored series). Re-ran `flutter pub outdated` after: nothing new became
      upgradable - every other outdated dep (intl included) was never actually blocked by
      community_charts_flutter, so the old pubspec.yaml comment blaming it for the intl ^0.19 cap
      was stale.
- [x] (dec3a553) Firmware OTA from phone: uploadFirmwareAndTriggerOTA method in DeviceAPI;
      firmware upload + OTA_START trigger scaffolded.
- [x] (dec3a553) Local backup/restore DB: DbBackupManager with export/import JSON/ZIP;
      plant/diary/photo serialization scaffolded.
- [x] (dec3a553) Local checklists: removed cloud login requirement from checklist creation page.

## 4. Remote greenhouse management (code audit of firmware + app, 2026-09-14)

What already exists, so nobody re-proposes it: light schedule (onoff/season/manual),
**on-device temperature-driven blower/fan curve** (`BOX_N_BLOWER_REF_MIN/MAX`, linear
21 °C→8 % .. 30 °C→30 %, with a sensor-absent failsafe that snaps fans to 100 %),
`sensor_health` with `LAST_ALERT`, `/dash` + `/kv`, 24 h local + 72 h cloud graphs, phone
foreground alerts, light/blower boosts, OTA from the app, TIME_TZ, CSV export, DB
backup/restore, the web dashboard, PIN lock. Crucially the firmware **already has the whole
remote channel**: `BROKER_URL`/`BROKER_CLIENTID` are writable + NVS (point them at your own
broker), it subscribes to `<clientid>.cmd` and runs `seti`/`sets` on any KV key (SHA256-signed
via `SIGN_KEY`), publishes Home Assistant MQTT discovery, state every 30 s, diag every 5 min.

**Essential**

- [ ] The app speaks no MQTT, so everything depends on the mesh VPN. No MQTT package in
      `pubspec.yaml`; "mqtt" appears only as `/mqttdiag` diagnostics. VPN down, or a network
      that blocks it, means losing both reading and control. The seam already exists:
      `lib/data/api/device/device_helper.dart` already routes commands as `seti -k KEY -v N`
      over a remote transport (the SGL websocket, which needs an SGL account) - add an MQTT
      transport beside it, pointed at the home broker. App only, medium, no firmware change.
- [x] (58897467) Controller address not editable by hand. When the saved IP stopped answering
      the only recovery was mDNS (`device_daemon_bloc.dart`, `resolveLocalName`), which does
      not work through the mesh VPN. A DHCP lease change while away = unreachable until you
      get home. Done: `DeviceAPI.resolveHost` tries the ordinary resolver before mDNS (IPv4
      only in both the literal and the resolved case - the app interpolates the result into a
      URL with no bracketing), and the address is editable from `settings_device_page.dart`,
      checked against the controller's own BROKER_CLIENTID before being saved. A hand-set
      address lives in the Hive misc box, not on the Devices row: it is a local preference, so
      the sync must not carry it, and it needs no schema migration (the `ip` column is still
      capped at 15 chars, so only the resolved IPv4 is stored there). The daemon resolves that
      address instead of the mDNS name, which is what stops a hand-picked controller from
      being repointed, while still retrying what comes back so a dropped packet recovers as
      before. Verified on the emulator against the live controller.

**Useful**

- [ ] No sensor history on the device at all - no ring buffer, no flash log. `/dash` and `/kv`
      are instantaneous and `DashHistory` only records while the app/service runs, so a phone
      that is off for two days leaves a two-day hole. No code needed: the firmware already
      publishes state + diag over MQTT with HA discovery, so Home Assistant (or
      Telegraf+InfluxDB) on the broker closes this. Infrastructure, low.
- [~] Alerts too narrow and phone-bound. `LocalAlertSettings` covered only temp/humidity min/max.
      **Done: "controller rebooted" (app e3d2ad14).** Opt-in `rebootAlertEnabled`; the watcher
      also reads `/mqttdiag` each poll and fires once when `n_restarts` goes up. Edge event in
      the pure evaluator (fires on increase, no back-to-normal, seeds silently, follows a
      counter reset, survives an outage, forgets while off). Extra fetch only when enabled;
      7 new unit tests. Known limit: n_restarts is controller-wide but state per-box, so two
      boxes on one controller both watching get two notifications - no per-ip fetch cache yet.
      **Not done, and why:**
      - "Light not on when scheduled" was investigated and deliberately skipped: the precise
        "inside the on-window" check needs the controller's local time, which the phone cannot
        get cleanly (`/dash` gives UTC epoch, no TZ; TIME_TZ is empty on this controller so
        local==UTC, but that is not general). Plus `led_dim==0` is ambiguous (intentional empty
        box vs fault), and the main failure it targets (timer task stuck) is now covered by the
        light-path watchdog (fw f7d5d4a). High false-positive risk for low marginal value.
      - VPD / CO2 / weight thresholds: trivial follow-up (same `_evaluateMetric`, data already in
        `/dash`), just not requested this round. CO2/weight need the matching sensor to be useful.
      - Broker-side alerting (survives a dead phone) is the bigger, separate medium item.
- [~] (fw 44a6bea, not yet OTA'd) HA discovery was observe-only beyond sensor health.
      **Done for the light schedule:** each box's on hour and off hour are now HA `number`
      entities (0-23), settable from Home Assistant over the broker with no app/VPN. One
      file-scope table `HA_BOX_HOURS` in `mqtt.c.template` drives discovery + subscribe +
      command + state echo-back. Hours take effect only in the on/off timer type (stored but
      unused in manual/season, as from the app). Built for v2.1, bundled for the next OTA.
      **Left for later (deliberately not done):** LED brightness and blower min/max.
      - Blower `BOX_N_BLOWER_MIN/MAX` map cleanly to per-box keys - same table pattern, easy
        follow-up if wanted.
      - LED brightness has no clean per-box key: `BOX_N_LED_DIM` is NOT a dimmer, it holds the
        epoch of the last "sunglasses" (temporary dim) request (`led.c` update_led). The real
        dimmer is `LED_N_DIM`, per channel (6), so a per-box brightness in HA would need a new
        firmware concept fanning one value out to a box's channels - more than HA plumbing.
      - `BOX_N_TIMER_OUTPUT` is read-only (computed); the settable mode key is
        `BOX_N_TIMER_TYPE`, but as an HA `number` 0/1/2 it is opaque - wants a proper HA
        `select` builder, which does not exist yet.
- [x] (fw f7d5d4a, not yet OTA'd) Task watchdog missing on the light-path tasks: `blower`,
      `fan`, `motor`, `valve`, `watering` called `esp_task_wdt_add`; `timer`, `led` and `i2c`
      did not. A hang there freezes the lights with nothing to reset it, which is the case
      `CONFIG_TASK_WDT_PANIC` exists for. Added the add/reset to `timer_task`, `led_task` and
      `i2c_task` (the last in `i2c.c.template`, and feeding the wdt per sensor module because
      one pass can be ~9 s on three buses). `onoff`/`season` need nothing: they are called
      from inside `timer_task`, which now feeds the wdt. `sht21` likewise runs under the i2c
      task. Built for v2.1, not yet flashed - it is bundled for the next firmware OTA.
- [ ] HTTP has no TLS and `HTTPD_AUTH` is deliberately off, so never expose `/i`, `/s`, `/kv`
      to the internet. (Alan's call: no auth on the HTTP API/fs.)
- [x] (verified 2026-09-15, no code change) MQTT `reboot`/`ota_start`/`sensor_health_*` command
      topics are unsigned, unlike the SHA256-signed `.cmd` channel - the firmware's
      `parse_ha_command` acts on them with no `SIGN_KEY` check. **Downgraded from CRITICAL:**
      probed `sink2.supergreenlab.com:1883` as an anonymous client against the live controller.
      Anonymous CONNECT is accepted, but the broker delivers **no** messages to an anonymous
      subscriber (reading a controller is blocked) and, though it PUBACKs an anonymous publish,
      it does **not** route it to the device - a benign reversible write to
      `sensor_health_period_s` (60→120/180/240) never reached the controller. So sink2 is a
      per-device relay to the SGL backend, not an open broker; broker isolation is what
      protects live controllers, not the firmware. The firmware defect is real defense-in-depth
      (it would bite on an open broker, or if sink2's isolation weakened) but not a live
      exposure. Signing those topics would break the Home Assistant buttons (they publish plain
      `PRESS`), so left as-is by choice. See memory `sink2-broker-isolation`.

**Nice to have**

- [ ] OTA resolves no DNS - it dials `OTA_SERVER_IP` only, the hostname just fills the `Host:`
      header - and if the server publishes no `.sha256` it flashes without integrity check.
- [ ] Single Wi-Fi SSID, no backup; after 5 failures it falls back to AP mode but does retry
      STA every ~2 min, so it self-heals. NTP server hard-coded to `pool.ntp.org` (the clock is
      persisted to NVS every 5 min, so the schedule survives an outage with slight drift).
- [ ] `DeviceAPI.uploadFirmwareAndTriggerOTA` is an empty stub while the real OTA path is
      elsewhere - remove it or finish it, it is just confusing.
- [ ] The `watering` module is fully exposed in KV (`WATERING_PERIOD/DURATION/POWER/LEFT`) but
      has no UI in the app. Only worth doing if the pump is actually installed.
- [ ] Two knowingly-accepted trade-offs from the editable-address work (58897467), both from
      the code review, neither worth blocking on: (a) in the "add controller" flow in AP mode,
      where there is no reachable DNS server, the new lookup can burn the full
      `DeviceAPI.dnsLookupTimeout` (3 s) before falling back to mDNS - the user watches a
      spinner for it; a shorter timeout at that one call site would pay for itself.
      (b) clearing a hand-set address leaves `device.ip` at whatever was typed while the
      settings row already reads "found automatically" - cosmetic, until the next rediscovery
      makes it true.
- [ ] `DeviceAPI.resolveLocalNameMDNS` has no timeout on its `client.lookup` stream, so an
      mDNS query nobody answers can hang indefinitely and the guarded `_deviceWorker` flag
      then keeps that device from being polled again. Pre-existing, but `resolveHost`
      (58897467) reaches it in more situations than before.

## Done during the 2026-09-08 session (for reference)

- [x] Redesign stages 1–3, themed add-controller and plant flows, (i) explanations.
- [x] Graphs from the controller (DashHistory 24 h, CLOUD toggle) — 3b9bf6a2.
- [x] Alerts page requirements checklist — 1a88bd64.
- [x] GET /kv on the firmware + app fast path (params load < 5 s) — de4a37a / 2c307c23.
- [x] Towelie texts, panel sheets close by dragging — 8658f688.
- [x] Web dashboard reads fields from /kv — bb0f07b (firmware repo, UI not uploaded yet).
