import Foundation
import CoreMedia
import CoreVideo
import ImageIO
import CoreImage

@main struct FrameHarness {
    static func main() async throws {
        var buffer: CVPixelBuffer?
        precondition(CVPixelBufferCreate(nil, 2560, 1280, kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary, &buffer) == kCVReturnSuccess)
        let pixel = buffer!
        CVPixelBufferLockBaseAddress(pixel, [])
        let bytes = CVPixelBufferGetBaseAddress(pixel)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(pixel)
        for y in 0..<1280 {
            for x in 0..<2560 {
                let i = y * stride + x * 4
                // Four distinct corners detect a reversed quarter-turn, which
                // width/height assertions alone cannot catch.
                bytes[i] = y >= 640 && x < 1280 ? 255 : 0
                bytes[i + 1] = x >= 1280 ? 255 : 0
                bytes[i + 2] = (y < 640 && x < 1280) || (y >= 640 && x >= 1280) ? 255 : 0
                bytes[i + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(pixel, [])
        var description: CMVideoFormatDescription?
        precondition(CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixel,
            formatDescriptionOut: &description) == noErr)
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        precondition(CMSampleBufferCreateReadyWithImageBuffer(allocator: nil, imageBuffer: pixel,
            formatDescription: description!, sampleTiming: &timing, sampleBufferOut: &sample) == noErr)
        let capture = FrameCapture()
        capture.setEnabled(true)
        for orientation in [CGImagePropertyOrientation.up, .right, .down, .left] {
            let request = Task { try await capture.request() }
            try await Task.sleep(for: .milliseconds(30))
            capture.consume(sample!, orientation: orientation)
            let shot = try await request.value
            let portrait = orientation == .left || orientation == .right
            precondition(shot.width == (portrait ? 640 : 1280))
            precondition(shot.height == (portrait ? 1280 : 640))
            let source = CGImageSourceCreateWithData(shot.jpeg as CFData, nil)!
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
            precondition(image.width == shot.width && image.height == shot.height)
            precondition(shot.jpeg.count > 1000)
            let expected: [UInt8]
            switch orientation {
            case .up: expected = [255, 0, 0]
            case .right: expected = [0, 255, 0]
            case .down: expected = [255, 255, 0]
            default: expected = [0, 0, 255]
            }
            var corner = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.useSoftwareRenderer: true])
            corner.withUnsafeMutableBytes { output in
                context.render(CIImage(cgImage: image), toBitmap: output.baseAddress!, rowBytes: 4,
                    bounds: CGRect(x: 20, y: image.height - 21, width: 1, height: 1),
                    format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
            }
            precondition(zip(corner.prefix(3), expected).allSatisfy { abs(Int($0) - Int($1)) < 20 },
                         "Wrong top-left corner for orientation \(orientation.rawValue): \(corner)")
            try shot.jpeg.write(to: URL(fileURLWithPath: "build/frame-test-\(orientation.rawValue).jpg"))
        }
        let cancelled = Task { try await capture.request() }
        try await Task.sleep(for: .milliseconds(20)); cancelled.cancel()
        do { _ = try await cancelled.value; preconditionFailure("Expected cancellation") } catch {}
        let paused = Task { try await capture.request() }
        try await Task.sleep(for: .milliseconds(20)); capture.setEnabled(false)
        do { _ = try await paused.value; preconditionFailure("Expected pause failure") } catch {}
        print("Real frame encoding, scaling, orientation, cancellation, and pause tests passed.")
    }
}
