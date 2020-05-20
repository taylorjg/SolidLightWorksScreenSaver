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
        animations2DRadio.state = defaultsManager.renderMode == RenderMode.animations2D ? .on : .off
        projections3DRadio.state = defaultsManager.renderMode == RenderMode.projections3D ? .on : .off
        enableMSAACheck.state = defaultsManager.enableMSAA ? .on : .off
        updateButtonState()
    }
    
    @IBOutlet weak var form1Check: NSButton! // Doubling Back
    @IBOutlet weak var form2Check: NSButton! // Coupling
    @IBOutlet weak var form3Check: NSButton! // Between You and I
    @IBOutlet weak var form4Check: NSButton! // Leaving
    @IBOutlet weak var switchIntervalPopUp: NSPopUpButton!
    @IBOutlet weak var animations2DRadio: NSButton!
    @IBOutlet weak var projections3DRadio: NSButton!
    @IBOutlet weak var enableMSAACheck: NSButton!
    @IBOutlet weak var okButton: NSButton!
    
    @IBAction func formCheckChanged(_ sender: NSButton) {
        updateButtonState()
    }
    
    @IBAction func renderModeChanged(_ sender: NSButton) {
        updateButtonState()
    }
    
    @IBAction func cancelButtonTapped(_ sender: NSButton) {
        close()
    }
    
    @IBAction func okButtonTapped(_ sender: NSButton) {
        defaultsManager.enabledForms = enabledForms
        defaultsManager.switchInterval = switchIntervalPopUp.selectedTag()
        defaultsManager.renderMode = animations2DRadio.state == .on
            ? RenderMode.animations2D
            : RenderMode.projections3D
        defaultsManager.enableMSAA = enableMSAACheck.state == .on
        close()
    }
    
    private func updateButtonState() {
        switchIntervalPopUp.isEnabled = enabledForms.count > 1
        if animations2DRadio.state == .on {
            enableMSAACheck.state = .on
            enableMSAACheck.isEnabled = false
        } else {
            enableMSAACheck.isEnabled = true
        }
        okButton.isEnabled = !enabledForms.isEmpty
    }
    
    private var enabledForms: [Int] {
        var enabledForms = [Int]()
        if form1Check.state == .on { enabledForms.append(1) }
        if form2Check.state == .on { enabledForms.append(2) }
        if form3Check.state == .on { enabledForms.append(3) }
        if form4Check.state == .on { enabledForms.append(4) }
        return enabledForms
    }
    
    private func close() {
        guard let window = view.window else { return }
        window.endSheet(window)
    }
}
