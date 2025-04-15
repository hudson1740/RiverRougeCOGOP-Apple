// YouTubePlayerView.swift
import SwiftUI
import WebKit
import AVFoundation

class YouTubePlayerManager: NSObject, ObservableObject {
    @Published var selectedVideoId: String?
    @Published var videos: [YouTubePlaylistItem] = []
    @Published var isLoading = false
    @Published var isLoadingVideo = false
    @Published var error: Error?
    @Published var hasPlaybackError = false
    @Published var isPlaying = false
    @Published var userPaused = false
    private var webView: WKWebView
    private var containerView: UIView
    private var enableBackgroundMusic: Bool = false
    private var isLoadingInProgress = false // Track if a load operation is in progress

    static let shared = YouTubePlayerManager()

    private override init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.scrollView.isScrollEnabled = false
        self.containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        self.containerView.isHidden = false
        super.init()
        self.webView.navigationDelegate = self

        self.webView.frame = self.containerView.bounds
        self.containerView.addSubview(self.webView)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            self.containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
            rootViewController.view.addSubview(self.containerView)
            print("Added containerView to root view controller")
        } else {
            print("Failed to find root view controller to add containerView")
        }

        loadBackgroundMusicSetting()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backgroundMusicSettingChanged),
            name: .backgroundMusicSettingChanged,
            object: nil
        )
        fetchVideos()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        webView.removeFromSuperview()
        containerView.removeFromSuperview()
        print("YouTubePlayerManager deinit - Removed containerView and WebView")
    }

    func fetchVideos() {
        isLoading = true
        YouTubeService.shared.fetchPlaylistItems { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let videos):
                    self.videos = videos
                    if videos.isEmpty {
                        self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No videos found in playlist"])
                    } else if self.selectedVideoId == nil {
                        self.selectedVideoId = videos.first?.snippet.resourceId.videoId
                    }
                case .failure(let error):
                    self.error = error
                    self.videos = []
                }
            }
        }
    }

    func loadVideo(videoId: String, shouldPlay: Bool = false) {
        // Prevent concurrent loads
        guard !isLoadingInProgress else {
            print("Load video skipped: Another load is already in progress for video ID: \(videoId)")
            return
        }
        guard !videoId.isEmpty else {
            print("Load video failed: Video ID is empty")
            DispatchQueue.main.async {
                self.isLoadingVideo = false
                self.hasPlaybackError = true
                self.isPlaying = false
                self.userPaused = true
            }
            return
        }

        self.isLoadingInProgress = true
        self.selectedVideoId = videoId
        self.isLoadingVideo = true
        self.hasPlaybackError = false
        self.isPlaying = shouldPlay
        self.userPaused = !shouldPlay

        let embedHTML = """
        <html>
        <body style="margin:0">
        <iframe id="player" width="100%" height="100%" src="https://www.youtube.com/embed/\(videoId)?autoplay=\(shouldPlay ? 1 : 0)&playsinline=1&rel=0&enablejsapi=1" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        <script>
            var player;
            function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    events: {
                        'onReady': function(event) {
                            \(shouldPlay ? "event.target.playVideo();" : "")
                        },
                        'onStateChange': function(event) {
                            if (event.data === YT.PlayerState.PLAYING) {
                                window.webkit.messageHandlers.playbackState.postMessage("playing");
                            } else if (event.data === YT.PlayerState.PAUSED) {
                                window.webkit.messageHandlers.playbackState.postMessage("paused");
                            }
                        },
                        'onError': function(event) {
                            window.webkit.messageHandlers.playbackState.postMessage("error-" + event.data);
                        }
                    }
                });
            }
        </script>
        <script src="https://www.youtube.com/iframe_api"></script>
        </body>
        </html>
        """
        print("Loading video ID: \(videoId), shouldPlay: \(shouldPlay)")
        self.webView.loadHTMLString(embedHTML, baseURL: nil)
        self.webView.configuration.userContentController.add(self, name: "playbackState")
    }

    func pauseVideo() {
        guard isPlaying else { return }
        self.userPaused = true
        self.webView.evaluateJavaScript("player.pauseVideo()") { result, error in
            if let error = error {
                print("Failed to pause video: \(error.localizedDescription)")
            } else {
                print("Video paused by user")
                self.isPlaying = false
            }
        }
    }

    func playVideo() {
        guard !isPlaying else { return }
        self.userPaused = false
        self.webView.evaluateJavaScript("player.playVideo()") { result, error in
            if let error = error {
                print("Failed to play video: \(error.localizedDescription)")
            } else {
                print("Video played")
                self.isPlaying = true
            }
        }
    }

    private func loadBackgroundMusicSetting() {
        enableBackgroundMusic = UserDefaults.standard.bool(forKey: "enableBackgroundMusic")
        updateAudioSession()
    }

    @objc private func backgroundMusicSettingChanged(_ notification: Notification) {
        if let enabled = notification.userInfo?["enabled"] as? Bool {
            enableBackgroundMusic = enabled
            updateAudioSession()
        }
    }

    private func updateAudioSession() {
        do {
            if enableBackgroundMusic {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
                print("Background audio playback enabled")
            } else {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                if isPlaying {
                    pauseVideo()
                }
                print("Background audio playback disabled")
            }
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func getWebView() -> WKWebView {
        return webView
    }
}

extension YouTubePlayerManager: WKNavigationDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoadingVideo = false
            self.isLoadingInProgress = false
            print("WebView finished loading video ID: \(self.selectedVideoId ?? "unknown"), Playback state: \(self.isPlaying ? "Playing" : "Paused")")
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoadingVideo = false
            self.isLoadingInProgress = false
            self.hasPlaybackError = true
            self.isPlaying = false
            self.userPaused = true
            print("WebView failed to load video ID: \(self.selectedVideoId ?? "unknown") - Error: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoadingVideo = false
            self.isLoadingInProgress = false
            self.hasPlaybackError = true
            self.isPlaying = false
            self.userPaused = true
            print("WebView failed provisional navigation for video ID: \(self.selectedVideoId ?? "unknown") - Error: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView started loading video ID: \(self.selectedVideoId ?? "unknown")")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "playbackState", let state = message.body as? String else { return }
        print("Received playback state from JavaScript: \(state), isPlaying: \(isPlaying), userPaused: \(userPaused), enableBackgroundMusic: \(enableBackgroundMusic)")

        switch state {
        case "playing":
            self.isPlaying = true
            self.userPaused = false
        case "paused":
            if isPlaying && !userPaused && enableBackgroundMusic {
                print("Video paused unexpectedly (not user-initiated) while background music is enabled - Resuming playback")
                self.webView.evaluateJavaScript("player.playVideo()") { result, error in
                    if let error = error {
                        print("Failed to resume video: \(error.localizedDescription)")
                    } else {
                        print("Video resumed after unexpected pause")
                    }
                }
            } else {
                self.isPlaying = false
                print("Video paused - Not resuming (userPaused: \(userPaused))")
            }
        case let errorState where errorState.starts(with: "error-"):
            let errorCode = errorState.replacingOccurrences(of: "error-", with: "")
            DispatchQueue.main.async {
                self.isLoadingVideo = false
                self.isLoadingInProgress = false
                self.hasPlaybackError = true
                self.isPlaying = false
                self.userPaused = true
                print("YouTube player error for video ID: \(self.selectedVideoId ?? "unknown") - Error code: \(errorCode)")
            }
        default:
            break
        }
    }
}

