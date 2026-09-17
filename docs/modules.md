# Modules

[← Back to README](../README.md)

Two modules let mission makers configure explosives and doors without changing
the server settings: Eden modules for an area, and Zeus modules for one explosive
or door in a live mission. The Eden modules are under **Systems (F5) →
Modules → TLB Interactions**.

The Eden modules work by **area**. Place the module, then resize its area (circle or
rectangle) over the building, compound or stretch of road you want to change.
Everything inside the area uses the module's options, and any option left on
*Use settings* keeps the CBA setting. Where two areas overlap, the smaller one
wins, so a small module over one building can refine a large one over a whole
town. Height is ignored.

- [Explosive settings](#explosive-settings)
- [Lock settings](#lock-settings)
- [Zeus modules](#zeus-modules)

---

## Explosive settings

Applies to every explosive inside the area, including explosives placed later in
the mission.

| Option | Values | Effect |
| --- | --- | --- |
| Procedure | Automatic, IED, Mine, Tripwire | Forces the procedure. *Automatic* uses the class lists and automatic detection. |
| Difficulty | Use settings, Easy, Normal, Hard, Expert | Replaces the defusal *Difficulty* setting for these explosives. |
| IED burial | Use settings, Buried, Not buried | Whether IEDs start under soil. |
| Tripwire grass | Use settings, Grass, No grass | Without grass the wire is visible from the start, and you go straight to tension, pins and the cut. |
| Tripwire branch | Use settings, Always, Never | Whether a tripwire leads to a second device. |
| Auto-clear dirt and grass | Use settings, On, Off | Whether soil, rim cells and grass clear themselves. |

The options are applied when a device's board is first opened. A device someone
has already started keeps what it was built with.

**Example: tripwires inside a building without grass.** Place *Explosive
settings* over the building and set *Tripwire grass* to *No grass*. To do this for
every building on the map, turn off *Grass on tripwires inside buildings* in the
[settings](settings.md#interactive-defusal---tripwires) instead.

## Lock settings

Applies to every door whose handle is inside the area, with or without
tsp_breach.

| Option | Values | Effect |
| --- | --- | --- |
| Lock at mission start | Leave as it is, Locked, Unlocked | Locks or unlocks these doors a few seconds into the mission, after random door locking has run. |
| Can be picked | Yes, No | *No* makes the lock unpickable. The door has to be opened another way. |
| Technique | Random, Pin tumbler, Rake, Sweet spot | Forces the technique for both tools. |
| Door class | From building type, Civilian, Military, Reinforced | Overrides the building lists, which sets the pin count and how tight the windows are. |
| Difficulty with a lock pick kit | Use settings, Very easy to Expert | Replaces the technique's kit difficulty. |
| Difficulty with a paperclip | Use settings, Very easy to Expert | Replaces the technique's paperclip difficulty. |

The technique's sliders from its settings page still apply on top.

**Example: a locked armoury with a hard lock.** Place *Lock settings* with a
small area over the armoury door. Set *Lock at mission start* to *Locked*,
*Technique* to *Sweet spot*, and both difficulties to *Hard*.

## Zeus modules

For a live mission, both modules are also available in Zeus under
**Modules → TLB Interactions**. They need
[Zeus Enhanced](https://steamcommunity.com/workshop/filedetails/?id=1779063631).

Unlike the Eden modules, a Zeus module configures **one** object:

- **Explosive settings:** place it on an explosive (or within 3 m of it). A dialog
  opens with the same options as the Eden module, plus **Rebuild the device**.
  Difficulty and auto-clear apply the next time the device is opened. Procedure,
  burial, grass and branch shape the device when it is built, so leave *Rebuild
  the device* ticked for them to apply to a device someone has already opened.
  Rebuilding loses any progress on it.
- **Lock settings:** place it on a door handle (or within 4 m of it). The lock
  state is applied straight away, and the other options are used the next time
  the lock is picked.

The same dialogs are in the Zeus **context menu** (right-click, or <kbd>V</kbd> by
default): point at an explosive and choose **Explosive settings**, or point at a
door and choose **Lock settings**. The entries only appear when there is an
explosive or door handle under the cursor.

Zeus settings are stored on the explosive or door and win over any Eden module
covering it. Place the module again to change them; choose *Use settings* to
clear an option.
