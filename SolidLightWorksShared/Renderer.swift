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
    FlatVertex(position: simd_float3(0, 0, 8), color: zAxisColor)
]

class Renderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    let flatPipelineState: MTLRenderPipelineState
    let line2DPipelineState: MTLRenderPipelineState
    
    var flatUniforms = FlatUniforms()
    var line2DUniforms = Line2DUniforms()
    
    let doublingBackForm = DoublingBackForm()
    let couplingForm = CouplingForm(outerRadius: 2, innerRadius: 1)
    let betweenYouAndIForm = BetweenYouAndIForm(width: 5, height: 6, initiallyWipingInEllipse: true)
    
    var hazeTexture: MTLTexture
    
    let viewMatrix = matrix4x4_translation(0, -2, -4)
    var projectionMatrix = matrix_float4x4()
    
    init?(metalKitView: MTKView, bundle: Bundle? = nil) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        do {
            flatPipelineState = try Renderer.buildRenderPipelineState(name: "Flat",
                                                                      device: device,
                                                                      metalKitView: metalKitView,
                                                                      bundle: bundle)
        } catch {
            print("Unable to compile render flat pipeline state.  Error info: \(error)")
            return nil
        }
        
        do {
            line2DPipelineState = try Renderer.buildRenderPipelineState(name: "Line2D",
                                                                        device: device,
                                                                        metalKitView: metalKitView,
                                                                        bundle: bundle)
        } catch {
            print("Unable to compile render line2D pipeline state.  Error info: \(error)")
            return nil
        }
        
        do {
            hazeTexture = try Renderer.loadTexture(device: device, textureName: "Haze", bundle: bundle)
        } catch {
            print("Unable to load haze texture. Error info: \(error)")
            return nil
        }
        
        super.init()
    }
    
    class func buildRenderPipelineState(name: String,
                                        device: MTLDevice,
                                        metalKitView: MTKView,
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
        
        let colorAttachments0 = pipelineDescriptor.colorAttachments[0]!
        colorAttachments0.pixelFormat = metalKitView.colorPixelFormat
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
    
    func draw(in view: MTKView) {
        
        flatUniforms.modelViewMatrix = viewMatrix
        flatUniforms.projectionMatrix = projectionMatrix
        
        line2DUniforms.modelViewMatrix = viewMatrix
        line2DUniforms.projectionMatrix = projectionMatrix
        line2DUniforms.color = simd_float4(1, 1, 1, 1)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                renderEncoder.pushDebugGroup("Draw Screen")
                renderEncoder.setRenderPipelineState(flatPipelineState)
                let screenVerticesLength = MemoryLayout<FlatVertex>.stride * screenVertices.count
                renderEncoder.setVertexBytes(screenVertices, length: screenVerticesLength, index: 0)
                let flatUniformsLength = MemoryLayout<FlatUniforms>.stride
                renderEncoder.setVertexBytes(&flatUniforms, length: flatUniformsLength, index: 1)
                renderEncoder.setFragmentBytes(&flatUniforms, length: flatUniformsLength, index: 1)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: screenVertices.count)
                renderEncoder.popDebugGroup()
                
                renderEncoder.pushDebugGroup("Draw Axes")
                let axesVerticesLength = MemoryLayout<FlatVertex>.stride * axesVertices.count
                renderEncoder.setVertexBytes(axesVertices, length: axesVerticesLength, index: 0)
                renderEncoder.setVertexBytes(&flatUniforms, length: flatUniformsLength, index: 1)
                renderEncoder.setFragmentBytes(&flatUniforms, length: flatUniformsLength, index: 1)
                renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: axesVertices.count)
                renderEncoder.popDebugGroup()
                
                let lineThickness: Float = 0.05
                let lines = doublingBackForm.getUpdatedPoints()
                // let lines = couplingForm.getUpdatedPoints()
                // let lines = betweenYouAndIForm.getUpdatedPoints()
                
                lines.forEach { line in
                    renderEncoder.pushDebugGroup("Draw Line")
                    let (vertices, indices) = makeLine2DVertices(line, lineThickness)
                    renderEncoder.setRenderPipelineState(line2DPipelineState)
                    let verticesLength = MemoryLayout<Line2DVertex>.stride * vertices.count
                    renderEncoder.setVertexBytes(vertices, length: verticesLength, index: 0)
                    let line2DUniformsLength = MemoryLayout<Line2DUniforms>.stride
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
                
                renderEncoder.endEncoding()
                view.currentDrawable.map(commandBuffer.present)
            }
            
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
