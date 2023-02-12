//
//  ImageSaver.swift
//  Keyneez
//
//  Created by Jung peter on 2/13/23.
//

import UIKit

struct ImageSaver {
  static func saveImage(image: UIImage, name: Int) -> Bool {
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
}
