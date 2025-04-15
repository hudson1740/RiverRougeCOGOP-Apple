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
            let reason: String?
        }
    }

    private struct VideoResponse: Codable {
        let items: [VideoItem]?
    }

    private struct VideoItem: Codable {
        let id: String
        let status: VideoStatus
    }

    private struct VideoStatus: Codable {
        let uploadStatus: String
        let privacyStatus: String
        let embeddable: Bool
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
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            } else {
                print("No HTTP response received")
            }

            if let data = data, let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(rawResponse)")
            } else {
                print("No data received or failed to convert data to string")
            }

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

            if let apiError = try? JSONDecoder().decode(YouTubeAPIError.self, from: data), apiError.error != nil || apiError.message != nil {
                let errorMessage = apiError.error?.message ?? apiError.message ?? "Unknown API error"
                let errorCode = apiError.error?.code ?? apiError.code ?? -1
                print("API Error Detected: \(errorMessage) (Code: \(errorCode))")
                completion(.failure(NSError(domain: "", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            do {
                let response = try JSONDecoder().decode(YouTubePlaylistResponse.self, from: data)
                let items = response.items?.filter {
                    let title = $0.snippet.title.lowercased()
                    return $0.snippet.resourceId.videoId != "" &&
                           !title.contains("deleted video") &&
                           !title.contains("private video") &&
                           !title.contains("unavailable") &&
                           $0.snippet.thumbnails?.defaultThumbnail?.url != nil
                } ?? []
                print("Successfully decoded response with \(items.count) items")
                completion(.success(items))
            } catch {
                print("Failed to decode response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }

    func checkVideoPlayability(videoId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=status&id=\(videoId)&key=\(Config.youtubeApiKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid video check URL: \(urlString)")
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error checking video playability for ID \(videoId): \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error checking video playability for ID \(videoId)")
                completion(false)
                return
            }

            guard let data = data else {
                print("No data received for video check ID \(videoId)")
                completion(false)
                return
            }

            do {
                let videoResponse = try JSONDecoder().decode(VideoResponse.self, from: data)
                guard let video = videoResponse.items?.first else {
                    print("No video found for ID \(videoId)")
                    completion(false)
                    return
                }

                let isPlayable = video.status.uploadStatus == "processed" &&
                                 video.status.embeddable &&
                                 video.status.privacyStatus != "private"
                print("Video ID \(videoId) is playable: \(isPlayable)")
                completion(isPlayable)
            } catch {
                print("Failed to decode video check response for ID \(videoId): \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
}
