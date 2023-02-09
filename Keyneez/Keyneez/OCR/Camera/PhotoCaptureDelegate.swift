//
//  PhotoCaptureDelegate.swift
//  Keyneez
//
//  Created by Jung peter on 1/8/23.
//

import AVFoundation
import Photos
import CoreVideo
import MLImage
import MLKitTextRecognitionKorean
import MLKitTextRecognition
import MLKit

class PhotoCaptureProcessor: NSObject {
  private(set) var requestedPhotoSettings: AVCapturePhotoSettings
  
  private let willCapturePhotoAnimation: () -> Void
  
  private let livePhotoCaptureHandler: (Bool) -> Void
  
  lazy var context = CIContext()
  
  private let completionHandler: (PhotoCaptureProcessor) -> Void
  
  private let photoProcessingHandler: (Bool) -> Void
  
  private let OCRCompletionHandler: ([String], UIImage) -> Void
  
  private var photoData: Data?
  
  private var livePhotoCompanionMovieURL: URL?
  
  private var portraitEffectsMatteData: Data?
  
  private var semanticSegmentationMatteDataArray = [Data]()
  private var maxPhotoProcessingTime: CMTime?
  
  
  
  // Save the location of captured photos
  var location: CLLocation?
  var koreanOptions = KoreanTextRecognizerOptions()
  
  init(with requestedPhotoSettings: AVCapturePhotoSettings,
       willCapturePhotoAnimation: @escaping () -> Void,
       livePhotoCaptureHandler: @escaping (Bool) -> Void,
       completionHandler: @escaping (PhotoCaptureProcessor) -> Void,
       photoProcessingHandler: @escaping (Bool) -> Void,
       OCRCompletionHandler: @escaping ([String], UIImage) -> Void
  ) {
    self.requestedPhotoSettings = requestedPhotoSettings
    self.willCapturePhotoAnimation = willCapturePhotoAnimation
    self.livePhotoCaptureHandler = livePhotoCaptureHandler
    self.completionHandler = completionHandler
    self.photoProcessingHandler = photoProcessingHandler
    self.OCRCompletionHandler = OCRCompletionHandler
  }
  
  private func didFinish() {
    completionHandler(self)
    photoData = nil
  }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
  /*
   This extension adopts all of the AVCapturePhotoCaptureDelegate protocol methods.
   */
  
  /// - Tag: WillBeginCapture
  func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
      livePhotoCaptureHandler(true)
    }
    maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
  }
  
  /// - Tag: WillCapturePhoto
  func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    willCapturePhotoAnimation()
    
    guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
      return
    }
    
    // Show a spinner if processing time exceeds one second.
    let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
    if maxPhotoProcessingTime > oneSecond {
      photoProcessingHandler(true)
    }
  }
  
  /// - Tag: DidFinishProcessingPhoto
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    photoProcessingHandler(false)
    
    if let error = error {
      print("Error capturing photo: \(error)")
      return
    } else {
      guard let data = photo.fileDataRepresentation() else {return}
      guard let tempImage = UIImage(data: data) else {return}

      var newCropped = makeCroppedImage(image: tempImage)
      photoData = newCropped.pngData()

      DispatchQueue.global().async { [weak self] in
        guard let self = self else {return}
        let visionImage = VisionImage(image: newCropped)
        OCRService().recognizeTextWithManual(in: visionImage, with: newCropped, width: newCropped.size.width, height: newCropped.size.height) { text, image in
          self.saveImage(image: image, name: 2)
          self.OCRCompletionHandler(text, image)
        }

      }
    }
    
  }
  
  func saveImage(image: UIImage, name: Int) -> Bool {
          guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
              return false
          }
          guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
              return false
          }
          do {
              try data.write(to: directory.appendingPathComponent("profile\(name).png")!)
              return true
          } catch {
              print(error.localizedDescription)
              return false
          }
      }
  
  private func makeCroppedImage(image: UIImage) -> UIImage {
    var image = UIImage(cgImage: resizeImage(image: image, size: image.size))
    let deviceScreen = UIScreen.main.bounds.size
    let newy = regionOfInterestSize.origin.y / deviceScreen.height * image.size.height
    let cardHeightInPhoto = regionOfInterestSize.height / deviceScreen.height * image.size.height
    let cardWidthInPhoto = cardHeightInPhoto * regionOfInterestSize.width / regionOfInterestSize.height
    let newx = image.size.width / 2 - cardWidthInPhoto / 2
    let cropped = image.cgImage?.cropping(to: CGRect(x: newx, y: newy, width: cardWidthInPhoto, height: cardHeightInPhoto))
    return UIImage(cgImage: cropped!, scale: image.scale, orientation: image.imageOrientation)
  }
  
  /// - Tag: DidFinishRecordingLive
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
    livePhotoCaptureHandler(false)
  }
  
  /// - Tag: DidFinishProcessingLive
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
    if error != nil {
      print("Error processing Live Photo companion movie: \(String(describing: error))")
      return
    }
    livePhotoCompanionMovieURL = outputFileURL
  }
  
  /// - Tag: DidFinishCapture
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
    if let error = error {
      print("Error capturing photo: \(error)")
      didFinish()
      return
    }
    
    guard let photoData = photoData else {
      print("No photo data resource")
      didFinish()
      return
    }
  }
  
  func resizeImage(image: UIImage, size: CGSize) -> CGImage {
    UIGraphicsBeginImageContext(size)
    image.draw(in:CGRect(x: 0, y: 0, width: size.width, height:size.height))
    let renderImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    guard let resultImage = renderImage?.cgImage else {
      print("image resizing error")
      return UIImage().cgImage!
    }
    return resultImage
  }
  
}

extension CGImage {
  var png: Data? {
    guard let mutableData = CFDataCreateMutable(nil, 0),
          let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(destination, self, nil)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return mutableData as Data
  }
}
