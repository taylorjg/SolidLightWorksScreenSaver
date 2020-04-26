//
//  ConfigSheetViewController.swift
//  SolidLightWorks
//
//  Created by Administrator on 26/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Cocoa

class ConfigSheetViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        form1Check.state = .off
        form2Check.state = .off
        form3Check.state = .off
        form4Check.state = .on
    }

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
        close()
    }
}
