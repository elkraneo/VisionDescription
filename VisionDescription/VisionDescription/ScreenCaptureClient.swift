import Dependencies
import DependenciesMacros
import Foundation
import ScreenCaptureKit

@DependencyClient
struct ScreenCaptureClient {
  var captureSimulatorImage: () async throws -> CGImage?

  enum ScreenCaptureError: Error {
    case simualtorNotFound
  }
}

extension DependencyValues {
  var screenCaptureClient: ScreenCaptureClient {
    get { self[ScreenCaptureClient.self] }
    set { self[ScreenCaptureClient.self] = newValue }
  }
}

extension ScreenCaptureClient: DependencyKey {
  static let liveValue = Self(captureSimulatorImage: { @MainActor in
    let simulatorWindows = try await SCShareableContent.current.windows
      .filter({ $0.owningApplication?.bundleIdentifier == "com.apple.iphonesimulator" })
      .filter(\.isOnScreen)
      .filter(\.isActive)

    if let firstActiveSimulatorWindow = simulatorWindows.first {
      let contentFilter = SCContentFilter(desktopIndependentWindow: firstActiveSimulatorWindow)
      let configuration = SCStreamConfiguration()
      configuration.captureResolution = .nominal
      configuration.width = Int(firstActiveSimulatorWindow.frame.width)
      configuration.height = Int(firstActiveSimulatorWindow.frame.height)
      configuration.shouldBeOpaque = true
      let image = try await SCScreenshotManager.captureImage(
        contentFilter: contentFilter,
        configuration: configuration
      )
      return image
    } else {
      throw ScreenCaptureError.simualtorNotFound
    }
  })
}
