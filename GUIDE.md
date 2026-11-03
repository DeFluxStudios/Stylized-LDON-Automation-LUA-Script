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
- Choose the mission request option for a leg. Random, Single Boss, Mob count,
  Collection and Rescue are available before the first run. Before requesting,
  the runner reads the live game list and checks the chosen index and label.
  An empty, unreadable or changed list does not send a request. Use **Refresh
  task types** with the Adventure Request window open to refresh manually.
- The default is hard difficulty and mob-count mission selection.
- Campaign scheduling advances through configured legs as tasks complete.
- After a campaign finishes, you can select different camps and start again
  without unloading the script. A new campaign uses its first selected camp;
  an unfinished adventure retains its own camp. Pausing and resuming preserves
  the campaign's counters and current camp.
- Start/resume queues initialization on the main Lua loop, not the ImGui
  drawing callback. Opening the Adventure Request window can briefly delay
  startup. Pause, stop, exit or closing the runner cancels pending startup.
- Selecting a mission type does not add objective-specific automation.
  Collection and Rescue objectives may require manual assistance.

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
- Everfrost entrance directions select separate routes. **Snowy mine** uses
  approach `2697.18, -4694.15, -91.06`, then entrance
  `2771.57, -4725.96, -104` (Y, X, Z; final height is a user-requested test). Portal directions retain the separate
  portal approach. Unrecognized Everfrost directions stop the entrance attempt
  and are printed to the log instead of guessing. The mine targets a nearby
  door and uses the existing click-range and zoning checks.

Travel depends on server zone IDs, NPC names, abilities, navmeshes, and
MacroQuest plugins being suitable for the character and server. Some routes
may require manual assistance.

### Entrance cross-check against LDON.mac

Unreleased route changes were cross-checked against the user-supplied
`LDON.mac` by Cannonballdex (with the contributors credited in that macro).
Only route facts were adapted, not its combat, networking or repeated-click
loops. Coordinates below are Y, X, Z.

| Camp / entrance | Approach and interaction |
| --- | --- |
| North Ro / quicksand | `5562.44, -1183.15, 25.01`; select the nearby entrance, not a fixed switch 3 |
| Rujark / cave in South Ro | `5, -222, 129.58`; target `OBJ_ZONEBOX`, not Scout Miigle or fixed switch 1 |
| Guktop / barricaded door | `441.77, 228.63, -9.13`; target `GKPORTAL701` |
| Innothule / rotting tree trunk | Keep the Triune points `1389.12, 1145.40, -15.62` and `1245.50, 1186.58, -10.49`; select a nearby entrance |
| Mistmoore / unearthed grave | Current test map point `-67, 3843`, without forcing Z; select the nearby entrance |
| Mistmoore / crypt | Screenshot approaches `-739.37, 3793.22, 1.06`, then `-760.27, 3838.85, 0` (Z adjusted for the navmesh beneath the building); target `MISTFCFN700` by name |
| Everfrost / portal | Keep the Triune approach points; target `MIRPORTAL700` rather than the nearest wall |
| Everfrost / snowy mine | Keep the user's two Triune points documented above; accept instance zoning while approaching, otherwise select a nearby entrance |

Nearest-door routes reject targets more than 40 units from the approach.
The final snowy-mine point allows a 10-second MoveUtils walk if navigation
stops within 35 units in 3D. It still requires arrival within 10 units in 3D
before targeting a door; pause and zoning stop the walk.
Named-door routes require the target name to match and preserve the existing
15-unit click-range checks. Unknown Guk, Mistmoore or Everfrost directions are
reported instead of selecting a default entrance. Navigation that zones into
the expected dungeon is complete and does not click again.

The macro's return-to-hub points/headings match the existing Lua. Its outbound
zone-line points differ from the user's recorded Triune paths, so those Lua
paths are retained. In particular, the macro's tree-trunk coordinates are not
substituted for the user's Triune route. Test the new named-door identities and
approach points in game before releasing these changes.

The user's latest screenshots provide two exact crypt approaches and the door
name `MISTFCFN700`; these replace the earlier rounded crypt map point.
The grave test point remains `-67, 3843`, and is not yet verified.
The final crypt waypoint keeps navigation Z=0 but checks arrival using only Y/X,
within 3 units, so the building floor's height does not block the door click.
Other waypoint arrival checks and the door's click-range checks are unchanged.
The old heading-125 crossing toward `-766.75, 3824.95` is not used for crypt
missions. Crypt entry requires the named door; grave entry uses nearby-door
checks. Actual instance zoning during navigation ends the approach without
clicking. The updated crypt path and door interaction need in-game verification.

### Optional shrink before TAC

Enable **Shrink on dungeon entry before TAC** under **Options and optional
plugins > Basic**. It is saved per character and defaults off. Before enabling
combat in a new adventure, the runner attempts one ready carried clicky:
Wand of Imperceptibility, Bracelet of the Shadow Hive, or Shimmering Bauble of
Trickery. Partial-name matching includes regular and tiered versions, not just
Legendary. Missing/unready items and unconfirmed size changes are reported,
then the runner continues. It does not attempt another click on pause/resume
in the same zone, or when the adventure is already complete.

Copy `ldon_shrink.lua` alongside `LDON_Triune.lua` on every box. Group shrinking
uses `/ac net group /lua run ldon_shrink <zone ID>`; BoxNet must be connected
and accept peer slash commands. Each box checks its own zone, inventory and
item readiness, targets itself and verifies a height decrease. It allows up
to 15 seconds to arrive and 10 seconds to confirm the click. The controller
waits for this bounded window before enabling TAC, but cannot confirm remote
delivery or success. Check each box's `[LDoN Shrink]` messages. Already being
minimum size can produce the no-size-decrease message. No retry is made.

### Regression checks

From the repository root, run `lua tests\regression.lua` with Lua 5.1, or
`luajit tests\regression.lua`. The suite compiles the full script and tests
its mission selection, entrance routing and campaign restart logic using
mocked MacroQuest interactions. It does not replace in-game testing of
navigation, door identity or server behavior.

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

### Reliability and optional plugins

- Entrance, exit, hub-return and camp-travel failures retry with a growing
  delay (limit set in **Options and optional plugins**, default 2) before the
  runner pauses with the specific failure reason.
- **Run preflight check** (`/ldon preflight`) verifies plugins, Triune, meshes
  and any enabled optional plugin. **Copy diagnostics** copies state and the
  recent log; the full log is `logs/LDON_Triune.log`.
- **Stop after current dungeon** (`/ldon finish`) and the scheduled stop finish
  the dungeon in progress, return to camp, then stop. Settings are saved per
  character in the MacroQuest config folder.
- **Long-Duration Buffs** (Triune plugin by DeFluxStudios): when enabled, the runner
  sends `/ac longbuff on` as combat starts. Build the roster in Triune first.
- **Swarm Pull** (plugin by matth, optional, off by default): when enabled, the
  runner starts `/ac swarm start` inside dungeons and stops it when the task
  completes. Turn off Swarm Pull's "Reset via Bazaar when idle" so it never
  leaves the dungeon. It suits kill and mob-count tasks.

- **MQ2AdvPath** (optional, off by default): record a working walk with
  `/ldon record start` then `/ldon record save <key>` and the runner can play it
  back for a zone crossing (`sro_to_innothule`, `innothule_to_guktop`,
  `gfaydark_to_lfaydark`, ...) or an entrance switch (`switch_guktop_0`). By
  default recordings are a fallback after built-in navigation fails; "Try
  recordings before built-in navigation" reverses that. Paths are saved in your
  MQ2AdvPath config, not in this repository.

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
