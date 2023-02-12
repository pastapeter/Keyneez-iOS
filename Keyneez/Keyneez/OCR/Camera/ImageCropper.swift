//
//  ImageCropper.swift
//  Keyneez
//
//  Created by Jung peter on 2/12/23.
//

import UIKit

struct ImageCropper {
  
  static func makeCroppedImage(image: UIImage, regionOfInterestSize: CGRect) -> UIImage {
    var image = UIImage(cgImage: ImageResizer.resize(image: image, to: image.size))
    let deviceScreen = UIScreen.main.bounds.size
    let newy = regionOfInterestSize.origin.y / deviceScreen.height * image.size.height
    let cardHeightInPhoto = regionOfInterestSize.height / deviceScreen.height * image.size.height
    let cardWidthInPhoto = cardHeightInPhoto * regionOfInterestSize.width / regionOfInterestSize.height
    let newx = image.size.width / 2 - cardWidthInPhoto / 2
    let cropped = image.cgImage?.cropping(to: CGRect(x: newx, y: newy, width: cardWidthInPhoto, height: cardHeightInPhoto))
    return UIImage(cgImage: cropped!, scale: image.scale, orientation: image.imageOrientation)
  }
  
}
