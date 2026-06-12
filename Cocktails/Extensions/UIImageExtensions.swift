import UIKit

// Source - https://stackoverflow.com/a/79195060
// Posted by Bhargav Agravat, modified by community. See post 'Timeline' for change history
// Retrieved 2026-04-28, License - CC BY-SA 4.0

extension UIImage {
    nonisolated func dominantColor() -> UIColor? {
        guard let cgImage = self.cgImage else { return nil }

        // Sampling at full resolution allocates width*height*4 bytes and draws the
        // entire CGImage on the calling (main) thread — a multi-MP user photo causes
        // a visible hitch. Cap the longest side; the dominant colour is unaffected.
        let maxDimension = 80
        let scale = min(1.0, Double(maxDimension) / Double(max(cgImage.width, cgImage.height)))
        let width = max(1, Int(Double(cgImage.width) * scale))
        let height = max(1, Int(Double(cgImage.height) * scale))
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
        let strideY = max(1, height / 20)
        let strideX = max(1, width / 20)
        for y in stride(from: 0, to: height, by: strideY) {
            for x in stride(from: 0, to: width, by: strideX) {
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

        return bestColor
    }
}
