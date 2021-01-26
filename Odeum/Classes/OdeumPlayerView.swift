//
//  OdeumPlayerView.swift
//  Odeum
//
//  Created by Nayanda Haberty on 23/01/21.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

// MARK: OdeumPlayerView

public class OdeumPlayerView: UIView {
    
    // MARK: View
    
    public internal(set) lazy var progressBar: UISlider = {
        let bar = UISlider()
        bar.thumbTintColor = .white
        bar.minimumTrackTintColor = .red
        bar.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.5)
        bar.maximumValue = 1
        bar.minimumValue = 0
        bar.setThumbImage(makeCircle(), for: .normal)
        bar.setThumbImage(makeCircle(withSize: .init(width: 16, height: 16)), for: .highlighted)
        bar.addTarget(self, action: #selector(slided(_:)), for: .valueChanged)
        bar.addTarget(self, action: #selector(didSlide(_:)), for: .touchUpInside)
        bar.addTarget(self, action: #selector(didSlide(_:)), for: .touchUpOutside)
        return bar
    }()
    public internal(set) lazy var videoViewHolder: UIView = {
        let view = UIView()
        view.addGestureRecognizer(tapGestureRecognizer)
        return view
    }()
    public internal(set) lazy var playerControl: PlayControlView = {
        let control = PlayControlView()
        control.delegate = self
        return control
    }()
    public internal(set) lazy var spinner: UIActivityIndicatorView = .init(activityIndicatorStyle: .white)
    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        gesture.cancelsTouchesInView = false
        return gesture
    }()
    
    // MARK: State
    public var videoIsFinished: Bool {
        guard let duration = player.currentItem?.duration else { return false }
        return player.currentTime() >= duration
    }
    public var isBuffering: Bool {
        spinner.alpha < 1
    }
    public var audioState: AudioState {
        playerControl.audioState
    }
    public var replayStep: ReplayStep {
        get {
            playerControl.replayStep
        } set {
            playerControl.replayStep = newValue
        }
    }
    public var playState: PlayState {
        playerControl.playState
    }
    public var forwardStep: ForwardStep {
        get {
            playerControl.forwardStep
        } set {
            playerControl.forwardStep = newValue
        }
    }
    public var fullScreenState: FullScreenState {
        playerControl.fullScreenState
    }
    public var videoItem: AVPlayerItem? {
        player.currentItem
    }
    
    // MARK: Delegate
    
    public weak var delegate: OdeumPlayerViewDelegate?
    
    // MARK: Player
    
    lazy var player: AVPlayer = {
        let player = AVPlayer()
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000),
            queue: .main) { [weak self] time in
            self?.timeTracked(time)
        }
        player.actionAtItemEnd = .pause
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        return player
    }()
    lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        return layer
    }()
    
    // MARK: Inspectable Properties
    @IBInspectable
    public var videoControlShownDuration: TimeInterval = 3
    
    // MARK: Properties
    var previousTimeStatus: AVPlayerTimeControlStatus?
    var hideWorker: DispatchWorkItem?
    weak var fullScreenViewController: UIViewController?
    var justSlided: Bool = false
    
    // MARK: Initializer
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = videoViewHolder.bounds
        videoViewHolder.layer.addSublayer(playerLayer)
        playerControl.layer.cornerRadius = playerControl.bounds.height / 2
        playerControl.clipsToBounds = true
    }
    
    // MARK: View Arrangement and Animating
    
    func setupConstraints() {
        videoViewHolder.translatesAutoresizingMaskIntoConstraints = false
        playerControl.translatesAutoresizingMaskIntoConstraints = false
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        playerControl.alpha = 0
        progressBar.alpha = 0
        spinner.alpha = 0
        addSubview(videoViewHolder)
        addSubview(spinner)
        addSubview(progressBar)
        addSubview(playerControl)
        NSLayoutConstraint.activate([
            videoViewHolder.topAnchor.constraint(equalTo: topAnchor),
            videoViewHolder.leftAnchor.constraint(equalTo: leftAnchor),
            videoViewHolder.bottomAnchor.constraint(equalTo: bottomAnchor),
            videoViewHolder.rightAnchor.constraint(equalTo: rightAnchor),
            playerControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            playerControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            playerControl.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16),
            playerControl.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 16),
            playerControl.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            playerControl.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -16),
            playerControl.heightAnchor.constraint(lessThanOrEqualToConstant: 48),
            playerControl.widthAnchor.constraint(lessThanOrEqualToConstant: 240),
            playerControl.widthAnchor.constraint(equalTo: playerControl.heightAnchor, multiplier: 5),
            progressBar.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            progressBar.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16),
            spinner.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 16),
            spinner.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            spinner.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -16),
        ])
    }
    
    func showSpinner() {
        self.spinner.startAnimating()
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.spinner.alpha = 1
            },
            completion: nil
        )
    }
    
    func hideSpinner() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.spinner.alpha = 0
            },
            completion: { _ in
                self.spinner.stopAnimating()
            }
        )
    }
    
    func showControl() {
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.progressBar.alpha = 1
                self.playerControl.alpha = 1
            },
            completion: nil
        )
    }
    
    func hideControl() {
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.progressBar.alpha = 0
                self.playerControl.alpha = 0
            },
            completion: nil
        )
    }

}