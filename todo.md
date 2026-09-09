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
- [ ] (re-check: the widgets already ellipsise; may be the ellipsis itself) Community: discussion titles and "Latest likes" still clipped on the right edge of
      some cards.
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

- [ ] (investigated 2026-09-08 23:40: dip shorter than the 5 s sampling, normal traffic keeps heap at 38-40 KB; firmware 9b10fac adds heap_min_ctx + counts sub-period dips, OTA 1788903414 flashed 2026-09-09 08:23; old firmware showed another dip to 1908 B at ~00:21 overnight, so it recurs; culprit still unknown, read heap_min_ctx at the next dip) Firmware: before the 22:47 reboot /mqttdiag showed heap_min_free 2320 B at uptime
      24205 s (about 22:20) while heap_low_events stayed 0 (the counter should trip
      under 8 KB). Find what ate the heap at that moment and why the counter missed it.

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

- [ ] Off-theme icons: Towelie cartoon mascot, banana emoji on the Measure page, dark
      colour tiles in Infos (strain, medium, phase), cartoon speed-dial icons, cartoon
      toggles in the Watering form.
- [ ] Speed dial: black rectangular labels cover the diary text; darker scrim or chip
      labels.
- [ ] Controller status: only page without cards; broker URL wraps over three lines.
- [ ] Units row: subtitle "Imperial · °F, in" with action "metric" reads as a
      contradiction; make it an explicit toggle.
- [ ] Empty space: New plant, New lab, Nutrient mix, Community comments leave 70–90 %
      of the screen empty; add empty states / tighter layout.
- [ ] Watering form: PH / EC / TDS labels are bold green centered, unlike the mono
      eyebrows used elsewhere.
- [ ] Nav drawer: the two plant rows use different icon/checkbox styles.
- [ ] Graphs: mark a stuck/flat sensor visually (dashed line or banner) instead of a
      perfectly flat line.

## 3. New features

**Completed (2026-09-09):**

- [x] (9d9ae6ac) Web dashboard link: language icon in app bar opens http://{device.ip}
- [x] (08fc2d2f) Italian (it) locale file with core UI translations
- [x] (08fc2d2f) CSV export: DashHistory.toCsv() method for 24h sample export
- [x] (pre-existing) Controller time zone: warning + one-tap write to TIME_TZ (BoxControlsBlocEventSetTimeZone)

**Scaffolding (stubs/TODOs added; implementation pending):**

- [ ] (a2ff9a65) Local alerts: polling hook added to DeviceDaemonBloc._checkLocalAlerts;
      needs threshold preferences UI + notification triggering.
- [ ] (TODO) Temporary overrides: add UI in Controls sheet for lights/blower boost timers.
- [ ] (TODO) Firmware OTA from phone: add OTA file serving + trigger in device API.
- [ ] (TODO) Local backup/restore DB: add export/import to AppDB for plants/diary/photos.
- [ ] (TODO) Local checklists: enable checklist creation without cloud login.

## Done during the 2026-09-08 session (for reference)

- [x] Redesign stages 1–3, themed add-controller and plant flows, (i) explanations.
- [x] Graphs from the controller (DashHistory 24 h, CLOUD toggle) — 3b9bf6a2.
- [x] Alerts page requirements checklist — 1a88bd64.
- [x] GET /kv on the firmware + app fast path (params load < 5 s) — de4a37a / 2c307c23.
- [x] Towelie texts, panel sheets close by dragging — 8658f688.
- [x] Web dashboard reads fields from /kv — bb0f07b (firmware repo, UI not uploaded yet).
