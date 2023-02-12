//
//  CameraRealTimeDelegate.swift
//  Keyneez
//
//  Created by Jung peter on 2/12/23.
//

import UIKit
import Foundation
import SnapKit
import AVFoundation
import MLKitTextRecognitionKorean
import MLKitTextRecognition
import MLKit
import MLImage
import CoreVideo
import Photos

class CameraRealTimeProcessor: NSObject {
  
  private var textRecognizer: TextRecognizable
  private var regionOfInterestSize: CGRect
  private var OCRCompletionHandler: ([String], UIImage) -> Void
  
  init(textRecognizer: TextRecognizable,
       regionOfInterestSize: CGRect,
       OCRCompletionHandler: @escaping ([String], UIImage) -> Void
  ) {
    self.textRecognizer = textRecognizer
    self.OCRCompletionHandler = OCRCompletionHandler
    self.regionOfInterestSize = regionOfInterestSize
  }
  
}

extension CameraRealTimeProcessor: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Failed to get image buffer from sample buffer.")
      return
    }
    
    let ciimage = sampleBuffer.convertToCIImage()
    let tempImage = UIImage(ciImage: ciimage)
    let newCropped = ImageCropper.makeCroppedImage(image: tempImage, regionOfInterestSize: regionOfInterestSize)
    let visionImage = VisionImage(image: newCropped)
    let orientation = UIUtilities.imageOrientation(
      fromDevicePosition: .front
    )
    visionImage.orientation = orientation
  
    guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
      print("Failed to create MLImage from sample buffer.")
      return
    }
    inputImage.orientation = orientation
    
    let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
    let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
    
    textRecognizer.recognizeText(in: visionImage, with: newCropped, width: imageWidth, height: imageHeight, completion: self.OCRCompletionHandler)
  }
  
}
