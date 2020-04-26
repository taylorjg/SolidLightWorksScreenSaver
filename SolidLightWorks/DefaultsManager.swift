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

private let DEFAULTS: [String: Any] = [
    KEY_ENABLED_FORMS: [1, 2, 3, 4],
    KEY_SWITCH_INTERVAL: 30
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
}
