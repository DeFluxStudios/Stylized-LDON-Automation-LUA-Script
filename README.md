# Stylized LDoN Automation Lua Script

MacroQuest Lua automation for Lost Dungeons of Norrath (LDoN) campaigns, with
Triune AutoCombat integration.

![LDoN Triune Runner artwork](artwork/ldon-triune-banner.svg)

**Current release: v1.3.2**

## What it does

- Requests hard-difficulty mob-count missions by default.
- Provides an in-game window to set campaign camps, dungeon counts, available
  mission request options, and the Main Assist. This release currently
  exposes the mob-count option.
- Supports solo runs and grouped runs started by the group leader.
- Configures the selected Main Assist as **Puller - Hunt** and other group
  members as **Assist - Chase** through Triune AutoCombat.
- Travels among supported LDoN hubs and dungeons and manages campaign legs.
- Includes navigation diagnostics and safe recovery helpers for reported mesh
  failures. It does not download or edit navmesh files.

See [GETTING_STARTED.md](GETTING_STARTED.md) for beginner installation
instructions and [GUIDE.md](GUIDE.md) for the full feature and usage guide.
Version history is in [CHANGELOG.md](CHANGELOG.md).

## Requirements

- MacroQuest with its Lua and ImGui support
- MQ2Nav and MQ2MoveUtils loaded, plus the required zone navmeshes
- Triune AutoCombat
- BoxNet for automatic remote-box setup
- The travel abilities/items used by the selected route; solo return requires
  the Bazaar and Back AA (331)

Dependencies and navmeshes are **not included** in the release archives.

## Quick start

1. Copy `LDON_Triune.lua` into MacroQuest's `lua` folder.
2. Start from a supported LDoN hub or an LDoN instance.
3. Run `/lua run LDON_Triune` in the MacroQuest console.
4. Configure the campaign and Main Assist in the runner window, then start.

The supplied ZIP and TAR.GZ archives contain the same script, beginner
instructions, feature guide, changelog, and project artwork. The artwork is
for documentation/branding only; it is not required by the Lua script.

## Compatibility note

The TAR.GZ package is provided for users who prefer Linux archive tools. It
does not imply native Linux support: EverQuest and MacroQuest runtime
compatibility on Linux (including Wine setups) has not been tested or verified.

## Credits and attributions

- **Cyfer** — LDoN mission and travel reference details adapted from the
  user-provided `LDON.lua`. The original reference material is not included in
  this repository.
- **DeFluxStudios** — MacroQuest Lua runner implementation, including the
  campaign scheduler, Triune AutoCombat integration, configuration UI, and
  navigation recovery behavior.
- **MacroQuest**, **Triune AutoCombat**, **MQ2Nav**, and **MQ2MoveUtils** are
  separate upstream projects and are required dependencies; they are not
  included in this repository or release.

## Project

- Repository: <https://github.com/DeFluxStudios/Stylized-LDON-Automation-LUA-Script>
- Releases: <https://github.com/DeFluxStudios/Stylized-LDON-Automation-LUA-Script/releases>
