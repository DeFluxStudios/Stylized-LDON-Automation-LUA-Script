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
   Its SHA-256 checksum is:
   98a2f9aca51230431a739a1476a82e95108f22912e9662eca260724ad31173d4
2. Before extracting, compare the checksum above with the checksum of your
   downloaded file. The release includes `SHA256SUMS.txt`; on Windows, you can
   calculate the local checksum in PowerShell with:

   ```powershell
   Get-FileHash .\LDON-Triune-v1.3.2-windows.zip -Algorithm SHA256
   ```

   The hash must match exactly. If it does not, download the file again.
3. Right-click the ZIP and choose **Extract All...**.
4. Open the extracted `LDON-Triune-v1.3.2` folder.
5. Copy `LDON_Triune.lua` into the `lua` folder inside your MacroQuest
   installation. For example:

   ```text
   C:\MacroQuest\lua\LDON_Triune.lua
   ```

   If your MacroQuest folder is somewhere else, use that installation's `lua`
   folder instead. Do not copy the whole extracted folder into `lua`; copy the
   `.lua` file itself.
6. In game, open the MacroQuest console and enter:

   ```text
   /lua run LDON_Triune
   ```

7. Configure the campaign in the window that opens. Start at a supported LDoN
   hub or inside an LDoN instance. For a group, start from the group leader's
   character.

The included `GUIDE.md`, `CHANGELOG.md`, and `artwork` folder are reference
materials. They do not need to be copied into MacroQuest's `lua` folder.

## Linux archive

The file `LDON-Triune-v1.3.2-linux.tar.gz` can be extracted with a desktop
archive utility or with. Its SHA-256 checksum is:

fcc98ec50ebbd50467bdd3e150f5ed26e64c0db9e0e289e142972e61ade10354

Compare it with the checksum of your downloaded archive before extracting.
The release includes `SHA256SUMS.txt`. You can verify from a terminal with:

```sh
sha256sum -c SHA256SUMS.txt
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
