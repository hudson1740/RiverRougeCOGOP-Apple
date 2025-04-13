// YouTubeService.swift
import Foundation

class YouTubeService {
    static let shared = YouTubeService()

    private struct YouTubeAPIError: Codable {
        let error: APIErrorDetails?
        let message: String?
        let code: Int?

        struct APIErrorDetails: Codable {
            let code: Int?
            let message: String?
            let errors: [APIError]?
        }

        struct APIError: Codable {
            let message: String?
            let domain: String?
            let reason: String? // Fixed syntax error: removed "the"
        }
    }

    func fetchPlaylistItems(retryCount: Int = 3, completion: @escaping (Result<[YouTubePlaylistItem], Error>) -> Void) {
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(Config.playlistId)&key=\(Config.youtubeApiKey)&maxResults=50"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        print("Attempting request to URL: \(url.absoluteString) (Retry count: \(retryCount))")
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Log HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            } else {
                print("No HTTP response received")
            }

            // Log raw response
            if let data = data, let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(rawResponse)")
            } else {
                print("No data received or failed to convert data to string")
            }

            // Handle network errors and retry
            if let error = error as NSError? {
                print("Network error: \(error.localizedDescription) (Code: \(error.code))")
                if retryCount > 0 && (error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorTimedOut || error.code == NSURLErrorCannotParseResponse) {
                    print("Retrying (\(retryCount) attempts left)...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.fetchPlaylistItems(retryCount: retryCount - 1, completion: completion)
                    }
                    return
                }
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response: Not an HTTP response")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response: Not an HTTP response"])))
                return
            }

            // Check HTTP status code
            let statusCode = httpResponse.statusCode
            if statusCode != 200 {
                let errorMessage = "HTTP Error: Status code \(statusCode)"
                print(errorMessage)
                completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            guard let data = data else {
                print("No data received from API")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from the server"])))
                return
            }

            // Handle API error response
            if let apiError = try? JSONDecoder().decode(YouTubeAPIError.self, from: data), apiError.error != nil || apiError.message != nil {
                let errorMessage = apiError.error?.message ?? apiError.message ?? "Unknown API error"
                let errorCode = apiError.error?.code ?? apiError.code ?? -1
                print("API Error Detected: \(errorMessage) (Code: \(errorCode))")
                completion(.failure(NSError(domain: "", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            // Decode playlist response
            do {
                let response = try JSONDecoder().decode(YouTubePlaylistResponse.self, from: data)
                let items = response.items ?? []
                print("Successfully decoded response with \(items.count) items")
                completion(.success(items))
            } catch {
                print("Failed to decode response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
