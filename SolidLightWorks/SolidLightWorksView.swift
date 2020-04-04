//
//  SolidLightWorksView.swift
//  SolidLightWorks
//
//  Created by Administrator on 25/03/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import ScreenSaver
import MetalKit

class SolidLightWorksView: ScreenSaverView {
    
    private var renderer: Renderer!
    private var mtkView: MTKView!
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        self.animationTimeInterval = 1.0/60.0
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        let subviewFrame = NSRect(origin: NSPoint.zero, size: frame.size)

        mtkView = MTKView(frame: subviewFrame, device: device)
        self.addSubview(mtkView)

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
