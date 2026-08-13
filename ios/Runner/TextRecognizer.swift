import Flutter
import UIKit
import Vision

enum TextRecognizer {
  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "CollateTextRecognizer") else { return }

    let channel = FlutterMethodChannel(
      name: "collate/ocr",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterError(code: "bad_arguments", message: "No image path", details: nil))
        return
      }

      recognize(path: path, result: result)
    }
  }

  private static func recognize(path: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let image = UIImage(contentsOfFile: path), let page = image.cgImage else {
        finish(result, FlutterError(code: "unreadable", message: "Could not read the page", details: nil))
        return
      }

      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          finish(result, FlutterError(code: "failed", message: error.localizedDescription, details: nil))
          return
        }

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let ordered = observations.sorted { first, second in
          if abs(first.boundingBox.maxY - second.boundingBox.maxY) > 0.01 {
            return first.boundingBox.maxY > second.boundingBox.maxY
          }
          return first.boundingBox.minX < second.boundingBox.minX
        }

        let lines = ordered.compactMap { $0.topCandidates(1).first?.string }
        finish(result, lines.joined(separator: "\n"))
      }

      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      if #available(iOS 16.0, *) {
        request.automaticallyDetectsLanguage = true
      }

      do {
        try VNImageRequestHandler(cgImage: page, options: [:]).perform([request])
      } catch {
        finish(result, FlutterError(code: "failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func finish(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async { result(value) }
  }
}
