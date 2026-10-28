# LDoN Triune Runner guide

## Overview

`LDON_Triune.lua` coordinates LDoN travel, mission requests, campaign
progression, and Triune AutoCombat. It supports solo play and leader-started
group play. It is an automation aid, not a guarantee that every private-server
configuration, route, or navmesh will behave identically.

## Features

### Campaign setup

- Configure sequential campaign legs in the in-game window, up to five camps.
- Choose a dungeon count for each leg, including skipping a leg.
- Choose the mission request option for a leg. This release currently exposes
  the mob-count option; additional mission categories are not currently
  exposed by the UI.
- The default is hard difficulty and mob-count mission selection.
- Campaign scheduling advances through configured legs as tasks complete.

### Travel and mission flow

- Recognizes the supported LDoN campaign hubs and routes between campaign
  areas and dungeon instances.
- Uses the applicable recruiter and dungeon-exit metadata for campaign travel.
- Includes inter-zone crossings for the configured South Ro, Innothule,
  Butcherblock, Greater Faydark, and Lesser Faydark routes.
- Can return a group to its campaign recruiter through the runner's group
  travel flow.
- The solo Bazaar-and-Back return path requires AA 331.
- When a Bazaar return is used, Magus Alaria is recognized; the existing East
  Commonlands Magus route remains available when the ability returns there.

Travel depends on server zone IDs, NPC names, abilities, navmeshes, and
MacroQuest plugins being suitable for the character and server. Some routes
may require manual assistance.

### Triune AutoCombat

- The selected Main Assist is assigned **Puller - Hunt**.
- Other boxed group characters are assigned **Assist - Chase**.
- Grouped runs should be started by the group leader, and group members should
  stay together.
- BoxNet is needed for automatic remote-box setup.
- Combat integration can pause/restart relevant actions as the runner
  transitions between travel and mission states.

### UI and commands

The runner window is used to configure campaign camps, dungeon counts, the
available mission option, and Main Assist. The script also provides:

```text
/ldon start
/ldon status
/ldon pause
/ldon resume
/ldon exit
/ldon type <option>
/ldon ma <character name>
/ldon ui
/ldon diagnostics
/ldon help
```

### Navigation diagnostics and recovery

- Shows navigation/plugin status and current position information.
- Opens diagnostics when Triune reports a mesh-isolation failure.
- Can inspect recent pathing positions and offer a retry using the existing
  local navmesh and movement tools.
- Recovery does not download, replace, or edit navmesh files.
- Recovery is bounded and may still require manual relocation if the route is
  genuinely blocked or the geometry is not represented in the mesh.

## Recommended setup

1. Install the script as described in [GETTING_STARTED.md](GETTING_STARTED.md).
2. Verify MQ2Nav, MQ2MoveUtils, and Triune AutoCombat independently before
   starting the runner.
3. Start in one of the supported hubs or an LDoN instance.
4. Open the runner and set the intended campaign legs, dungeon count, mission
   type, and Main Assist.
5. Begin with a short, supervised run so you can confirm server-specific
   travel abilities, NPC names, and navmeshes.
6. Use `/ldon status` or `/ldon diagnostics` if progress stops. Pause the
   runner before manually relocating a character.

## Limitations

- The script does not install or configure MacroQuest plugins or navmeshes.
- A valid local navmesh and appropriate travel abilities are still required.
- NPC names, destinations, and zone IDs may differ on custom servers.
- The Linux TAR.GZ is an archive-format convenience only. Native Linux
  compatibility has not been verified.
- The artwork in the repository/release is branding and is not loaded by the
  script at runtime.
