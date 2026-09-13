# Building

[← Back to README](../README.md)

## Requirements

- Windows with PowerShell 5.1 or newer
- [Arma 3 Tools](https://store.steampowered.com/app/233800/Arma_3_Tools/)
  (optional for building — used to binarise configs and sign; required to
  regenerate textures)
- Python 3 with [Pillow](https://pypi.org/project/pillow/) (only to regenerate
  textures)

No P: drive and no third-party packer are needed.

## Build

```powershell
.\tools\build.ps1
```

Output lands in `release\@TLB Interactions`:

```
@TLB Interactions/
  addons/
    tlbi_main.pbo
    tlbi_defusal.pbo
    tlbi_lockpick.pbo
    tlbi_lockpick_items.pbo
  mod.cpp
  LICENSE
  README.md
```

What the script does:

1. Stages every folder under `addons/` that has a `$PBOPREFIX$` file. All addons
   are staged before any is compiled, because components include headers from
   each other (defusal takes its version from main).
2. If Arma 3 Tools' **CfgConvert** is found, binarises each `config.cpp` to
   `config.bin` and fails the build if a config doesn't compile. A config that uses
   `__has_include` is left as `config.cpp`, so the check happens on the player's
   machine. Without Arma 3 Tools every config ships as `config.cpp`, which the
   engine reads fine.
3. Writes each PBO with its built-in packer: a `Vers` header carrying the prefix,
   one entry per file, the data, and a trailing SHA1 checksum. Development
   leftovers (`*.md`, `*.bak`, `*.psd`, `*.tmp`, keys, PBOs) are excluded.
4. Copies `mod.cpp`, `LICENSE` and `README.md` into the release folder.

**Arma must be closed** while building if the game has the release folder
loaded — Windows keeps the PBOs locked.

### Options

```powershell
# build and copy straight into a mod folder
.\tools\build.ps1 -Deploy "E:\SteamLibrary\steamapps\common\Arma 3\!Workshop"

# build and sign, for servers that verify signatures
.\tools\build.ps1 -Sign -KeyName tlbi_1.0.0

# skip binarising configs
.\tools\build.ps1 -NoBinarize
```

Signing creates `<KeyName>.biprivatekey` in the repository root on first use (it
is git-ignored — **never commit it**) and puts the public `.bikey` in the release
`keys` folder.

## Regenerating textures

All textures are generated; none are hand-painted.

```powershell
python tools\gen_assets.py           # defusal boards  -> addons\defusal\data
python tools\gen_lockpick_assets.py  # lockpicking     -> addons\lockpick\data
python tools\gen_item_icons.py       # stand-in items  -> addons\lockpick_items\data
```

Each writes PNGs to a git-ignored folder under `tools/` and converts them with
ImageToPAA. Only power-of-two sizes convert.

### Layout previews

Judge layout changes without launching the game. The previews use the same
layout fractions as the SQF drawing code:

```powershell
python tools\preview_board.py     # IED board             -> tools\.preview\board.png
python tools\preview_types.py     # mine and tripwire     -> tools\.preview\
python tools\preview_lockpick.py  # lockpicking views     -> tools\.preview\lockpick.png
```

## Repository layout

```
addons/
  main/                  mod identity, version, logo
  defusal/
    data/                generated PAA textures
    functions/           fn_*.sqf, registered through CfgFunctions
    gui/                 control styles and the board dialog
    config.cpp
    script_component.hpp shared constants (IDCs, state layouts, difficulty macros)
    stringtable.xml
  lockpick/
    data/                generated PAA textures
    functions/           board, techniques, tsp_breach takeover, door system
    gui/                 lockpicking dialog
    config.cpp
    script_component.hpp
    stringtable.xml
  lockpick_items/        stand-in Lock Pick Kit and Paperclip (unbinarised config)
docs/                    this documentation
tools/
  build.ps1              packer and release builder
  gen_assets.py          defusal texture generator
  gen_lockpick_assets.py lockpicking texture generator
  gen_item_icons.py      item icon generator
  preview_*.py           offline layout previews
mod.cpp                  launcher entry
LICENSE                  APL-ND
```

## Conventions

- Functions are one file each, `fn_<name>.sqf`, with a header comment giving
  author, purpose, arguments and return value, and are registered in the addon's
  `CfgFunctions`.
- Every player-facing string lives in the addon's `stringtable.xml`.
- ACE is used only through public functions, events and interact-menu actions —
  never by overriding its functions (they are `compileFinal`) or re-opening its
  config classes.
- Any new visual goes through a generator script as a texture; controls are not
  rotated at runtime.
