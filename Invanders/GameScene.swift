//
//  GameScene.swift
//  Invanders
//
//  Created by Macbook M4 Pro on 14.03.2026.
//

import SpriteKit
import AVFoundation
import UIKit

final class GameScene: SKScene {

    private enum GameState {
        case intro
        case playing
        case waveTransition
        case gameOver
    }

    private enum BulletOwner {
        case player
        case enemy
    }

    private enum OverlayButtonAction {
        case startGame
        case showScore
        case showMenu
        case closeMenu
        case backToMenu
    }

    private enum OverlayStyle {
        case intro
        case score
        case menu
        case waveClear
        case gameOver

        var titleColor: UIColor {
            switch self {
            case .intro: return Palette.lime
            case .score: return Palette.bullet
            case .menu: return Palette.cyan
            case .waveClear: return Palette.cyan
            case .gameOver: return Palette.red
            }
        }

        var panelStrokeColor: UIColor {
            switch self {
            case .intro: return Palette.grid
            case .score: return Palette.bullet.withAlphaComponent(0.45)
            case .menu: return Palette.cyan.withAlphaComponent(0.45)
            case .waveClear: return Palette.cyan.withAlphaComponent(0.45)
            case .gameOver: return Palette.red.withAlphaComponent(0.55)
            }
        }

        var subtitleColor: UIColor {
            switch self {
            case .intro: return Palette.hud
            case .score: return Palette.hud
            case .menu: return Palette.hud
            case .waveClear: return Palette.bullet
            case .gameOver: return UIColor(red: 1.0, green: 0.86, blue: 0.88, alpha: 1.0)
            }
        }

        var subtitleFont: UIFont {
            switch self {
            case .intro, .score, .menu:
                return UIFont(name: "Menlo-Bold", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .bold)
            case .waveClear:
                return UIFont(name: "AvenirNextCondensed-Heavy", size: 72) ?? .systemFont(ofSize: 72, weight: .heavy)
            case .gameOver:
                return UIFont(name: "AvenirNextCondensed-Heavy", size: 20) ?? .systemFont(ofSize: 20, weight: .heavy)
            }
        }

        var subtitleLineHeight: CGFloat {
            switch self {
            case .intro, .score, .menu:
                return 18
            case .waveClear:
                return 72
            case .gameOver:
                return 28
            }
        }

        var hintColor: UIColor {
            switch self {
            case .intro: return Palette.bullet
            case .score: return Palette.bullet
            case .menu: return Palette.lime
            case .waveClear: return Palette.bullet
            case .gameOver: return UIColor(red: 1.0, green: 0.60, blue: 0.66, alpha: 1.0)
            }
        }

        var panelFillColor: UIColor {
            switch self {
            case .intro, .score, .menu, .waveClear:
                return Palette.panel
            case .gameOver:
                return UIColor(red: 0.09, green: 0.03, blue: 0.05, alpha: 0.92)
            }
        }
    }

    private enum WavePattern: CaseIterable {
        case classic
        case pulse
        case zigzag
        case drift
        case compression

        var label: String {
            switch self {
            case .classic: return "CLASSIC SWEEP"
            case .pulse: return "PULSE SWARM"
            case .zigzag: return "ZIGZAG RAID"
            case .drift: return "PHASE DRIFT"
            case .compression: return "COMPRESSION DROP"
            }
        }
    }

    private enum AlienTier: Int, CaseIterable {
        case red = 0
        case yellow = 1
        case blue = 2
        case green = 3

        var alienColor: UIColor {
            switch self {
            case .red: return Palette.red
            case .yellow: return Palette.bullet
            case .blue: return Palette.cyan
            case .green: return Palette.lime
            }
        }

        var scoreValue: Int {
            switch self {
            case .red: return 180
            case .yellow: return 140
            case .blue: return 110
            case .green: return 80
            }
        }

        var bodyPattern: [String] {
            switch self {
            case .red:
                return [
                    "00111100",
                    "01111110",
                    "11111111",
                    "11111111",
                    "01111110",
                    "00100100"
                ]
            case .yellow:
                return [
                    "00111100",
                    "01111110",
                    "11111111",
                    "11011011",
                    "11111111",
                    "01000010"
                ]
            case .blue:
                return [
                    "00100100",
                    "01111110",
                    "11111111",
                    "11111111",
                    "01111110",
                    "01011010"
                ]
            case .green:
                return [
                    "00100100",
                    "01111110",
                    "11111111",
                    "10111101",
                    "01111110",
                    "01000010"
                ]
            }
        }

        var bulletPattern: [String] {
            switch self {
            case .red:
                return [
                    "010",
                    "111",
                    "111",
                    "010",
                    "010",
                    "111",
                    "010"
                ]
            case .yellow:
                return [
                    "1001",
                    "1111",
                    "0110",
                    "0110",
                    "1111",
                    "1001"
                ]
            case .blue:
                return [
                    "00100",
                    "01110",
                    "11111",
                    "01110",
                    "00100"
                ]
            case .green:
                return [
                    "0110",
                    "1111",
                    "1111",
                    "0110",
                    "0110"
                ]
            }
        }

        var bulletVelocity: CGFloat {
            switch self {
            case .red: return -250
            case .yellow: return -320
            case .blue: return -360
            case .green: return -340
            }
        }
    }

    private final class Bullet {
        let node: SKSpriteNode
        let owner: BulletOwner
        let velocity: CGVector
        var isAlive = true

        init(node: SKSpriteNode, owner: BulletOwner, velocity: CGVector) {
            self.node = node
            self.owner = owner
            self.velocity = velocity
        }
    }

    private final class Alien {
        let node: SKSpriteNode
        let tier: AlienTier
        let scoreValue: Int
        let row: Int
        let column: Int
        let wobbleSeed: CGFloat
        var anchorPosition: CGPoint
        var isAlive = true

        init(node: SKSpriteNode, tier: AlienTier, scoreValue: Int, row: Int, column: Int) {
            self.node = node
            self.tier = tier
            self.scoreValue = scoreValue
            self.row = row
            self.column = column
            self.wobbleSeed = CGFloat.random(in: -1...1)
            self.anchorPosition = node.position
        }
    }

    private final class RetroFeedbackManager {
        private struct ToneClip {
            let data: Data
            let duration: TimeInterval
        }

        private enum Waveform {
            case sine
            case pulse
        }

        private let sampleRate: Double = 44_100
        private let lightImpact = UIImpactFeedbackGenerator(style: .light)
        private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        private let successFeedback = UINotificationFeedbackGenerator()
        private let errorFeedback = UINotificationFeedbackGenerator()
        private var activePlayers: [AVAudioPlayer] = []

        private lazy var playerShotClip = makeClip(
            startFrequency: 960,
            endFrequency: 540,
            duration: 0.08,
            amplitude: 0.12,
            waveform: .pulse
        )

        private lazy var enemyShotClip = makeClip(
            startFrequency: 380,
            endFrequency: 220,
            duration: 0.10,
            amplitude: 0.10,
            waveform: .pulse
        )

        private lazy var popClip = makeClip(
            startFrequency: 420,
            endFrequency: 160,
            duration: 0.09,
            amplitude: 0.10,
            waveform: .pulse
        )

        private lazy var explosionClip = makeClip(
            startFrequency: 180,
            endFrequency: 52,
            duration: 0.26,
            amplitude: 0.18,
            waveform: .pulse
        )

        private lazy var playerHitClip = makeClip(
            startFrequency: 210,
            endFrequency: 84,
            duration: 0.32,
            amplitude: 0.18,
            waveform: .sine
        )

        private lazy var waveStartClips = [
            makeClip(startFrequency: 310, endFrequency: 310, duration: 0.10, amplitude: 0.09, waveform: .sine),
            makeClip(startFrequency: 420, endFrequency: 420, duration: 0.10, amplitude: 0.09, waveform: .sine),
            makeClip(startFrequency: 560, endFrequency: 560, duration: 0.14, amplitude: 0.10, waveform: .sine)
        ]

        private lazy var gameOverClips = [
            makeClip(startFrequency: 260, endFrequency: 220, duration: 0.16, amplitude: 0.10, waveform: .pulse),
            makeClip(startFrequency: 180, endFrequency: 130, duration: 0.18, amplitude: 0.11, waveform: .pulse),
            makeClip(startFrequency: 120, endFrequency: 72, duration: 0.24, amplitude: 0.12, waveform: .sine)
        ]

        private var lastShotHapticTime: TimeInterval = 0
        private var isPrepared = false
        private var audioEnabled = true

        var isAudioEnabled: Bool {
            audioEnabled
        }

        func prepare() {
            guard !isPrepared else { return }
            isPrepared = true

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                audioEnabled = true
            } catch {
                audioEnabled = false
            }

            lightImpact.prepare()
            mediumImpact.prepare()
            heavyImpact.prepare()
            successFeedback.prepare()
            errorFeedback.prepare()
        }

        func setAudioEnabled(_ enabled: Bool) {
            audioEnabled = enabled
        }

        func playerShot() {
            prepare()
            play(clip: playerShotClip)

            let now = Date().timeIntervalSinceReferenceDate
            if now - lastShotHapticTime > 0.28 {
                lightImpact.impactOccurred(intensity: 0.45)
                lastShotHapticTime = now
            }
        }

        func enemyShot() {
            prepare()
            play(clip: enemyShotClip)
        }

        func bunkerHit() {
            prepare()
            play(clip: popClip)
        }

        func alienDestroyed() {
            prepare()
            play(clip: explosionClip)
            mediumImpact.impactOccurred(intensity: 0.55)
        }

        func playerHit() {
            prepare()
            play(clip: playerHitClip)
            heavyImpact.impactOccurred(intensity: 0.95)
        }

