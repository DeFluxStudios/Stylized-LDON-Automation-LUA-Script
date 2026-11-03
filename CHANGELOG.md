# Changelog

All notable changes to the LDoN Triune Runner are documented here. The script
currently reports version **1.4.6**.

## Version history note

The repository began with a single import commit and had no historical tags or
release records. The entries before v1.3.2 below are therefore a retrospective
feature ledger reconstructed from the current script and the available project
history; they are not claims that matching releases or tags were previously
published. The initial public package is v1.3.2.

## [1.4.6] - 2026-11-02

- Set final snowy-mine waypoint height to -104 at the user's request.
  Entry succeeded in game, though movement remains rough.
- If the final snowy-mine navmesh approach stops within 35 units, allow a
  10-second MoveUtils walk, requiring verified 3D arrival within 10 units
  before targeting the entrance. Stop walking on pause or zoning.
- Replace snowy-mine approach points with the user's latest screenshot:
  `2697.18, -4694.15, -91.06`, then `2771.57, -4725.96, -104` (Y, X, Z).
  Preserve the existing arrival tolerances and entrance-door safety checks.
- Add an opt-in, saved shrink-on-dungeon-entry option before TAC combat starts.
  Each box checks its own ready carried shrink clicky, including regular and
  tiered versions of the three supported items. Attempts one click per entry;
  reports failures and continues. Requires ldon_shrink.lua on each box and
  BoxNet slash-command acceptance for remote boxes. Live shrink testing pending.
- Check final crypt waypoint arrival in Y/X only, retaining navigation Z=0.
  Standing on the building floor no longer fails arrival solely due to height.
  The 3-unit horizontal arrival limit and door-click safety checks remain.
- Update the crypt approach from the user's latest screenshots: navigate through
  `-739.37, 3793.22, 1.06` then `-760.27, 3838.85, 0` (Y, X, Z), and target
  `MISTFCFN700` by name before clicking. Leave the grave route unchanged.
  The second point uses Z=0 because the navmesh runs beneath the building.
  Crypt approach and door click were confirmed working in game.
- Grave retains test point `-67, 3843` (Y, X), without forced Z, followed by
  nearby-door selection. Grave routing remains unverified. Remove the old
  crypt crossing toward the grave and its assumed heading.
- Cross-check entrance routes against the supplied `LDON.mac` by Cannonballdex:
  add North Ro quicksand and South Ro Rujark cave approaches, target
  `OBJ_ZONEBOX`, `GKPORTAL701` and `MIRPORTAL700` by name rather
  than hardcoded or nearest switch IDs, and add the Guktop approach point.
- Replace Mistmoore fixed switch IDs with location-based nearby entrance
  targeting. Unknown Guk/Mistmoore directions now report an
  error rather than choosing an arbitrary entrance.
- Retain the user's Triune tree-trunk, snowy-mine and portal coordinates and
  existing recorded zone-line crossings. Return-to-hub coordinates/headings
  agree with the macro. Normalize North/South Ro and Commonlands route aliases.
- Detect zoning during entrance navigation or recorded playback before
  clicking; reject unrelated destinations. Preserve existing named entrance
  recording keys. The added approaches and named doors still need in-game
  validation on Triune except for the confirmed crypt and snowy-mine entries.
- Validation: 76 mocked LuaJIT regressions pass; full script syntax checked.

## [1.4.5] - 2026-10-29

- Correct a regression in the 2026-11-01 changes: Start could open the
  Adventure Request window and call `mq.delay` inside the ImGui callback.
  Start/resume now queues startup on the main Lua loop, where delays can yield
  safely. Pause, stop, exit and window close cancel pending startup. Added
  callback-context and coroutine-yield regressions. A native MQ2Lua crash was
  reported on Start; this unsafe path is fixed but still needs in-client retest.
- Additional fixes (2026-11-01): show Random, Single Boss, Mob count,
  Collection and Rescue on first launch, using the local client UI order.
  Validate the selected index and label against the live recruiter list
  before requesting; unreadable, empty or mismatched lists send no request.
- Route Everfrost "snowy mine" directions through approach
  `2697.71, -4686.63, -87.75` and entrance `2774.88, -4723.56, -93.31`
  (Y, X, Z), then target a nearby door and verify click range and zoning.
  Keep the portal route separate; unknown directions report an error rather
  than guessing. The snowy-mine route still needs in-game validation.
- Fix starting another campaign with a stale previous camp, including North
  Ro: reconcile the hub on fresh start, preserve unfinished-adventure ownership,
  update the hub even when already at the target, and use Magus travel for
  cross-camp returns rather than transition-zone crossings. Preserve paused
  campaign state and completed-leg return ordering.
- Add Lua 5.1/LuaJIT regression checks for mission requests, both Everfrost
  routes, click safety and campaign restarts using mocked MQ interactions.
