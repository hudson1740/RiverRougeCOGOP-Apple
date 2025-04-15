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
    private var webView: WKWebView?
    private var containerView: UIView?
    private var enableBackgroundMusic: Bool = false
    private var isLoadingInProgress = false
    private var playableVideoIds: Set<String> = []
    private var lastPlaylistCheck: Date?
    private var isCheckingPlayability = false

    private struct PlayabilityCheckState {
        var currentVideoId: String?
        var currentVideoItem: YouTubePlaylistItem?
        var remainingVideos: [YouTubePlaylistItem] = []
        var checkedVideos: [YouTubePlaylistItem] = []
    }
    private var playabilityCheckState = PlayabilityCheckState()

    static let shared = YouTubePlayerManager()

    private override init() {
        super.init()
        setupWebView()
        loadBackgroundMusicSetting()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backgroundMusicSettingChanged),
            name: .backgroundMusicSettingChanged,
            object: nil
        )
        loadCachedPlayableVideos()
        fetchVideos()
    }

    private func setupWebView() {
        do {
            let configuration = WKWebViewConfiguration()
            configuration.allowsInlineMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            
            self.webView = WKWebView(frame: .zero, configuration: configuration)
            guard let webView = self.webView else {
                print("Failed to initialize WKWebView")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize WKWebView"])
            }
            
            webView.scrollView.isScrollEnabled = false
            self.containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            guard let containerView = self.containerView else {
                print("Failed to initialize containerView")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize containerView"])
            }
            
            containerView.isHidden = false
            webView.frame = containerView.bounds
            containerView.addSubview(webView)
            webView.navigationDelegate = self

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
                rootViewController.view.addSubview(containerView)
                print("Added containerView to root view controller")
            } else {
                print("Failed to find root view controller to add containerView")
            }
        } catch {
            print("Error setting up WebView: \(error.localizedDescription)")
            self.error = error
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        webView?.removeFromSuperview()
        containerView?.removeFromSuperview()
        print("YouTubePlayerManager deinit - Removed containerView and WebView")
    }

    private func loadCachedPlayableVideos() {
        if let cachedIds = UserDefaults.standard.array(forKey: "playableVideoIds") as? [String] {
            self.playableVideoIds = Set(cachedIds)
            print("Loaded \(playableVideoIds.count) cached playable video IDs")
        } else {
            print("No cached playable video IDs found")
        }
        if let lastCheck = UserDefaults.standard.object(forKey: "lastPlaylistCheck") as? Date {
            self.lastPlaylistCheck = lastCheck
            print("Last playlist check: \(lastCheck)")
        }
    }

    private func savePlayableVideos() {
        UserDefaults.standard.set(Array(playableVideoIds), forKey: "playableVideoIds")
        UserDefaults.standard.set(Date(), forKey: "lastPlaylistCheck")
        print("Saved \(playableVideoIds.count) playable video IDs")
    }

    func fetchVideos() {
        print("Fetching videos...")
        isLoading = true
        YouTubeService.shared.fetchPlaylistItems { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let videos):
                    print("Successfully fetched \(videos.count) videos")
                    self.videos = videos
                    if videos.isEmpty {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No playable videos found in playlist"])
                        print("Error: \(error.localizedDescription)")
                        self.error = error
                    }
                case .failure(let error):
                    print("Failed to fetch videos: \(error.localizedDescription)")
                    self.error = error
                    self.videos = []
                }
            }
        }
    }

    func checkAllVideosForPlayability(completion: @escaping () -> Void) {
        guard !isCheckingPlayability else {
            print("Playability check already in progress, skipping")
            return
        }
        guard !videos.isEmpty else {
            print("No videos to check for playability")
            completion()
            return
        }

        print("Starting playability check for \(videos.count) videos")
        isCheckingPlayability = true
        self.playabilityCheckState = PlayabilityCheckState(
            currentVideoId: nil,
            currentVideoItem: nil,
            remainingVideos: videos,
            checkedVideos: []
        )
        self.playableVideoIds.removeAll()

        func checkNextVideo() {
            guard !self.playabilityCheckState.remainingVideos.isEmpty else {
                DispatchQueue.main.async {
                    print("Playability check completed. \(self.playabilityCheckState.checkedVideos.count) videos are playable")
                    self.videos = self.playabilityCheckState.checkedVideos
                    self.savePlayableVideos()
                    if self.playabilityCheckState.checkedVideos.isEmpty {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No playable videos found in playlist"])
                        print("Error: \(error.localizedDescription)")
                        self.error = error
                        self.selectedVideoId = nil
                    } else if self.selectedVideoId == nil || !self.playabilityCheckState.checkedVideos.contains(where: { $0.snippet.resourceId.videoId == self.selectedVideoId }) {
                        self.selectedVideoId = self.playabilityCheckState.checkedVideos.first?.snippet.resourceId.videoId
                        print("Selected first playable video ID: \(self.selectedVideoId ?? "none")")
                        if let nextVideoId = self.selectedVideoId {
                            self.loadVideo(videoId: nextVideoId, shouldPlay: false)
                        }
                    }
                    self.isCheckingPlayability = false
                    completion()
                }
                return
            }

            let video = self.playabilityCheckState.remainingVideos.removeFirst()
            let videoId = video.snippet.resourceId.videoId
            print("Checking playability for video ID: \(videoId)")
            self.playabilityCheckState.currentVideoId = videoId
            self.playabilityCheckState.currentVideoItem = video
            self.loadVideo(videoId: videoId, shouldPlay: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.playabilityCheckState.currentVideoId == videoId {
                    print("Check timeout for video ID: \(videoId) - Treating as unplayable")
                    self.playabilityCheckState.currentVideoId = nil
                    self.playabilityCheckState.currentVideoItem = nil
                    checkNextVideo()
                }
            }
        }

        checkNextVideo()
    }

    func loadVideo(videoId: String, shouldPlay: Bool = false) {
        guard let webView = webView else {
            print("Cannot load video: WKWebView is nil")
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebView not initialized"])
            return
        }

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
                if let index = self.videos.firstIndex(where: { $0.snippet.resourceId.videoId == videoId }) {
                    self.videos.remove(at: index)
                    self.playableVideoIds.remove(videoId)
                    self.savePlayableVideos()
                    print("Removed unplayable video ID: \(videoId) from list due to empty ID")
                }
                if self.videos.isEmpty {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No playable videos found in playlist"])
                    print("Error: \(error.localizedDescription)")
                    self.error = error
                    self.selectedVideoId = nil
                } else {
                    self.selectedVideoId = self.videos.first?.snippet.resourceId.videoId
                    if let nextVideoId = self.selectedVideoId {
                        self.loadVideo(videoId: nextVideoId, shouldPlay: false)
                    }
                }
            }
            return
        }

        self.isLoadingInProgress = true
        self.selectedVideoId = videoId
        self.isLoadingVideo = true
        self.hasPlaybackError = false
        self.isPlaying = shouldPlay
        self.userPaused = !shouldPlay

        webView.configuration.userContentController.removeScriptMessageHandler(forName: "playbackState")

        let embedHTML = """
        <html>
        <body style="margin:0">
        <div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
            var player;
            var errorOccurred = false;
            function onYouTubeIframeAPIReady() {
                try {
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '\(videoId)',
                        playerVars: {
                            'autoplay': \(shouldPlay ? 1 : 0),
                            'playsinline': 1,
                            'rel': 0,
                            'enablejsapi': 1
                        },
                        events: {
                            'onReady': function(event) {
                                try {
                                    \(shouldPlay ? "event.target.playVideo();" : "")
                                    window.webkit.messageHandlers.playbackState.postMessage("ready");
                                } catch (e) {
                                    window.webkit.messageHandlers.playbackState.postMessage("error-" + (e.message || "unknown"));
                                }
                            },
                            'onStateChange': function(event) {
                                try {
                                    if (event.data === YT.PlayerState.PLAYING) {
                                        window.webkit.messageHandlers.playbackState.postMessage("playing");
                                    } else if (event.data === YT.PlayerState.PAUSED) {
                                        window.webkit.messageHandlers.playbackState.postMessage("paused");
                                    }
                                } catch (e) {
                                    window.webkit.messageHandlers.playbackState.postMessage("error-" + (e.message || "unknown"));
                                }
                            },
                            'onError': function(event) {
                                errorOccurred = true;
                                window.webkit.messageHandlers.playbackState.postMessage("error-" + event.data);
                            }
                        }
                    });
                } catch (e) {
                    errorOccurred = true;
                    window.webkit.messageHandlers.playbackState.postMessage("error-" + (e.message || "unknown"));
                }
            }
            function getPlayerState() {
                try {
                    return player ? player.getPlayerState() : -1;
                } catch (e) {
                    return -1;
                }
            }
        </script>
        </body>
        </html>
        """
        print("Loading video ID: \(videoId), shouldPlay: \(shouldPlay)")
        webView.loadHTMLString(embedHTML, baseURL: nil)
        webView.configuration.userContentController.add(self, name: "playbackState")
    }

    func pauseVideo() {
        guard isPlaying else {
            print("Pause video skipped: Video is not playing")
            return
        }
        guard let webView = webView else {
            print("Cannot pause video: WKWebView is nil")
            return
        }
        self.userPaused = true
        webView.evaluateJavaScript("player.pauseVideo()") { result, error in
            if let error = error {
                print("Failed to pause video: \(error.localizedDescription)")
            } else {
                print("Video paused by user")
                self.isPlaying = false
            }
        }
    }

    func playVideo() {
        guard !isPlaying else {
            print("Play video skipped: Video is already playing")
            return
        }
        guard let webView = webView else {
            print("Cannot play video: WKWebView is nil")
            return
        }
        self.userPaused = false
        webView.evaluateJavaScript("player.playVideo()") { result, error in
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
        print("Loaded background music setting: \(enableBackgroundMusic)")
        updateAudioSession()
    }

    @objc private func backgroundMusicSettingChanged(_ notification: Notification) {
        if let enabled = notification.userInfo?["enabled"] as? Bool {
            enableBackgroundMusic = enabled
            print("Background music setting changed: \(enabled)")
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

    func getWebView() -> WKWebView? {
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
            if let currentId = self.selectedVideoId,
               let currentIndex = self.videos.firstIndex(where: { $0.snippet.resourceId.videoId == currentId }) {
                self.videos.remove(at: currentIndex)
                self.playableVideoIds.remove(currentId)
                self.savePlayableVideos()
                print("Removed unplayable video ID: \(currentId) from list due to navigation failure")
            }
            if self.isCheckingPlayability, self.playabilityCheckState.currentVideoId == self.selectedVideoId {
                self.playabilityCheckState.currentVideoId = nil
                self.playabilityCheckState.currentVideoItem = nil
                self.checkAllVideosForPlayability { }
            } else {
                if self.videos.isEmpty {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No playable videos found in playlist"])
                    print("Error: \(error.localizedDescription)")
                    self.error = error
                    self.selectedVideoId = nil
                } else {
                    self.selectedVideoId = self.videos.first?.snippet.resourceId.videoId
                    if let nextVideoId = self.selectedVideoId {
                        self.loadVideo(videoId: nextVideoId, shouldPlay: false)
                    }
                }
            }
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
            if let currentId = self.selectedVideoId,
               let currentIndex = self.videos.firstIndex(where: { $0.snippet.resourceId.videoId == currentId }) {
                self.videos.remove(at: currentIndex)
                self.playableVideoIds.remove(currentId)
                self.savePlayableVideos()
                print("Removed unplayable video ID: \(currentId) from list due to provisional navigation failure")
            }
            if self.isCheckingPlayability, self.playabilityCheckState.currentVideoId == self.selectedVideoId {
                self.playabilityCheckState.currentVideoId = nil
                self.playabilityCheckState.currentVideoItem = nil
                self.checkAllVideosForPlayability { }
            } else {
                if self.videos.isEmpty {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No playable videos found in playlist"])
                    print("Error: \(error.localizedDescription)")
                    self.error = error
                    self.selectedVideoId = nil
                } else {
                    self.selectedVideoId = self.videos.first?.snippet.resourceId.videoId
                    if let nextVideoId = self.selectedVideoId {
                        self.loadVideo(videoId: nextVideoId, shouldPlay: false)
                    }
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView started loading video ID: \(self.selectedVideoId ?? "unknown")")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "playbackState", let state = message.body as? String else { return }
        guard let webView = message.webView else {
            print("Cannot process script message: WKWebView is nil")
            return
        }

        print("Received playback state from JavaScript: \(state), isPlaying: \(isPlaying), userPaused: \(userPaused), enableBackgroundMusic: \(enableBackgroundMusic)")

        switch state {
        case "ready":
            if self.isCheckingPlayability, let videoId = self.playabilityCheckState.currentVideoId,
               let videoItem = self.playabilityCheckState.currentVideoItem,
               videoId == self.selectedVideoId {
                print("Check succeeded for video ID: \(videoId)")
                self.playableVideoIds.insert(videoId)
                self.playabilityCheckState.checkedVideos.append(videoItem)
                self.playabilityCheckState.currentVideoId = nil
                self.playabilityCheckState.currentVideoItem = nil
                self.checkAllVideosForPlayability { }
            }
        case "playing":
            self.isPlaying = true
            self.userPaused = false
        case "paused":
            if isPlaying && !userPaused && enableBackgroundMusic {
                print("Video paused unexpectedly (not user-initiated) while background music is enabled - Resuming playback")
                self.webView?.evaluateJavaScript("player.playVideo()") { result, error in
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
                if let currentId = self.selectedVideoId,
                   let currentIndex = self.videos.firstIndex(where: { $0.snippet.resourceId.videoId == currentId }) {
                    self.videos.remove(at: currentIndex)
                    self.playableVideoIds.remove(currentId)
                    self.savePlayableVideos()
                    print("Removed unplayable video ID: \(currentId) from list due to playback error")
                }
                if self.isCheckingPlayability, self.playabilityCheckState.currentVideoId == self.selectedVideoId {
                    self.playabilityCheckState.currentVideoId = nil
                    self.playabilityCheckState.currentVideoItem = nil
                    self.checkAllVideosForPlayability { }
                } else {
                    if self.videos.isEmpty {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No playable videos found in playlist"])
                        print("Error: \(error.localizedDescription)")
                        self.error = error
                        self.selectedVideoId = nil
                    } else {
                        self.selectedVideoId = self.videos.first?.snippet.resourceId.videoId
                        if let nextVideoId = self.selectedVideoId {
                            self.loadVideo(videoId: nextVideoId, shouldPlay: false)
                        }
                    }
                }
            }
        default:
            print("Unknown playback state received: \(state)")
        }
    }
}

struct YouTubePlayerView: View {
    @ObservedObject private var manager = YouTubePlayerManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var lastTappedTime: Date?
    @State private var searchText: String = ""
    @State private var scrollToTop: Bool = false
    @State private var hasCheckedPlayability: Bool = false
    @State private var showFullDisclaimer: Bool = false // State for showing full disclaimer

    var filteredVideos: [YouTubePlaylistItem] {
        if searchText.isEmpty {
            return manager.videos
        } else {
            return manager.videos.filter {
                $0.snippet.title.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.black, .purple.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if manager.isLoading {
                ProgressView("Loading Playlist...")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            } else if let error = manager.error {
                VStack {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        manager.fetchVideos()
                        hasCheckedPlayability = false
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding()
            } else if manager.videos.isEmpty {
                Text("No playable videos found in playlist.")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            } else {
                VStack {
                    Text("Regularly Played Church Songs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                        .padding(.bottom, 5)

                    ZStack {
                        YouTubeWebPlayer()
                            .frame(height: manager.videos.isEmpty ? 0 : 300)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: .black.opacity(0.3), radius: 5)

                        if manager.isLoadingVideo {
                            ProgressView()
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
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
                                .shadow(radius: 5)
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
                                            .shadow(radius: 3)
                                    }
                                    .padding()
                                    .disabled(manager.isLoadingVideo)
                                }
                            }
                        }
                    }

                    // Search bar with refresh button
                    HStack {
                        TextField("Search videos...", text: $searchText)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)

                        Button(action: {
                            searchText = ""
                            hasCheckedPlayability = false
                            manager.videos = []
                            manager.selectedVideoId = nil
                            manager.error = nil
                            manager.fetchVideos()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 2)

                    // Short disclaimer text, tappable to show full disclaimer
                    Text("Videos are from YouTube. We don’t own them. See YouTube’s Terms.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .onTapGesture {
                            showFullDisclaimer = true
                        }

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredVideos) { item in
                                    Button(action: {
                                        let now = Date()
                                        if let lastTap = lastTappedTime, now.timeIntervalSince(lastTap) < 1.0 {
                                            print("Tap ignored - Too soon after last tap")
                                            return
                                        }
                                        lastTappedTime = now
                                        manager.loadVideo(videoId: item.snippet.resourceId.videoId, shouldPlay: false)
                                    }) {
                                        HStack {
                                            if let thumbnailUrl = item.snippet.thumbnails?.defaultThumbnail?.url,
                                               let url = URL(string: thumbnailUrl), !thumbnailUrl.isEmpty {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 120, height: 90)
                                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                                            .shadow(radius: 3)
                                                    case .failure, .empty:
                                                        Image(systemName: "music.note")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 120, height: 90)
                                                            .foregroundColor(.gray)
                                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                                    @unknown default:
                                                        Image(systemName: "music.note")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 120, height: 90)
                                                            .foregroundColor(.gray)
                                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                                    }
                                                }
                                            } else {
                                                Image(systemName: "music.note")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 120, height: 90)
                                                    .foregroundColor(.gray)
                                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                            }
                                            Text(item.snippet.title)
                                                .foregroundColor(manager.selectedVideoId == item.snippet.resourceId.videoId ? .blue : .white)
                                                .lineLimit(2)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                        }
                                        .padding(.vertical, 5)
                                        .background(manager.selectedVideoId == item.snippet.resourceId.videoId ? Color.gray.opacity(0.2) : .clear)
                                        .cornerRadius(5)
                                        .padding(.horizontal, 5)
                                        .id(item.snippet.resourceId.videoId)
                                    }
                                    .disabled(manager.isLoadingVideo)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .onAppear {
                            if !hasCheckedPlayability {
                                hasCheckedPlayability = true
                                manager.checkAllVideosForPlayability {
                                    withAnimation {
                                        proxy.scrollTo(filteredVideos.first?.snippet.resourceId.videoId, anchor: .top)
                                    }
                                }
                            }
                        }
                        .onChange(of: scrollToTop) { _ in
                            withAnimation {
                                proxy.scrollTo(filteredVideos.first?.snippet.resourceId.videoId, anchor: .top)
                            }
                        }
                    }
                }
                .alert(isPresented: $showFullDisclaimer) {
                    Alert(
                        title: Text("Disclaimer"),
                        message: Text("This app, RiverRougeCOGOP, uses the YouTube API Services to retrieve and display videos from a playlist of popular church songs. We do not own or claim ownership of these videos. All video content is hosted on YouTube and is owned by its respective creators or rights holders. By using this app, you agree to YouTube’s Terms of Service (https://www.youtube.com/t/terms) and Privacy Policy (https://policies.google.com/privacy). We are not responsible for the availability, accuracy, usefulness, safety, or legality of the content, and you access it at your own risk."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .navigationTitle("Worship Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            print("YouTubePlayerView dismissed - Playback state: \(manager.isPlaying ? "Playing" : "Paused"), userPaused: \(manager.userPaused)")
            manager.pauseVideo()
        }
    }
}

struct YouTubeWebPlayer: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        return YouTubePlayerManager.shared.getWebView() ?? WKWebView()
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
