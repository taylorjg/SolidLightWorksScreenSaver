//
//  DefaultsManager.swift
//  SolidLightWorks
//
//  Created by Administrator on 26/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation
import ScreenSaver

private let KEY_ENABLED_FORMS = "enabled-forms"
private let KEY_SWITCH_INTERVAL = "switch-interval"
private let KEY_RENDER_MODE = "render-mode"

private func renderModeToInt(_ renderMode: RenderMode) -> Int {
    switch renderMode {
    case .drawing2D: return 0
    case .projection3D: return 1
    }
}

private func intToRendeMode(_ int: Int) -> RenderMode {
    switch int {
    case 0: return .drawing2D
    case 1: return .projection3D
    default: fatalError("Unknown render mode int \(int)")
    }
}

private let DEFAULTS: [String: Any] = [
    KEY_ENABLED_FORMS: Settings.defaultEnabledForms,
    KEY_SWITCH_INTERVAL: Settings.defaultSwitchInterval,
    KEY_RENDER_MODE: renderModeToInt(Settings.defaultRenderMode)
]

class DefaultsManager {
    
    let screenSaverDefaults: ScreenSaverDefaults
    
    init() {
        let identifier = Bundle(for: ConfigSheetViewController.self).bundleIdentifier!
        screenSaverDefaults = ScreenSaverDefaults.init(forModuleWithName: identifier)!
        screenSaverDefaults.register(defaults: DEFAULTS)
    }
    
    var switchInterval: Int {
        get {
            return screenSaverDefaults.integer(forKey: KEY_SWITCH_INTERVAL)
        }
        set {
            screenSaverDefaults.set(newValue, forKey: KEY_SWITCH_INTERVAL)
            screenSaverDefaults.synchronize()
        }
    }
    
    var enabledForms: [Int] {
        get {
            let array = screenSaverDefaults.array(forKey: KEY_ENABLED_FORMS) ?? []
            return array.map { el in el as! Int }
        }
        set {
            screenSaverDefaults.set(newValue, forKey: KEY_ENABLED_FORMS)
            screenSaverDefaults.synchronize()
        }
    }
    
    var renderMode: RenderMode {
        get {
            let int = screenSaverDefaults.integer(forKey: KEY_RENDER_MODE)
            return intToRendeMode(int)
        }
        set {
            let int = renderModeToInt(newValue)
            screenSaverDefaults.set(int, forKey: KEY_RENDER_MODE)
            screenSaverDefaults.synchronize()
        }
    }
}