- Fix the Everfrost Peaks entrance (Miragul's Menagerie). The runner targeted
  the nearest door, a wall switch (EFWALL1) it could not reach, instead of the
  glimmering portal. It now walks to two recorded points, then targets and
  clicks the nearest door object there (reporting its name and distance if it
  cannot) and waits for the zone change. The portal route is untested in game.
- Fix Triune not restarting after a death. When you died inside a dungeon and
  the runner brought you back into the same dungeon, it believed combat was
  already configured and left Triune paused. Leaving a dungeon zone now clears
  that state, so `/ac run` and the Hunt setup are sent again on re-entry.
- Correct the Long-Duration Buffs attribution: the plugin is by DeFluxStudios,
  not Triune (runner window, comments, README, guide and plugin metadata).

## [1.4.4] - 2026-10-29

- Fix "Could not navigate to a close interaction point at the Magus" (seen in
  the Bazaar). The approach spot is now accepted within 5 units, and the
  runner falls back to /nav to the Magus and then a straight MoveUtils walk,
  judging success by the real distance to the Magus.

- Fix the Guktop entrance switch failing when the navmesh snaps the approach
  point to another floor ("Could not locate destination on navmesh"). The
  runner now judges success by distance to the switch, and falls back to
  walking straight to it with MoveUtils. It also no longer tries to travel to
  Innothule when it is already in the entrance zone.

- Fix the runner window and Adventure window not resetting after the last
  configured dungeon: the campaign now fully resets (counts, travel state,
  stats on the next start), presses Leave Adventure on the finished assignment,
  and a new run can start without restarting the script. A finished assignment
  that lingers outside the instance no longer blocks the campaign.
- Start from any zone. Outside LDoN, the runner uses Bazaar and Back and the
  Magus to reach the first selected camp (or the camp that owns an existing
  adventure) and requests an adventure only if none is active.
- Deepest Guk routing is now keyword-based on both sides: "barricaded door", "Guk portal" and "Root Garden" go to Guktop; "cauldron of lost souls", "rotting tree trunk" and Innothule mentions go to the tree trunk. Unrecognized text still defaults to Guktop.

## [1.4.3] - 2026-10-29

- Add an Adventure difficulty selector (Normal or Hard) to the main window and
  `/ldon difficulty normal|hard`; the choice is saved per character.
- Move the Swarm Pull toggle to the main window and add `/ldon swarm on|off`;
  turning it off mid-run stops Swarm Pull and resumes normal combat.

## [1.4.2] - 2026-10-29

- Fix the camp artwork not filling or scaling with the window. The real image
  size is now read from the file header and the image is cropped to cover the
  window without stretching or showing padded texture area.
- Fix Deepest Guk missions that use the rotting tree trunk in Innothule Swamp
  being sent to the Guktop barricaded door. The entrance is now chosen from the
  mission text.
- Walk to two approach points before clicking the Innothule tree trunk so the
  runner no longer runs into the side of it.

## [1.4.1] - 2026-10-29

- Make the window friendlier: quick-start prompt, a "How to use this window"
  section, an "Apply recommended settings" button, tooltips, and installed or
  missing status with recommendations for each optional plugin (Long Buffs,
  MQ2AdvPath, Swarm Pull).

## [1.4.0] - 2026-10-29

- Fix the South Ro to East Commonlands return so it uses the close-approach Magus
  routine instead of speaking from up to 35 units away.
- Add automatic retries with backoff for entrance, exit, hub-return and camp
  travel failures, with specific failure reasons and a configurable limit.
- Fall back to the dungeon exit when a solo Bazaar and Back return fails.
- Add a preflight checklist (`/ldon preflight`), a run summary, a stuck-progress
  warning, a rolling `logs/LDON_Triune.log`, and a Copy diagnostics button.
- Save and load settings per character; add Stop after current dungeon
  (`/ldon finish`) and an optional scheduled stop.
- Sample navmesh recovery points every two seconds instead of every loop.
- Add optional integration with the Long-Duration Buffs Triune plugin (by DeFluxStudios).
- Add optional integration with the Swarm Pull Triune plugin (by matth); it is
  off by default and skipped when the plugin file is absent.
- Add optional MQ2AdvPath (RedGuides) recorded routes for zone crossings and
  entrance switches, with `/ldon record`; off by default.
- Add `scripts/release.ps1` to build the release archives and checksums.

## [1.3.3] - 2026-10-29

- Try nearby approach points around an LDoN entrance switch when the nearest
  navmesh approach is unreachable; confirm interaction range before clicking.
- Approach Magus NPCs closely before speaking to ensure their travel dialogue
  is within interaction range.

## [1.3.2] - 2026-10-28

- Add Bazaar (zone 151) recognition to return travel.
- Recognize Magus Alaria for travel from the Bazaar.
- Preserve the East Commonlands Magus route when Bazaar and Back returns the
  character there.
- Publish beginner installation instructions, a feature guide, and original
  project artwork with Windows ZIP and Linux TAR.GZ packages.

## [1.3.1] - Retrospective milestone

- Add navigation failure diagnostics and a user-triggered recovery flow.
- Inspect local navigation state and recent pathable positions for recovery.
- Keep mesh recovery local; the runner does not download or edit mesh files.

## [1.3.0] - Retrospective milestone

- Add campaign-leg planning and sequential multi-camp configuration.
- Support mission and dungeon-count options in the runner interface.
- Expand travel, instance-exit, recruiter, and group-return handling.

## [1.2.0] - Retrospective milestone

- Integrate Triune AutoCombat with a configurable Main Assist.
- Set up the Main Assist as Puller - Hunt and other group boxes as Assist -
  Chase.
- Add solo/group behavior and MacroQuest `/ldon` controls.

## [1.0.0] - Retrospective milestone

- Establish the MacroQuest Lua LDoN runner and its core campaign flow.
- Default the runner to hard mob-count missions.
- Add an in-game configuration window and supported LDoN hub/dungeon data.

## Versioning

Releases use semantic versioning (`MAJOR.MINOR.PATCH`). The Lua `VERSION`
constant and release tag should match. Patch releases are for compatible fixes
and data updates; minor releases add backward-compatible features; major
releases indicate breaking behavior or configuration changes.
