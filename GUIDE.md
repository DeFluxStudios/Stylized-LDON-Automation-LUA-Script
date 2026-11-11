# LDoN Triune Runner guide

## Overview

`LDON_Triune.lua` coordinates LDoN travel, mission requests, campaign
progression, and Triune AutoCombat. It supports solo play and group play started
from any one character. It is an automation aid, not a guarantee that every private-server
configuration, route, or navmesh will behave identically.

## Requirements

| What | Needed for | How to check |
| --- | --- | --- |
| MacroQuest with Lua and ImGui | Everything | `/lua run LDON_Triune` opens the window |
| **MQ2Nav** plugin and zone navmeshes | All travel. The runner will not start without the plugin | `/plugin MQ2Nav`, then `/ldon preflight` |
| **MQ2MoveUtils** plugin | Zone crossings and walking fallbacks. The runner will not start without it | `/plugin MQ2MoveUtils` |
| **Triune AutoCombat** ([tunaria/TriuneAutocombat](https://github.com/tunaria/TriuneAutocombat)) | Combat in dungeons | `/lua run triune` |
| **BoxNet** (built into Triune AutoCombat) | Grouped runs only | `/ac net peers` lists your boxes |
| **Bazaar and Back** AA 331 | Starting a solo run, and reaching your first camp from outside LDoN. Grouped returns use the dungeon exit without it, and a solo return falls back to the exit if the AA is not ready within three minutes | Check your AA window |

BoxNet needs the MacroQuest launcher running and, on every box, its
**Also run other slash commands** setting turned on. The grouped preflight line
**BoxNet transport plugin loaded** looks for MQ2EQBC or MQ2DanNet, which BoxNet
does not use, so you can ignore that line if `/ac net peers` lists your boxes.

**Optional extras.** The first four stay off until you enable them in the window. Camp artwork has no switch; it shows whenever the folder is present.

| Extra | What it adds | What you need |
| --- | --- | --- |
| Shrink once on every zone entry | Attempts one click of a shrink item in each zone | `ldon_shrink.lua` beside the runner on every box, and a Wand of Imperceptibility, Bracelet of the Shadow Hive or Shimmering Bauble of Trickery |
| Long-Duration Buffs | Sends `/ac longbuff on` as combat starts | `lua/tac/long_buffs.lua`, `lua/tac_long_buffs_store.lua` and a roster built in Triune (Settings > Plugins > Long-Duration Buffs) |
| Swarm Pull | Pulls groups of mobs | `lua/tac/Swarm_Pull_v2.0.lua` or `lua/tac/swarm_pull.lua` |
| Group follow and recorded routes | Boxes follow your character to the dungeon, and you can record paths for trouble spots | **MQ2AdvPath** plugin (`/plugin MQ2AdvPath`). Without it, boxes walk the entrance route themselves |
| Camp artwork | Window backgrounds | `ldon_art` folder beside the runner. The images are not in the release archives, and the window works without them |

## Features

### Campaign setup

- Configure sequential campaign legs in the in-game window, up to five camps.
- Choose a dungeon count for each leg, including skipping a leg.
- Choose the mission request option for a leg: Random, Single Boss, Mob count,
  Collection or Rescue. Before requesting, the runner reads the recruiter's list
  and checks your choice. An empty, unreadable or changed list does not send a
  request. Use **Refresh task types** with the Adventure Request window open to
  refresh manually.
- The default is hard difficulty and mob-count mission selection.
- Campaign scheduling advances through configured legs as tasks complete.
- After a campaign finishes, you can select different camps and start again
  without unloading the script. A new campaign uses its first selected camp;
  an unfinished adventure retains its own camp. Pausing and resuming preserves
  the campaign's counters and current camp.
- Start/resume queues initialization on the main Lua loop, not the ImGui
  drawing callback. Opening the Adventure Request window can briefly delay
  startup. Pause, stop, exit or closing the runner cancels pending startup.
- Selecting a mission type does not add objective-specific automation. Collection,
  Rescue and other objectives may need you to step in. Random can give you one the
  runner cannot finish, so your character may stand idle until you take over. TAC
  does not know the special mechanics of these objectives.

### Travel and mission flow

- In Mushroom Grove (`gukd`) only, the controller navigates to
  `140.38, -790.08, -25.96`, then `151.44, -754.05, -25.96` (Y, X, Z)
  before enabling TAC or Swarm Pull. Each point requires arrival within 5
  units in 3D within 60 seconds. Failure leaves combat paused. This runs once
  per entry, not again on same-zone resume, and skips completed adventures.
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
  three approach points in order: `2698.93, -4693.65, -95.64`,
  `2751.72, -4645.75, -84.40`, then `2772.53, -4727.61, -97.37`
  (Y, X, Z). Portal directions retain the separate
  portal approach. Unrecognized Everfrost directions stop the entrance attempt
  and are printed to the log instead of guessing. The mine targets a nearby
  door and uses the existing click-range and zoning checks.

Travel depends on server zone IDs, NPC names, abilities, navmeshes, and
MacroQuest plugins being suitable for the character and server. Some routes
may require manual assistance.

### Entrance routes

Routes were cross-checked against `LDON.mac` by Cannonballdex, with the
contributors credited in that macro. The macro is not bundled here. Only route
facts were used, not its combat, networking or repeated-click loops. Coordinates
below are Y, X, Z.

| Camp / entrance | Approach and interaction |
| --- | --- |
| North Ro / quicksand | Targets `TAKPORTAL700` by name with the usual door navigation and click checks. The macro's off-mesh approach point and a fixed switch ID are not used |
| Rujark / cave in South Ro | Approaches `Scout_Miigle`, then targets `RUJPORTAL701` by name. Local South Ro door data differs from the macro, so its `5, -222, 129.58` point and `OBJ_ZONEBOX` door are not used |
| Guktop / barricaded door | `441.77, 228.63, -9.13`; target `GKPORTAL701` |
| Innothule / rotting tree trunk | Walks the Triune points `1389.12, 1145.40, -15.62` and `1245.50, 1186.58, -10.49`, then selects a nearby entrance |
| Mistmoore / grave directions | Goes through Greater and Lesser Faydark, then switch 10, with no added approach waypoints |
| Mistmoore / other directions | Goes through Greater and Lesser Faydark, then switch 7, with no added approach waypoints |
| Everfrost / portal | Two-point approach. The first point uses a 3-unit horizontal arrival check to allow for the floor-height offset seen in game. The final point keeps its height check and bounded walking fallback, then the nearest door is clicked within a 15-unit limit; no door name is required |
| Everfrost / snowy mine | Walks the three Triune points listed above, accepts instance zoning on the way, and otherwise selects a nearby entrance |

The Mistmoore grave route has no separate in-game confirmation yet.

Nearest-door routes reject targets more than 40 units from the approach.
The final snowy-mine point allows a 10-second MoveUtils walk if navigation
stops within 35 units in 3D. It still requires arrival within 10 units in 3D
before targeting a door; pause and zoning stop the walk.
Named-door routes require the target name to match and preserve the existing
15-unit click-range checks. Unknown Guk or Everfrost directions are
reported instead of selecting a default entrance. Navigation that zones into
the expected dungeon is complete and does not click again.

The macro's return-to-hub points and headings match the runner's. Its outbound
zone-line points differ from the paths recorded on Triune, so the recorded paths
stay. The macro's tree-trunk coordinates are likewise not used in place of the
Triune route.

### Optional shrink on every zone entry

Enable **Shrink once on every zone entry** under **Options and optional
plugins > Basic**. It is saved per character and defaults off. While running,
the runner attempts one ready carried clicky in every zone, including camps,
travel zones and completed adventures, before travel or combat setup:
Wand of Imperceptibility, Bracelet of the Shadow Hive, or Shimmering Bauble of
Trickery. Partial-name matching includes regular and tiered versions, not just
Legendary. Size resets when you zone on Triune, so each zone needs its own click.
Missing/unready items and unconfirmed size changes are reported,
then the runner continues. It does not attempt another click on pause/resume
in the same zone. Returning to a zone after leaving allows one new attempt.
The option also applies to the current zone when starting the runner. A zone
where combat is already running is skipped, because nothing would resume the
pause there, and shrinking starts from the next zone. In a dungeon the runner
starts Triune first. Elsewhere, if Triune is not running, the controller still
clicks its own item, but group boxes are not sent a shrink and the runner says so.

Copy `ldon_shrink.lua` alongside `LDON_Triune.lua` on every box. Group shrinking
uses `/ac net group /lua run ldon_shrink <zone ID>`; BoxNet must be connected
and accept peer slash commands. Each box checks its own zone, inventory and
item readiness, targets itself and verifies a height decrease. It allows up
to 15 seconds to arrive and 10 seconds to confirm the click. In a group with
Triune running, the controller waits 27 seconds from the start of each attempt,
so with this option on each such zone adds that wait. It cannot confirm remote
delivery or success. Check each box's `[LDoN Shrink]` messages. Already being
minimum size can produce the no-size-decrease message, though on Triune it
usually means the click failed. No retry is made. Shrink has not yet been
confirmed in game.

### Regression checks

From the repository root, run `lua tests\regression.lua` with Lua 5.1, or
`luajit tests\regression.lua`. The suite compiles the full script and tests
its mission selection, entrance routing and campaign restart logic using
mocked MacroQuest interactions. It does not replace in-game testing of
navigation, door identity or server behavior. It also does not cover the group
return, and its helper loads functions as globals, so it cannot catch a function
used before its local declaration. Test grouped runs in game.

### Triune AutoCombat

Press **Group roles...** in the runner window, or use `/ldon roles`, to choose:

| Role | What it does |
| --- | --- |
| **Main Tank** | Healers assist this character, so heals land on it. It stops moving behind the mob. |
| **Main Assist** | Everyone else follows this character and attacks its target. |
| **Puller** | The main character in **Puller - Hunt**. It finds the targets, and Swarm Pull runs here too. |
| **Extra puller** | Tick any other box in the **Extra puller** column to put it in **Puller - Hunt** as well. Triune AutoCombat keeps pullers off each other's mobs. |

- A Main Tank or Puller you leave unset is the same as the Main Assist. The window
  shows what each character will be told before anything is sent.
- The Main Tank, Main Assist and Puller cannot be extra pullers, because the rest of
  the group follows them. Extra pullers hunt away from the healers, who stay with the
  Main Tank, so pick characters that can survive alone. `/ldon pullers add <name>`,
  `remove <name>` and `clear` do the same from the command line.
- Classes come from each character's saved Triune loadout. Anyone with a Cleric,
  Druid, Shaman, Paladin, Ranger or Beastlord class counts as a healer, so check
  that column.
- Roles are sent on every dungeon entry, and **Apply to group now** sends them
  straight away. Other boxes use **Assist - Chase**.
- Press Start on one character only. If it is not the group leader you get a
  warning, and the run continues.
- After a task is accepted, boxes follow your character with MQ2AdvPath. Each box
  prints `Following <name> to the dungeon.` Your character waits up to two minutes
  inside before starting combat, unless something attacks it. A box that loses you
  for 20 seconds, or has no MQ2AdvPath, walks the entrance route itself.
- **Solo run (leave boxes alone)**, next to **Group roles...**, or `/ldon solo on`,
  runs the mission with your character only while you stay grouped. The boxes are
  not gathered, followed, waited for, paused or given roles, so you can use them for
  other things. Your character runs **Puller - Hunt** and returns with Bazaar and
  Back, as in a solo run, so it needs AA 331. Whether boxes outside the dungeon still
  get adventure credit depends on the server, so check your adventure stats after
  the first run.
- BoxNet is needed for automatic remote-box setup.
- Combat integration can pause/restart relevant actions as the runner
  transitions between travel and mission states.

### UI and commands

The runner window is used to configure campaign camps, dungeon counts, the
available mission option, and group roles. The script also provides:

```text
/ldon help
/ldon ui
/ldon start | resume
/ldon pause | stop
/ldon finish
/ldon exit
/ldon status
/ldon preflight
/ldon diagnostics
/ldon save
/ldon ma <character name>
/ldon type <number>
/ldon difficulty normal | hard
/ldon swarm on | off
/ldon record start | save <key> | play <key>
```

`/ldon type` takes the number of the mission type in the dropdown (3 is Mob count,
5 is Rescue), not its name, and applies to the camp leg in progress. Before a
campaign starts, use the window's **Task type** column instead, because the
command may change a different camp's row.

Two more commands exist for the scripts' own use and are not meant to be typed:
`/ldon remote-return <hub zone ID>` and `/ldon remote-follow`, which your character
sends to boxes during a run (`/ldon remote-follow off` on a box stops it following),
and `/ldon meshfail`, which runs the same handler as the
`/ldonmeshfail` bind that Triune uses to report a mesh failure.

### Reliability and optional plugins

- Entrance, exit, hub-return and camp-travel failures retry with a growing
  delay (limit set in **Options and optional plugins**, default 2) before the
  runner pauses with the specific failure reason.
- **Run preflight check** (`/ldon preflight`) verifies plugins, Triune, meshes
  and any enabled optional plugin. **Copy diagnostics** copies state and the
  recent log; the full log is `logs/LDON_Triune.log`.
- **Stop after current dungeon** (`/ldon finish`) and the scheduled stop finish
  the dungeon in progress, return to camp, then stop. Settings are saved per
  character in the MacroQuest config folder, except **Stop after minutes**, which
  resets each session.
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
  default recordings are a fallback after built-in navigation fails. "Try
  recordings before built-in navigation" reverses that for zone crossings only;
  entrance switches always try the built-in route first. Paths are saved in your
  MQ2AdvPath config, not in this repository.

### Other window options

- **Adventure difficulty**: Normal or Hard, default Hard. `/ldon difficulty` sets
  the same thing.
- **Use Swarm Pull (Triune AutoCombat plugin) inside dungeons**: off by default.
  When it is on, **Pull count** (default 3, up to 20) and **Pull radius** (default
  200, from 20 to 1000) appear under **Options and optional plugins**.
- **Auto-stand from sitting / Feign Death in combat**: on by default. It stands
  only when you and all group members are above 50% HP.
- **Repeat campaign after final camp**: off by default. When on, the campaign
  starts again at the first selected camp after the last one finishes.
- **Stop after minutes (0 = off)**: up to 480. Once that time has passed, the
  runner finishes the current dungeon and stops.
- **Apply recommended settings**: sets the Auto-retry limit to 2 and the difficulty
  to Hard, turns Long-Duration Buffs on if installed, and turns off Stop after
  minutes, recorded routes, Swarm Pull and shrink. Auto-stand and Repeat campaign
  are left as they are.

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
3. Stand anywhere. In one of the supported hubs or an LDoN instance the runner
   starts right there; from any other zone it travels to your first camp using
   Bazaar and Back and the Magus.
4. Open the runner and set the intended campaign legs, dungeon count, mission
   type, and group roles.
5. Begin with a short, supervised run so you can confirm server-specific
   travel abilities, NPC names, and navmeshes.
6. Use `/ldon status` or `/ldon diagnostics` if progress stops. Pause the
   runner before manually relocating a character.

## Limitations

- **Known problem:** one ramp in Deepest Guk (zone `guka`) is broken on the navmesh,
  so navigation cannot cross it and may report that it cannot find a path. If your
  group stalls there, pause the runner, walk across the ramp by hand, then resume.
  A fix is planned.
- The new group features have been tested far more in simulation than in play. Start
  with a short, supervised run, and please report what you see.
- The script does not install or configure MacroQuest plugins or navmeshes.
- A valid local navmesh and appropriate travel abilities are still required.
- NPC names, destinations, and zone IDs may differ on custom servers.
- The Linux TAR.GZ is an archive-format convenience only. Native Linux
  compatibility has not been verified.
- The artwork in the repository/release is branding and is not loaded by the
  script at runtime.

## Credits

Credits and attributions are in [README.md](README.md).
