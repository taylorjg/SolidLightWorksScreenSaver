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
    
    var keyboardControlDelegate: KeyboardControlDelegate?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_ANSI_F:
            keyboardControlDelegate?.onSwitchForm()
            break
        case kVK_ANSI_P:
            keyboardControlDelegate?.onSwitchCameraPose()
            break
        case kVK_ANSI_2:
            keyboardControlDelegate?.onSelect2DDrawingMode()
            break
        case kVK_ANSI_3:
            keyboardControlDelegate?.onSelect3DProjectionMode()
            break
        case kVK_ANSI_A:
            keyboardControlDelegate?.onToggleAxesHelpers()
            break
        case kVK_ANSI_V:
            keyboardControlDelegate?.onToggleVertexNormalsHelpers()
            break
        default:
            break
        }
    }
}
