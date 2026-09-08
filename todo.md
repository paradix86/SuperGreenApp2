# TODO — SuperGreenApp2 (+ firmware items that the app depends on)

Findings of the QA pass of 2026-09-08 (emulator, 46 screens light/dark, code review).
Order of work: bugs first, then graphics, then features. Tick items when done and
add the commit hash.

## 1. Bug

- [ ] Grow log / take pic: denying the camera permission leaves an endless "Loading.."
      with no Back and no tabs; only a force-stop recovers. Handle the refusal with a
      message and a way out (take-pic flow).
- [ ] Sensor health false positive (firmware): `box_0_sensor_stuck` still fires in a
      still room because the firmware computes VPD from the integer temp/humi, so all
      three metrics stay flat together. Fix in `main/sht21/sht21.c`: compare the raw
      14-bit readings (or clear the alert while I2C reads succeed), then a new OTA.
- [ ] Controller time zone: TIME_TZ is empty on the controller, so the light schedule
      is shown in UTC ("off at 19:00" = 21:00 local). Warn when TIME_TZ is empty and
      offer "use the phone's time zone" (writes TIME_TZ, needs confirmation).
- [ ] "Not synced" badge on every diary card when there is no SGL account: hide it when
      not logged in (`lib/widgets/feed_card/feed_card_title.dart`).
- [ ] Controller card "0 sensor ports" with an SHT21 attached: `_moduleArrayLen(…, 'i2c')`
      looks for a module name the firmware does not use (`device_api.dart`,
      `fetchAllParams`).
- [ ] Box slots: "No more free led channels" is rendered in green; it is a blocking state.
- [ ] Community: discussion titles and "Latest likes" still clipped on the right edge of
      some cards.
- [ ] `DeviceAPI.resolveLocalName`: the `name.replaceAll('.local', '')` result is
      discarded, a saved name ending in `.local` becomes `…locallocal.local` and the
      mDNS lookup fails.
- [ ] Dark mode: white circles behind the icons in Plant settings; light check icon in
      the LED dim app bar.
- [ ] Alerts page: `futureFn` callbacks use `context` after an async gap without a
      mounted check (back out quickly → "deactivated widget").
- [ ] Graphs: the local series is preferred even when the last sample is hours old;
      fall back to cloud (or show "stale") when the newest local sample is older than
      a few minutes.

## 2. Graphics to improve

- [ ] Legacy screens not yet restyled: SGL account (huge green title, LOGIN /
      CREATE ACCOUNT pills), PIN lock (full green background + keypad), Remote control
      (floating green pill), Box slots (flat list with box icons), "Login required"
      dialog (stock Material).
- [ ] Off-theme icons: Towelie cartoon mascot, banana emoji on the Measure page, dark
      colour tiles in Infos (strain, medium, phase), cartoon speed-dial icons, cartoon
      toggles in the Watering form.
- [ ] Buttons: UPDATE PLANT / UPDATE LAB uppercase; "Create checklist" solid green;
      CREATE PLANT / CREATE LAB grey pill (it is the disabled state until a name is
      typed, but it does not read as such).
- [ ] Speed dial: black rectangular labels cover the diary text; darker scrim or chip
      labels.
- [ ] Controller status: only page without cards; broker URL wraps over three lines.
- [ ] "Archive plant" full red banner breaks the row pattern.
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

- [ ] Local alerts without cloud: the app already polls `/dash` every 15 s; send a
      local notification when temp/RH leave a range (Android foreground service).
- [ ] Controller time zone from the app (see bug above): warning + one tap.
- [ ] Longer local history and CSV export of DashHistory (24 h today).
- [ ] Temporary overrides in Controls: "lights 100 % for 10 min", "blower boost", with
      automatic return to the schedule.
- [ ] Local backup / restore of the DB (plants, diary, photos) to a file, for users
      without an account.
- [ ] Firmware update from the phone: the app serves the OTA file on the LAN and
      triggers OTA_START (what we do by hand with `python -m http.server`).
- [ ] Link to the controller's web dashboard (http://<ip>) from the controller page.
- [ ] Local checklists: "Create checklist" asks for a login; reminders could live on the
      phone only.
- [ ] Explanations (i) in Italian, if wanted.

## Done during the 2026-09-08 session (for reference)

- [x] Redesign stages 1–3, themed add-controller and plant flows, (i) explanations.
- [x] Graphs from the controller (DashHistory 24 h, CLOUD toggle) — 3b9bf6a2.
- [x] Alerts page requirements checklist — 1a88bd64.
- [x] GET /kv on the firmware + app fast path (params load < 5 s) — de4a37a / 2c307c23.
- [x] Towelie texts, panel sheets close by dragging — 8658f688.
- [x] Web dashboard reads fields from /kv — bb0f07b (firmware repo, UI not uploaded yet).
