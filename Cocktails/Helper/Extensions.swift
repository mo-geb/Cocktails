import UIKit
import SwiftUI

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }

    var fullVersionString: String {
        "v\(appVersion) (Build \(buildNumber))"
    }
}

// Source - https://stackoverflow.com/a/79195060
// Posted by Bhargav Agravat, modified by community. See post 'Timeline' for change history
// Retrieved 2026-04-28, License - CC BY-SA 4.0

extension UIImage {
    func dominantColor() -> UIColor? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow

        var rawData = [UInt8](repeating: 0, count: totalBytes)
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var bestColor: UIColor = .white
        var maxVibrancy: CGFloat = 0

        // Sample a 20x20 grid across the image — fast and ignores minor noise/shadows
        for y in stride(from: 0, to: height, by: height / 20) {
            for x in stride(from: 0, to: width, by: width / 20) {
                let byteIndex = (bytesPerRow * y) + (x * bytesPerPixel)

                let r = CGFloat(rawData[byteIndex])     / 255.0
                let g = CGFloat(rawData[byteIndex + 1]) / 255.0
                let b = CGFloat(rawData[byteIndex + 2]) / 255.0
                let a = CGFloat(rawData[byteIndex + 3]) / 255.0

                // Skip transparent pixels (common in PNG drink images)
                if a < 0.5 { continue }

                let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0
                color.getHue(&h, saturation: &s, brightness: &v, alpha: nil)

                // Vibrancy = saturation × brightness; targets bright colours over muddy browns/greys
                let vibrancy = s * v
                if vibrancy > maxVibrancy {
                    maxVibrancy = vibrancy
                    bestColor = color
                }
            }
        }

        return bestColor.withAlphaComponent(0.2)
    }
}
