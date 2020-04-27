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
    }
    
    @IBOutlet weak var switchIntervalPopUp: NSPopUpButton!
    
    // Doubling Back
    @IBOutlet weak var form1Check: NSButton!
    
    // Coupling
    @IBOutlet weak var form2Check: NSButton!
    
    // Between You and I
    @IBOutlet weak var form3Check: NSButton!
    
    // Leaving
    @IBOutlet weak var form4Check: NSButton!
    
    private func close() {
        guard let window = view.window else { return }
        window.endSheet(window)
    }
    
    @IBAction func cancelButtonTapped(_ sender: NSButton) {
        close()
    }
    
    @IBAction func okButtonTapped(_ sender: NSButton) {
        var enabledForms = [Int]()
        if form1Check.state == .on { enabledForms.append(1) }
        if form2Check.state == .on { enabledForms.append(2) }
        if form3Check.state == .on { enabledForms.append(3) }
        if form4Check.state == .on { enabledForms.append(4) }
        defaultsManager.enabledForms = enabledForms
        defaultsManager.switchInterval = switchIntervalPopUp.selectedTag()
        close()
    }
}
