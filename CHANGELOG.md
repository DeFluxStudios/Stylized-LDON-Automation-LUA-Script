# Changelog

All notable changes to the LDoN Triune Runner are documented here. The script
currently reports version **1.3.3**.

## Version history note

The repository began with a single import commit and had no historical tags or
release records. The entries before v1.3.2 below are therefore a retrospective
feature ledger reconstructed from the current script and the available project
history; they are not claims that matching releases or tags were previously
published. The initial public package is v1.3.2.

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
