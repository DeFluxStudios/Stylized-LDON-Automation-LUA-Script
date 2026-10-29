# Changelog

All notable changes to the LDoN Triune Runner are documented here. The script
currently reports version **1.4.4**.

## Version history note

The repository began with a single import commit and had no historical tags or
release records. The entries before v1.3.2 below are therefore a retrospective
feature ledger reconstructed from the current script and the available project
history; they are not claims that matching releases or tags were previously
published. The initial public package is v1.3.2.

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
- Add optional integration with the Long-Duration Buffs Triune plugin (by Triune).
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
