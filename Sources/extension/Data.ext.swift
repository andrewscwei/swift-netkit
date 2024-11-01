import Foundation

extension Data {

  var mimeType: String {
    get {
      var c = UInt8()

      copyBytes(to: &c, count: 1)

      switch (c) {
      case 0xFF: return "image/jpeg"
      case 0x89: return "image/png"
      case 0x47: return "image/gif"
      case 0x49,
           0x4D: return "image/tiff"
      case 0x25: return "application/pdf"
      case 0xD0: return "application/vnd"
      case 0x46: return "text/plain"
      case 0x00: return "video/mp4"
      default: return "application/octet-stream"
      }
    }
  }
}
