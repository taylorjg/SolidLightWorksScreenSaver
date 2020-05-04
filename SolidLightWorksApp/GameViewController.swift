//
//  GameViewController.swift
//  SolidLightWorksApp
//
//  Created by Administrator on 26/03/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        print(FileManager.default.temporaryDirectory)

        guard let mtkView = self.view as? MyMTKView else {
            print("View attached to GameViewController is not an instance of MyMTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice

        guard let newRenderer = Renderer(mtkView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
        mtkView.keyboardControlDelegate = renderer
    }
}
