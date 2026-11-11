# Changelog

All notable changes to the LDoN Triune Runner are documented here. The script
currently reports version **1.5.0-rc.1**.

## Version history note

The repository began with a single import commit and had no historical tags or
release records. The entries before v1.3.2 below are therefore a retrospective
feature ledger reconstructed from the current script and the available project
history; they are not claims that matching releases or tags were previously
published. The initial public package is v1.3.2.

## [1.5.0-rc.1] - 2026-11-11

Release candidate for testing, requested by a player. Not yet run in game.

- **Solo run while grouped.** A **Solo run (leave boxes alone)** checkbox next to
  **Group roles...**, or `/ldon solo on | off`, makes your character run the mission
  alone without leaving the group. Boxes are not gathered at the recruiter, followed,
  waited for at the dungeon, paused, shrunk or given roles. Your character runs
  Puller - Hunt and uses the solo Bazaar and Back return, so it needs AA 331.
  Switching it on during a grouped entry stops the boxes following first. Whether
  boxes outside the dungeon still get adventure credit is up to the server.
- **Extra pullers.** Tick boxes in the new **Extra puller** column of the Group Roles
  window, or use `/ldon pullers add | remove <name>` and `/ldon pullers clear`. Each
  extra puller runs Puller - Hunt and assists the Main Tank, as the Puller does.
  Triune AutoCombat's pull coordination keeps pullers off each other's mobs. The
  Main Tank, Main Assist and Puller cannot be extra pullers, and Swarm Pull stays on
  the Puller. The window warns that extra pullers hunt away from the healers.
- Both settings are saved per character.
- Validation: 150 mocked LuaJIT regressions pass; full script syntax checked. The
  zone approach and route code is byte-identical to v1.4.7.

## [1.4.7] - 2026-11-07

Added and fixed for players:

- **Group Roles window.** Choose a Main Tank, Main Assist and Puller with
  `/ldon roles`. Every box is told its job on each dungeon entry, including boxes in
  another zone, and healers assist the Main Tank.
- **Boxes come with you.** After a task is accepted, boxes follow your character to
  the dungeon with MQ2AdvPath. A box that loses you for 20 seconds, or has no
  MQ2AdvPath, walks the entrance route itself. Combat waits up to two minutes for
  them, unless something attacks first.
- **Fix the Lua error at the end of a grouped dungeon** and on a grouped start from
  outside LDoN.
- **Start from any character.** Starting from someone other than the group leader
  warns and continues instead of refusing.
- **Start from any stage.** An adventure from another camp goes to that camp first.
  Unrecognized mission text or directions warn, then use the zone, the planned camp
  or each known entrance in turn, instead of stopping.
- **A lost adventure ends cleanly.** The runner exits and clears it without counting
  it as a completed dungeon. The lesser-reward warning is not treated as a loss.
- **Rotting tree trunk entrance in Innothule.** Navigation only goes to the first
  point, then the character walks into the log and clicks from inside, up to three
  times. From Guktop it walks back to Innothule first.
- **Navigation fallbacks.** A failed approach point is retried, walked straight to
  when within 60 units, and skipped when another point follows.
- **Camp detection** reads entrance wording such as Upper Guk, Innothule Swamp,
  Lesser Faydark, Southern Ro and Northern Ro.
- The window offers the five mission types Random, Single Boss, Mob count, Collection
  and Rescue. A saved choice outside these goes back to the camp's default.
- Known problem: one Deepest Guk ramp (zone `guka`) is broken on the navmesh, so
  navigation cannot cross it. Walk it by hand. A fix is planned.

Route and shrink changes in this release:


The zone approaches below were reported working in game on Triune on 2026-11-04.
That report did not single out the Mistmoore grave route and did not cover shrink,
so neither is confirmed yet.

- Fix Rujark entry after Magus travel to South Ro: approach `Scout_Miigle`, then
  target `RUJPORTAL701` by name, as listed in the local South Ro door data. Remove
  the reference macro's unreachable `5, -222, 129.58` waypoint and its
  `OBJ_ZONEBOX` target. The recording key stays `switch_sro_1`.
- Fix North Ro quicksand entry: remove the off-mesh `5562.44, -1183.15, 25.01`
  approach and target `TAKPORTAL700` by name, as listed in the local North Ro door
  data. The recording key stays `switch_nro_3`.
- Restore Lesser Faydark's routing from before the LDON.mac cross-check: directions
  containing "grave" use switch 10 and all others use switch 7, through the existing
  Greater and Lesser Faydark crossings. Remove the grave and crypt approach points
  and the named crypt door, so unknown Mistmoore directions now use switch 7 instead
  of stopping with an error.
- Restore the Everfrost portal's nearest-door interaction from v1.4.5 after its two
  waypoints and walking fallback: walk to a door more than 15 and up to 40 units
  away, click only within 15 units, then wait for the zone change. Remove the
  `MIRPORTAL700` name check. The portal route no longer falls back to a recorded
  path.
- Let the first Everfrost portal waypoint pass on the existing 3-unit horizontal
  check, because the floor sits about 4 units below the navigation point.
- Replace the snowy-mine route with three approach points:
  `2698.93, -4693.65, -95.64`, `2751.72, -4645.75, -84.40`, then
  `2772.53, -4727.61, -97.37` (Y, X, Z). The walking fallback still applies only to
  the final point.
- In Mushroom Grove (`gukd`), move the controller through
  `140.38, -790.08, -25.96` then `151.44, -754.05, -25.96` before enabling TAC or
  Swarm Pull, once per zone entry and once if the runner starts inside the zone. A
  failed move leaves combat paused and pauses the runner. Other dungeons and
  completed adventures skip this.
- Extend the saved shrink option to every zone while the runner is active, including
  camps, travel zones, completed adventures and the zone where the runner starts.
  The window now calls it **Shrink once on every zone entry**. Movement and combat
  setup wait for the attempt, so group runs with Triune running spend up to 27
  seconds in each zone waiting on the boxes. Pausing and resuming in the same zone
  does not click again. The saved setting and its default-off behavior are unchanged.
- Keep TAC running when shrink is switched on in a zone where combat is already set
  up; shrink starts from the next zone. Start Triune before a dungeon shrink, and
  send group shrink commands only while Triune is running.
- Validation: 141 mocked LuaJIT regressions pass; full script syntax checked.

## [1.4.6] - 2026-11-02

- Set final snowy-mine waypoint height to -104.
  Entry succeeded in game, though movement remains rough.
- If the final snowy-mine navmesh approach stops within 35 units, allow a
  10-second MoveUtils walk, requiring verified 3D arrival within 10 units
  before targeting the entrance. Stop walking on pause or zoning.
- Replace the snowy-mine approach points:
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
- Update the crypt approach: navigate through
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
- Retain the Triune tree-trunk, snowy-mine and portal coordinates and
  existing recorded zone-line crossings. Return-to-hub coordinates/headings
  agree with the macro. Normalize North/South Ro and Commonlands route aliases.
- Detect zoning during entrance navigation or recorded playback before
  clicking; reject unrelated destinations. Preserve existing named entrance
  recording keys. The added approaches and named doors still need in-game
  validation on Triune except for the confirmed crypt and snowy-mine entries.
- Validation: 76 mocked LuaJIT regressions pass; full script syntax checked.

## [1.4.5] - 2026-11-01

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