struct YouTubePlayerView: View {
    @ObservedObject private var manager = YouTubePlayerManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var lastTappedTime: Date? // For debouncing

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if manager.isLoading {
                ProgressView("Loading Playlist...")
                    .foregroundColor(.white)
            } else if let error = manager.error {
                VStack {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        manager.fetchVideos()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else if manager.videos.isEmpty {
                Text("No videos found in playlist.")
                    .foregroundColor(.white)
                    .padding()
            } else {
                VStack {
                    Text("Popular Church Songs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                        .padding(.bottom, 5)

                    ZStack {
                        YouTubeWebPlayer()
                            .frame(height: manager.videos.isEmpty ? 0 : 300)
                            .cornerRadius(10)
                            .padding()

                        if manager.isLoadingVideo {
                            ProgressView()
                                .foregroundColor(.white)
                        }

                        if manager.hasPlaybackError {
                            VStack {
                                Text("Video unavailable")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Button("Watch on YouTube") {
                                    if let videoId = manager.selectedVideoId ?? manager.videos.first?.snippet.resourceId.videoId {
                                        let youtubeURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
                                        UIApplication.shared.open(youtubeURL)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                            .frame(height: 300)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .padding()
                        } else {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if manager.isPlaying {
                                            manager.pauseVideo()
                                        } else {
                                            manager.playVideo()
                                        }
                                    }) {
                                        Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding()
                                }
                            }
                        }
                    }

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(manager.videos) { item in
                                Button(action: {
                                    // Debounce: Ignore taps within 0.5 seconds of the last tap
                                    let now = Date()
                                    if let lastTap = lastTappedTime, now.timeIntervalSince(lastTap) < 0.5 {
                                        print("Tap ignored - Too soon after last tap")
                                        return
                                    }
                                    lastTappedTime = now
                                    manager.loadVideo(videoId: item.snippet.resourceId.videoId, shouldPlay: true)
                                }) {
                                    HStack {
                                        if let thumbnailUrl = item.snippet.thumbnails?.defaultThumbnail?.url,
                                           let url = URL(string: thumbnailUrl) {
                                            AsyncImage(url: url) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 120, height: 90)
                                            .cornerRadius(5)
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 90)
                                                .foregroundColor(.gray)
                                                .cornerRadius(5)
                                        }
                                        Text(item.snippet.title)
                                            .foregroundColor(manager.selectedVideoId == item.snippet.resourceId.videoId ? .blue : .white)
                                            .lineLimit(2)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                    .background(manager.selectedVideoId == item.snippet.resourceId.videoId ? .gray.opacity(0.2) : .clear)
                                    .cornerRadius(5)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Worship Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            print("YouTubePlayerView dismissed - Playback state: \(manager.isPlaying ? "Playing" : "Paused"), userPaused: \(manager.userPaused)")
        }
    }
}

struct YouTubeWebPlayer: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = YouTubePlayerManager.shared.getWebView()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // WebView is managed by YouTubePlayerManager
    }
}

struct YouTubePlayerView_Previews: PreviewProvider {
    static var previews: some View {
        YouTubePlayerView()
            .preferredColorScheme(.dark)
    }
}
