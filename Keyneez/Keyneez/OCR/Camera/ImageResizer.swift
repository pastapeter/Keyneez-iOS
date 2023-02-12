//
//  ImageResizer.swift
//  Keyneez
//
//  Created by Jung peter on 2/12/23.
//

import UIKit

struct ImageResizer {
  
  static func resize(image: UIImage,to size: CGSize) -> CGImage {
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

