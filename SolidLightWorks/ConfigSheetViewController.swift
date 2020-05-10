//
//  ConfigSheetViewController.swift
//  SolidLightWorks
//
//  Created by Administrator on 26/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Cocoa

class ConfigSheetViewController: NSViewController {
    
    let defaultsManager = DefaultsManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let enabledForms = defaultsManager.enabledForms
        form1Check.state = enabledForms.contains(1) ? .on : .off
        form2Check.state = enabledForms.contains(2) ? .on : .off
        form3Check.state = enabledForms.contains(3) ? .on : .off
        form4Check.state = enabledForms.contains(4) ? .on : .off
        switchIntervalPopUp.selectItem(withTag: defaultsManager.switchInterval)
        drawing2D.state = defaultsManager.renderMode == RenderMode.drawing2D ? .on : .off
        projection3D.state = defaultsManager.renderMode == RenderMode.projection3D ? .on : .off
    }
    
    // Doubling Back
    @IBOutlet weak var form1Check: NSButton!
    
    // Coupling
    @IBOutlet weak var form2Check: NSButton!
    
    // Between You and I
    @IBOutlet weak var form3Check: NSButton!
    
    // Leaving
    @IBOutlet weak var form4Check: NSButton!
    
    @IBOutlet weak var switchIntervalPopUp: NSPopUpButton!
    
    @IBOutlet weak var projection3D: NSButton!
    @IBOutlet weak var drawing2D: NSButton!
    
    @IBAction func renderModeChanged(_ sender: NSButton) {
    }
    
    @IBAction func cancelButtonTapped(_ sender: NSButton) {
        close()
    }
    
    private func close() {
        guard let window = view.window else { return }
        window.endSheet(window)
    }
    
    @IBAction func okButtonTapped(_ sender: NSButton) {
        var enabledForms = [Int]()
        if form1Check.state == .on { enabledForms.append(1) }
        if form2Check.state == .on { enabledForms.append(2) }
        if form3Check.state == .on { enabledForms.append(3) }
        if form4Check.state == .on { enabledForms.append(4) }
        defaultsManager.enabledForms = enabledForms
        defaultsManager.switchInterval = switchIntervalPopUp.selectedTag()
        defaultsManager.renderMode = drawing2D.state == .on ? RenderMode.drawing2D : RenderMode.projection3D
        close()
    }
}
