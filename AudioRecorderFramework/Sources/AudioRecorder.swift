//
//  Recorder.swift
//  AudioRecorder
//
//  Created by Clay on 5/18/17.
//  Copyright © 2017 Clay Ellis. All rights reserved.
//

import UIKit
import AVFoundation

public protocol AudioRecorderControllerDelegate: class {
    func audioRecorderControllerDidCancel(_ recorder: AudioRecorderController)
    func audioRecorderController(_ recorder: AudioRecorderController, didFinishRecordingAudioWithURL audioURL: URL)
}

open class AudioRecorderController: UIViewController {
    
    open weak var delegate: AudioRecorderControllerDelegate?
    open var outputFileType: AVFileType = .mp4
    open var allowsAudioPortSelection = true
    open var defaultAudioPort: AudioPort = .default
    
    fileprivate let _navigationController = UINavigationController()
    fileprivate let _controller = _AudioRecorderController()
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        loadInternalViewHierarchy()
    }
    
    private func loadInternalViewHierarchy() {
        _controller.parentController = self
        _navigationController.view.backgroundColor = .black
        addChildViewController(_navigationController)
        _navigationController.didMove(toParentViewController: self)
        view.addAutoLayoutSubview(_navigationController.view)
        _navigationController.view.fillSuperview()
        _navigationController.setViewControllers([_controller], animated: false)
    }
    
}

public enum AudioPort {
    case `default`
    case speaker
}

