//
//  UIImage+Helpers.swift
//  Notifications
//
//  Created by WCA on 7/5/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit

enum ImageFileType {
	
	case JPG(compressionQuality: CGFloat)
	case PNG
	
	var fileExtension: String {
		switch self {
		case .JPG(_):
			return ".jpg"
		case .PNG:
			return ".png"
		}
	}
}

enum ImageError: Error {
	case UnableToConvertImageToData
}

public extension UIImage {
	
	public func scale(width:CGFloat, height:CGFloat) -> UIImage? {
		let oldWidth = self.size.width
		let oldHeight = self.size.height
		let scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight
		let newHeight = oldHeight * scaleFactor
		let newWidth = oldWidth * scaleFactor
		let newSize = CGSize(width:newWidth, height:newHeight)
		return scale(to: newSize)
	}
	
	public func scaleAspectFill(to size: CGSize) -> UIImage? {
		
		let renderer = UIGraphicsImageRenderer(size: size)
		let scaledImage = renderer.image {(context) in
			self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		}
		return scaledImage
	}
	
	public func scaleAndCrop(from fromSize: CGSize, to toSize:CGSize) -> UIImage? {
		let renderFormat = UIGraphicsImageRendererFormat.default()
		renderFormat.opaque = false
		let renderer = UIGraphicsImageRenderer(size: CGSize(width: toSize.width, height: toSize.height), format: renderFormat)
		let newImage = renderer.image { (context) in
			self.draw(in: CGRect(x: 0, y: 0, width: fromSize.width, height: fromSize.height))
		}
		return newImage
	}
	
	public func scaleAspectFit(to size: CGSize) -> UIImage? {
		let aspect = self.size.width / self.size.height
		if (size.width / aspect > size.height) {
			return self.scaleAndCrop(from:CGSize.init(width: size.width, height: size.width / aspect), to: size)
		}
		else{
			return self.scaleAndCrop(from:CGSize(width: size.height * aspect, height: size.height), to: size)
		}
	}
	
	public func scale(to size:CGSize) -> UIImage? {
		UIGraphicsBeginImageContext(size)
		self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return scaledImage
	}
	
	// colorize image with given tint color
	// this is similar to Photoshop's "Color" layer blend mode
	// this is perfect for non-greyscale source images, and images that have both highlights and shadows that should be preserved
	// white will stay white and black will stay black as the lightness of the image is preserved
	public func tintColor(_ tintColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw black background - workaround to preserve color of partially transparent pixels
			context.setBlendMode(.normal)
			tintColor.setFill()
			context.fill(rect)
			
			// draw original image
			context.setAlpha(0.5)
			context.setBlendMode(.luminosity)
			context.draw(self.cgImage!, in: rect)
		}
	}
	
	// fills the alpha channel of the source image with the given color
	// any color information except to the alpha channel will be ignored
	func fillAlpha(fillColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw tint color
			context.setBlendMode(.normal)
			fillColor.setFill()
			context.fill(rect)
			
			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(self.cgImage!, in: rect)
		}
	}
	
	private func modifiedImage( draw: (CGContext, CGRect) -> ()) -> UIImage {
		
		// using scale correctly preserves retina images
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		let context: CGContext! = UIGraphicsGetCurrentContext()
		assert(context != nil)
		
		// correctly rotate image
		context.translateBy(x: 0, y: size.height)
		context.scaleBy(x: 1.0, y: -1.0)
		
		let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
		
		draw(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
}

public class Image: NSObject {
	
	public var imageThumbnail: UIImage?
	public var imageSmall: UIImage?
	public var imageMedium: UIImage?
	public var imageFull: UIImage?
	
	public override init() {
		super.init()
	}
	
	public static func scaled(image:UIImage, toWidth width:CGFloat, andHeight height:CGFloat) -> UIImage? {
		let oldWidth = image.size.width
		let oldHeight = image.size.height
		let scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight
		let newHeight = oldHeight * scaleFactor
		let newWidth = oldWidth * scaleFactor
		let newSize = CGSize(width:newWidth, height:newHeight)
		return scaled(image: image, to: newSize)
	}
	
	public static func scaled(image:UIImage, to size:CGSize) -> UIImage? {
		UIGraphicsBeginImageContext(size)
		image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return scaledImage
	}
	
	public func sized(forImage image:UIImage) {
		imageThumbnail = Image.scaled(image: image, toWidth: 160, andHeight: 160)
		imageSmall = Image.scaled(image: image, toWidth: 640, andHeight: 640)
		imageMedium = Image.scaled(image: image, toWidth: 2024, andHeight: 2024)
		imageFull = image
	}
	
}

extension UIImage {
	func saveToTempLocationWithFileType(fileType: ImageFileType) throws -> URL? {
		let imageData: Data?
		
		switch fileType {
		case .JPG(let quality):
			imageData = UIImageJPEGRepresentation(self, quality)
		case .PNG:
			imageData = UIImagePNGRepresentation(self)
		}
		guard let data = imageData else {
			throw ImageError.UnableToConvertImageToData
		}
		let filename = ProcessInfo.processInfo.globallyUniqueString + fileType.fileExtension
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
		
		try data.write(to: url, options: .atomicWrite)
		return url
	}
}

extension CKAsset {
	convenience init(image: UIImage, fileType: ImageFileType = .PNG) throws {
		let url = try image.saveToTempLocationWithFileType(fileType: fileType)
		self.init(fileURL: url!)
	}
	
	convenience init(data: Data) throws {
		let filename: String = ProcessInfo.processInfo.globallyUniqueString + "dat"
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
		try data.write(to: url, options: .atomicWrite)
		self.init(fileURL: url)
	}
	
	public var image: UIImage? {
		do {
			let data = try Data(contentsOf: fileURL)
			let image = UIImage(data: data)
			return image
		}
		catch {
			return nil
		}
	}
}

