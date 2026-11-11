# Getting started

These steps are written for someone installing a MacroQuest Lua script for the
first time.

## Before installing

The runner goes in the MacroQuest `lua` folder (usually `<MacroQuest folder>\lua`).

Make sure your MacroQuest setup already has:

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

This download contains the LDoN runner and its optional shrink helper. It does
not install plugins,
MacroQuest, navmeshes, or in-game abilities. Follow the installation
instructions for those projects separately.

## Windows installation

1. Download `LDON-Triune-v1.5.0-rc.1-windows.zip` from the GitHub release.
   The release notes list its SHA-256 checksum in plain text.
2. Before extracting, compare the published checksum with the checksum of your
   downloaded file. The release includes `SHA256SUMS.txt`; on Windows, you can
   calculate the local checksum in PowerShell with:

   ```powershell
   Get-FileHash .\LDON-Triune-v1.5.0-rc.1-windows.zip -Algorithm SHA256
   ```

   `Get-FileHash` prints capital letters and the release notes use lower case,
   which makes no difference. Every character must otherwise match. If one does
   not, download the file again.
3. Right-click the ZIP and choose **Extract All...**.
4. Open the extracted `LDON-Triune-v1.5.0-rc.1` folder.
5. Copy `LDON_Triune.lua` into the `lua` folder inside your MacroQuest
   installation. For example:

   ```text
   C:\MacroQuest\lua\LDON_Triune.lua
   ```

   If your MacroQuest folder is somewhere else, use that installation's `lua`
   folder instead. Do not copy the whole extracted folder into `lua`; copy the
   `.lua` file itself. In a group, every box needs the runner too. You only press
   Start on one character, and it starts the runner on the others for you.
   For optional **Shrink once on every zone entry**, also copy
   `ldon_shrink.lua` alongside the runner on every box. The option defaults off;
   group boxes require connected BoxNet with peer slash commands enabled.
6. In game, open the MacroQuest console and enter:

   ```text
   /lua run LDON_Triune
   ```

7. Configure the campaign in the window that opens. You can start anywhere: in
   a supported LDoN camp or instance the runner starts right there, and from any
   other zone it travels to your first camp using Bazaar and Back and the Magus.
   For a group, press **Group roles...** first and choose your Main Tank, Main
   Assist and Puller, then press Start on one character only.

The included `GUIDE.md`, `CHANGELOG.md`, and `artwork` folder are reference
materials. They do not need to be copied into MacroQuest's `lua` folder.

## Linux archive

The file `LDON-Triune-v1.5.0-rc.1-linux.tar.gz` can be extracted with a desktop
archive utility or the command below. Its SHA-256 checksum is listed in the
release notes and `SHA256SUMS.txt`.

Compare it with the checksum of your downloaded archive before extracting. Put
`SHA256SUMS.txt` from the release beside the archive, then run:

```sh
tr -d '\r' < SHA256SUMS.txt | sha256sum -c --ignore-missing
tar -xzf LDON-Triune-v1.5.0-rc.1-linux.tar.gz
```

The extracted folder has the same contents as the Windows ZIP. Copy
`LDON_Triune.lua` into the `lua` directory of the MacroQuest installation you
use. The archive format is supported on Linux, but the EverQuest/MacroQuest
runtime is Windows software and Linux/Wine compatibility is not verified by
this project.

## Start, pause, and get help

In game:

```text
/lua run LDON_Triune
/ldon help
```

Useful commands:

| Command | What it does |
| --- | --- |
| `/ldon help` | List the commands in chat |
| `/ldon ui` | Ask the runner window to show. Closing the window exits the runner, so after closing it use `/lua run LDON_Triune` |
| `/ldon start` or `/ldon resume` | Start or resume the campaign |
| `/ldon pause` or `/ldon stop` | Pause the runner; the window stays open |
| `/ldon finish` | Stop after the current dungeon, back at camp |
| `/ldon exit` | Stop and close the runner |
| `/ldon status` | Show state and a run summary |
| `/ldon preflight` | Check plugins, Triune, navmeshes and enabled extras |
| `/ldon diagnostics` | Open navigation diagnostics |
| `/ldon save` | Save settings for this character |
| `/ldon roles` | Open or close the Group Roles window |
| `/ldon roles apply` | Send your group roles to every box right now |
| `/ldon mt <name>` or `same` | Set the Main Tank, or make it the same as the Main Assist |
| `/ldon ma <name>` | Set the Main Assist |
| `/ldon puller <name>` or `same` | Set the Puller, or make it the same as the Main Assist |
| `/ldon pullers add <name>`, `remove <name>` or `clear` | Add or remove extra pullers, who also run Puller - Hunt. With no arguments it lists them |
| `/ldon solo on` or `off` | Run the mission with this character only while staying grouped, leaving the boxes alone |
| `/ldon type <number>` | Set the mission type by its number in the dropdown (1 Random, 2 Single Boss, 3 Mob count, 4 Collection, 5 Rescue) for the camp leg in progress. Before a campaign starts, use the window's **Task type** column instead, because this command may change a different camp's row |
| `/ldon difficulty normal` or `hard` | Set the adventure risk |
| `/ldon swarm on` or `off` | Turn Swarm Pull on or off |
| `/ldon record start`, `save <key>`, `play <key>` | Record and test an MQ2AdvPath route |

Five mission types are in the window's **Task type** dropdown: Random, Single Boss,
Mob count, Collection and Rescue. Hard mob-count missions are the default and are
the most hands-off. Before requesting, the runner checks your choice against the
recruiter's list and will not request if it cannot confirm it. Other objectives may
need you to step in, and Random can give you one the runner does not know how to
finish, so your character may stand idle until you take over.

When a campaign finishes, choose the next camps and press **Start campaign**;
you do not need to restart the Lua. An unfinished adventure keeps its owning
camp when starting or resuming.

## If it does not start

- Confirm the file is named exactly `LDON_Triune.lua` and is in MacroQuest's
  `lua` folder.
- Run `/ldon preflight` to check plugins, Triune and navmeshes.
- For a group, run `/ac net peers` and confirm every box is listed.
- Starting outside LDoN uses Bazaar and Back AA 331 to reach the first camp. A
  solo run needs the AA to start at all. A group without it should start from a
  supported camp or LDoN instance.
- Use `/ldon status` and `/ldon diagnostics` to see runner/navigation status.
- Check the MacroQuest console for `[LDON]` messages.
- For grouped play, press Start on one character only. If you see a red
  `Cannot bind /ldon`, an older copy is still running: use `/ldon exit` on that
  character and start again.
- For solo return behavior, make sure the required Bazaar and Back AA is
  available.

If you report an issue, include the zone, whether the run is solo or grouped,
the relevant `[LDON]` console output, and a description of the step where it
stopped. Do not post account credentials or other private information.

## Credits

Credits and attributions are in [README.md](README.md).