        func waveStart() {
            prepare()
            successFeedback.notificationOccurred(.success)

            for (index, clip) in waveStartClips.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) { [weak self] in
                    self?.play(clip: clip)
                }
            }
        }

        func gameOver() {
            prepare()
            errorFeedback.notificationOccurred(.error)

            for (index, clip) in gameOverClips.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) { [weak self] in
                    self?.play(clip: clip)
                }
            }
        }

        func overlayButtonTap() {
            prepare()
            lightImpact.impactOccurred(intensity: 0.8)
            lightImpact.prepare()
        }

        private func play(clip: ToneClip?) {
            guard audioEnabled, let clip else { return }
            do {
                let player = try AVAudioPlayer(data: clip.data)
                player.volume = 0.9
                player.prepareToPlay()
                activePlayers.append(player)
                player.play()

                DispatchQueue.main.asyncAfter(deadline: .now() + clip.duration + 0.12) { [weak self] in
                    self?.activePlayers.removeAll { $0.isPlaying == false }
                }
            } catch {
                audioEnabled = false
            }
        }

        private func makeClip(
            startFrequency: Double,
            endFrequency: Double,
            duration: Double,
            amplitude: Float,
            waveform: Waveform
        ) -> ToneClip? {
            let frameCount = Int(sampleRate * duration)
            guard frameCount > 0 else { return nil }

            let attack = max(0.005, duration * 0.08)
            let release = max(0.02, duration * 0.48)
            let sustainEnd = max(attack, duration - release)

            var phase = 0.0
            var pcmData = Data(capacity: frameCount * MemoryLayout<Int16>.size)

            for frame in 0..<frameCount {
                let t = Double(frame) / sampleRate
                let progress = t / duration
                let frequency = startFrequency + (endFrequency - startFrequency) * progress
                phase += (2 * .pi * frequency) / sampleRate

                let baseWave: Double
                switch waveform {
                case .sine:
                    baseWave = sin(phase)
                case .pulse:
                    baseWave = sin(phase) > 0 ? 1 : -1
                }

                let envelope: Double
                if t < attack {
                    envelope = t / attack
                } else if t > sustainEnd {
                    envelope = max(0, 1 - ((t - sustainEnd) / release))
                } else {
                    envelope = 1
                }

                let shaped = baseWave * envelope * Double(amplitude) * (0.82 + (1 - progress) * 0.18)
                let sample = Int16(max(-1, min(1, shaped)) * Double(Int16.max))
                var littleEndianSample = sample.littleEndian
                withUnsafeBytes(of: &littleEndianSample) { bytes in
                    pcmData.append(contentsOf: bytes)
                }
            }

            return ToneClip(data: makeWAVData(pcmData: pcmData, sampleRate: Int(sampleRate)), duration: duration)
        }

        private func makeWAVData(pcmData: Data, sampleRate: Int) -> Data {
            let channels: UInt16 = 1
            let bitsPerSample: UInt16 = 16
            let byteRate = UInt32(sampleRate) * UInt32(channels) * UInt32(bitsPerSample / 8)
            let blockAlign = channels * (bitsPerSample / 8)
            let dataSize = UInt32(pcmData.count)
            let riffSize = 36 + dataSize

            var data = Data()
            data.append("RIFF".data(using: .ascii)!)
            data.append(contentsOf: withUnsafeBytes(of: riffSize.littleEndian, Array.init))
            data.append("WAVE".data(using: .ascii)!)
            data.append("fmt ".data(using: .ascii)!)

            let fmtChunkSize: UInt32 = 16
            let audioFormat: UInt16 = 1
            data.append(contentsOf: withUnsafeBytes(of: fmtChunkSize.littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: channels.littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian, Array.init))
            data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian, Array.init))
            data.append("data".data(using: .ascii)!)
            data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian, Array.init))
            data.append(pcmData)
            return data
        }
    }

    private final class BunkerCell {
        let node: SKSpriteNode
        var durability: Int

        init(node: SKSpriteNode, durability: Int) {
            self.node = node
            self.durability = durability
        }
    }

    private final class Star {
        let node: SKSpriteNode
        let speed: CGFloat
        let drift: CGFloat

        init(node: SKSpriteNode, speed: CGFloat, drift: CGFloat) {
            self.node = node
            self.speed = speed
            self.drift = drift
        }
    }

    private struct Palette {
        static let backgroundTop = UIColor(red: 0.02, green: 0.03, blue: 0.06, alpha: 1.0)
        static let backgroundBottom = UIColor(red: 0.02, green: 0.12, blue: 0.05, alpha: 1.0)
        static let grid = UIColor(red: 0.27, green: 0.94, blue: 0.48, alpha: 0.10)
        static let hud = UIColor(red: 0.76, green: 1.00, blue: 0.86, alpha: 1.0)
        static let player = UIColor(red: 0.32, green: 0.96, blue: 1.00, alpha: 1.0)
        static let bullet = UIColor(red: 0.96, green: 1.00, blue: 0.20, alpha: 1.0)
        static let enemyBullet = UIColor(red: 1.00, green: 0.25, blue: 0.37, alpha: 1.0)
        static let bunker = UIColor(red: 0.53, green: 1.00, blue: 0.38, alpha: 1.0)
        static let magenta = UIColor(red: 0.97, green: 0.21, blue: 0.94, alpha: 1.0)
        static let lime = UIColor(red: 0.37, green: 1.00, blue: 0.23, alpha: 1.0)
        static let orange = UIColor(red: 1.00, green: 0.45, blue: 0.14, alpha: 1.0)
        static let cyan = UIColor(red: 0.32, green: 0.96, blue: 1.00, alpha: 1.0)
        static let red = UIColor(red: 1.00, green: 0.24, blue: 0.33, alpha: 1.0)
        static let panel = UIColor(red: 0.03, green: 0.05, blue: 0.09, alpha: 0.88)
    }

    private let highScoreKey = "pl.glasek.Invanders.highScore"
    private let scoreBoardKey = "pl.glasek.Invanders.scoreBoard"
    private let audioEnabledKey = "pl.glasek.Invanders.audioEnabled"

    private let worldNode = SKNode()
    private let starfieldNode = SKNode()
    private let bunkerNode = SKNode()
    private let bulletNode = SKNode()
    private let alienNode = SKNode()
    private let hudNode = SKNode()
    private let overlayNode = SKNode()
    private let flashNode = SKSpriteNode(color: .white, size: .zero)

    private let backgroundNode = SKSpriteNode()
    private let scanlineNode = SKSpriteNode()

    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let highScoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-DemiBold")
    private let waveLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let livesLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    private let overlayPanel = SKShapeNode(rectOf: CGSize(width: 100, height: 100), cornerRadius: 28)
    private let overlayTitle = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let overlaySubtitleNode = SKNode()
    private let overlayHintNode = SKNode()
    private let overlayButton = SKShapeNode(rectOf: CGSize(width: 100, height: 52), cornerRadius: 18)
    private let overlayButtonLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let overlaySecondaryButton = SKShapeNode(rectOf: CGSize(width: 100, height: 52), cornerRadius: 18)
    private let overlaySecondaryButtonLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let overlayTertiaryButton = SKShapeNode(rectOf: CGSize(width: 100, height: 52), cornerRadius: 18)
    private let overlayTertiaryButtonLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let overlayScoreboardNode = SKNode()
    private let overlayVersionLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let overlayAudioToggle = SKShapeNode(rectOf: CGSize(width: 100, height: 52), cornerRadius: 18)
    private let overlayAudioLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let overlayAudioValueLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let overlayAudioIcon = SKSpriteNode()
    private let feedback = RetroFeedbackManager()

    private var playerNode = SKSpriteNode()
    private var stars: [Star] = []
    private var bullets: [Bullet] = []
    private var aliens: [Alien] = []
    private var bunkerCells: [BunkerCell] = []

    private var gameState: GameState = .intro
    private var lastUpdateTime: TimeInterval = 0
    private var playerTargetX: CGFloat?
    private var touchIsActive = false
    private var playerFireCooldown: TimeInterval = 0
    private var enemyFireCooldown: TimeInterval = 0
    private var waveTransitionTimer: TimeInterval = 0
    private var playerInvulnerabilityTime: TimeInterval = 0
    private var formationDirection: CGFloat = 1
    private var formationSpeed: CGFloat = 58
    private var formationTime: TimeInterval = 0
    private var formationBounceCount = 0
    private var wavePattern: WavePattern = .classic
    private var overlayButtonAction: OverlayButtonAction?
    private var overlaySecondaryButtonAction: OverlayButtonAction?
    private var overlayTertiaryButtonAction: OverlayButtonAction?
    private var overlayStyle: OverlayStyle = .intro
    private var overlayButtonBaseFillColor = Palette.lime.withAlphaComponent(0.92)
    private var overlayButtonBaseStrokeColor = Palette.grid
    private var overlayButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
    private var overlaySecondaryButtonBaseFillColor = Palette.cyan.withAlphaComponent(0.16)
    private var overlaySecondaryButtonBaseStrokeColor = Palette.cyan.withAlphaComponent(0.55)
    private var overlaySecondaryButtonBaseLabelColor = Palette.cyan
    private var overlayTertiaryButtonBaseFillColor = Palette.cyan.withAlphaComponent(0.16)
    private var overlayTertiaryButtonBaseStrokeColor = Palette.cyan.withAlphaComponent(0.55)
    private var overlayTertiaryButtonBaseLabelColor = Palette.cyan
    private var overlayButtonPressed = false
    private var overlaySecondaryButtonPressed = false
    private var overlayTertiaryButtonPressed = false
    private var overlayAudioTogglePressed = false
    private var scoreBoardEntries: [Int] = []
    private var pixelTextureCache: [String: SKTexture] = [:]
    private var cachedBackgroundTexture: SKTexture?
    private var cachedBackgroundSize: CGSize = .zero
    private var cachedScanlineTexture: SKTexture?
    private var cachedScanlineSize: CGSize = .zero
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "DEV"
    private let waveClearCountdownDuration: TimeInterval = 3.0

    private var score = 0 {
        didSet { updateHUD() }
    }

    private var highScore = 0 {
        didSet { updateHUD() }
    }

    private var lives = 3 {
        didSet { updateHUD() }
    }

    private var wave = 1 {
        didSet { updateHUD() }
    }

    private var didSetupScene = false

    override func didMove(to view: SKView) {
        if !didSetupScene {
            didSetupScene = true
            highScore = UserDefaults.standard.integer(forKey: highScoreKey)
            scoreBoardEntries = loadScoreBoard()
            backgroundColor = .black
            feedback.prepare()
            feedback.setAudioEnabled(loadAudioEnabledPreference())
            buildScene()
            createStarfield()
            createPlayer()
            updateHUD()
            enterIntroState()
        }

        layoutScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard didSetupScene else { return }
        layoutScene()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if gameState == .intro {
            updateOverlayButtonPressed(isPressed: isTouchInsideOverlayButton(touch))
            updateOverlaySecondaryButtonPressed(isPressed: isTouchInsideOverlaySecondaryButton(touch))
            updateOverlayTertiaryButtonPressed(isPressed: isTouchInsideOverlayTertiaryButton(touch))
            updateAudioTogglePressed(isPressed: isTouchInsideAudioToggle(touch))
            return
        }

        if gameState == .gameOver {
            updateOverlayButtonPressed(isPressed: isTouchInsideOverlayButton(touch))
            return
        }

        touchIsActive = true
        updatePlayerTarget(with: touch.location(in: self))
        firePlayerBulletIfNeeded(force: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if gameState == .intro || gameState == .gameOver {
            updateOverlayButtonPressed(isPressed: isTouchInsideOverlayButton(touch))
            updateOverlaySecondaryButtonPressed(isPressed: isTouchInsideOverlaySecondaryButton(touch))
            updateOverlayTertiaryButtonPressed(isPressed: isTouchInsideOverlayTertiaryButton(touch))
            updateAudioTogglePressed(isPressed: isTouchInsideAudioToggle(touch))
            return
        }

        touchIsActive = true
        updatePlayerTarget(with: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .intro || gameState == .gameOver {
            let shouldTriggerPrimary = touches.first.map(isTouchInsideOverlayButton) == true && overlayButtonPressed
            let shouldTriggerSecondary = touches.first.map(isTouchInsideOverlaySecondaryButton) == true && overlaySecondaryButtonPressed
            let shouldTriggerTertiary = touches.first.map(isTouchInsideOverlayTertiaryButton) == true && overlayTertiaryButtonPressed
            let shouldToggleAudio = touches.first.map(isTouchInsideAudioToggle) == true && overlayAudioTogglePressed
            updateOverlayButtonPressed(isPressed: false)
            updateOverlaySecondaryButtonPressed(isPressed: false)
            updateOverlayTertiaryButtonPressed(isPressed: false)
            updateAudioTogglePressed(isPressed: false)
            if shouldTriggerPrimary {
                handleOverlayButtonAction()
            } else if shouldTriggerSecondary {
                handleOverlaySecondaryButtonAction()
            } else if shouldTriggerTertiary {
                handleOverlayTertiaryButtonAction()
            } else if shouldToggleAudio {
                toggleAudioPreference()
            }
            return
        }

        touchIsActive = false
        playerTargetX = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .intro || gameState == .gameOver {
            updateOverlayButtonPressed(isPressed: false)
            updateOverlaySecondaryButtonPressed(isPressed: false)
            updateOverlayTertiaryButtonPressed(isPressed: false)
            updateAudioTogglePressed(isPressed: false)
            return
        }

        touchIsActive = false
        playerTargetX = nil
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        var dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        dt = min(dt, 1.0 / 20.0)

        updateStars(deltaTime: dt)
        pulseScanlines(currentTime: currentTime)
        playerFireCooldown = max(0, playerFireCooldown - dt)

        guard gameState != .intro else { return }

        if playerInvulnerabilityTime > 0 {
            playerInvulnerabilityTime = max(0, playerInvulnerabilityTime - dt)
            let blinkPhase = sin(currentTime * 30)
            playerNode.alpha = blinkPhase > 0 ? 0.35 : 1.0
        } else {
            playerNode.alpha = 1.0
        }

        switch gameState {
        case .playing:
            updatePlayer(deltaTime: dt)
            updateAliens(deltaTime: dt)
            updateBullets(deltaTime: dt)
            handleCollisions()
            cleanupDestroyedNodes()
            guard gameState == .playing else { return }
            checkForWaveCompletion()
        case .waveTransition:
            waveTransitionTimer -= dt
            updateWaveClearOverlayCountdown()
            if waveTransitionTimer <= 0 {
                beginWave()
            }
        case .gameOver, .intro:
            break
        }
    }

    private func buildScene() {
        addChild(backgroundNode)
        addChild(worldNode)
        addChild(hudNode)
        addChild(overlayNode)
        addChild(scanlineNode)
        addChild(flashNode)

        worldNode.addChild(starfieldNode)
        worldNode.addChild(bunkerNode)
        worldNode.addChild(bulletNode)
        worldNode.addChild(alienNode)

        configureHUD()
        configureOverlay()

        flashNode.zPosition = 45
        flashNode.alpha = 0
        flashNode.blendMode = .add

        backgroundNode.zPosition = -20
        scanlineNode.zPosition = 40
        scanlineNode.alpha = 0.22
    }

    private func configureHUD() {
        let labels = [scoreLabel, highScoreLabel, waveLabel, statusLabel, livesLabel]

        for label in labels {
            label.horizontalAlignmentMode = .left
            label.fontColor = Palette.hud
            label.zPosition = 30
            hudNode.addChild(label)
        }

        scoreLabel.fontSize = 32
        highScoreLabel.fontSize = 15
        waveLabel.fontSize = 20
        statusLabel.fontSize = 12
        livesLabel.fontSize = 14

        waveLabel.horizontalAlignmentMode = .right
        livesLabel.horizontalAlignmentMode = .right

        statusLabel.fontColor = Palette.lime
        highScoreLabel.fontColor = Palette.cyan
        livesLabel.fontColor = Palette.bullet
    }

    private func configureOverlay() {
        overlayNode.zPosition = 35
        overlayNode.addChild(overlayPanel)
        overlayNode.addChild(overlayTitle)
        overlayNode.addChild(overlaySubtitleNode)
        overlayNode.addChild(overlayHintNode)
        overlayNode.addChild(overlayButton)
        overlayNode.addChild(overlayButtonLabel)
        overlayNode.addChild(overlaySecondaryButton)
        overlayNode.addChild(overlaySecondaryButtonLabel)
        overlayNode.addChild(overlayTertiaryButton)
        overlayNode.addChild(overlayTertiaryButtonLabel)
        overlayNode.addChild(overlayScoreboardNode)
        overlayNode.addChild(overlayVersionLabel)
        overlayNode.addChild(overlayAudioToggle)
        overlayAudioToggle.addChild(overlayAudioIcon)
        overlayAudioToggle.addChild(overlayAudioLabel)
        overlayAudioToggle.addChild(overlayAudioValueLabel)

        overlayPanel.fillColor = Palette.panel
        overlayPanel.strokeColor = Palette.grid
        overlayPanel.lineWidth = 2

        overlayTitle.fontColor = Palette.lime
        overlayTitle.fontSize = 46
        overlayTitle.horizontalAlignmentMode = .center
        overlayTitle.verticalAlignmentMode = .center

        overlayButton.fillColor = Palette.lime.withAlphaComponent(0.92)
        overlayButton.strokeColor = Palette.grid
        overlayButton.lineWidth = 2

        overlayButtonLabel.fontColor = UIColor.black.withAlphaComponent(0.88)
        overlayButtonLabel.fontSize = 28
        overlayButtonLabel.horizontalAlignmentMode = .center
        overlayButtonLabel.verticalAlignmentMode = .center

        overlaySecondaryButton.fillColor = Palette.cyan.withAlphaComponent(0.16)
        overlaySecondaryButton.strokeColor = Palette.cyan.withAlphaComponent(0.55)
        overlaySecondaryButton.lineWidth = 2

        overlaySecondaryButtonLabel.fontColor = UIColor.black.withAlphaComponent(0.88)
        overlaySecondaryButtonLabel.fontSize = 28
        overlaySecondaryButtonLabel.horizontalAlignmentMode = .center
        overlaySecondaryButtonLabel.verticalAlignmentMode = .center

        overlayTertiaryButton.fillColor = Palette.cyan.withAlphaComponent(0.16)
        overlayTertiaryButton.strokeColor = Palette.cyan.withAlphaComponent(0.55)
        overlayTertiaryButton.lineWidth = 2

        overlayTertiaryButtonLabel.fontColor = UIColor.black.withAlphaComponent(0.88)
        overlayTertiaryButtonLabel.fontSize = 28
        overlayTertiaryButtonLabel.horizontalAlignmentMode = .center
        overlayTertiaryButtonLabel.verticalAlignmentMode = .center

        overlayVersionLabel.fontColor = Palette.hud.withAlphaComponent(0.78)
        overlayVersionLabel.fontSize = 13
        overlayVersionLabel.horizontalAlignmentMode = .center
        overlayVersionLabel.verticalAlignmentMode = .center
        overlayVersionLabel.text = "VERSION \(appVersion)"

        overlayAudioToggle.fillColor = Palette.lime.withAlphaComponent(0.92)
        overlayAudioToggle.strokeColor = Palette.grid
        overlayAudioToggle.lineWidth = 2

        overlayAudioLabel.fontColor = UIColor.black.withAlphaComponent(0.88)
        overlayAudioLabel.fontSize = 28
        overlayAudioLabel.horizontalAlignmentMode = .center
        overlayAudioLabel.verticalAlignmentMode = .center
        overlayAudioLabel.text = "VOLUME"

        overlayAudioValueLabel.fontColor = UIColor.black.withAlphaComponent(0.88)
        overlayAudioValueLabel.fontSize = 18
        overlayAudioValueLabel.horizontalAlignmentMode = .right
        overlayAudioValueLabel.verticalAlignmentMode = .center

        overlayAudioIcon.texture = makeSpeakerTexture(isEnabled: true)
        overlayAudioIcon.texture?.filteringMode = .nearest
        overlayAudioIcon.isHidden = true
        overlayAudioValueLabel.isHidden = true
    }

    private func layoutScene() {
        let isScore = overlayStyle == .score
        let isMenu = overlayStyle == .menu
        let isGameOver = overlayStyle == .gameOver
        let isWaveClear = overlayStyle == .waveClear
        let panelSize = overlayPanelSize()
        let panelY = size.height * (isGameOver ? 0.48 : 0.56)
        let buttonWidth = panelSize.width - 34
        let titleYOffset: CGFloat = isMenu ? 120 : (isScore ? 122 : (isGameOver ? 100 : (isWaveClear ? 86 : 156)))
        let subtitleYOffset: CGFloat = isMenu ? 86 : (isScore ? 88 : (isGameOver ? 40 : (isWaveClear ? 20 : 92)))
        let hintYOffset: CGFloat = isMenu ? -104 : (isScore ? -112 : (isGameOver ? -22 : (isWaveClear ? -54 : 30)))
        let buttonStackSpacing: CGFloat = 18
        let introButtonBottomPadding: CGFloat = 24
        let buttonHeight: CGFloat = 52
        let introTertiaryButtonYOffset = -panelSize.height / 2 + introButtonBottomPadding + buttonHeight / 2
        let introSecondaryButtonYOffset = introTertiaryButtonYOffset + buttonHeight + buttonStackSpacing
        let introPrimaryButtonYOffset = introSecondaryButtonYOffset + buttonHeight + buttonStackSpacing
        let primaryButtonYOffset: CGFloat = isMenu ? -118 : (isScore ? -142 : (isGameOver ? -92 : introPrimaryButtonYOffset))
        let secondaryButtonYOffset: CGFloat = isMenu ? -202 : (isScore ? -202 : introSecondaryButtonYOffset)
        let tertiaryButtonYOffset: CGFloat = isMenu ? -170 : (isScore ? -170 : introTertiaryButtonYOffset)
        let scoreBoardYOffset: CGFloat = isScore ? 14 : 28
        let versionYOffset: CGFloat = isMenu ? 8 : -84
        let audioToggleYOffset: CGFloat = isMenu ? -46 : -84
        let overlayButtonRect = CGRect(x: -buttonWidth / 2, y: -26, width: buttonWidth, height: 52)
        let overlayAudioButtonRect = CGRect(x: -buttonWidth / 2, y: -28, width: buttonWidth, height: 56)

        if cachedBackgroundSize != size || cachedBackgroundTexture == nil {
            cachedBackgroundTexture = makeBackgroundTexture(size: size)
            cachedBackgroundSize = size
        }
        backgroundNode.texture = cachedBackgroundTexture
        backgroundNode.size = size
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        if cachedScanlineSize != size || cachedScanlineTexture == nil {
            cachedScanlineTexture = makeScanlineTexture(size: size)
            cachedScanlineSize = size
        }
        scanlineNode.texture = cachedScanlineTexture
        scanlineNode.size = size
        scanlineNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        flashNode.size = size
        flashNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        scoreLabel.position = CGPoint(x: 24, y: size.height - 64)
        highScoreLabel.position = CGPoint(x: 24, y: size.height - 92)
        statusLabel.position = CGPoint(x: 24, y: size.height - 118)
        waveLabel.position = CGPoint(x: size.width - 24, y: size.height - 66)
        livesLabel.position = CGPoint(x: size.width - 24, y: size.height - 92)

        overlayPanel.path = CGPath(
            roundedRect: CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2, width: panelSize.width, height: panelSize.height),
            cornerWidth: 28,
            cornerHeight: 28,
            transform: nil
        )
        overlayButton.path = CGPath(
            roundedRect: overlayButtonRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        overlaySecondaryButton.path = CGPath(
            roundedRect: overlayButtonRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        overlayTertiaryButton.path = CGPath(
            roundedRect: overlayButtonRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )
        overlayAudioToggle.path = CGPath(
            roundedRect: overlayAudioButtonRect,
            cornerWidth: 18,
            cornerHeight: 18,
            transform: nil
        )

        overlayPanel.position = CGPoint(x: size.width / 2, y: panelY)
        overlayTitle.position = CGPoint(x: size.width / 2, y: panelY + titleYOffset)
        overlaySubtitleNode.position = CGPoint(x: size.width / 2, y: panelY + subtitleYOffset)
        overlayHintNode.position = CGPoint(x: size.width / 2, y: panelY + hintYOffset)
        overlayButton.position = CGPoint(x: size.width / 2, y: panelY + primaryButtonYOffset)
        overlayButtonLabel.position = overlayButton.position
        overlaySecondaryButton.position = CGPoint(x: size.width / 2, y: panelY + secondaryButtonYOffset)
        overlaySecondaryButtonLabel.position = overlaySecondaryButton.position
        overlayTertiaryButton.position = CGPoint(x: size.width / 2, y: panelY + tertiaryButtonYOffset)
        overlayTertiaryButtonLabel.position = overlayTertiaryButton.position
        overlayScoreboardNode.position = CGPoint(x: size.width / 2, y: panelY + scoreBoardYOffset)
        overlayVersionLabel.position = CGPoint(x: size.width / 2, y: panelY + versionYOffset)
        overlayAudioToggle.position = CGPoint(x: size.width / 2, y: panelY + audioToggleYOffset)
        overlayAudioIcon.position = CGPoint(x: -buttonWidth / 2 + 30, y: 0)
        overlayAudioLabel.position = CGPoint(x: 0, y: 0)
        overlayAudioValueLabel.position = CGPoint(x: buttonWidth / 2 - 18, y: 0)

        if playerNode.parent == worldNode {
            playerNode.position.y = size.height * 0.10
            if playerNode.position.x == 0 {
                playerNode.position.x = size.width / 2
            } else {
                playerNode.position.x = max(36, min(size.width - 36, playerNode.position.x))
            }
        }

        if stars.isEmpty {
            createStarfield()
        } else {
            relayoutStars()
        }
    }

    private func createStarfield() {
        stars.removeAll()
        starfieldNode.removeAllChildren()

        let starCount = 66

        for index in 0..<starCount {
            let sizeClass: CGFloat = index % 7 == 0 ? 3 : (index % 3 == 0 ? 2 : 1.5)
            let color = index % 6 == 0 ? Palette.lime.withAlphaComponent(0.9) : UIColor.white.withAlphaComponent(0.85)
            let star = SKSpriteNode(color: color, size: CGSize(width: sizeClass, height: sizeClass))
            star.alpha = CGFloat.random(in: 0.35...0.95)
            star.blendMode = .add
            star.position = CGPoint(x: CGFloat.random(in: 0...max(1, size.width)), y: CGFloat.random(in: 0...max(1, size.height)))
            star.zPosition = -5

            let glow = SKSpriteNode(color: color, size: CGSize(width: sizeClass * 3, height: sizeClass * 3))
            glow.alpha = 0.12
            glow.blendMode = .add
            star.addChild(glow)

            starfieldNode.addChild(star)
            stars.append(Star(node: star, speed: CGFloat.random(in: 24...110), drift: CGFloat.random(in: -12...12)))
        }
    }

    private func relayoutStars() {
        for star in stars where star.node.position.y > size.height {
            star.node.position.y = CGFloat.random(in: 0...size.height)
            star.node.position.x = CGFloat.random(in: 0...size.width)
        }
    }

    private func createPlayer() {
        let texture = makePixelTexture(
            pattern: [
                "00011000",
                "00111100",
                "01111110",
                "11111111",
                "11111111",
                "01100110",
                "01100110",
                "00100100"
            ],
            color: Palette.player,
            pixelSize: 4
        )

        playerNode = SKSpriteNode(texture: texture)
        playerNode.name = "player"
        playerNode.zPosition = 8
        playerNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        playerNode.texture?.filteringMode = .nearest

        addGlow(to: playerNode, color: Palette.player, alpha: 0.10, scale: 1.14)
        worldNode.addChild(playerNode)
    }

    private func startNewGame() {
        clearArena()

        score = 0
        lives = 3
        wave = 1
        formationTime = 0
        playerInvulnerabilityTime = 0
        touchIsActive = false
        playerTargetX = nil
        gameState = .playing

        playerNode.alpha = 1.0
        playerNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        playerNode.isHidden = false

        beginWave()
        overlayNode.isHidden = true
        statusLabel.text = "HOLD TO MOVE  |  AUTO FIRE ONLINE"
    }

    private func enterIntroState() {
        clearArena()

        score = 0
        lives = 3
        wave = 1
        formationTime = 0
        formationBounceCount = 0
        playerInvulnerabilityTime = 0
        touchIsActive = false
        playerTargetX = nil
        playerFireCooldown = 0
        enemyFireCooldown = 0
        waveTransitionTimer = 0
        gameState = .intro

        playerNode.alpha = 1.0
        playerNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        playerNode.isHidden = true

        showOverlay(
            title: "INVANDERS",
            subtitle: "Space Invaders reborn: neon CRT, classic arcade loop, responsive touch controls.",
            hint: "Hold after launch to move your ship and keep firing.",
            style: .intro,
            buttonTitle: "START",
            buttonAction: .startGame,
            secondaryButtonTitle: "SCORE",
            secondaryButtonAction: .showScore,
            tertiaryButtonTitle: "MENU",
            tertiaryButtonAction: .showMenu
        )
        statusLabel.text = "PRESS START"
    }

    private func showScoreOverlay() {
        showOverlay(
            title: "SCORE",
            subtitle: "",
            hint: "",
            style: .score,
            buttonTitle: "BACK",
            buttonAction: .closeMenu
        )
        statusLabel.text = "SCORE BOARD"
    }

    private func showMenuOverlay() {
        showOverlay(
            title: "MENU",
            subtitle: "AUDIO CONTROL",
            hint: "",
            style: .menu,
            buttonTitle: "BACK",
            buttonAction: .closeMenu
        )
        statusLabel.text = "MENU ONLINE"
    }

    private func beginWave() {
        clearWave()
        wavePattern = pattern(for: wave)
        spawnAliens(for: wave)
        formationDirection = 1
        formationSpeed = 44 + CGFloat(wave * 3)
        formationTime = 0
        formationBounceCount = 0
        playerFireCooldown = 0
        enemyFireCooldown = 1.2
        gameState = .playing
        overlayNode.isHidden = true
        statusLabel.text = wave == 1 ? "SECTOR LIVE  |  \(wavePattern.label)" : "WAVE \(wave)  |  \(wavePattern.label)"
        feedback.waveStart()
    }

    private func buildBunkers() {
        bunkerNode.removeAllChildren()
        bunkerCells.removeAll()

        let pattern = [
            "01111110",
            "11111111",
            "11111111",
            "11100111",
            "11000011"
        ]

        let bunkerCount = 4
        let pixelSize = max(6.0, min(9.0, size.width * 0.012))
        let totalWidth = CGFloat(bunkerCount - 1) * size.width * 0.22
        let startX = (size.width - totalWidth) / 2
        let baseY = size.height * 0.23

        for bunkerIndex in 0..<bunkerCount {
            let offsetX = startX + CGFloat(bunkerIndex) * size.width * 0.22

            for (rowIndex, row) in pattern.enumerated() {
                for (columnIndex, character) in row.enumerated() where character == "1" {
                    let cell = SKSpriteNode(color: Palette.bunker, size: CGSize(width: pixelSize, height: pixelSize))
                    cell.position = CGPoint(
                        x: offsetX + CGFloat(columnIndex) * pixelSize,
                        y: baseY + CGFloat(pattern.count - rowIndex) * pixelSize
                    )
                    cell.alpha = 0.95
                    cell.zPosition = 5
                    cell.blendMode = .add

                    let glow = SKSpriteNode(color: Palette.bunker, size: CGSize(width: pixelSize * 2.1, height: pixelSize * 2.1))
                    glow.alpha = 0.12
                    glow.blendMode = .add
                    cell.addChild(glow)

                    bunkerNode.addChild(cell)
                    bunkerCells.append(BunkerCell(node: cell, durability: 2))
                }
            }
        }
    }

    private func spawnAliens(for wave: Int) {
        let columns = 6
        let tiers = AlienTier.allCases
        let rows = tiers.count
        let spacingX = min(size.width * 0.15, 74)
        let spacingY = min(size.height * 0.07, 58)
        let groupWidth = CGFloat(columns - 1) * spacingX
        let startX = (size.width - groupWidth) / 2
        let startY = alienTopLimit(forRow: 0, spacingY: spacingY)
        let pixelSize = max(5, min(7, Int(size.width / 58)))

        for row in 0..<rows {
            let tier = tiers[row]
            let texture = makePixelTexture(pattern: tier.bodyPattern, color: tier.alienColor, pixelSize: pixelSize)

            for column in 0..<columns {
                let node = SKSpriteNode(texture: texture)
                node.position = CGPoint(
                    x: startX + CGFloat(column) * spacingX,
                    y: startY - CGFloat(row) * spacingY
                )
                node.setScale(0.5)
                node.zPosition = 7
                node.texture?.filteringMode = .nearest

                addGlow(to: node, color: tier.alienColor, alpha: 0.12, scale: 1.16)
                alienNode.addChild(node)

                let scoreValue = tier.scoreValue + (wave - 1) * 10
                aliens.append(Alien(node: node, tier: tier, scoreValue: scoreValue, row: row, column: column))
            }
        }
    }

    private func updatePlayerTarget(with point: CGPoint) {
        let clampedX = max(32, min(size.width - 32, point.x))
        playerTargetX = clampedX
    }

    private func updatePlayer(deltaTime: TimeInterval) {
        guard let targetX = playerTargetX else { return }

        let smoothing = min(1, CGFloat(deltaTime) * 12)
        playerNode.position.x += (targetX - playerNode.position.x) * smoothing

        if touchIsActive {
            firePlayerBulletIfNeeded(force: false)
        }
    }

    private func updateAliens(deltaTime: TimeInterval) {
        guard !aliens.isEmpty else { return }

        let aliveAliens = aliens.filter(\.isAlive)
        guard !aliveAliens.isEmpty else { return }

        formationTime += deltaTime
        let movement = formationSpeed * CGFloat(deltaTime) * formationDirection

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX: CGFloat = 0

        for alien in aliveAliens {
            alien.anchorPosition.x += movement
            alien.node.position = positionedAlienPoint(for: alien)
            minX = min(minX, alien.node.frame.minX)
            maxX = max(maxX, alien.node.frame.maxX)
        }

        if minX <= 18 || maxX >= size.width - 18 {
            formationDirection *= -1
            formationBounceCount += 1

            let shouldDropOnThisBounce = formationBounceCount.isMultiple(of: 2)
            if shouldDropOnThisBounce {
                for alien in aliveAliens {
                    alien.anchorPosition.y -= 2
                    alien.node.position = positionedAlienPoint(for: alien)
                }
            }

            shakeWorld(intensity: 8)
        }

        if aliveAliens.contains(where: { $0.node.frame.minY <= playerNode.position.y + 54 }) {
            triggerGameOver(reason: "The formation breached the city grid.")
            return
        }

        enemyFireCooldown -= deltaTime
        if enemyFireCooldown <= 0 {
            fireEnemyBullet()
            let minimumCooldown = max(0.26, 1.02 - Double(wave) * 0.06)
            enemyFireCooldown = minimumCooldown + Double.random(in: 0...0.35)
        }
    }

    private func updateBullets(deltaTime: TimeInterval) {
        for bullet in bullets where bullet.isAlive {
            bullet.node.position.x += bullet.velocity.dx * CGFloat(deltaTime)
            bullet.node.position.y += bullet.velocity.dy * CGFloat(deltaTime)

            if bullet.node.position.x < -60
                || bullet.node.position.x > size.width + 60
                || bullet.node.position.y > size.height + 40
                || bullet.node.position.y < -40 {
                bullet.isAlive = false
            }
        }
    }

    private func handleCollisions() {
        handleBulletVsBullet()
        handleBulletVsBunkers()
        handlePlayerBulletVsAliens()
        handleEnemyBulletVsPlayer()
    }

    private func handleBulletVsBullet() {
        let playerBullets = bullets.filter { $0.isAlive && $0.owner == .player }
        let enemyBullets = bullets.filter { $0.isAlive && $0.owner == .enemy }

        for playerBullet in playerBullets {
            for enemyBullet in enemyBullets where enemyBullet.isAlive {
                if playerBullet.node.frame.intersects(enemyBullet.node.frame) {
                    playerBullet.isAlive = false
                    enemyBullet.isAlive = false
                    spawnExplosion(at: midpoint(playerBullet.node.position, enemyBullet.node.position), color: Palette.bullet, amount: 8, spread: 18)
                    feedback.bunkerHit()
                    return
                }
            }
        }
    }

    private func handleBulletVsBunkers() {
        for bullet in bullets where bullet.isAlive {
            for cell in bunkerCells where cell.durability > 0 {
                if bullet.node.frame.intersects(cell.node.frame) {
                    bullet.isAlive = false
                    damageBunkerCell(cell)
                    spawnExplosion(at: bullet.node.position, color: bullet.owner == .player ? Palette.bullet : Palette.enemyBullet, amount: 6, spread: 16)
                    feedback.bunkerHit()
                    break
                }
            }
        }
    }

    private func handlePlayerBulletVsAliens() {
        let playerBullets = bullets.filter { $0.isAlive && $0.owner == .player }

        for bullet in playerBullets {
            for alien in aliens where alien.isAlive {
                if bullet.node.frame.intersects(alien.node.frame) {
                    bullet.isAlive = false
                    alien.isAlive = false
                    score += alien.scoreValue
                    spawnExplosion(at: alien.node.position, color: alien.tier.alienColor, amount: 18, spread: 42)
                    alien.node.removeFromParent()
                    flashScreen(color: alien.tier.alienColor.withAlphaComponent(0.35), duration: 0.08)
                    shakeWorld(intensity: 6)
                    feedback.alienDestroyed()
                    break
                }
            }
        }
    }

    private func handleEnemyBulletVsPlayer() {
        guard playerInvulnerabilityTime <= 0 else { return }

        let enemyBullets = bullets.filter { $0.isAlive && $0.owner == .enemy }
        let hitFrame = playerNode.frame.insetBy(dx: 4, dy: 2)

        for bullet in enemyBullets where bullet.node.frame.intersects(hitFrame) {
            bullet.isAlive = false
            spawnExplosion(at: playerNode.position, color: Palette.enemyBullet, amount: 20, spread: 48)
            shakeWorld(intensity: 14)
            flashScreen(color: Palette.enemyBullet.withAlphaComponent(0.35), duration: 0.12)
            feedback.playerHit()
            applyPlayerHit()
            break
        }
    }

    private func applyPlayerHit() {
        lives -= 1

        if lives <= 0 {
            triggerGameOver(reason: "Your ship was overrun.")
            return
        }

        playerInvulnerabilityTime = 2.0
        playerNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        statusLabel.text = "SHIP HIT  |  SHIELDS RECOVERING"
    }

    private func firePlayerBulletIfNeeded(force: Bool) {
        guard gameState == .playing else { return }

        if force == false, playerFireCooldown > 0 { return }

        let bulletSprite = makeBulletSprite(color: Palette.bullet)
        bulletSprite.position = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 28)
        bulletNode.addChild(bulletSprite)
        bullets.append(Bullet(node: bulletSprite, owner: .player, velocity: CGVector(dx: 0, dy: 620)))
        playerFireCooldown = 0.16
        feedback.playerShot()
    }

    private func fireEnemyBullet() {
        let aliveAliens = aliens.filter(\.isAlive)
        guard !aliveAliens.isEmpty else { return }

        guard let activeTier = activeEnemyShootingTier(from: aliveAliens) else { return }

        let eligibleAliens = aliveAliens.filter { $0.tier == activeTier }
        let grouped = Dictionary(grouping: eligibleAliens) { Int($0.node.position.x.rounded()) }
        let firingLane = grouped.values.randomElement() ?? eligibleAliens
        guard let shooter = firingLane.min(by: { $0.node.position.y < $1.node.position.y }) else { return }

        let waveBoost = CGFloat(wave - 1) * 8
        let baseSpeed = activeTier.bulletVelocity - waveBoost

        switch activeTier {
        case .green:
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: 0, y: -24),
                velocity: CGVector(dx: 0, dy: baseSpeed)
            )
        case .blue:
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: -10, y: -22),
                velocity: CGVector(dx: 0, dy: baseSpeed)
            )
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: 10, y: -22),
                velocity: CGVector(dx: 0, dy: baseSpeed)
            )
        case .yellow:
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: 0, y: -24),
                velocity: CGVector(dx: 0, dy: baseSpeed)
            )
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: -8, y: -22),
                velocity: CGVector(dx: -110, dy: baseSpeed + 24)
            )
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: 8, y: -22),
                velocity: CGVector(dx: 110, dy: baseSpeed + 24)
            )
        case .red:
            spawnEnemyBullet(
                tier: activeTier,
                from: shooter.node.position,
                offset: CGPoint(x: 0, y: -26),
                velocity: CGVector(dx: 0, dy: baseSpeed),
                scale: 1.55
            )
        }

        feedback.enemyShot()
    }

    private func makeBulletSprite(color: UIColor) -> SKSpriteNode {
        let texture = makePixelTexture(
            pattern: [
                "0110",
                "1111",
                "1111",
                "0110",
                "0110",
                "1111"
            ],
            color: color,
            pixelSize: 3
        )

        let sprite = SKSpriteNode(texture: texture)
        sprite.zPosition = 6
        sprite.texture?.filteringMode = .nearest
        sprite.blendMode = .add
        addGlow(to: sprite, color: color, alpha: 0.24, scale: 1.6)
        return sprite
    }

    private func makeEnemyBulletSprite(for tier: AlienTier) -> SKSpriteNode {
        let texture = makePixelTexture(
            pattern: tier.bulletPattern,
            color: tier.alienColor,
            pixelSize: 3
        )

        let sprite = SKSpriteNode(texture: texture)
        sprite.zPosition = 6
        sprite.texture?.filteringMode = .nearest
        sprite.blendMode = .add
        addGlow(to: sprite, color: tier.alienColor, alpha: 0.22, scale: 1.45)
        return sprite
    }

    private func spawnEnemyBullet(
        tier: AlienTier,
        from origin: CGPoint,
        offset: CGPoint,
        velocity: CGVector,
        scale: CGFloat = 1
    ) {
        let bulletSprite = makeEnemyBulletSprite(for: tier)
        bulletSprite.position = CGPoint(x: origin.x + offset.x, y: origin.y + offset.y)
        bulletSprite.setScale(scale)
        bulletNode.addChild(bulletSprite)
        bullets.append(Bullet(node: bulletSprite, owner: .enemy, velocity: velocity))
    }

    private func activeEnemyShootingTier(from aliveAliens: [Alien]) -> AlienTier? {
        for tier in AlienTier.allCases.reversed() {
            if aliveAliens.contains(where: { $0.tier == tier }) {
                return tier
            }
        }

        return nil
    }

    private func damageBunkerCell(_ cell: BunkerCell) {
        cell.durability -= 1

        if cell.durability <= 0 {
            cell.node.removeFromParent()
            return
        }

        cell.node.color = Palette.bunker.withAlphaComponent(0.5)
        cell.node.alpha = 0.55
    }

    private func checkForWaveCompletion() {
        guard gameState == .playing else { return }

        if aliens.contains(where: \.isAlive) == false {
            wave += 1
            gameState = .waveTransition
            waveTransitionTimer = waveClearCountdownDuration
            showOverlay(
                title: "WAVE CLEAR",
                subtitle: waveClearSubtitleText(),
                hint: waveClearHintText(),
                style: .waveClear
            )
            overlayNode.isHidden = false
        }
    }

    private func updateWaveClearOverlayCountdown() {
        guard overlayStyle == .waveClear else { return }

        let contentWidth = overlayPanelSize().width - 54
        configureOverlayText(
            in: overlaySubtitleNode,
            text: waveClearSubtitleText(),
            font: overlayStyle.subtitleFont,
            color: overlayStyle.subtitleColor,
            maxWidth: contentWidth,
            lineHeight: overlayStyle.subtitleLineHeight
        )
        configureOverlayText(
            in: overlayHintNode,
            text: waveClearHintText(),
            font: UIFont(name: "Menlo-Bold", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .bold),
            color: overlayStyle.hintColor,
            maxWidth: contentWidth - 8,
            lineHeight: 16
        )
    }

    private func waveClearSubtitleText() -> String {
        String(max(1, Int(ceil(waveTransitionTimer))))
    }

    private func waveClearHintText() -> String {
        "Arcade pressure goes up.\nSector \(wave) auto-deploys at zero."
    }

    private func triggerGameOver(reason: String) {
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }
        registerScore(score)

        gameState = .gameOver
        touchIsActive = false
        playerTargetX = nil

        feedback.gameOver()
        showOverlay(
            title: "GAME OVER",
            subtitle: "LAST SCORE: \(score)\nHIGH SCORE: \(highScore)",
            hint: "",
            style: .gameOver
            ,
            buttonTitle: "BACK",
            buttonAction: .backToMenu
        )
        statusLabel.text = "RUN TERMINATED"
    }

    private func clearArena() {
        clearWave()
        bunkerNode.removeAllChildren()
        bunkerCells.removeAll()
    }

    private func clearWave() {
        bulletNode.removeAllChildren()
        alienNode.removeAllChildren()
        bullets.removeAll()
        aliens.removeAll()
    }

    private func cleanupDestroyedNodes() {
        bullets.removeAll { bullet in
            guard bullet.isAlive == false else { return false }
            bullet.node.removeFromParent()
            return true
        }

        bunkerCells.removeAll { cell in
            cell.durability <= 0
        }

        aliens.removeAll { alien in
            alien.isAlive == false
        }
    }

    private func updateStars(deltaTime: TimeInterval) {
        for star in stars {
            star.node.position.y -= star.speed * CGFloat(deltaTime)
            star.node.position.x += star.drift * CGFloat(deltaTime) * 0.18

            if star.node.position.y < -12 {
                star.node.position.y = size.height + 12
                star.node.position.x = CGFloat.random(in: 0...size.width)
            }

            if star.node.position.x < -8 {
                star.node.position.x = size.width + 8
            } else if star.node.position.x > size.width + 8 {
                star.node.position.x = -8
            }
        }
    }

    private func pulseScanlines(currentTime: TimeInterval) {
        scanlineNode.alpha = 0.18 + CGFloat((sin(currentTime * 1.6) + 1) * 0.02)
    }

    private func pattern(for wave: Int) -> WavePattern {
        switch wave {
        case 1:
            return .classic
        case 2:
            return .pulse
        case 3:
            return .zigzag
        case 4:
            return .drift
        default:
            return WavePattern.allCases[(wave - 1) % WavePattern.allCases.count]
        }
    }

    private func positionedAlienPoint(for alien: Alien) -> CGPoint {
        var point = alien.anchorPosition
        let t = CGFloat(formationTime)
        let centeredColumn = CGFloat(alien.column) - 2.5
        let centeredRow = CGFloat(alien.row) - 2.0
        let spacingY = min(size.height * 0.07, 58)

        switch wavePattern {
        case .classic:
            break
        case .pulse:
            point.x += sin(t * 3.0 + CGFloat(alien.row) * 0.7 + alien.wobbleSeed) * 8
            point.y += cos(t * 3.2 + CGFloat(alien.column) * 0.5) * 1.6
        case .zigzag:
            let lane = (alien.row + alien.column).isMultiple(of: 2) ? 1.0 : -1.0
            point.x += lane * sin(t * 4.4 + CGFloat(alien.row) * 0.6) * 14
            point.y += sin(t * 2.2 + CGFloat(alien.column) * 0.8) * 4
        case .drift:
            point.x += sin(t * 2.1 + CGFloat(alien.column) * 0.9) * 18
            point.y += cos(t * 2.8 + CGFloat(alien.row) * 0.7 + alien.wobbleSeed) * 10
        case .compression:
            let compression = sin(t * 3.0) * 0.24
            point.x += centeredColumn * 16 * compression
            point.y += centeredRow * 6 * -compression
        }

        point.y = min(point.y, alienTopLimit(forRow: alien.row, spacingY: spacingY))

        return point
    }

    private func alienTopLimit(forRow row: Int, spacingY: CGFloat) -> CGFloat {
        let hudSafeCeiling = size.height - 170
        return hudSafeCeiling - CGFloat(row) * spacingY
    }

    private func updateHUD() {
        scoreLabel.text = String(format: "%05d", score)
        highScoreLabel.text = "HIGH \(String(format: "%05d", highScore))"
        waveLabel.text = "WAVE \(wave)"
        livesLabel.text = "LIVES \(String(repeating: "▮", count: max(0, lives)))"
    }

    private func showOverlay(
        title: String,
        subtitle: String,
        hint: String,
        style: OverlayStyle = .intro,
        buttonTitle: String? = nil,
        buttonAction: OverlayButtonAction? = nil,
        secondaryButtonTitle: String? = nil,
        secondaryButtonAction: OverlayButtonAction? = nil,
        tertiaryButtonTitle: String? = nil,
        tertiaryButtonAction: OverlayButtonAction? = nil
    ) {
        overlayStyle = style
        overlayTitle.text = title
        overlayTitle.fontColor = style.titleColor
        overlayPanel.fillColor = style.panelFillColor
        overlayPanel.strokeColor = style.panelStrokeColor
        let contentWidth = overlayPanelSize().width - 54
        configureOverlayText(
            in: overlaySubtitleNode,
            text: subtitle,
            font: style.subtitleFont,
            color: style.subtitleColor,
            maxWidth: contentWidth,
            lineHeight: style.subtitleLineHeight
        )
        configureOverlayText(
            in: overlayHintNode,
            text: hint,
            font: UIFont(name: "Menlo-Bold", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .bold),
            color: style.hintColor,
            maxWidth: contentWidth - 8,
            lineHeight: 16
        )
        overlayButtonAction = buttonAction
        overlaySecondaryButtonAction = secondaryButtonAction
        overlayTertiaryButtonAction = tertiaryButtonAction
        overlayButtonLabel.text = buttonTitle
        overlaySecondaryButtonLabel.text = secondaryButtonTitle
        overlayTertiaryButtonLabel.text = tertiaryButtonTitle
        let hasButton = buttonTitle != nil && buttonAction != nil
        let hasSecondaryButton = secondaryButtonTitle != nil && secondaryButtonAction != nil
        let hasTertiaryButton = tertiaryButtonTitle != nil && tertiaryButtonAction != nil
        if let buttonAction {
            switch buttonAction {
            case .startGame:
                overlayButtonBaseFillColor = Palette.lime.withAlphaComponent(0.92)
                overlayButtonBaseStrokeColor = Palette.grid
                overlayButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .showScore:
                overlayButtonBaseFillColor = Palette.bullet.withAlphaComponent(0.92)
                overlayButtonBaseStrokeColor = Palette.grid
                overlayButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .showMenu:
                overlayButtonBaseFillColor = Palette.cyan.withAlphaComponent(0.92)
                overlayButtonBaseStrokeColor = Palette.cyan.withAlphaComponent(0.55)
                overlayButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .closeMenu:
                overlayButtonBaseFillColor = Palette.orange.withAlphaComponent(0.90)
                overlayButtonBaseStrokeColor = Palette.orange.withAlphaComponent(0.55)
                overlayButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.90)
            case .backToMenu:
                overlayButtonBaseFillColor = Palette.red.withAlphaComponent(0.94)
                overlayButtonBaseStrokeColor = Palette.red.withAlphaComponent(0.55)
                overlayButtonBaseLabelColor = UIColor.white.withAlphaComponent(0.94)
            }
        }
        if let secondaryButtonAction {
            switch secondaryButtonAction {
            case .startGame:
                overlaySecondaryButtonBaseFillColor = Palette.lime.withAlphaComponent(0.92)
                overlaySecondaryButtonBaseStrokeColor = Palette.grid
                overlaySecondaryButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .showScore:
                overlaySecondaryButtonBaseFillColor = Palette.bullet.withAlphaComponent(0.92)
                overlaySecondaryButtonBaseStrokeColor = Palette.grid
                overlaySecondaryButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .showMenu:
                overlaySecondaryButtonBaseFillColor = Palette.lime.withAlphaComponent(0.92)
                overlaySecondaryButtonBaseStrokeColor = Palette.grid
                overlaySecondaryButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .closeMenu:
                overlaySecondaryButtonBaseFillColor = Palette.orange.withAlphaComponent(0.16)
                overlaySecondaryButtonBaseStrokeColor = Palette.orange.withAlphaComponent(0.55)
                overlaySecondaryButtonBaseLabelColor = Palette.orange
            case .backToMenu:
                overlaySecondaryButtonBaseFillColor = Palette.red.withAlphaComponent(0.16)
                overlaySecondaryButtonBaseStrokeColor = Palette.red.withAlphaComponent(0.55)
                overlaySecondaryButtonBaseLabelColor = Palette.red
            }
        }
        if let tertiaryButtonAction {
            switch tertiaryButtonAction {
            case .startGame:
                overlayTertiaryButtonBaseFillColor = Palette.lime.withAlphaComponent(0.92)
                overlayTertiaryButtonBaseStrokeColor = Palette.grid
                overlayTertiaryButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .showScore:
                overlayTertiaryButtonBaseFillColor = Palette.bullet.withAlphaComponent(0.92)
                overlayTertiaryButtonBaseStrokeColor = Palette.grid
                overlayTertiaryButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .showMenu:
                overlayTertiaryButtonBaseFillColor = Palette.lime.withAlphaComponent(0.92)
                overlayTertiaryButtonBaseStrokeColor = Palette.grid
                overlayTertiaryButtonBaseLabelColor = UIColor.black.withAlphaComponent(0.88)
            case .closeMenu:
                overlayTertiaryButtonBaseFillColor = Palette.orange.withAlphaComponent(0.16)
                overlayTertiaryButtonBaseStrokeColor = Palette.orange.withAlphaComponent(0.55)
                overlayTertiaryButtonBaseLabelColor = Palette.orange
            case .backToMenu:
                overlayTertiaryButtonBaseFillColor = Palette.red.withAlphaComponent(0.16)
                overlayTertiaryButtonBaseStrokeColor = Palette.red.withAlphaComponent(0.55)
                overlayTertiaryButtonBaseLabelColor = Palette.red
            }
        }
        overlayButton.isHidden = !hasButton
        overlayButtonLabel.isHidden = !hasButton
        overlaySecondaryButton.isHidden = !hasSecondaryButton
        overlaySecondaryButtonLabel.isHidden = !hasSecondaryButton
        overlayTertiaryButton.isHidden = !hasTertiaryButton
        overlayTertiaryButtonLabel.isHidden = !hasTertiaryButton
        let showScoreBoard = style == .score
        let showVersionLabel = style == .menu
        let showAudioToggle = style == .menu
        overlayScoreboardNode.isHidden = !showScoreBoard
        overlayVersionLabel.isHidden = !showVersionLabel
        overlayAudioToggle.isHidden = !showAudioToggle
        updateOverlayButtonPressed(isPressed: false)
        updateOverlaySecondaryButtonPressed(isPressed: false)
        updateOverlayTertiaryButtonPressed(isPressed: false)
        updateAudioTogglePressed(isPressed: false)
        if showScoreBoard || showAudioToggle {
            updateMenuContent()
        }
        layoutScene()
        overlayNode.isHidden = false
    }

    private func handleOverlayButtonAction() {
        feedback.overlayButtonTap()

        switch overlayButtonAction {
        case .startGame:
            startNewGame()
        case .showScore:
            showScoreOverlay()
        case .showMenu:
            showMenuOverlay()
        case .closeMenu:
            enterIntroState()
        case .backToMenu:
            enterIntroState()
        case .none:
            break
        }
    }

    private func handleOverlaySecondaryButtonAction() {
        feedback.overlayButtonTap()

        switch overlaySecondaryButtonAction {
        case .startGame:
            startNewGame()
        case .showScore:
            showScoreOverlay()
        case .showMenu:
            showMenuOverlay()
        case .closeMenu:
            enterIntroState()
        case .backToMenu:
            enterIntroState()
        case .none:
            break
        }
    }

    private func handleOverlayTertiaryButtonAction() {
        feedback.overlayButtonTap()

        switch overlayTertiaryButtonAction {
        case .startGame:
            startNewGame()
        case .showScore:
            showScoreOverlay()
        case .showMenu:
            showMenuOverlay()
        case .closeMenu, .backToMenu:
            enterIntroState()
        case .none:
            break
        }
    }

    private func isTouchInsideOverlayButton(_ touch: UITouch) -> Bool {
        let point = touch.location(in: overlayNode)
        return overlayNode.isHidden == false && overlayButton.isHidden == false && overlayButton.contains(point)
    }

    private func isTouchInsideOverlaySecondaryButton(_ touch: UITouch) -> Bool {
        let point = touch.location(in: overlayNode)
        return overlayNode.isHidden == false && overlaySecondaryButton.isHidden == false && overlaySecondaryButton.contains(point)
    }

    private func isTouchInsideAudioToggle(_ touch: UITouch) -> Bool {
        let point = touch.location(in: overlayNode)
        return overlayNode.isHidden == false && overlayAudioToggle.isHidden == false && overlayAudioToggle.contains(point)
    }

    private func isTouchInsideOverlayTertiaryButton(_ touch: UITouch) -> Bool {
        let point = touch.location(in: overlayNode)
        return overlayNode.isHidden == false && overlayTertiaryButton.isHidden == false && overlayTertiaryButton.contains(point)
    }

    private func updateOverlayButtonPressed(isPressed: Bool) {
        overlayButtonPressed = isPressed

        guard overlayButton.isHidden == false else { return }

        if isPressed {
            overlayButton.fillColor = overlayButtonBaseFillColor.withAlphaComponent(min(1.0, overlayButtonBaseFillColor.cgColor.alpha * 0.72))
            overlayButton.strokeColor = overlayButtonBaseStrokeColor.withAlphaComponent(min(1.0, overlayButtonBaseStrokeColor.cgColor.alpha + 0.20))
            overlayButtonLabel.alpha = 0.82
            overlayButton.setScale(0.985)
        } else {
            overlayButton.fillColor = overlayButtonBaseFillColor
            overlayButton.strokeColor = overlayButtonBaseStrokeColor
            overlayButtonLabel.fontColor = overlayButtonBaseLabelColor
            overlayButtonLabel.alpha = 1.0
            overlayButton.setScale(1.0)
        }
    }

    private func updateOverlaySecondaryButtonPressed(isPressed: Bool) {
        overlaySecondaryButtonPressed = isPressed

        guard overlaySecondaryButton.isHidden == false else { return }

        if isPressed {
            overlaySecondaryButton.fillColor = overlaySecondaryButtonBaseFillColor.withAlphaComponent(min(1.0, overlaySecondaryButtonBaseFillColor.cgColor.alpha + 0.12))
            overlaySecondaryButton.strokeColor = overlaySecondaryButtonBaseStrokeColor.withAlphaComponent(min(1.0, overlaySecondaryButtonBaseStrokeColor.cgColor.alpha + 0.20))
            overlaySecondaryButtonLabel.alpha = 0.84
            overlaySecondaryButton.setScale(0.985)
        } else {
            overlaySecondaryButton.fillColor = overlaySecondaryButtonBaseFillColor
            overlaySecondaryButton.strokeColor = overlaySecondaryButtonBaseStrokeColor
            overlaySecondaryButtonLabel.fontColor = overlaySecondaryButtonBaseLabelColor
            overlaySecondaryButtonLabel.alpha = 1.0
            overlaySecondaryButton.setScale(1.0)
        }
    }

    private func updateAudioTogglePressed(isPressed: Bool) {
        overlayAudioTogglePressed = isPressed

        guard overlayAudioToggle.isHidden == false else { return }

        applyAudioToggleAppearance(isPressed: isPressed)
    }

    private func updateOverlayTertiaryButtonPressed(isPressed: Bool) {
        overlayTertiaryButtonPressed = isPressed

        guard overlayTertiaryButton.isHidden == false else { return }

        if isPressed {
            overlayTertiaryButton.fillColor = overlayTertiaryButtonBaseFillColor.withAlphaComponent(min(1.0, overlayTertiaryButtonBaseFillColor.cgColor.alpha + 0.12))
            overlayTertiaryButton.strokeColor = overlayTertiaryButtonBaseStrokeColor.withAlphaComponent(min(1.0, overlayTertiaryButtonBaseStrokeColor.cgColor.alpha + 0.20))
            overlayTertiaryButtonLabel.alpha = 0.84
            overlayTertiaryButton.setScale(0.985)
        } else {
            overlayTertiaryButton.fillColor = overlayTertiaryButtonBaseFillColor
            overlayTertiaryButton.strokeColor = overlayTertiaryButtonBaseStrokeColor
            overlayTertiaryButtonLabel.fontColor = overlayTertiaryButtonBaseLabelColor
            overlayTertiaryButtonLabel.alpha = 1.0
            overlayTertiaryButton.setScale(1.0)
        }
    }

    private func overlayPanelSize() -> CGSize {
        let width = min(size.width * 0.76, 330)
        let height: CGFloat
        switch overlayStyle {
        case .menu:
            height = 310
        case .score:
            height = 380
        case .intro:
            height = 420
        case .waveClear:
            height = 300
        case .gameOver:
            height = 340
        }
        return CGSize(width: width, height: height)
    }

    private func configureOverlayText(
        in container: SKNode,
        text: String,
        font: UIFont,
        color: UIColor,
        maxWidth: CGFloat,
        lineHeight: CGFloat
    ) {
        container.removeAllChildren()

        let lines = wrappedLines(for: text, font: font, maxWidth: maxWidth)
        let totalHeight = CGFloat(max(0, lines.count - 1)) * lineHeight

        for (index, line) in lines.enumerated() {
            let label = SKLabelNode(fontNamed: font.fontName)
            label.text = line
            label.fontSize = font.pointSize
            label.fontColor = color
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: totalHeight / 2 - CGFloat(index) * lineHeight)
            container.addChild(label)
        }
    }

    private func wrappedLines(for text: String, font: UIFont, maxWidth: CGFloat) -> [String] {
        let paragraphs = text.components(separatedBy: "\n")
        var lines: [String] = []
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        for paragraph in paragraphs {
            let words = paragraph.split(separator: " ").map(String.init)
            guard !words.isEmpty else {
                lines.append("")
                continue
            }

            var currentLine = words[0]

            for word in words.dropFirst() {
                let candidate = currentLine + " " + word
                let candidateWidth = (candidate as NSString).size(withAttributes: attributes).width

                if candidateWidth <= maxWidth {
                    currentLine = candidate
                } else {
                    lines.append(currentLine)
                    currentLine = word
                }
            }

            lines.append(currentLine)
        }

        return lines
    }

    private func updateMenuContent() {
        overlayScoreboardNode.removeAllChildren()

        let cabinetOuter = SKShapeNode(
            rectOf: CGSize(width: 252, height: 196),
            cornerRadius: 26
        )
        cabinetOuter.fillColor = UIColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 0.92)
        cabinetOuter.strokeColor = Palette.orange.withAlphaComponent(0.45)
        cabinetOuter.lineWidth = 3
        cabinetOuter.glowWidth = 8
        cabinetOuter.position = CGPoint(x: 0, y: 6)
        overlayScoreboardNode.addChild(cabinetOuter)

        let cabinetInner = SKShapeNode(
            rectOf: CGSize(width: 228, height: 170),
            cornerRadius: 18
        )
        cabinetInner.fillColor = UIColor(red: 0.02, green: 0.04, blue: 0.07, alpha: 0.96)
        cabinetInner.strokeColor = Palette.cyan.withAlphaComponent(0.20)
        cabinetInner.lineWidth = 2
        cabinetInner.position = CGPoint(x: 0, y: 6)
        overlayScoreboardNode.addChild(cabinetInner)

        let bezelLeft = SKShapeNode(rectOf: CGSize(width: 10, height: 164), cornerRadius: 5)
        bezelLeft.fillColor = Palette.orange.withAlphaComponent(0.18)
        bezelLeft.strokeColor = .clear
        bezelLeft.position = CGPoint(x: -112, y: 6)
        overlayScoreboardNode.addChild(bezelLeft)

        let bezelRight = SKShapeNode(rectOf: CGSize(width: 10, height: 164), cornerRadius: 5)
        bezelRight.fillColor = Palette.orange.withAlphaComponent(0.18)
        bezelRight.strokeColor = .clear
        bezelRight.position = CGPoint(x: 112, y: 6)
        overlayScoreboardNode.addChild(bezelRight)

        let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "RANK   TOP SCORES"
        titleLabel.fontSize = 18
        titleLabel.fontColor = Palette.bullet
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 76)
        overlayScoreboardNode.addChild(titleLabel)

        let titleAccent = SKShapeNode(rectOf: CGSize(width: 150, height: 2), cornerRadius: 1)
        titleAccent.fillColor = Palette.bullet.withAlphaComponent(0.65)
        titleAccent.strokeColor = .clear
        titleAccent.position = CGPoint(x: 0, y: 64)
        overlayScoreboardNode.addChild(titleAccent)

        let entries = Array(scoreBoardEntries.prefix(5))

        for index in 0..<5 {
            let value = index < entries.count ? String(format: "%05d", entries[index]) : "-----"
            let rowNode = makeScoreboardRow(rank: index + 1, value: value, isLeader: index == 0)
            rowNode.position = CGPoint(x: 0, y: 32 - CGFloat(index) * 25)
            overlayScoreboardNode.addChild(rowNode)
        }

        applyAudioToggleAppearance(isPressed: overlayAudioTogglePressed)
    }

    private func makeScoreboardRow(rank: Int, value: String, isLeader: Bool) -> SKNode {
        let rowNode = SKNode()

        let background = SKShapeNode(rectOf: CGSize(width: 206, height: isLeader ? 28 : 22), cornerRadius: 10)
        if isLeader {
            background.fillColor = UIColor(red: 0.38, green: 0.28, blue: 0.05, alpha: 0.90)
            background.strokeColor = Palette.bullet.withAlphaComponent(0.78)
            background.lineWidth = 2.5
            background.glowWidth = 5.5

            let shine = SKShapeNode(rectOf: CGSize(width: 196, height: 8), cornerRadius: 4)
            shine.fillColor = UIColor.white.withAlphaComponent(0.10)
            shine.strokeColor = .clear
            shine.position = CGPoint(x: 0, y: 7)
            rowNode.addChild(shine)

            let crown = SKLabelNode(fontNamed: "Menlo-Bold")
            crown.text = "TOP"
            crown.fontSize = 11
            crown.fontColor = UIColor.black.withAlphaComponent(0.85)
            crown.horizontalAlignmentMode = .center
            crown.verticalAlignmentMode = .center
            crown.position = CGPoint(x: -54, y: 0)

            let crownBadge = SKShapeNode(rectOf: CGSize(width: 30, height: 14), cornerRadius: 6)
            crownBadge.fillColor = Palette.bullet.withAlphaComponent(0.96)
            crownBadge.strokeColor = .clear
            crownBadge.position = crown.position
            rowNode.addChild(crownBadge)
            rowNode.addChild(crown)
        } else {
            background.fillColor = UIColor(red: 0.08, green: 0.12, blue: 0.16, alpha: 0.78)
            background.strokeColor = Palette.cyan.withAlphaComponent(0.16)
            background.lineWidth = 1.5
        }
        rowNode.addChild(background)

        let rankLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        rankLabel.text = String(format: "#%d", rank)
        rankLabel.fontSize = isLeader ? 18 : 15
        rankLabel.fontColor = isLeader ? Palette.bullet : Palette.hud.withAlphaComponent(0.92)
        rankLabel.horizontalAlignmentMode = .left
        rankLabel.verticalAlignmentMode = .center
        rankLabel.position = CGPoint(x: -92, y: isLeader ? 0 : -0.5)
        rowNode.addChild(rankLabel)

        let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.text = value
        scoreLabel.fontSize = isLeader ? 22 : 18
        scoreLabel.fontColor = isLeader ? UIColor(red: 1.0, green: 0.97, blue: 0.74, alpha: 1.0) : Palette.hud
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 92, y: isLeader ? 0 : -0.5)
        rowNode.addChild(scoreLabel)

        return rowNode
    }

    private func audioToggleBaseFillColor() -> UIColor {
        feedback.isAudioEnabled ? Palette.lime.withAlphaComponent(0.92) : Palette.red.withAlphaComponent(0.94)
    }

    private func audioToggleBaseStrokeColor() -> UIColor {
        feedback.isAudioEnabled ? Palette.grid : Palette.red.withAlphaComponent(0.62)
    }

    private func audioToggleContentColor() -> UIColor {
        UIColor.black.withAlphaComponent(0.88)
    }

    private func applyAudioToggleAppearance(isPressed: Bool) {
        let fillColor = audioToggleBaseFillColor()
        let strokeColor = audioToggleBaseStrokeColor()
        let contentColor = audioToggleContentColor()

        if isPressed {
            overlayAudioToggle.fillColor = fillColor.withAlphaComponent(min(1.0, fillColor.cgColor.alpha * 0.72))
            overlayAudioToggle.strokeColor = strokeColor.withAlphaComponent(min(1.0, strokeColor.cgColor.alpha + 0.20))
            overlayAudioToggle.setScale(0.985)
        } else {
            overlayAudioToggle.fillColor = fillColor
            overlayAudioToggle.strokeColor = strokeColor
            overlayAudioToggle.setScale(1.0)
        }

        overlayAudioLabel.fontColor = contentColor
        overlayAudioValueLabel.fontColor = contentColor
        overlayAudioIcon.color = contentColor
    }

    private func loadScoreBoard() -> [Int] {
        let values = UserDefaults.standard.array(forKey: scoreBoardKey) as? [Int] ?? []
        return Array(values.sorted(by: >).prefix(5))
    }

    private func registerScore(_ value: Int) {
        guard value > 0 else { return }

        scoreBoardEntries.append(value)
        scoreBoardEntries = Array(scoreBoardEntries.sorted(by: >).prefix(5))
        UserDefaults.standard.set(scoreBoardEntries, forKey: scoreBoardKey)
    }

    private func loadAudioEnabledPreference() -> Bool {
        if UserDefaults.standard.object(forKey: audioEnabledKey) == nil {
            return true
        }

        return UserDefaults.standard.bool(forKey: audioEnabledKey)
    }

    private func toggleAudioPreference() {
        let newValue = !feedback.isAudioEnabled
        feedback.setAudioEnabled(newValue)
        UserDefaults.standard.set(newValue, forKey: audioEnabledKey)
        updateMenuContent()
        feedback.overlayButtonTap()
    }

    private func addGlow(to sprite: SKSpriteNode, color: UIColor, alpha: CGFloat, scale: CGFloat) {
        guard let texture = sprite.texture else { return }

        let glow = SKSpriteNode(texture: texture)
        glow.color = color
        glow.colorBlendFactor = 0.35
        glow.alpha = alpha
        glow.setScale(scale)
        glow.blendMode = .add
        glow.zPosition = -1
        sprite.addChild(glow)
    }

    private func spawnExplosion(at position: CGPoint, color: UIColor, amount: Int, spread: CGFloat) {
        let container = SKNode()
        container.position = position
        container.zPosition = 15
        worldNode.addChild(container)

        for _ in 0..<amount {
            let particleSize = CGFloat.random(in: 3...7)
            let particle = SKSpriteNode(color: color.withAlphaComponent(CGFloat.random(in: 0.6...1.0)), size: CGSize(width: particleSize, height: particleSize))
            particle.blendMode = .add
            particle.position = .zero
            container.addChild(particle)

            let dx = CGFloat.random(in: -spread...spread)
            let dy = CGFloat.random(in: -spread...spread)
            let duration = Double.random(in: 0.18...0.42)

            particle.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: duration),
                    .fadeOut(withDuration: duration)
                ]),
                .removeFromParent()
            ]))
        }

        container.run(.sequence([
            .wait(forDuration: 0.5),
            .removeFromParent()
        ]))
    }

    private func flashScreen(color: UIColor, duration: TimeInterval) {
        flashNode.color = color
        flashNode.removeAllActions()
        flashNode.alpha = 0.0
        flashNode.run(.sequence([
            .fadeAlpha(to: 0.22, duration: duration * 0.35),
            .fadeOut(withDuration: duration * 0.65)
        ]))
    }

    private func shakeWorld(intensity: CGFloat) {
        worldNode.removeAction(forKey: "shake")

        let shake = SKAction.sequence([
            .moveBy(x: intensity, y: 0, duration: 0.03),
            .moveBy(x: -intensity * 1.6, y: 0, duration: 0.05),
            .moveBy(x: intensity * 0.6, y: 0, duration: 0.03)
        ])

        worldNode.run(shake, withKey: "shake")
    }

    private func midpoint(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2)
    }

    private func makeSpeakerTexture(isEnabled: Bool) -> SKTexture {
        let pattern = isEnabled
            ? [
                "0011000000011000",
                "0111100000111100",
                "1111110011111110",
                "1111111111111111",
                "1111111111111111",
                "1111110011111110",
                "0111100000111100",
                "0011000000011000"
            ]
            : [
                "0011000000001001",
                "0111100000010010",
                "1111110000100100",
                "1111111001001000",
                "1111111001001000",
                "1111110000100100",
                "0111100000010010",
                "0011000000001001"
            ]

        return makePixelTexture(pattern: pattern, color: .white, pixelSize: 2)
    }

    private func makePixelTexture(pattern: [String], color: UIColor, pixelSize: Int) -> SKTexture {
        let cacheKey = pixelTextureCacheKey(pattern: pattern, color: color, pixelSize: pixelSize)
        if let cachedTexture = pixelTextureCache[cacheKey] {
            return cachedTexture
        }

        let width = pattern.first?.count ?? 0
        let height = pattern.count
        let renderSize = CGSize(width: width * pixelSize, height: height * pixelSize)

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            cgContext.clear(CGRect(origin: .zero, size: renderSize))

            for (rowIndex, row) in pattern.enumerated() {
                for (columnIndex, value) in row.enumerated() where value == "1" {
                    let rect = CGRect(
                        x: columnIndex * pixelSize,
                        y: rowIndex * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )

                    cgContext.setFillColor(color.cgColor)
                    cgContext.fill(rect)
                }
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        pixelTextureCache[cacheKey] = texture
        return texture
    }

    private func pixelTextureCacheKey(pattern: [String], color: UIColor, pixelSize: Int) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let resolvedColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let colorKey = [
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255)),
            Int(round(alpha * 255))
        ].map(String.init).joined(separator: "-")

        return "\(pixelSize)|\(colorKey)|\(pattern.joined(separator: "/"))"
    }

    private func makeBackgroundTexture(size: CGSize) -> SKTexture {
        let renderSize = CGSize(width: max(1, Int(size.width)), height: max(1, Int(size.height)))
        let renderer = UIGraphicsImageRenderer(size: renderSize)

        let image = renderer.image { context in
            let cgContext = context.cgContext
            let colors = [Palette.backgroundTop.cgColor, Palette.backgroundBottom.cgColor] as CFArray

            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: renderSize.width / 2, y: 0),
                    end: CGPoint(x: renderSize.width / 2, y: renderSize.height),
                    options: []
                )
            }

            cgContext.setLineWidth(1)
            cgContext.setStrokeColor(Palette.grid.cgColor)

            stride(from: 0, through: renderSize.height, by: 48).forEach { y in
                cgContext.move(to: CGPoint(x: 0, y: CGFloat(y)))
                cgContext.addLine(to: CGPoint(x: renderSize.width, y: CGFloat(y)))
                cgContext.strokePath()
            }

            stride(from: 0, through: renderSize.width, by: 48).forEach { x in
                cgContext.move(to: CGPoint(x: CGFloat(x), y: 0))
                cgContext.addLine(to: CGPoint(x: CGFloat(x), y: renderSize.height))
                cgContext.strokePath()
            }

        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private func makeScanlineTexture(size: CGSize) -> SKTexture {
        let renderSize = CGSize(width: max(1, Int(size.width)), height: max(1, Int(size.height)))
        let renderer = UIGraphicsImageRenderer(size: renderSize)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            cgContext.clear(CGRect(origin: .zero, size: renderSize))

            for y in stride(from: 0, through: renderSize.height, by: 4) {
                let alpha = y.truncatingRemainder(dividingBy: 8) == 0 ? 0.12 : 0.04
                cgContext.setFillColor(UIColor.black.withAlphaComponent(alpha).cgColor)
                cgContext.fill(CGRect(x: 0, y: y, width: renderSize.width, height: 2))
            }

            let vignetteColors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.18).cgColor,
                UIColor.black.withAlphaComponent(0.42).cgColor
            ] as CFArray

            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: vignetteColors, locations: [0.0, 0.72, 1.0]) {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: renderSize.width / 2, y: renderSize.height / 2),
                    startRadius: min(renderSize.width, renderSize.height) * 0.18,
                    endCenter: CGPoint(x: renderSize.width / 2, y: renderSize.height / 2),
                    endRadius: max(renderSize.width, renderSize.height) * 0.72,
                    options: []
                )
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}
