//
//  ContentView.swift
//  VisionDescription
//
//  Created by Cristian Díaz on 20.11.23.
//

import Dependencies
import Foundation
import SwiftUI

@Observable
class ViewModel {
  @ObservationIgnored
  @Dependency(\.visionClient) var visionClient
  @ObservationIgnored
  @Dependency(\.screenCaptureClient) var screenCaptureClient
  var imageInProcess: Image?

  var message = ""
  var isDescriptionInFlight = false

  func captureSimulatorImage() async throws -> CGImage? {
    message = ""
    isDescriptionInFlight = true
    let image = try await screenCaptureClient.captureSimulatorImage()
    if let image {
      imageInProcess = Image(nsImage: NSImage(cgImage: image, size: .init(width: 100, height: 100)))
    }
    return image
  }

  func describeImage(_ encodedImage: String) async throws {
    try await message = visionClient.describeImage(encodedImage)
    isDescriptionInFlight = false
  }
}

struct ContentView: View {
  @State private var model = ViewModel()

  var body: some View {
    ZStack {
      if model.isDescriptionInFlight {
        ProgressView()
          .accessibilityHidden(true)
      } else {
        if model.message.isEmpty {
          ContentUnavailableView(
            "No Description",
            systemImage: "waveform.badge.magnifyingglass",
            description: Text("You should open the simulator and press the describe button.")
          )
        } else {
          ScrollView {
            Text(model.message)
              .font(.system(size: 24))
              .padding()
          }
          .accessibilityHidden(false)
          .accessibilityLabel("Vision description response")
          .accessibilityValue(model.message)
        }
      }
    }
    .navigationSubtitle("gpt-4-vision-preview")
    .toolbar {
      ToolbarItem {
        Button("Describe", systemImage: "point.3.filled.connected.trianglepath.dotted") {
          Task { @MainActor in
            do {
              let image = try await model.captureSimulatorImage()
              if let encodedImage = image?.pngData?.base64EncodedString() {
                try await model.describeImage(encodedImage)
              }
            } catch {
              fatalError("Simulator window not found.")
            }
          }
        }
        .accessibilityLabel("Describe simulator with Vision")
        .accessibilityHint(
          "Activate to send the current simulator view to ChatGPT and obtain an AI generated response."
        )
        .disabled(model.isDescriptionInFlight)
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .labelStyle(.titleAndIcon)
        .symbolRenderingMode(.multicolor)
      }
    }
  }
}

#Preview {
  ContentView()
}

extension CGImage {
  var pngData: Data? {
    let bitmapRep = NSBitmapImageRep(cgImage: self)
    return bitmapRep.representation(using: .png, properties: [:])
  }
}
