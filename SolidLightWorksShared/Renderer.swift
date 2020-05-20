//
//  Renderer.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 26/03/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Metal
import MetalKit
import simd

enum RenderMode {
    case animations2D
    case projections3D
}

struct Settings {
    static let defaultEnabledForms = [1, 2, 3, 4]
    static let defaultSwitchInterval = 30
    static let defaultRenderMode = RenderMode.animations2D
    static let defaultEnableMSAA = false
    
    let interactive: Bool
    let enabledForms: [Int]
    let switchInterval: Int
    let renderMode: RenderMode
    let enableMSAA: Bool
}

extension Settings {
    init() {
        interactive = true
        enabledForms = Settings.defaultEnabledForms
        switchInterval = Settings.defaultSwitchInterval
        renderMode = Settings.defaultRenderMode
        enableMSAA = true
    }
}

class Renderer: NSObject, MTKViewDelegate, KeyboardControlDelegate {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let flatPipelineState: MTLRenderPipelineState
    private let line2DPipelineState: MTLRenderPipelineState
    private let membranePipelineState: MTLRenderPipelineState
    private var installations = [Installation]()
    private var currentInstallationIndex = 0
    private var currentCameraPoseCount = 0
    private var currentCameraPoseIndex = 0
    private var renderAxesHelpers = false
    private var renderVertexNormalsHelpers = false
    private var renderMode = RenderMode.animations2D
    private let hazeTexture: MTLTexture
    private var commonUniforms = CommonUniforms()
    private let commonUniformsLength = MemoryLayout<CommonUniforms>.stride
    
    init?(mtkView: MTKView, bundle: Bundle? = nil, settings: Settings) {
        if settings.interactive ||
            settings.renderMode == .animations2D ||
            (settings.renderMode == .projections3D && settings.enableMSAA) {
            mtkView.sampleCount = 4
        }
        self.device = mtkView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        do {
            flatPipelineState = try Renderer.buildRenderPipelineState(name: "Flat",
                                                                      device: device,
                                                                      mtkView: mtkView,
                                                                      bundle: bundle)
        } catch {
            print("Unable to compile render flat pipeline state.  Error info: \(error)")
            return nil
        }
        
        do {
            line2DPipelineState = try Renderer.buildRenderPipelineState(name: "Line2D",
                                                                        device: device,
                                                                        mtkView: mtkView,
                                                                        bundle: bundle)
        } catch {
            print("Unable to compile render line2D pipeline state.  Error info: \(error)")
            return nil
        }
        
        do {
            membranePipelineState = try Renderer.buildRenderPipelineState(name: "Membrane",
                                                                          device: device,
                                                                          mtkView: mtkView,
                                                                          bundle: bundle)
        } catch {
            print("Unable to compile render membrane pipeline state.  Error info: \(error)")
            return nil
        }
        
        do {
            hazeTexture = try Renderer.loadTexture(device: device, textureName: "Haze", bundle: bundle)
        } catch {
            print("Unable to load haze texture. Error info: \(error)")
            return nil
        }
        
        self.renderMode = settings.renderMode
        
        if settings.enabledForms.contains(1) { installations.append(DoublingBackInstallation()) }
        if settings.enabledForms.contains(2) { installations.append(CouplingInstallation()) }
        if settings.enabledForms.contains(3) { installations.append(BetweenYouAndIInstallation()) }
        if settings.enabledForms.contains(4) { installations.append(LeavingInstallation()) }
        
        if settings.enabledForms.isEmpty {
            installations.append(LeavingInstallation())
        }
        
        super.init()
        
        if (!settings.interactive && installations.count > 1) {
            switchInstallation(switchInterval: settings.switchInterval)
        }
    }
    
    func onSwitchForm() {
        currentInstallationIndex = (currentInstallationIndex + 1) % installations.count
        currentCameraPoseIndex = 0
    }
    