internal class _AudioRecorderController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    private enum State {
        case empty
        case recording
        case paused
        case playing
        case cancelled
        case saved
        case error(message: String)
    }

    // MARK: Members
    
    fileprivate weak var parentController: AudioRecorderController!
    private let contentView = _AudioRecorderView()
    
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer?
    private let composer = TrackMerger()
    
    // MARK: Properties
    
    private var previousState: State = .empty
    private var state: State = .empty {
        didSet {
            previousState = oldValue
            stateDidChange()
        }
    }
    
    private var audioPort: AudioPort = .default {
        didSet {
            audioPortDidChange()
        }
    }
    
    /// The recording timestamp in milliseconds
    private var recordingTimestamp: TimeInterval = 0 {
        didSet {
            updateTimestampLabel(with: recordingTimestamp)
        }
    }
    
    /// The playback timestamp in milliseconds
    private var playbackTimestamp: TimeInterval = 0 {
        didSet {
            updateTimestampLabel(with: playbackTimestamp)
        }
    }
    
    private var recordingTimer: Timer?
    private var playingTimer: Timer?
    
    /// The `URL` at which the newly recorded audio will be found
    private var outputURL: URL!
    
    // MARK: Lifecycle
    
    deinit {
        teardown()
    }
    
    override func loadView() {
        edgesForExtendedLayout = []
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    // MARK: Member Configuration
    
    private func configure() {
        configureNavigationBar()
        state = .empty
        configureButtonTargets()
        configureOutputURL()
        // The audio recorder starts recording at the outputURL.
        // Each time the recorder is paused, it begins recording to a new temporary file.
        configureAudioRecorder(with: outputURL)
        recordingTimestamp = 0
        playbackTimestamp = 0
        audioPort = parentController.defaultAudioPort
        contentView.portButton.isHidden = !parentController.allowsAudioPortSelection
    }
    
    private func configureNavigationBar() {
        title = "Record Audio"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        navigationController?.navigationBar.barStyle = .black
    }
    
    private func configureButtonTargets() {
        contentView.recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        contentView.playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        contentView.portButton.addTarget(self, action: #selector(portTapped), for: .touchUpInside)
    }
    
    private func configureOutputURL() {
        outputURL = newRecordingURL
    }
    
    private var newRecordingURL: URL {
        var fileExtension = ".mp4"
        switch parentController.outputFileType {
        case .mp4: fileExtension = ".mp4"
        case .m4a: fileExtension = ".m4a"
        case .ac3: fileExtension = ".ac3"
        case .amr: fileExtension = ".amr"
        case .aifc: fileExtension = ".aifc"
        case .aiff: fileExtension = ".aiff"
        case .mp3: fileExtension = ".mp3"
        default: break
        }
        let filename = "\(UUID().uuidString)\(fileExtension)"
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: documentsPath).appendingPathComponent(filename)
    }
    
    private func configureAudioRecorder(with url: URL? = nil) {
        let settings = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 16000, AVNumberOfChannelsKey: 2]
        do {
            audioRecorder = try AVAudioRecorder(url: url ?? newRecordingURL, settings: settings)
            audioRecorder.delegate = self
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
    
    private func configureAudioPlayer(with url: URL? = nil) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url ?? audioRecorder.url)
            audioPlayer?.delegate = self
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
    
    private func routeAudio(to port: AudioPort) {
        do {
            let session = AVAudioSession.sharedInstance()
            switch port {
            case .default:
                try session.overrideOutputAudioPort(.none)
            case .speaker:
                try session.overrideOutputAudioPort(.speaker)
            }
        } catch {
            if port != .default {
                audioPort = .default
            }
        }
    }
    
    // MARK: AVAudioRecorderDelegate
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        state = .error(message: error?.localizedDescription ?? "Error encoding audio")
    }
    
    // MARK: AVAudioPlayerDelegate
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        state = .error(message: error?.localizedDescription ?? "Error decoding audio for playback")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .paused
    }
    
    // MARK: Button Targets
    
    @objc
    private func cancelTapped() {
        state = .cancelled
    }
    
    @objc
    private func saveTapped() {
        state = .saved
    }
    
    @objc
    private func recordTapped() {
        if case .recording = state {
            state = .paused
        } else {
            state = .recording
        }
    }
    
    @objc
    private func playTapped() {
        if case .playing = state {
            state = .paused
        } else {
            state = .playing
        }
    }
    
    @objc
    private func portTapped() {
        if audioPort == .default {
            audioPort = .speaker
        } else {
            audioPort = .default
        }
    }
    
    // MARK: State
    
    private func stateDidChange() {
        switch (previousState, state) {
        case (_, .empty):
            break
            
        case (.empty, .recording):
            startRecording()
            
        case (.paused, .recording):
            resumeRecording()
            
        case (.recording, .paused):
            pauseRecording()
            
        case (.paused, .playing):
            if let player = audioPlayer, player.currentTime != 0 {
                resumePlaying()
            } else {
                startPlaying()
            }
            
        case (.playing, .paused):
            pausePlaying()
            
        case (_, .cancelled):
            cancel()
            
        case (_, .saved):
            save()
            
        case (_, .error):
            // Errors are handled automatically in updateUI(for:)
            break
            
        default:
            fatalError("AudioRecorderController: Unknown state reached. Previous: \(previousState), Current: \(state)")
        }
        
        updateUI(for: state)
    }
    
    private func audioPortDidChange() {
        routeAudio(to: audioPort)
        updatePortButton(for: audioPort)
    }
    
    // MARK: - Logic
    
    private func cancel() {
        parentController.delegate?.audioRecorderControllerDidCancel(parentController)
    }
    
    private func save() {
        parentController.delegate?.audioRecorderController(parentController, didFinishRecordingAudioWithURL: outputURL)
    }
    
    // MARK: Recording
    
    private func startRecording() {
        recordingTimestamp = 0
        startRecordingTimer()
        audioRecorder.deleteRecording()
        audioRecorder.record()
    }
    
    private func resumeRecording() {
        configureAudioRecorder(with: newRecordingURL)
        startRecordingTimer()
        audioRecorder.record()
    }
    
    private func pauseRecording() {
        stopRecordingTimer()
        if audioRecorder.isRecording {
            audioRecorder.stop()
            composer.merge(trackAt: audioRecorder.url, intoTrackAt: outputURL, outputFileType: parentController.outputFileType) {
                [unowned self] url, error in
                if let error = error {
                    switch error {
                    case .urlsNotUnique:
                        self.configureAudioPlayer(with: self.audioRecorder.url)
                    default:
                        self.state = .error(message: error.localizedDescription)
                    }
                } else {
                    self.configureAudioPlayer(with: url)
                }
            }
        }
    }
    
    private func stopRecording() {
        stopRecordingTimer()
        if audioRecorder.isRecording {
            audioRecorder.stop()
        }
    }
    
    private func startRecordingTimer() {
        stopRecordingTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) {
            [weak self] _ in
            self?.recordingTimestamp += 1
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
    }
    
    // MARK: Playback
    
    private func startPlaying() {
        configureAudioPlayer(with: outputURL)
        playbackTimestamp = 0
        startPlaybackTimer()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
    
    private func resumePlaying() {
        startPlaybackTimer()
        audioPlayer?.play()
    }
    
    private func pausePlaying() {
        stopPlaybackTimer()
        if let player = audioPlayer, player.isPlaying {
            audioPlayer?.pause()
        }
    }
    
    private func stopPlaying() {
        stopPlaybackTimer()
        if let player = audioPlayer, player.isPlaying {
            audioPlayer?.stop()
        }
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) {
            [weak self] _ in
            self?.playbackTimestamp += 1
        }
    }
    
    private func stopPlaybackTimer() {
        playingTimer?.invalidate()
    }
    
    // MARK: UI Updates
    
    private func updateUI(for state: State) {
        updateCancelButton(for: state)
        updateSaveButton(for: state)
        updateTimestampLabel(for: state)
        updateRecordButton(for: state)
        updatePlayButton(for: state)
        updateErrorLabel(for: state)
    }
    
    private func updateCancelButton(for state: State) {
        let button = navigationItem.leftBarButtonItem
        switch state {
        default: button?.isEnabled = true
        }
    }
    
    private func updateSaveButton(for state: State) {
        let button = navigationItem.rightBarButtonItem
        switch state {
        case .paused:
            button?.isEnabled = true
            
        default:
            button?.isEnabled = false
        }
    }
    
    private func updateTimestampLabel(for state: State) {
        let label = contentView.timestampLabel
        switch state {
        case .empty, .paused:
            label.textColor = UIColor.white.withAlphaComponent(0.5)
        default:
            label.textColor = .white
        }
    }
    
    /// Displays the `time` in "00:00.00" format
    ///
    /// - Parameter time: The timestamp to display (in milliseconds)
    private func updateTimestampLabel(with time: TimeInterval) {
        let t = Int(time)
        let mil = t % 60
        let sec = (t / 60) % 60
        let min = t / 3600
        let format = "%02d:%02d.%02d"
        let timestamp = String(format: format, min, sec, mil)
        contentView.timestampLabel.text = timestamp
    }
    
    private func updateRecordButton(for state: State) {
        let button = contentView.recordButton
        animateChanges(on: button) {
            switch state {
            case .empty:
                button.isSelected = false
                button.isEnabled = true
                
            case .recording:
                button.isSelected = true
                button.isEnabled = true
                
            case .paused:
                button.isSelected = false
                button.isEnabled = true
                
            default:
                button.isSelected = false
                button.isEnabled = false
            }
        }
    }
    
    private func updatePlayButton(for state: State) {
        let button = contentView.playButton
        animateChanges(on: button) {
            switch state {
            case .empty:
                button.isSelected = false
                button.isEnabled = false
                
            case .playing:
                button.isSelected = true
                button.isEnabled = true
                
            case .paused:
                button.isSelected = false
                button.isEnabled = true
                
            default:
                button.isSelected = false
                button.isEnabled = false
            }
        }
    }
    
    private func updateErrorLabel(for state: State) {
        let label = contentView.errorLabel
        switch state {
        case .error(let message):
            label.text = message
            label.isHidden = false
            
        default:
            label.isHidden = true
        }
    }
    
    private func updatePortButton(for port: AudioPort) {
        let button = contentView.portButton
        switch port {
        case .default:
            button.isSelected = false
        case .speaker:
            button.isSelected = true
        }
    }
    
    private func animateChanges(on view: UIView, _ changes: @escaping () -> ()) {
        UIView.transition(with: view,
                          duration: 0.3,
                          options: [.transitionCrossDissolve, .curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                          animations: changes,
                          completion: nil)
    }
    
    // MARK: System Notifications
    
    private func registerForNotifications() {
        // add a "backgrounded" state
        // stop recording
        // NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    private func unregisterFromNotifications() {
        // NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Teardown
    
    private func teardown() {
        unregisterFromNotifications()
        stopRecording()
        stopPlaying()
    }
    
}

fileprivate class _AudioRecorderView: UIView {
    
    let errorLabel = UILabel()
    let timestampLabel = UILabel()
    let recordButton = UIButton()
    let playButton = UIButton()
    let portButton = UIButton()
    
    private let verticalStack = UIStackView()
    private let horizontalStack = UIStackView()
    
    init() {
        super.init(frame: .zero)
        configureSubviews()
        configureLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        backgroundColor = .black
        
        errorLabel.textAlignment = .center
        errorLabel.textColor = .red
        errorLabel.font = UIFont.preferredFont(forTextStyle: .body)
        errorLabel.numberOfLines = 0
        
        timestampLabel.textAlignment = .center
        timestampLabel.textColor = .white
        
        let timestampFont = UIFont.monospacedDigitSystemFont(ofSize: 45, weight: UIFont.Weight.ultraLight)
        timestampLabel.font = timestampFont
        
        func image(named name: String) -> UIImage? {
            return UIImage(named: name, in: Bundle(for: AudioRecorderController.self), compatibleWith: nil)
        }
        
        recordButton.setImage(image(named: "Record Button"), for: .normal)
        recordButton.setImage(image(named: "Record Button Highlighted"), for: .highlighted)
        recordButton.setImage(image(named: "Record Button Disabled"), for: .disabled)
        recordButton.setImage(image(named: "Stop Button"), for: .selected)
        recordButton.setImage(image(named: "Stop Button Highlighted"), for: [.selected, .highlighted])
        recordButton.setImage(image(named: "Stop Button Disabled"), for: [.selected, .disabled])
        
        playButton.setImage(image(named: "Play Button"), for: .normal)
        playButton.setImage(image(named: "Play Button Highlighted"), for: .highlighted)
        playButton.setImage(image(named: "Play Button Disabled"), for: .disabled)
        playButton.setImage(image(named: "Pause Button"), for: .selected)
        playButton.setImage(image(named: "Pause Button Highlighted"), for: [.selected, .highlighted])
        playButton.setImage(image(named: "Pause Button Disabled"), for: [.selected, .disabled])
        
        portButton.setImage(image(named: "Speaker"), for: .normal)
        portButton.setImage(image(named: "Speaker Highlighted"), for: .highlighted)
        portButton.setImage(image(named: "Speaker Selected"), for: .selected)
        portButton.setImage(image(named: "Speaker Selected Highlighted"), for: [.selected, .highlighted])
        portButton.contentHorizontalAlignment = .right
        
        verticalStack.axis = .vertical
        verticalStack.spacing = 60
        verticalStack.alignment = .center
        
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 50
        horizontalStack.alignment = .center
    }
    
    private func configureLayout() {
        addAutoLayoutSubview(portButton)
        addAutoLayoutSubview(errorLabel)
        addAutoLayoutSubview(verticalStack)
        verticalStack.addArrangedSubview(timestampLabel)
        verticalStack.addArrangedSubview(horizontalStack)
        horizontalStack.addArrangedSubview(playButton)
        horizontalStack.addArrangedSubview(recordButton)
        verticalStack.centerInSuperview()
        
        NSLayoutConstraint.activate([
            portButton.rightAnchor.constraint(equalTo: rightMargin),
            portButton.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            portButton.widthAnchor.constraint(equalToConstant: 50),
            portButton.heightAnchor.constraint(equalTo: portButton.widthAnchor),
            
            errorLabel.leftAnchor.constraint(equalTo: leftMargin),
            errorLabel.rightAnchor.constraint(equalTo: rightMargin),
            errorLabel.topAnchor.constraint(equalTo: topAnchor, constant: 35)
            ])
    }
    
}
