//
//  Extension+SampleBuffer.swift
//  Keyneez
//
//  Created by Jung peter on 2/13/23.
//

import UIKit
import AVFoundation

extension CMSampleBuffer {
  func convertToCIImage() -> CIImage {
    let pixelBuffer = CMSampleBufferGetImageBuffer(self)!
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    
    let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)!
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let newContext = CGContext(data: baseAddress,
                               width: width,
                               height: height,
                               bitsPerComponent: 8,
                               bytesPerRow: bytesPerRow,
                               space: colorSpace,
                               bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    
    let imageRef = newContext.makeImage()!
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    var output = CIImage(cgImage: imageRef)
    
    var transform = output.orientationTransform(forExifOrientation: 6) // UIImageOrientation.right
    output = output.transformed(by: transform)
    
    let ratio = output.extent.size.width / output.extent.size.width
    transform = output.orientationTransform(forExifOrientation: 1)
    transform = transform.scaledBy(x: ratio, y: ratio)
    output = output.transformed(by: transform)
    
    transform = output.orientationTransform(forExifOrientation: 1)
    transform = transform.translatedBy(x: 0, y: -(output.extent.size.height - output.extent.size.height) / 2)
    output = output.transformed(by: transform)
    
    return output.cropped(to: CGRect(origin: CGPoint.zero, size: output.extent.size))
  }

}

