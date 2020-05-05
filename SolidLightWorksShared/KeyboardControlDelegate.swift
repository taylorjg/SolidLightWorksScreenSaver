//
//  KeyboardControlDelegate.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 04/05/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

protocol KeyboardControlDelegate {
    func onSwitchForm()
    func onSwitchCameraPose()
    func onToggleRenderMode()
    func onToggleAxesHelpers()
    func onToggleVertexNormalsHelpers()
}
