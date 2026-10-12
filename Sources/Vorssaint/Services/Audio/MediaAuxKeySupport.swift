// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import CoreGraphics

/// Posts the systemDefined aux-button events physical media keys produce
/// (NX_KEYTYPE_* packed into subtype 8). Shared by the radial menu and mouse
/// button media actions.
enum MediaAuxKeySupport {
    /// A full press: key-down then key-up, the same pair a finger produces.
    static func postPress(auxKeyType: Int32) {
        postAuxKey(auxKeyType, down: true)
        postAuxKey(auxKeyType, down: false)
    }

    static func postAuxKey(_ type: Int32, down: Bool) {
        let stateFlags: NSEvent.ModifierFlags = down
            ? NSEvent.ModifierFlags(rawValue: 0xA00)
            : NSEvent.ModifierFlags(rawValue: 0xB00)
        let data1 = (Int(type) << 16) | ((down ? 0xA : 0xB) << 8)
        guard let event = NSEvent.otherEvent(with: .systemDefined,
                                             location: .zero,
                                             modifierFlags: stateFlags,
                                             timestamp: ProcessInfo.processInfo.systemUptime,
                                             windowNumber: 0,
                                             context: nil,
                                             subtype: 8,
                                             data1: data1,
                                             data2: -1)
        else { return }
        event.cgEvent?.post(tap: .cghidEventTap)
    }
}
