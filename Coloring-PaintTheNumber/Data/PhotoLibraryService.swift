//
//  PhotoLibraryService.swift
//  Coloring-PaintTheNumber
//

import Photos
import UIKit

enum PhotoSaver {
    static func save(_ image: UIImage) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return false }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        return true
    }
}
