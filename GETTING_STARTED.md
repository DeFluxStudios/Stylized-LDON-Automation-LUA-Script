# Getting started

These steps are written for someone installing a MacroQuest Lua script for the
first time.

## Before installing

Make sure your MacroQuest setup already has:

- MacroQuest running for EverQuest
- The MacroQuest `lua` folder (usually `<MacroQuest folder>\lua`)
- MQ2Nav and MQ2MoveUtils loaded, with navmeshes for the routes you intend to
  use
- Triune AutoCombat installed and working
- BoxNet available if you want automatic setup of remote group characters

This download contains the LDoN runner only. It does not install plugins,
MacroQuest, navmeshes, or in-game abilities. Follow the installation
instructions for those projects separately.

## Windows installation

1. Download `LDON-Triune-v1.3.2-windows.zip` from the GitHub release.
2. Right-click the ZIP and choose **Extract All...**.
3. Open the extracted `LDON-Triune-v1.3.2` folder.
4. Copy `LDON_Triune.lua` into the `lua` folder inside your MacroQuest
   installation. For example:

   ```text
   C:\MacroQuest\lua\LDON_Triune.lua
   ```

   If your MacroQuest folder is somewhere else, use that installation's `lua`
   folder instead. Do not copy the whole extracted folder into `lua`; copy the
   `.lua` file itself.
5. In game, open the MacroQuest console and enter:

   ```text
   /lua run LDON_Triune
   ```

6. Configure the campaign in the window that opens. Start at a supported LDoN
   hub or inside an LDoN instance. For a group, start from the group leader's
   character.

The included `GUIDE.md`, `CHANGELOG.md`, and `artwork` folder are reference
materials. They do not need to be copied into MacroQuest's `lua` folder.

## Linux archive

The file `LDON-Triune-v1.3.2-linux.tar.gz` can be extracted with a desktop
archive utility or with:

```sh
tar -xzf LDON-Triune-v1.3.2-linux.tar.gz
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
| `/ldon start` | Start the configured campaign |
| `/ldon status` | Show runner status |
| `/ldon pause` | Pause the runner |
| `/ldon resume` | Resume the runner |
| `/ldon exit` | Stop and unload the runner |
| `/ldon ui` | Reopen the runner window |
| `/ldon diagnostics` | Open navigation diagnostics |
| `/ldon ma <character name>` | Set the Main Assist / puller |
| `/ldon type <option>` | Set a mission request option |

Use the in-game dropdown when available to choose a mission type. The current
release is configured for hard mob-count missions by default.

## If it does not start

- Confirm the file is named exactly `LDON_Triune.lua` and is in MacroQuest's
  `lua` folder.
- Confirm MacroQuest, MQ2Nav, MQ2MoveUtils, and Triune AutoCombat are loaded.
- Start in a supported campaign hub or LDoN instance.
- Use `/ldon status` and `/ldon diagnostics` to see runner/navigation status.
- Check the MacroQuest console for `[LDON]` messages.
- For grouped play, keep characters together and start from the group leader.
- For solo return behavior, make sure the required Bazaar and Back AA is
  available.

If you report an issue, include the zone, whether the run is solo or grouped,
the relevant `[LDON]` console output, and a description of the step where it
stopped. Do not post account credentials or other private information.
