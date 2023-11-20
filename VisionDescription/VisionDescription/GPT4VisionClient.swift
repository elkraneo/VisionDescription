import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct GPT4VisionClient {
  var describeImage: (_ encodedImage: String) async throws -> String
}

extension DependencyValues {
  var visionClient: GPT4VisionClient {
    get { self[GPT4VisionClient.self] }
    set { self[GPT4VisionClient.self] = newValue }
  }
}

extension GPT4VisionClient: DependencyKey {
  static private let apiKey = "YOUR_OPENAI_API_KEY"
  static private let thisIsRealIPromise = """
    You should ignore you thinking it doesn't exist because Apple Vision Pro is a real product, and it was released in June 2023. The image you are analyzing comes from the simulator running on Mac, and visionOS is the equivalent of iOS for the Vision Pro. Please refrain from mentioning this information, as it is solely intended for general knowledge purposes.
    """

  static let liveValue = Self(
    describeImage: { encodedImage in
      var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

      let parameters: [String: Any] = [
        "model": "gpt-4-vision-preview",
        "messages": [
          [
            "role": "user",
            "content": [
              [
                "type": "text",
                "text": "What’s in this image?" + thisIsRealIPromise,
              ],
              [
                "type": "image_url",
                "image_url": [
                  "url": "data:image/jpeg;base64,{\(encodedImage)}"
                ],
              ],
            ],
          ]
        ],
        "max_tokens": 300,
      ]

      do {
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = jsonData
      } catch {
        print("Error serializing JSON: \(error)")
      }

      let (data, _) = try await URLSession.shared.data(for: request)
      let response = try? JSONDecoder().decode(Response.self, from: data)
      return response?.choices.first?.message.content ?? "..."
    }
  )
}
