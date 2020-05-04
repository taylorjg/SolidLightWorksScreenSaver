//
//  MyMTKView.swift
//  SolidLightWorksApp
//
//  Created by Administrator on 04/05/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Cocoa
import MetalKit
import Carbon.HIToolbox.Events

class MyMTKView: MTKView {
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_ANSI_F:
            print("Switch form")
            break
        case kVK_ANSI_P:
            print("Switch camera pose")
            break
        case kVK_ANSI_2:
            print("Render 2D drawings")
            break
        case kVK_ANSI_3:
            print("Render 3D projections")
            break
        case kVK_ANSI_A:
            print("Toggle axes helpers")
            break
        case kVK_ANSI_V:
            print("Toggle vertex normal helpers")
            break
        default:
            break
        }
    }
}
