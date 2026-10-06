import AVFoundation
import Flutter
import Speech
import UIKit

/// All media state belongs to the main actor. The app never records or speaks
/// to a recognizer after entering the background.
@MainActor
final class VoiceMemoBridge: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private static var retained: VoiceMemoBridge?
    static func register(messenger: FlutterBinaryMessenger) {
        let bridge = VoiceMemoBridge(messenger: messenger)
        retained = bridge
    }

    private let channel: FlutterMethodChannel
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var recordingURL: URL?
    private var playbackURL: URL?
    private var durationMs = 0
    private var interrupted = false
    private var permissionOperation: UUID?
    private var speechTask: SFSpeechRecognitionTask?
    private var speechResult: FlutterResult?
    private var speechOperation: UUID?
    private var speechTimeout: Task<Void, Never>?

    private init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.appsbay.onlynote/voice_memos", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { result(FlutterMethodNotImplemented); return }
            Task { @MainActor in await self.handle(call, result: result) }
        }
        for name in [UIApplication.didEnterBackgroundNotification, AVAudioSession.interruptionNotification,
                     AVAudioSession.mediaServicesWereResetNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.background() }
            })
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) async {
        do {
            let args = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "state": result(state())
            case "startRecording":
                guard UIApplication.shared.applicationState != .background else { result(error("cancelled")); return }
                guard recorder == nil, permissionOperation == nil, speechResult == nil else {
                    result(error("busy")); return
                }
                let url = try ownedURL(args["path"] as? String, recording: true)
                guard !FileManager.default.fileExists(atPath: url.path) else {
                    result(error("file_exists")); return
                }
                let operation = UUID()
                permissionOperation = operation
                let allowed: Bool
                if #available(iOS 17.0, *) { allowed = await AVAudioApplication.requestRecordPermission() }
                else {
                    allowed = await withCheckedContinuation { continuation in
                        AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
                    }
                }
                guard permissionOperation == operation else { result(error("cancelled")); return }
                permissionOperation = nil
                guard allowed else { result(error("permission_denied")); return }
                stopPlayback()
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)
                let audio = try AVAudioRecorder(url: url, settings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100.0, AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                ])
                audio.delegate = self
                guard audio.prepareToRecord(), audio.record(forDuration: 300) else {
                    try? FileManager.default.removeItem(at: url)
                    result(error("record_failed")); return
                }
                recorder = audio
                recordingURL = url
                playbackURL = nil
                durationMs = 0
                interrupted = false
                startTimer()
                emit()
                result(state())
            case "stopRecording": stopRecording(); result(state())
            case "cancelRecording":
                permissionOperation = nil
                stopRecording()
                // Dart ownership journal removes a cancelled draft; native code never
                // deletes a previous memo just because a new permission request failed.
                recordingURL = nil; durationMs = 0; interrupted = false
                emit(); result(state())
            case "play":
                guard UIApplication.shared.applicationState != .background else { result(error("cancelled")); return }
                guard recorder == nil, permissionOperation == nil, speechResult == nil else { result(error("busy")); return }
                let url = try ownedURL(args["path"] as? String)
                if playbackURL == url, let player {
                    try AVAudioSession.sharedInstance().setActive(true)
                    player.play()
                } else {
                    stopPlayback()
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
                    try AVAudioSession.sharedInstance().setActive(true)
                    let audio = try AVAudioPlayer(contentsOf: url)
                    audio.delegate = self
                    guard audio.prepareToPlay(), audio.play() else { result(error("play_failed")); return }
                    player = audio; playbackURL = url
                }
                startTimer(); emit(); result(state())
            case "pause":
                player?.pause()
                timer?.invalidate(); timer = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                emit(); result(state())
            case "stopPlayback": stopPlayback(); emit(); result(state())
            case "duration":
                let url = try ownedURL(args["path"] as? String)
                let seconds = try await AVURLAsset(url: url).load(.duration).seconds
                guard seconds.isFinite, seconds > 0, seconds <= 300.5 else { result(error("invalid_audio")); return }
                result(Int(seconds * 1000))
            case "transcribe":
                guard UIApplication.shared.applicationState != .background else { result(error("cancelled")); return }
                guard recorder == nil, permissionOperation == nil, speechResult == nil else { result(error("busy")); return }
                let url = try ownedURL(args["path"] as? String)
                stopPlayback()
                let operation = UUID()
                speechOperation = operation; speechResult = result
                let authorization = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
                }
                guard speechOperation == operation else { return }
                guard authorization == .authorized else { finishSpeech(error("permission_denied")); return }
                let locale = Locale(identifier: args["locale"] as? String ?? Locale.current.identifier)
                guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable,
                      recognizer.supportsOnDeviceRecognition else { finishSpeech(error("transcription_unavailable")); return }
                let request = SFSpeechURLRecognitionRequest(url: url)
                request.requiresOnDeviceRecognition = true
                request.shouldReportPartialResults = false
                speechTask = recognizer.recognitionTask(with: request) { [weak self] recognition, failure in
                    Task { @MainActor in
                        guard let self, self.speechOperation == operation else { return }
                        if let recognition, recognition.isFinal {
                            let transcript = recognition.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                            self.finishSpeech(transcript.isEmpty ? self.error("no_speech") : transcript)
                        } else if failure != nil { self.finishSpeech(self.error("transcription_failed")) }
                    }
                }
                speechTimeout = Task { @MainActor [weak self] in
                    do { try await Task.sleep(nanoseconds: 60_000_000_000) } catch { return }
                    guard self?.speechOperation == operation else { return }
                    self?.finishSpeech(self?.error("transcription_timeout"))
                }
                emit()
            case "cancelTranscription": finishSpeech(error("cancelled")); result(state())
            case "background": background(); result(state())
            default: result(FlutterMethodNotImplemented)
            }
        } catch {
            if recorder == nil && player == nil {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
            result(self.error("media_failed", message: error.localizedDescription))
        }
    }

    private func ownedURL(_ path: String?, recording: Bool = false) throws -> URL {
        guard let path, path.hasPrefix("/"), !path.contains("\0"), !path.split(separator: "/").contains("..") else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        let url = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        let roots = [FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                     FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first].compactMap { $0 }
        let owned = roots.contains { root in
            let canonical = root.standardizedFileURL.resolvingSymlinksInPath().path
            return url.path.hasPrefix(canonical + "/note_audio/") || (!recording && url.path.hasPrefix(canonical + "/template_audio/"))
        }
        guard owned, url.pathExtension.lowercased() == "m4a" else { throw CocoaError(.fileReadNoPermission) }
        if recording { try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true) }
        return url
    }
    private func state() -> [String: Any] {
        let phase = recorder != nil ? "recording" : speechResult != nil ? "transcribing" : player?.isPlaying == true ? "playing" : player != nil ? "paused" : "idle"
        let recognizer = SFSpeechRecognizer()
        return ["phase": phase, "path": playbackURL?.path ?? recordingURL?.path ?? "",
                "durationMs": recorder.map { Int($0.currentTime * 1000) } ?? player.map { Int($0.duration * 1000) } ?? durationMs,
                "positionMs": player.map { Int($0.currentTime * 1000) } ?? 0,
                "interrupted": interrupted,
                "transcriptionSupported": recognizer?.supportsOnDeviceRecognition == true]
    }
    private func emit() {
        if let recorder { durationMs = Int(recorder.currentTime * 1000) }
        channel.invokeMethod("stateChanged", arguments: state())
    }
    private func error(_ code: String, message: String? = nil) -> FlutterError { FlutterError(code: code, message: message ?? code, details: nil) }
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.emit() }
        }
    }
    private func stopRecording() {
        guard let audio = recorder else { return }
        durationMs = Int(audio.currentTime * 1000)
        audio.stop(); recorder = nil
        timer?.invalidate(); timer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        emit()
    }
    private func stopPlayback() {
        player?.stop(); player = nil; playbackURL = nil
        timer?.invalidate(); timer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private func finishSpeech(_ value: Any?) {
        let result = speechResult
        speechResult = nil; speechOperation = nil
        speechTask?.cancel(); speechTask = nil
        speechTimeout?.cancel(); speechTimeout = nil
        emit(); result?(value)
    }
    private func background() {
        permissionOperation = nil
        interrupted = interrupted || recorder != nil
        stopRecording(); stopPlayback(); finishSpeech(error("cancelled")); emit()
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard self.recorder === recorder else { return }
        durationMs = flag ? Int(((try? AVAudioPlayer(contentsOf: recorder.url).duration)
            ?? Double(durationMs) / 1000) * 1000) : 0
        self.recorder = nil; timer?.invalidate(); timer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        emit()
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { stopPlayback(); emit() }
}
