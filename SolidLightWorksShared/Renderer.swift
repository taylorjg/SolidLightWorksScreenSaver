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

let screenGrey = Float(0xc0) / Float(0xff)
let screenColor = simd_float4(screenGrey, screenGrey, screenGrey, 0.2)

let screenVertices = [
    FlatVertex(position: simd_float3(-8, 0, 0), color: screenColor),
    FlatVertex(position: simd_float3(8, 0, 0), color: screenColor),
    FlatVertex(position: simd_float3(-8, 6, 0), color: screenColor),
    FlatVertex(position: simd_float3(-8, 6, 0), color: screenColor),
    FlatVertex(position: simd_float3(8, 0, 0), color: screenColor),
    FlatVertex(position: simd_float3(8, 6, 0), color: screenColor)
]

let xAxisColor = simd_float4(1, 0, 0, 1)
let yAxisColor = simd_float4(0, 1, 0, 1)
let zAxisColor = simd_float4(0, 0, 1, 1)

let axesVertices = [
    FlatVertex(position: simd_float3(0, 0, 0), color: xAxisColor),
    FlatVertex(position: simd_float3(8, 0, 0), color: xAxisColor),
    FlatVertex(position: simd_float3(0, 0, 0), color: yAxisColor),
    FlatVertex(position: simd_float3(0, 6, 0), color: yAxisColor),
    FlatVertex(position: simd_float3(0, 0, 0), color: zAxisColor),
    FlatVertex(position: simd_float3(0, 0, 8), color: zAxisColor),
    FlatVertex(position: simd_float3(0, 0, 0), color: simd_float4(1, 1, 0, 1)),
    FlatVertex(position: simd_float3(0, 0, -8), color: simd_float4(1, 1, 0, 1))
]

class Renderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let flatPipelineState: MTLRenderPipelineState
    let line2DPipelineState: MTLRenderPipelineState
    let membranePipelineState: MTLRenderPipelineState
    var installations = [Installation]()
    var installationIndex = 0
    let renderAxes = false
    let render2D = false
    let hazeTexture: MTLTexture
    var viewMatrix: matrix_float4x4
    var projectionMatrix: matrix_float4x4
    
    init?(mtkView: MTKView,
          bundle: Bundle? = nil,
          enabledForms: [Int] = [1, 2, 3, 4],
          switchInterval: Int = 30) {
        mtkView.sampleCount = 4
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
        
        viewMatrix = matrix_float4x4()
        projectionMatrix = matrix_float4x4()
        
        if enabledForms.contains(1) { installations.append(DoublingBackInstallation()) }
        if enabledForms.contains(2) { installations.append(CouplingInstallation()) }
        if enabledForms.contains(3) { installations.append(BetweenYouAndIInstallation()) }
        if enabledForms.contains(4) { installations.append(LeavingInstallation()) }
        
        if enabledForms.isEmpty {
            installations.append(BetweenYouAndIInstallation())
        }
        
        super.init()
        
        // switchInstallation(switchInterval: switchInterval)
        switchInstallation(switchInterval: 5)
    }
    
    private func switchInstallation(switchInterval: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(switchInterval)) {
            self.installationIndex = (self.installationIndex + 1) % self.installations.count
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
        pipelineDescriptor.sampleCount = 4
        
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
    
    private func renderAxes(renderEncoder: MTLRenderCommandEncoder) {
        var flatUniforms = FlatUniforms()
        flatUniforms.modelViewMatrix = viewMatrix
        flatUniforms.projectionMatrix = projectionMatrix
        let flatUniformsLength = MemoryLayout<FlatUniforms>.stride
        renderEncoder.pushDebugGroup("Draw Axes")
        renderEncoder.setRenderPipelineState(flatPipelineState)
        let axesVerticesLength = MemoryLayout<FlatVertex>.stride * axesVertices.count
        renderEncoder.setVertexBytes(axesVertices, length: axesVerticesLength, index: 0)
        renderEncoder.setVertexBytes(&flatUniforms, length: flatUniformsLength, index: 1)
        renderEncoder.setFragmentBytes(&flatUniforms, length: flatUniformsLength, index: 1)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: axesVertices.count)
        renderEncoder.popDebugGroup()
    }
    
    private func renderScreen(renderEncoder: MTLRenderCommandEncoder) {
        var flatUniforms = FlatUniforms()
        flatUniforms.modelViewMatrix = viewMatrix
        flatUniforms.projectionMatrix = projectionMatrix
        let flatUniformsLength = MemoryLayout<FlatUniforms>.stride
        renderEncoder.pushDebugGroup("Draw Screen")
        renderEncoder.setRenderPipelineState(flatPipelineState)
        let screenVerticesLength = MemoryLayout<FlatVertex>.stride * screenVertices.count
        renderEncoder.setVertexBytes(screenVertices, length: screenVerticesLength, index: 0)
        renderEncoder.setVertexBytes(&flatUniforms, length: flatUniformsLength, index: 1)
        renderEncoder.setFragmentBytes(&flatUniforms, length: flatUniformsLength, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: screenVertices.count)
        renderEncoder.popDebugGroup()
    }
    
    private func renderScreenFormLine(renderEncoder: MTLRenderCommandEncoder,
                                      screenForm: ScreenForm,
                                      lineIndex: Int) {
        var line2DUniforms = Line2DUniforms()
        line2DUniforms.viewMatrix = viewMatrix
        line2DUniforms.projectionMatrix = projectionMatrix
        line2DUniforms.color = simd_float4(1, 1, 1, 1)
        renderEncoder.pushDebugGroup("Draw Screen Form Line")
        renderEncoder.setRenderPipelineState(line2DPipelineState)
        let lineThickness: Float = 0.05
        let line = screenForm.lines[lineIndex]
        let (vertices, indices) = makeLine2DVertices(line.points, lineThickness)
        let verticesLength = MemoryLayout<Line2DVertex>.stride * vertices.count
        if (verticesLength <= 4096) {
            renderEncoder.setVertexBytes(vertices, length: verticesLength, index: 0)
        } else {
            let verticesBuffer = device.makeBuffer(bytes: vertices, length: verticesLength, options: [])!
            renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        }
        let line2DUniformsLength = MemoryLayout<Line2DUniforms>.stride
        line2DUniforms.modelMatrix = screenForm.transform
        renderEncoder.setVertexBytes(&line2DUniforms, length: line2DUniformsLength, index: 1)
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
                                         projectedForm: ProjectedForm,
                                         lineIndex: Int) {
        let line = projectedForm.lines[lineIndex]
        var membraneUniforms = MembraneUniforms()
        membraneUniforms.modelMatrix = projectedForm.transform
        membraneUniforms.viewMatrix = viewMatrix
        membraneUniforms.projectionMatrix = projectionMatrix
        membraneUniforms.normalMatrix = viewMatrix.upperLeft
        membraneUniforms.projectorPosition = projectedForm.projectorPosition
        // TODO: membraneUniforms.cameraPosition = cameraPose.position
        membraneUniforms.cameraPosition = simd_float3()
        let membraneUniformsLength = MemoryLayout<MembraneUniforms>.stride
        renderEncoder.pushDebugGroup("Draw Projected Form Line")
        renderEncoder.setRenderPipelineState(membranePipelineState)
        let (vertices, indices) = makeMembraneVertices(points: line.points,
                                                       projectorPosition: projectedForm.projectorPosition)
        let verticesLength = MemoryLayout<MembraneVertex>.stride * vertices.count
        let verticesBuffer = device.makeBuffer(bytes: vertices, length: verticesLength, options: [])!
        renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&membraneUniforms, length: membraneUniformsLength, index: 1)
        renderEncoder.setFragmentBytes(&membraneUniforms, length: membraneUniformsLength, index: 1)
        let indicesLength = MemoryLayout<UInt16>.stride * indices.count
        let indicesBuffer = device.makeBuffer(bytes: indices, length: indicesLength, options: [])!
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indices.count,
                                            indexType: .uint16,
                                            indexBuffer: indicesBuffer,
                                            indexBufferOffset: 0)
        renderEncoder.popDebugGroup()
    }
    
    private func renderProjectedForm(renderEncoder: MTLRenderCommandEncoder,
                                     projectedForm: ProjectedForm) {
        for lineIndex in projectedForm.lines.indices {
            renderProjectedFormLine(renderEncoder: renderEncoder,
                                    projectedForm: projectedForm,
                                    lineIndex: lineIndex)
        }
    }
    
    private func renderProjectedForms(renderEncoder: MTLRenderCommandEncoder,
                                      projectedForms: [ProjectedForm]) {
        projectedForms.forEach { projectedForm in
            renderProjectedForm(renderEncoder: renderEncoder, projectedForm: projectedForm)
        }
    }
    
    private func renderInstallation2D(renderEncoder: MTLRenderCommandEncoder, installation: Installation) {
        let installationData2D = installation.getInstallationData2D()
        let cameraPose = installationData2D.cameraPose
        viewMatrix = matrix_lookat(eye: cameraPose.position,
                                   point: cameraPose.target,
                                   up: simd_float3(0, 1, 0))
        if renderAxes {
            renderAxes(renderEncoder: renderEncoder)
        }
        renderScreenForms(renderEncoder: renderEncoder, screenForms: installationData2D.screenForms)
    }
    
    private func renderInstallation3D(renderEncoder: MTLRenderCommandEncoder, installation: Installation) {
        let installationData3D = installation.getInstallationData3D()
        let cameraPose = installationData3D.cameraPoses[0]
        viewMatrix = matrix_lookat(eye: cameraPose.position,
                                   point: cameraPose.target,
                                   up: simd_float3(0, 1, 0))
        if renderAxes {
            renderAxes(renderEncoder: renderEncoder)
        }
        renderScreen(renderEncoder: renderEncoder)
        renderScreenForms(renderEncoder: renderEncoder, screenForms: installationData3D.screenForms)
        renderProjectedForms(renderEncoder: renderEncoder, projectedForms: installationData3D.projectedForms)
    }
    
    func draw(in view: MTKView) {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let renderPassDescriptor = view.currentRenderPassDescriptor
            if let renderPassDescriptor = renderPassDescriptor,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                let installation = installations[installationIndex]
                if render2D {
                    renderInstallation2D(renderEncoder: renderEncoder, installation: installation)
                } else {
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
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65),
                                                         aspectRatio:aspect,
                                                         nearZ: 0.1,
                                                         farZ: 100.0)
    }
}
