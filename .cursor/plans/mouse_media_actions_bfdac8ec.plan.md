---
name: Mouse media actions
overview: Extend mouse button shortcuts so each button can fire either a keyboard shortcut or a media action (radial media keys plus volume up/down), with mutually exclusive UI controls in Mouse settings.
todos:
  - id: model-storage
    content: Add MouseButtonMediaAction + MouseButtonAction; retarget encode/decode/claims in MouseButtonShortcutSupport
    status: completed
  - id: aux-helper
    content: Extract MediaAuxKeySupport; wire RadialMenuService and MouseButtonShortcutService fire paths
    status: completed
  - id: settings-ui
    content: Add exclusive Media menu beside Set shortcut in MouseButtonSettings mapping rows
    status: completed
  - id: strings
    content: Add mouse-button media/volume strings and update captions across locales
    status: completed
  - id: tests
    content: Update PointerInputFeatureTests for tagged storage and media actions
    status: completed
isProject: false
---

# Mouse button media actions

## Approach

Keep the existing `mouseButtonShortcuts` `[String: String]` dictionary. Values stay either:
- keyboard: current `GlobalShortcut.storageValue` (`option:103`)
- media: `media:<action>` (e.g. `media:volumeDown`, `media:playPause`)

Old configs keep working. Unknown/invalid values are still dropped on decode.

Per-button binding becomes a tagged union; the settings row shows **Set shortcut** and a **Media** menu side by side, and choosing one clears the other.

## Data model

In [`MouseButtonShortcutSupport.swift`](Sources/Vorssaint/Services/MouseButtons/MouseButtonShortcutSupport.swift):

- Add `MouseButtonMediaAction: String, CaseIterable` with:
  - radial-aligned: `playPause`, `previousTrack`, `nextTrack`, `nowPlaying`
  - new: `volumeUp`, `volumeDown`
- Add `MouseButtonAction`:
  - `case shortcut(GlobalShortcut)`
  - `case media(MouseButtonMediaAction)`
- Change encode/decode / `firesShortcut` / claims helpers to use `[Int64: MouseButtonAction]`
- Decode order: if value has prefix `media:`, parse action raw value; else parse `GlobalShortcut`
- Encode media as `"media:" + rawValue`

Do **not** add volume cases to `RadialMenuMediaKey` (avoids changing the radial menu picker). Map play/pause/next/prev aux codes to the same integers radial already uses (16 / 20 / 19); volume uses `PreciseVolumeMediaKey` codes (`0` / `1`).

## Shared media posting

Extract the private aux posting from [`RadialMenuService.swift`](Sources/Vorssaint/Services/RadialMenu/RadialMenuService.swift) into a small shared helper (e.g. [`MediaAuxKeySupport.swift`](Sources/Vorssaint/Services/Audio/MediaAuxKeySupport.swift) next to precise-volume support):

- `postPress(auxKeyType: Int32)` — down then up, same `NSEvent.otherEvent` subtype-8 packing radial uses today
- Point `RadialMenuService.postMediaKey` at this helper (behavior unchanged)

[`MouseButtonShortcutService`](Sources/Vorssaint/Services/MouseButtons/MouseButtonShortcutService.swift):

- Store `mappings: [Int64: MouseButtonAction]`
- On fire, switch:
  - `.shortcut` → existing keyboard `post(_:)`
  - `.media` with aux type → `MediaAuxKeySupport.postPress`
  - `.media(.nowPlaying)` → `RadialNowPlayingService.shared.presentDetails(at: NSEvent.mouseLocation)` (same card as radial, anchored at the pointer)

## Settings UI

In [`MouseButtonSettings.swift`](Sources/Vorssaint/UI/Settings/MouseButtonSettings.swift) `mappingRow`:

```
[Button name] ………… [Set shortcut] [Media ▾] [×]
```

- Keep `ShortcutRecorderButton` as today
- Add a compact `Menu` (same control size as nearby settings menus) listing all `MouseButtonMediaAction` cases
- Label behavior:
  - no media → placeholder like “Media key”
  - media selected → selected action title
- Mutual exclusion on save:
  - recording a shortcut → store `.shortcut`, clear media
  - picking a media item → store `.media`, clear shortcut
- Remove still clears the whole mapping
- Pending “add button” rows work the same once either control is chosen

## Strings

[`MouseButtonStrings.swift`](Sources/Vorssaint/Core/MouseButtonStrings.swift) (+ all locales in that file):

- media menu placeholder / accessibility
- `volumeUp` / `volumeDown` labels
- Reuse radial labels for play/pause/prev/next/now playing via `FeatureStrings.radialMenu` (or thin wrappers) so wording stays consistent
- Soften hub/enable captions that currently say only “key combination” so they cover media too (enUS + other locales in the same file)

## Tests

Update [`PointerInputFeatureTests.swift`](Tests/PointerInputFeatureTests.swift):

- encode/decode round-trip for shortcut and `media:*` values
- invalid `media:foo` dropped; legacy shortcut strings still decode
- fire path conceptually covered via support helpers (`fires…` returns media action)
- keep existing shortcut/side-wheel cases compiling against the new action type

Add a small unit check that volume/play aux types match the known codes (`0`/`1`/`16`/`19`/`20`).

## Out of scope

- Adding volume slices to the radial menu itself
- Mute (not requested)
- New UserDefaults keys or export format beyond richer string values in the existing dict
