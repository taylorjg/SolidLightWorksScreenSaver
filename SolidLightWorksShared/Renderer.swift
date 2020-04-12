//
//  Renderer.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 26/03/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

enum RendererError: Error {
    case badVertexDescriptor
}

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
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var flatPipelineState: MTLRenderPipelineState
    var flatUniformBuffer: MTLBuffer
    var flatUniforms: UnsafeMutablePointer<FlatUniforms>
    
    var line2DPipelineState: MTLRenderPipelineState
    var line2DUniformBuffer: MTLBuffer
    var line2DUniforms: UnsafeMutablePointer<Line2DUniforms>
    let travellingWaveRight = TravellingWave(cx: 0, cy: 2, width: 6, height: 4, vertical: false)
    let travellingWaveUp = TravellingWave(cx: 0, cy: 2, width: 6, height: 4, vertical: true)
    let circleWaveOuter = CircleWave(R: 2, A: 0.4, F: 3.5, S: 0.001, f: 0.001, rotationPhase: 0, oscillationPhase: 0)
    let circleWaveInner = CircleWave(R: 1, A: 0.4, F: 3.5, S: -0.001, f: -0.001, rotationPhase: Float.pi / 2, oscillationPhase: 0)
    
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    
    var rotation: Float = 0
    var tick = 0
    
    var hazeTexture: MTLTexture
    
    init?(metalKitView: MTKView, bundle: Bundle? = nil) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        let flatUniformBufferSize = MemoryLayout<FlatUniforms>.size
        guard let buffer2 = self.device.makeBuffer(length:flatUniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else { return nil }
        flatUniformBuffer = buffer2
        flatUniforms = UnsafeMutableRawPointer(flatUniformBuffer.contents()).bindMemory(to: FlatUniforms.self, capacity: 1)
        
        do {
            flatPipelineState = try Renderer.buildRenderFlatPipelineWithDevice(device: device,
                                                                               metalKitView: metalKitView,
                                                                               bundle: bundle)
        } catch {
            print("Unable to compile render flat pipeline state.  Error info: \(error)")
            return nil
        }
        
        let line2DUniformBufferSize = MemoryLayout<Line2DUniforms>.size
        guard let buffer3 = self.device.makeBuffer(length:line2DUniformBufferSize, options:[MTLResourceOptions.storageModeShared]) else { return nil }
        line2DUniformBuffer = buffer3
        line2DUniforms = UnsafeMutableRawPointer(line2DUniformBuffer.contents()).bindMemory(to: Line2DUniforms.self, capacity: 1)
        
        do {
            line2DPipelineState = try Renderer.buildRenderLine2DPipelineWithDevice(device: device,
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
    
    class func buildRenderFlatPipelineWithDevice(device: MTLDevice,
                                                 metalKitView: MTKView,
                                                 bundle: Bundle?) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = bundle != nil
            ? try device.makeDefaultLibrary(bundle: bundle!)
            : device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexFlatShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentFlatShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
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
    
    class func buildRenderLine2DPipelineWithDevice(device: MTLDevice,
                                                   metalKitView: MTKView,
                                                   bundle: Bundle?) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = bundle != nil
            ? try device.makeDefaultLibrary(bundle: bundle!)
            : device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexLine2DShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentLine2DShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
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
        /// Load texture data with optimal parameters for sampling
        
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
    
    private func updateGameState() {
        /// Update any game state before rendering
        
        let viewMatrix = matrix4x4_translation(0, -2.0, -4.0)
        
        flatUniforms[0].projectionMatrix = projectionMatrix
        flatUniforms[0].modelViewMatrix = viewMatrix
        
        line2DUniforms[0].projectionMatrix = projectionMatrix
        line2DUniforms[0].modelViewMatrix = viewMatrix
        line2DUniforms[0].color = simd_float4(1, 1, 1, 1)
    }
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            self.updateGameState()
            
            let divisions = 127
            let lineThickness: Float = 0.05
            
            let wavePointsRight = travellingWaveRight.getPoints(divisions: divisions, tick: tick)
            let wavePointsUp = travellingWaveUp.getPoints(divisions: divisions, tick: tick)
            // let wavePointsRight = circleWaveOuter.getPoints(divisions: divisions, tick: tick)
            // let wavePointsUp = circleWaveInner.getPoints(divisions: divisions, tick: tick)
            tick += 1
            let (waveVerticesRight, waveIndicesRight) = makeLine2DVertices(wavePointsRight, lineThickness)
            let (waveVerticesUp, waveIndicesUp) = makeLine2DVertices(wavePointsUp, lineThickness)
            let waveIndicesRightBuffer = device.makeBuffer(bytes: waveIndicesRight,
                                                           length: MemoryLayout<UInt16>.stride * waveIndicesRight.count,
                                                           options: [])!
            let waveIndicesUpBuffer = device.makeBuffer(bytes: waveIndicesUp,
                                                        length: MemoryLayout<UInt16>.stride * waveIndicesUp.count,
                                                        options: [])!
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                //                renderEncoder.pushDebugGroup("Draw Screen")
                //                renderEncoder.setRenderPipelineState(flatPipelineState)
                //                renderEncoder.setVertexBytes(screenVertices,
                //                                             length: MemoryLayout<FlatVertex>.stride * screenVertices.count,
                //                                             index: 0)
                //                renderEncoder.setVertexBuffer(flatUniformBuffer, offset:0, index: 1)
                //                renderEncoder.setFragmentBuffer(flatUniformBuffer, offset:0, index: 1)
                //                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: screenVertices.count)
                //                renderEncoder.popDebugGroup()
                
                //                renderEncoder.pushDebugGroup("Draw Axes")
                //                renderEncoder.setVertexBytes(axesVertices, length: axesVertices.count * MemoryLayout<FlatVertex>.stride, index: 0)
                //                renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: axesVertices.count)
                //                renderEncoder.popDebugGroup()
                
                renderEncoder.pushDebugGroup("Draw Tavelling Wave Right")
                renderEncoder.setRenderPipelineState(line2DPipelineState)
                renderEncoder.setVertexBytes(waveVerticesRight,
                                             length: MemoryLayout<Line2DVertex>.stride * waveVerticesRight.count,
                                             index: 0)
                renderEncoder.setVertexBuffer(line2DUniformBuffer, offset:0, index: 1)
                renderEncoder.setFragmentBuffer(line2DUniformBuffer, offset:0, index: 1)
                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: waveIndicesRight.count,
                                                    indexType: .uint16,
                                                    indexBuffer: waveIndicesRightBuffer,
                                                    indexBufferOffset: 0)
                renderEncoder.popDebugGroup()
                
                renderEncoder.pushDebugGroup("Draw Tavelling Wave Up")
                renderEncoder.setVertexBytes(waveVerticesUp,
                                             length: MemoryLayout<Line2DVertex>.stride * waveVerticesUp.count,
                                             index: 0)
                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: waveIndicesUp.count,
                                                    indexType: .uint16,
                                                    indexBuffer: waveIndicesUpBuffer,
                                                    indexBufferOffset: 0)
                renderEncoder.popDebugGroup()
                
                renderEncoder.endEncoding()
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65),
                                                         aspectRatio:aspect,
                                                         nearZ: 0.1,
                                                         farZ: 100.0)
    }
}