    func onSwitchCameraPose() {
        if currentCameraPoseCount > 0 {
            currentCameraPoseIndex = (currentCameraPoseIndex + 1) % currentCameraPoseCount
        } else {
            currentCameraPoseIndex = 0
        }
    }
    
    func onToggleRenderMode() {
        switch (renderMode) {
        case .animations2D:
            renderMode = .projections3D
            break
        case .projections3D:
            renderMode = .animations2D
            break
        }
    }
    
    func onToggleAxesHelpers() {
        renderAxesHelpers = !renderAxesHelpers
    }
    
    func onToggleVertexNormalsHelpers() {
        renderVertexNormalsHelpers = !renderVertexNormalsHelpers
    }
    
    private func switchInstallation(switchInterval: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(switchInterval)) {
            self.currentInstallationIndex = (self.currentInstallationIndex + 1) % self.installations.count
            self.switchInstallation(switchInterval: switchInterval)
        }
    }
    
    class func buildRenderPipelineState(name: String,
                                        device: MTLDevice,
                                        mtkView: MTKView,
                                        bundle: Bundle?) throws -> MTLRenderPipelineState {
        let library = bundle != nil
            ? try device.makeDefaultLibrary(bundle: bundle!)
            : device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertex\(name)Shader")
        let fragmentFunction = library?.makeFunction(name: "fragment\(name)Shader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "\(name)RenderPipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.sampleCount = mtkView.sampleCount
        
        let colorAttachments0 = pipelineDescriptor.colorAttachments[0]!
        colorAttachments0.pixelFormat = mtkView.colorPixelFormat
        colorAttachments0.isBlendingEnabled = true
        colorAttachments0.rgbBlendOperation = .add
        colorAttachments0.alphaBlendOperation = .add
        colorAttachments0.sourceRGBBlendFactor = .sourceAlpha
        colorAttachments0.sourceAlphaBlendFactor = .sourceAlpha
        colorAttachments0.destinationRGBBlendFactor = .oneMinusSourceAlpha
        colorAttachments0.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    class func loadTexture(device: MTLDevice,
                           textureName: String,
                           bundle: Bundle?) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: bundle,
                                            options: textureLoaderOptions)
    }
    
    private func renderAxesHelpers(renderEncoder: MTLRenderCommandEncoder) {
        commonUniforms.modelMatrix = matrix_identity_float4x4
        let xAxisColor = simd_float4(1, 0, 0, 1)
        let yAxisColor = simd_float4(0, 1, 0, 1)
        let zAxisColor = simd_float4(0, 0, 1, 1)
        let zAxisColor2 = simd_float4(1, 1, 0, 1)
        let vertices = [
            FlatVertex(position: simd_float3(0, 0, 0), color: xAxisColor),
            FlatVertex(position: simd_float3(8, 0, 0), color: xAxisColor),
            FlatVertex(position: simd_float3(0, 0, 0), color: yAxisColor),
            FlatVertex(position: simd_float3(0, 6, 0), color: yAxisColor),
            FlatVertex(position: simd_float3(0, 0, 0), color: zAxisColor),
            FlatVertex(position: simd_float3(0, 0, 8), color: zAxisColor),
            FlatVertex(position: simd_float3(0, 0, 0), color: zAxisColor2),
            FlatVertex(position: simd_float3(0, 0, -8), color: zAxisColor2)
        ]
        let verticesLength = MemoryLayout<FlatVertex>.stride * vertices.count
        renderEncoder.pushDebugGroup("Draw Axes")
        renderEncoder.setRenderPipelineState(flatPipelineState)
        renderEncoder.setVertexBytes(vertices, length: verticesLength, index: 0)
        renderEncoder.setVertexBytes(&commonUniforms, length: commonUniformsLength, index: 1)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.popDebugGroup()
    }
    
    private func renderVertexNormalsHelpers(renderEncoder: MTLRenderCommandEncoder,
                                            vertices: [MembraneVertex],
                                            transform: matrix_float4x4) {
        commonUniforms.modelMatrix = transform
        renderEncoder.pushDebugGroup("Draw Vertex Normals")
        renderEncoder.setRenderPipelineState(flatPipelineState)
        let color = simd_float4(0, 0, 1, 1)
        let vertexNormalVertices = vertices.flatMap { vertex -> [FlatVertex] in
            let p1 = vertex.position
            let p2 = p1 + (vertex.normal * 0.2)
            return [
                FlatVertex(position: p1, color: color),
                FlatVertex(position: p2, color: color)
            ]
        }
        let vertexNormalVerticesLength = MemoryLayout<FlatVertex>.stride * vertexNormalVertices.count
        if vertexNormalVerticesLength <= 4096 {
            renderEncoder.setVertexBytes(vertexNormalVertices, length: vertexNormalVerticesLength, index: 0)
        } else {
            let verticesBuffer = device.makeBuffer(bytes: vertexNormalVertices, length: vertexNormalVerticesLength, options: [])!
            renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        }
        renderEncoder.setVertexBytes(&commonUniforms, length: commonUniformsLength, index: 1)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexNormalVertices.count)
        renderEncoder.popDebugGroup()
    }
    
    private func renderPlane(renderEncoder: MTLRenderCommandEncoder,
                             width: Float,
                             height: Float,
                             color: simd_float4,
                             transform: matrix_float4x4) {
        commonUniforms.modelMatrix = transform
        let halfWidth = width / 2
        let halfHeight = height / 2
        let vertices = [
            FlatVertex(position: simd_float3(-halfWidth, -halfHeight, 0), color: color),
            FlatVertex(position: simd_float3(halfWidth, -halfHeight, 0), color: color),
            FlatVertex(position: simd_float3(-halfWidth, halfHeight, 0), color: color),
            FlatVertex(position: simd_float3(-halfWidth, halfHeight, 0), color: color),
            FlatVertex(position: simd_float3(halfWidth, -halfHeight, 0), color: color),
            FlatVertex(position: simd_float3(halfWidth, halfHeight, 0), color: color)
        ]
        let verticesLength = MemoryLayout<FlatVertex>.stride * vertices.count
        renderEncoder.pushDebugGroup("Draw Plane")
        renderEncoder.setRenderPipelineState(flatPipelineState)
        renderEncoder.setVertexBytes(vertices, length: verticesLength, index: 0)
        renderEncoder.setVertexBytes(&commonUniforms, length: commonUniformsLength, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.popDebugGroup()
    }
    
    private func renderScreen(renderEncoder: MTLRenderCommandEncoder, screen: Screen) {
        let grey = Float(0xc0) / Float(0xff)
        let color = simd_float4(grey, grey, grey, 0.2)
        let transform = matrix4x4_translation(0, screen.height / 2, 0)
        renderPlane(renderEncoder: renderEncoder,
                    width: screen.width,
                    height: screen.height,
                    color: color,
                    transform: transform)
    }
    
    private func renderFloor(renderEncoder: MTLRenderCommandEncoder, floor: Floor) {
        let grey = Float(0xd0) / Float(0xff)
        let color = simd_float4(grey, grey, grey, 0.2)
        let rotation = matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(1, 0, 0))
        let translation = matrix4x4_translation(0, 0, floor.depth / 2)
        let transform = translation * rotation
        renderPlane(renderEncoder: renderEncoder,
                    width: floor.width,
                    height: floor.depth,
                    color: color,
                    transform: transform)
    }
    
    private func renderLeftWall(renderEncoder: MTLRenderCommandEncoder, leftWall: LeftWall) {
        let grey = Float(0xa0) / Float(0xff)
        let color = simd_float4(grey, grey, grey, 0.2)
        let rotation = matrix4x4_rotation(radians: Float.pi / 2, axis: simd_float3(0, 1, 0))
        let translation = matrix4x4_translation(-leftWall.distance, leftWall.height / 2, leftWall.length / 2)
        let transform = translation * rotation
        renderPlane(renderEncoder: renderEncoder,
                    width: leftWall.length,
                    height: leftWall.height,
                    color: color,
                    transform: transform)
    }
    
    private func renderScreenFormLine(renderEncoder: MTLRenderCommandEncoder,
                                      screenForm: ScreenForm,
                                      lineIndex: Int) {
        let line = screenForm.lines[lineIndex]
        commonUniforms.modelMatrix = screenForm.transform
        var line2DUniforms = Line2DUniforms()
        line2DUniforms.color = simd_float4(1, 1, 1, line.opacity)
        let line2DUniformsLength = MemoryLayout<Line2DUniforms>.stride
        renderEncoder.pushDebugGroup("Draw Screen Form Line")
        renderEncoder.setRenderPipelineState(line2DPipelineState)
        let lineThickness: Float = 0.05
        let (vertices, indices) = makeLine2DVertices(line.points, lineThickness)
        let verticesLength = MemoryLayout<Line2DVertex>.stride * vertices.count
        if (verticesLength <= 4096) {
            renderEncoder.setVertexBytes(vertices, length: verticesLength, index: 0)
        } else {
            let verticesBuffer = device.makeBuffer(bytes: vertices, length: verticesLength, options: [])!
            renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        }
        renderEncoder.setVertexBytes(&commonUniforms, length: commonUniformsLength, index: 1)
        renderEncoder.setFragmentBytes(&line2DUniforms, length: line2DUniformsLength, index: 1)
        let indicesLength = MemoryLayout<UInt16>.stride * indices.count
        let indicesBuffer = device.makeBuffer(bytes: indices, length: indicesLength, options: [])!
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indices.count,
                                            indexType: .uint16,
                                            indexBuffer: indicesBuffer,
                                            indexBufferOffset: 0)
        renderEncoder.popDebugGroup()
    }
    
    private func renderScreenForm(renderEncoder: MTLRenderCommandEncoder, screenForm: ScreenForm) {
        for lineIndex in screenForm.lines.indices {
            renderScreenFormLine(renderEncoder: renderEncoder,
                                 screenForm: screenForm,
                                 lineIndex: lineIndex)
        }
    }
    
    private func renderScreenForms(renderEncoder: MTLRenderCommandEncoder, screenForms: [ScreenForm]) {
        screenForms.forEach { screenForm in
            renderScreenForm(renderEncoder: renderEncoder, screenForm: screenForm)
        }
    }
    
    private func renderProjectedFormLine(renderEncoder: MTLRenderCommandEncoder,
                                         cameraPose: CameraPose,
                                         projectedForm: ProjectedForm,
                                         lineIndex: Int) {
        let line = projectedForm.lines[lineIndex]
        commonUniforms.modelMatrix = projectedForm.transform
        var membraneUniforms = MembraneUniforms()
        membraneUniforms.projectorPosition = projectedForm.projectorPosition
        membraneUniforms.worldCameraPosition = cameraPose.position
        membraneUniforms.opacity = line.opacity
        let membraneUniformsLength = MemoryLayout<MembraneUniforms>.stride
        renderEncoder.pushDebugGroup("Draw Projected Form Line")
        renderEncoder.setRenderPipelineState(membranePipelineState)
        let (vertices, indices) = makeMembraneVertices(points: line.points,
                                                       projectorPosition: projectedForm.projectorPosition)
        let verticesLength = MemoryLayout<MembraneVertex>.stride * vertices.count
        let verticesBuffer = device.makeBuffer(bytes: vertices, length: verticesLength, options: [])!
        renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&commonUniforms, length: commonUniformsLength, index: 1)
        renderEncoder.setVertexBytes(&membraneUniforms, length: membraneUniformsLength, index: 2)
        renderEncoder.setFragmentBytes(&membraneUniforms, length: membraneUniformsLength, index: 0)
        renderEncoder.setFragmentTexture(hazeTexture, index: 0)
        let indicesLength = MemoryLayout<UInt16>.stride * indices.count
        let indicesBuffer = device.makeBuffer(bytes: indices, length: indicesLength, options: [])!
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indices.count,
                                            indexType: .uint16,
                                            indexBuffer: indicesBuffer,
                                            indexBufferOffset: 0)
        renderEncoder.popDebugGroup()
        if renderVertexNormalsHelpers {
            renderVertexNormalsHelpers(renderEncoder: renderEncoder,
                                       vertices: vertices,
                                       transform: projectedForm.transform)
        }
    }
    
    private func renderProjectedForm(renderEncoder: MTLRenderCommandEncoder,
                                     cameraPose: CameraPose,
                                     projectedForm: ProjectedForm) {
        for lineIndex in projectedForm.lines.indices {
            renderProjectedFormLine(renderEncoder: renderEncoder,
                                    cameraPose: cameraPose,
                                    projectedForm: projectedForm,
                                    lineIndex: lineIndex)
        }
    }
    
    private func renderProjectedForms(renderEncoder: MTLRenderCommandEncoder,
                                      cameraPose: CameraPose,
                                      projectedForms: [ProjectedForm]) {
        projectedForms.forEach { projectedForm in
            renderProjectedForm(renderEncoder: renderEncoder,
                                cameraPose: cameraPose,
                                projectedForm: projectedForm)
        }
    }
    
    private func renderInstallation2D(renderEncoder: MTLRenderCommandEncoder, installation: Installation) {
        let installationData2D = installation.getInstallationData2D()
        let cameraPose = installationData2D.cameraPose
        commonUniforms.viewMatrix = matrix_lookat(eye: cameraPose.position,
                                                  point: cameraPose.target,
                                                  up: simd_float3(0, 1, 0))
        if renderAxesHelpers {
            renderAxesHelpers(renderEncoder: renderEncoder)
        }
        renderScreenForms(renderEncoder: renderEncoder, screenForms: installationData2D.screenForms)
    }
    
    private func renderInstallation3D(renderEncoder: MTLRenderCommandEncoder, installation: Installation) {
        let installationData3D = installation.getInstallationData3D()
        currentCameraPoseCount = installationData3D.cameraPoses.count
        let cameraPose = installationData3D.cameraPoses[currentCameraPoseIndex]
        commonUniforms.viewMatrix = matrix_lookat(eye: cameraPose.position,
                                                  point: cameraPose.target,
                                                  up: simd_float3(0, 1, 0))
        if renderAxesHelpers {
            renderAxesHelpers(renderEncoder: renderEncoder)
        }
        installationData3D.screen.map { screen in
            renderScreen(renderEncoder: renderEncoder, screen: screen)
        }
        installationData3D.floor.map { floor in
            renderFloor(renderEncoder: renderEncoder, floor: floor)
        }
        installationData3D.leftWall.map { leftWall in
            renderLeftWall(renderEncoder: renderEncoder, leftWall: leftWall)
        }
        renderProjectedForms(renderEncoder: renderEncoder,
                             cameraPose: cameraPose,
                             projectedForms: installationData3D.projectedForms)
        renderScreenForms(renderEncoder: renderEncoder, screenForms: installationData3D.screenForms)
    }
    
    func draw(in view: MTKView) {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let renderPassDescriptor = view.currentRenderPassDescriptor
            if let renderPassDescriptor = renderPassDescriptor,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                let installation = installations[currentInstallationIndex]
                
                switch renderMode {
                case .animations2D:
                    renderInstallation2D(renderEncoder: renderEncoder, installation: installation)
                case .projections3D:
                    renderInstallation3D(renderEncoder: renderEncoder, installation: installation)
                }
                
                renderEncoder.endEncoding()
            }
            view.currentDrawable.map(commandBuffer.present)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width) / Float(size.height)
        commonUniforms.projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65),
                                                                        aspectRatio:aspect,
                                                                        nearZ: 0.1,
                                                                        farZ: 100.0)
    }
}
