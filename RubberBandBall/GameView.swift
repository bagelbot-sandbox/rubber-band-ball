import SwiftUI
import UIKit
import AVFoundation

// Logical coordinates match the 660 x 780 canvas used by the web version.
private let logicalWidth: CGFloat = 660
private let logicalHeight: CGFloat = 780
private let gridWidth = 11
private let gridHeight = 13
private let tileSize: CGFloat = 60
private let wallWidth: CGFloat = tileSize * 0.24
private let moveRepeatInterval: TimeInterval = 0.12
private let moveTravelDuration: TimeInterval = 0.12
private let swipeTurnThreshold: CGFloat = 18
private let backgroundImageName = "NicholasBackground"
private let levelMusicNames = ["strings", "drums", "clarinets", "horns"]
private let victoryMusicName = "all"
private let musicVolume: Float = 0.35

private let rubberBandColors: [Color] = [
    Color(hex: 0xfac737),
    Color(hex: 0xf2473f),
    Color(hex: 0x40b9f2),
    Color(hex: 0x5bc76d),
    Color(hex: 0xd96ef2)
]

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Model types

private struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

private enum Direction {
    case up, down, left, right

    func applied(to point: GridPoint) -> GridPoint {
        switch self {
        case .up: return GridPoint(x: point.x, y: point.y - 1)
        case .down: return GridPoint(x: point.x, y: point.y + 1)
        case .left: return GridPoint(x: point.x - 1, y: point.y)
        case .right: return GridPoint(x: point.x + 1, y: point.y)
        }
    }
}

private enum Instrument {
    case violin, drums, clarinet, trumpet
}

private struct Level {
    let number: Int
    let start: GridPoint
    let exit: GridPoint
    let bands: Set<GridPoint>
    let walls: Set<GridPoint>
    let instrumentalist: GridPoint
    let instrument: Instrument
}

private func makeLevel(
    _ number: Int,
    start: GridPoint,
    exit: GridPoint,
    bands: [GridPoint],
    innerWalls: [GridPoint],
    instrumentalist: GridPoint,
    instrument: Instrument
) -> Level {
    var walls = Set(innerWalls)

    for x in 0..<gridWidth {
        walls.insert(GridPoint(x: x, y: 0))
        walls.insert(GridPoint(x: x, y: gridHeight - 1))
    }

    for y in 0..<gridHeight {
        walls.insert(GridPoint(x: 0, y: y))
        walls.insert(GridPoint(x: gridWidth - 1, y: y))
    }

    walls.remove(start)
    walls.remove(exit)
    for band in bands {
        walls.remove(band)
    }

    return Level(
        number: number,
        start: start,
        exit: exit,
        bands: Set(bands),
        walls: walls,
        instrumentalist: instrumentalist,
        instrument: instrument
    )
}

private let levels: [Level] = [
    makeLevel(
        1,
        start: GridPoint(x: 1, y: 1),
        exit: GridPoint(x: 9, y: 11),
        bands: [
            GridPoint(x: 9, y: 10), GridPoint(x: 9, y: 9), GridPoint(x: 9, y: 8), GridPoint(x: 9, y: 7),
            GridPoint(x: 5, y: 11), GridPoint(x: 7, y: 8), GridPoint(x: 4, y: 11), GridPoint(x: 7, y: 7),
            GridPoint(x: 3, y: 11), GridPoint(x: 8, y: 5), GridPoint(x: 9, y: 3), GridPoint(x: 5, y: 7),
            GridPoint(x: 1, y: 11), GridPoint(x: 7, y: 4), GridPoint(x: 4, y: 7), GridPoint(x: 2, y: 9),
            GridPoint(x: 9, y: 1), GridPoint(x: 5, y: 5), GridPoint(x: 1, y: 9), GridPoint(x: 6, y: 3)
        ],
        innerWalls: [
            GridPoint(x: 1, y: 2), GridPoint(x: 2, y: 2), GridPoint(x: 3, y: 2), GridPoint(x: 4, y: 2),
            GridPoint(x: 5, y: 2), GridPoint(x: 6, y: 2), GridPoint(x: 7, y: 2), GridPoint(x: 8, y: 2),
            GridPoint(x: 2, y: 3), GridPoint(x: 8, y: 3), GridPoint(x: 2, y: 4), GridPoint(x: 4, y: 4),
            GridPoint(x: 5, y: 4), GridPoint(x: 6, y: 4), GridPoint(x: 8, y: 4), GridPoint(x: 2, y: 5),
            GridPoint(x: 6, y: 5), GridPoint(x: 2, y: 6), GridPoint(x: 3, y: 6), GridPoint(x: 4, y: 6),
            GridPoint(x: 6, y: 6), GridPoint(x: 7, y: 6), GridPoint(x: 8, y: 6), GridPoint(x: 9, y: 6),
            GridPoint(x: 2, y: 7), GridPoint(x: 6, y: 7), GridPoint(x: 2, y: 8), GridPoint(x: 4, y: 8),
            GridPoint(x: 5, y: 8), GridPoint(x: 6, y: 8), GridPoint(x: 8, y: 8), GridPoint(x: 4, y: 9),
            GridPoint(x: 8, y: 9), GridPoint(x: 2, y: 10), GridPoint(x: 3, y: 10), GridPoint(x: 4, y: 10),
            GridPoint(x: 5, y: 10), GridPoint(x: 6, y: 10), GridPoint(x: 7, y: 10), GridPoint(x: 8, y: 10)
        ],
        instrumentalist: GridPoint(x: 9, y: 1),
        instrument: .violin
    ),
    makeLevel(
        2,
        start: GridPoint(x: 1, y: 11),
        exit: GridPoint(x: 9, y: 1),
        bands: [
            GridPoint(x: 8, y: 1), GridPoint(x: 7, y: 1), GridPoint(x: 6, y: 1), GridPoint(x: 9, y: 4),
            GridPoint(x: 7, y: 3), GridPoint(x: 6, y: 3), GridPoint(x: 3, y: 1), GridPoint(x: 7, y: 5),
            GridPoint(x: 2, y: 1), GridPoint(x: 5, y: 4), GridPoint(x: 9, y: 8), GridPoint(x: 3, y: 3),
            GridPoint(x: 7, y: 7), GridPoint(x: 1, y: 2), GridPoint(x: 4, y: 5), GridPoint(x: 7, y: 8),
            GridPoint(x: 9, y: 10), GridPoint(x: 3, y: 5), GridPoint(x: 7, y: 9), GridPoint(x: 1, y: 4)
        ],
        innerWalls: [
            GridPoint(x: 4, y: 1), GridPoint(x: 2, y: 2), GridPoint(x: 4, y: 2), GridPoint(x: 5, y: 2),
            GridPoint(x: 6, y: 2), GridPoint(x: 8, y: 2), GridPoint(x: 2, y: 3), GridPoint(x: 4, y: 3),
            GridPoint(x: 8, y: 3), GridPoint(x: 2, y: 4), GridPoint(x: 4, y: 4), GridPoint(x: 6, y: 4),
            GridPoint(x: 7, y: 4), GridPoint(x: 8, y: 4), GridPoint(x: 2, y: 5), GridPoint(x: 6, y: 5),
            GridPoint(x: 2, y: 6), GridPoint(x: 3, y: 6), GridPoint(x: 4, y: 6), GridPoint(x: 5, y: 6),
            GridPoint(x: 6, y: 6), GridPoint(x: 8, y: 6), GridPoint(x: 9, y: 6), GridPoint(x: 2, y: 7),
            GridPoint(x: 8, y: 7), GridPoint(x: 2, y: 8), GridPoint(x: 3, y: 8), GridPoint(x: 4, y: 8),
            GridPoint(x: 5, y: 8), GridPoint(x: 6, y: 8), GridPoint(x: 8, y: 8), GridPoint(x: 6, y: 9),
            GridPoint(x: 1, y: 10), GridPoint(x: 2, y: 10), GridPoint(x: 3, y: 10), GridPoint(x: 4, y: 10),
            GridPoint(x: 6, y: 10), GridPoint(x: 7, y: 10), GridPoint(x: 8, y: 10), GridPoint(x: 6, y: 11)
        ],
        instrumentalist: GridPoint(x: 8, y: 1),
        instrument: .drums
    ),
    makeLevel(
        3,
        start: GridPoint(x: 5, y: 11),
        exit: GridPoint(x: 5, y: 1),
        bands: [
            GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2), GridPoint(x: 3, y: 1),
            GridPoint(x: 1, y: 3), GridPoint(x: 4, y: 1), GridPoint(x: 3, y: 2), GridPoint(x: 3, y: 3),
            GridPoint(x: 1, y: 5), GridPoint(x: 6, y: 3), GridPoint(x: 7, y: 4), GridPoint(x: 8, y: 5),
            GridPoint(x: 5, y: 3), GridPoint(x: 7, y: 5), GridPoint(x: 9, y: 7), GridPoint(x: 3, y: 6),
            GridPoint(x: 1, y: 8), GridPoint(x: 5, y: 5), GridPoint(x: 7, y: 7), GridPoint(x: 9, y: 9)
        ],
        innerWalls: [
            GridPoint(x: 2, y: 2), GridPoint(x: 4, y: 2), GridPoint(x: 5, y: 2), GridPoint(x: 6, y: 2),
            GridPoint(x: 7, y: 2), GridPoint(x: 8, y: 2), GridPoint(x: 2, y: 3), GridPoint(x: 4, y: 3),
            GridPoint(x: 8, y: 3), GridPoint(x: 1, y: 4), GridPoint(x: 2, y: 4), GridPoint(x: 4, y: 4),
            GridPoint(x: 6, y: 4), GridPoint(x: 8, y: 4), GridPoint(x: 4, y: 5), GridPoint(x: 6, y: 5),
            GridPoint(x: 2, y: 6), GridPoint(x: 4, y: 6), GridPoint(x: 5, y: 6), GridPoint(x: 6, y: 6),
            GridPoint(x: 7, y: 6), GridPoint(x: 8, y: 6), GridPoint(x: 9, y: 6), GridPoint(x: 2, y: 7),
            GridPoint(x: 4, y: 7), GridPoint(x: 2, y: 8), GridPoint(x: 3, y: 8), GridPoint(x: 4, y: 8),
            GridPoint(x: 6, y: 8), GridPoint(x: 7, y: 8), GridPoint(x: 8, y: 8), GridPoint(x: 8, y: 9),
            GridPoint(x: 2, y: 10), GridPoint(x: 3, y: 10), GridPoint(x: 4, y: 10), GridPoint(x: 5, y: 10),
            GridPoint(x: 6, y: 10), GridPoint(x: 7, y: 10), GridPoint(x: 8, y: 10), GridPoint(x: 4, y: 11)
        ],
        instrumentalist: GridPoint(x: 5, y: 3),
        instrument: .clarinet
    ),
    makeLevel(
        4,
        start: GridPoint(x: 1, y: 5),
        exit: GridPoint(x: 9, y: 5),
        bands: [
            GridPoint(x: 9, y: 11), GridPoint(x: 8, y: 11), GridPoint(x: 9, y: 9), GridPoint(x: 8, y: 1),
            GridPoint(x: 8, y: 9), GridPoint(x: 7, y: 1), GridPoint(x: 9, y: 7), GridPoint(x: 5, y: 11),
            GridPoint(x: 7, y: 2), GridPoint(x: 9, y: 6), GridPoint(x: 6, y: 9), GridPoint(x: 5, y: 1),
            GridPoint(x: 7, y: 7), GridPoint(x: 3, y: 11), GridPoint(x: 6, y: 3), GridPoint(x: 6, y: 7),
            GridPoint(x: 3, y: 1), GridPoint(x: 7, y: 5), GridPoint(x: 3, y: 9), GridPoint(x: 3, y: 2)
        ],
        innerWalls: [
            GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2), GridPoint(x: 4, y: 2), GridPoint(x: 5, y: 2),
            GridPoint(x: 6, y: 2), GridPoint(x: 8, y: 2), GridPoint(x: 4, y: 3), GridPoint(x: 8, y: 3),
            GridPoint(x: 1, y: 4), GridPoint(x: 2, y: 4), GridPoint(x: 3, y: 4), GridPoint(x: 4, y: 4),
            GridPoint(x: 6, y: 4), GridPoint(x: 7, y: 4), GridPoint(x: 8, y: 4), GridPoint(x: 6, y: 5),
            GridPoint(x: 8, y: 5), GridPoint(x: 1, y: 6), GridPoint(x: 2, y: 6), GridPoint(x: 3, y: 6),
            GridPoint(x: 4, y: 6), GridPoint(x: 5, y: 6), GridPoint(x: 6, y: 6), GridPoint(x: 8, y: 6),
            GridPoint(x: 2, y: 7), GridPoint(x: 2, y: 8), GridPoint(x: 4, y: 8), GridPoint(x: 5, y: 8),
            GridPoint(x: 6, y: 8), GridPoint(x: 7, y: 8), GridPoint(x: 8, y: 8), GridPoint(x: 9, y: 8),
            GridPoint(x: 4, y: 9), GridPoint(x: 2, y: 10), GridPoint(x: 3, y: 10), GridPoint(x: 4, y: 10),
            GridPoint(x: 5, y: 10), GridPoint(x: 6, y: 10), GridPoint(x: 7, y: 10), GridPoint(x: 8, y: 10)
        ],
        instrumentalist: GridPoint(x: 7, y: 5),
        instrument: .trumpet
    )
]

// MARK: - Coordinates

private func gridPoint(_ point: GridPoint) -> CGPoint {
    CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}

private func pixel(_ grid: CGPoint) -> CGPoint {
    CGPoint(x: grid.x * tileSize + tileSize / 2, y: grid.y * tileSize + tileSize / 2)
}

private func circle(_ center: CGPoint, radius: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

private func ellipse(center: CGPoint, rx: CGFloat, ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
}

private func bounce(_ value: Double, limit: Double) -> CGFloat {
    guard limit > 0 else { return 0 }
    let period = limit * 2
    let position = value.truncatingRemainder(dividingBy: period)
    return CGFloat(position <= limit ? position : period - position)
}

// MARK: - Music

private final class MusicPlayer {
    private var background: AVAudioPlayer?
    private var victory: AVAudioPlayer?
    private var currentName = ""
    private var muted = false

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    }

    func playLevel(_ name: String) {
        if name == currentName {
            if background?.isPlaying == false {
                background?.play()
            }
            return
        }

        victory?.stop()
        background?.stop()
        currentName = name
        background = makePlayer(named: name)
        background?.play()
    }

    func playVictory() {
        background?.stop()
        currentName = ""
        victory?.stop()
        victory = makePlayer(named: victoryMusicName)
        victory?.play()
    }

    func setMuted(_ isMuted: Bool) {
        muted = isMuted
        let volume: Float = isMuted ? 0 : musicVolume
        background?.volume = volume
        victory?.volume = volume
    }

    private func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let data = NSDataAsset(name: name)?.data,
              let player = try? AVAudioPlayer(data: data) else {
            return nil
        }
        player.numberOfLoops = -1
        player.volume = muted ? 0 : musicVolume
        player.prepareToPlay()
        return player
    }
}

// MARK: - Game state

private final class GameModel: ObservableObject {
    @Published private(set) var levelIndex = 0
    @Published private(set) var ball = levels[0].start
    @Published private(set) var collected = 0
    @Published private(set) var moves = 0
    @Published private(set) var remaining = levels[0].bands
    @Published private(set) var hasWon = false
    @Published private(set) var isMuted = false

    private(set) var from: CGPoint
    private(set) var moveStart: TimeInterval = 0
    private var activeDirection: Direction?
    private var repeatTimer: Timer?
    private let music = MusicPlayer()

    init() {
        from = gridPoint(levels[0].start)
    }

    var level: Level {
        levels[levelIndex]
    }

    private var now: TimeInterval {
        Date().timeIntervalSinceReferenceDate
    }

    func start() {
        music.playLevel(levelMusicNames[levelIndex])
    }

    func startMoving(_ direction: Direction) {
        activeDirection = direction
        guard repeatTimer == nil else { return }

        step(direction)
        repeatTimer = Timer.scheduledTimer(withTimeInterval: moveRepeatInterval, repeats: true) { [weak self] _ in
            guard let self = self, let current = self.activeDirection else { return }
            self.step(current)
        }
    }

    func stopMoving() {
        activeDirection = nil
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    func restartLevel() {
        stopMoving()
        loadLevel()
        music.playLevel(levelMusicNames[levelIndex])
    }

    func playAgain() {
        stopMoving()
        levelIndex = 0
        hasWon = false
        loadLevel()
        music.playLevel(levelMusicNames[levelIndex])
    }

    func toggleMute() {
        isMuted.toggle()
        music.setMuted(isMuted)
    }

    func visualPosition(at time: TimeInterval) -> CGPoint {
        let progress = min(1, max(0, (time - moveStart) / moveTravelDuration))
        let eased = CGFloat(progress * progress * (3 - 2 * progress))
        let target = gridPoint(ball)
        return CGPoint(
            x: from.x + (target.x - from.x) * eased,
            y: from.y + (target.y - from.y) * eased
        )
    }

    private func loadLevel() {
        let start = level.start
        ball = start
        from = gridPoint(start)
        moveStart = now
        collected = 0
        moves = 0
        remaining = level.bands
    }

    private func step(_ direction: Direction) {
        guard !hasWon else { return }

        let current = level
        let next = direction.applied(to: ball)
        guard !current.walls.contains(next) else { return }

        from = visualPosition(at: now)
        ball = next
        moveStart = now
        moves += 1

        if remaining.remove(next) != nil {
            collected += 1
        }

        if remaining.isEmpty && next == current.exit {
            completeLevel()
        }
    }

    private func completeLevel() {
        if levelIndex == levels.count - 1 {
            stopMoving()
            hasWon = true
            music.playVictory()
            return
        }

        levelIndex += 1
        loadLevel()
        music.playLevel(levelMusicNames[levelIndex])
    }
}

// MARK: - Drawing

private func scaled(_ context: GraphicsContext, to size: CGSize) -> GraphicsContext {
    var result = context
    let factor = size.width / logicalWidth
    result.scaleBy(x: factor, y: factor)
    return result
}

private func drawSnow(_ context: inout GraphicsContext, time: TimeInterval) {
    let ms = time * 1000
    for index in 0..<70 {
        let i = Double(index)
        let radius = CGFloat(1.2 + Double(index % 4) * 0.45)
        let speed = 0.02 + Double(index % 5) * 0.008
        let drift = Double(9 + (index % 6) * 4)
        let phase = i * 0.63
        let baseX = (i * 97).truncatingRemainder(dividingBy: 660)
        let baseY = (i * 173).truncatingRemainder(dividingBy: 780)
        let fall = (baseY + ms * speed).truncatingRemainder(dividingBy: 804)
        let sway = sin(ms * 0.0011 + phase) * drift
        let x = (baseX + sway + 660).truncatingRemainder(dividingBy: 660)
        let y = fall - 12
        let opacity = 0.36 + (Double(radius) - 1.2) * 0.12
        context.fill(
            circle(CGPoint(x: x, y: y), radius: radius),
            with: .color(Color.white.opacity(opacity))
        )
    }
}

private func drawWalls(_ context: inout GraphicsContext, level: Level) {
    var links = Path()
    for wall in level.walls {
        let right = GridPoint(x: wall.x + 1, y: wall.y)
        let down = GridPoint(x: wall.x, y: wall.y + 1)
        if level.walls.contains(right) {
            links.move(to: pixel(gridPoint(wall)))
            links.addLine(to: pixel(gridPoint(right)))
        }
        if level.walls.contains(down) {
            links.move(to: pixel(gridPoint(wall)))
            links.addLine(to: pixel(gridPoint(down)))
        }
    }

    context.stroke(
        links,
        with: .color(Color(hex: 0x77e6ef, opacity: 0.22)),
        style: StrokeStyle(lineWidth: wallWidth + 8, lineCap: .round, lineJoin: .round)
    )
    context.stroke(
        links,
        with: .color(Color(hex: 0x14616f)),
        style: StrokeStyle(lineWidth: wallWidth, lineCap: .round, lineJoin: .round)
    )

    var bigNodes = Path()
    var smallNodes = Path()
    let bigRadius = wallWidth * 0.52
    let smallRadius = wallWidth * 0.26
    for wall in level.walls {
        let center = pixel(gridPoint(wall))
        bigNodes.addEllipse(in: CGRect(x: center.x - bigRadius, y: center.y - bigRadius, width: bigRadius * 2, height: bigRadius * 2))
        smallNodes.addEllipse(in: CGRect(x: center.x - smallRadius, y: center.y - smallRadius, width: smallRadius * 2, height: smallRadius * 2))
    }
    context.fill(bigNodes, with: .color(Color(hex: 0x14616f)))
    context.fill(smallNodes, with: .color(Color(hex: 0x77e6ef, opacity: 0.42)))
}

private func drawExit(_ context: inout GraphicsContext, at exit: GridPoint, isOpen: Bool) {
    let c = pixel(gridPoint(exit))
    var flag = Path()
    flag.addRect(CGRect(x: c.x - 8, y: c.y - 18, width: 5, height: 34))
    flag.move(to: CGPoint(x: c.x - 3, y: c.y - 18))
    flag.addLine(to: CGPoint(x: c.x + 20, y: c.y - 11))
    flag.addLine(to: CGPoint(x: c.x - 3, y: c.y - 3))
    flag.closeSubpath()
    let color = isOpen ? Color(hex: 0x51d26b) : Color.white.opacity(0.45)
    context.fill(flag, with: .color(color))
}

private func drawRubberBand(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat, color: Color, time: TimeInterval) {
    var local = context
    local.translateBy(x: center.x, y: center.y)
    local.rotate(by: .radians(time * 1000 / 430))
    local.addFilter(.shadow(color: color, radius: 8))
    local.stroke(
        ellipse(center: .zero, rx: size / 2, ry: size * 0.24),
        with: .color(color),
        lineWidth: max(4, size * 0.16)
    )
}

private func drawInstrumentalist(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat, color: Color, instrument: Instrument, time: TimeInterval) {
    let ms = time * 1000
    let bounce = CGFloat(sin(ms / 120)) * size * 0.08
    var local = context
    local.translateBy(x: center.x, y: center.y + bounce)
    local.rotate(by: .radians(sin(ms / 180) * 0.12))

    var glow = local
    glow.addFilter(.shadow(color: color, radius: 8))
    glow.stroke(
        ellipse(center: .zero, rx: size * 0.25, ry: size * 0.43),
        with: .color(color),
        lineWidth: max(3, size * 0.11)
    )

    drawInstrument(&local, instrument, size: size)
}

private func drawInstrument(_ context: inout GraphicsContext, _ instrument: Instrument, size s: CGFloat) {
    switch instrument {
    case .violin:
        let frame = CGRect(x: -s * 0.14, y: s * 0.02 - s * 0.2, width: s * 0.28, height: s * 0.4)
        context.fill(Path(ellipseIn: frame), with: .color(Color(hex: 0xad6428)))
        context.stroke(Path(ellipseIn: frame), with: .color(Color(hex: 0xe2a14a)), lineWidth: max(2, s * 0.05))
        var neck = Path()
        neck.move(to: CGPoint(x: s * 0.16, y: -s * 0.28))
        neck.addLine(to: CGPoint(x: s * 0.34, y: s * 0.3))
        context.stroke(neck, with: .color(Color(hex: 0xf7e8ba)), lineWidth: max(2, s * 0.04))

    case .drums:
        let shell = CGRect(x: -s * 0.22, y: s * 0.06, width: s * 0.44, height: s * 0.22)
        context.fill(Path(shell), with: .color(Color(hex: 0xd64b45)))
        context.stroke(Path(shell), with: .color(Color(hex: 0xf7f0d0)), lineWidth: max(2, s * 0.05))
        var sticks = Path()
        sticks.move(to: CGPoint(x: -s * 0.18, y: -s * 0.28))
        sticks.addLine(to: CGPoint(x: -s * 0.04, y: s * 0.04))
        sticks.move(to: CGPoint(x: s * 0.18, y: -s * 0.28))
        sticks.addLine(to: CGPoint(x: s * 0.04, y: s * 0.04))
        context.stroke(sticks, with: .color(Color(hex: 0xf7e8ba)), lineWidth: max(2, s * 0.04))

    case .clarinet:
        var barrel = Path()
        barrel.move(to: CGPoint(x: -s * 0.08, y: -s * 0.3))
        barrel.addLine(to: CGPoint(x: s * 0.08, y: s * 0.32))
        context.stroke(barrel, with: .color(Color(hex: 0xd7efff)), lineWidth: max(2, s * 0.08))
        var bell = context
        bell.translateBy(x: s * 0.1, y: s * 0.36)
        bell.rotate(by: .radians(0.25))
        bell.fill(
            Path(ellipseIn: CGRect(x: -s * 0.13, y: -s * 0.08, width: s * 0.26, height: s * 0.16)),
            with: .color(Color(hex: 0x222222))
        )

    case .trumpet:
        let valve = CGRect(x: -s * 0.28, y: -s * 0.04, width: s * 0.42, height: s * 0.12)
        context.fill(Path(valve), with: .color(Color(hex: 0xf6c94f)))
        context.stroke(Path(valve), with: .color(Color(hex: 0xf7d86e)), lineWidth: max(2, s * 0.04))
        var bell = Path()
        bell.move(to: CGPoint(x: s * 0.1, y: -s * 0.14))
        bell.addLine(to: CGPoint(x: s * 0.36, y: -s * 0.25))
        bell.addLine(to: CGPoint(x: s * 0.36, y: s * 0.25))
        bell.addLine(to: CGPoint(x: s * 0.1, y: s * 0.14))
        bell.closeSubpath()
        context.fill(bell, with: .color(Color(hex: 0xf6c94f)))
        context.stroke(bell, with: .color(Color(hex: 0xf7d86e)), lineWidth: max(2, s * 0.04))
    }
}

private func drawBall(_ context: inout GraphicsContext, center c: CGPoint, radius r: CGFloat, collected: Int) {
    var glow = context
    glow.addFilter(.shadow(color: Color(hex: 0xf59e22, opacity: 0.5), radius: 16))
    let gradient = Gradient(stops: [
        Gradient.Stop(color: Color(hex: 0xfff06a), location: 0),
        Gradient.Stop(color: Color(hex: 0xf49a24), location: 0.55),
        Gradient.Stop(color: Color(hex: 0xd7332b), location: 1)
    ])
    glow.fill(
        circle(c, radius: r),
        with: .radialGradient(
            gradient,
            center: CGPoint(x: c.x - 12, y: c.y - 12),
            startRadius: 4,
            endRadius: r
        )
    )

    let bandCount = max(3, collected + 3)
    for index in 0..<bandCount {
        var band = context
        band.translateBy(x: c.x, y: c.y)
        band.rotate(by: .radians(Double(index) * 31 * Double.pi / 180))
        band.stroke(
            ellipse(center: .zero, rx: r * 0.82, ry: r * 0.36),
            with: .color(rubberBandColors[index % rubberBandColors.count]),
            lineWidth: max(3, r * 0.16)
        )
    }
}

private func drawMaze(
    _ context: inout GraphicsContext,
    level: Level,
    remaining: Set<GridPoint>,
    ballPosition: CGPoint,
    collected: Int,
    bandColor: Color,
    time: TimeInterval
) {
    drawWalls(&context, level: level)
    drawExit(&context, at: level.exit, isOpen: remaining.isEmpty)

    for band in level.bands where remaining.contains(band) {
        if band == level.instrumentalist {
            drawInstrumentalist(
                &context,
                center: pixel(gridPoint(band)),
                size: tileSize * 0.72,
                color: bandColor,
                instrument: level.instrument,
                time: time
            )
        } else {
            drawRubberBand(
                &context,
                center: pixel(gridPoint(band)),
                size: tileSize * 0.58,
                color: bandColor,
                time: time
            )
        }
    }

    drawBall(
        &context,
        center: pixel(ballPosition),
        radius: tileSize * (0.3 + CGFloat(collected) * 0.009),
        collected: collected
    )
}

private func drawDancers(_ context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
    let instruments: [Instrument] = [.violin, .drums, .clarinet, .trumpet]
    for (index, instrument) in instruments.enumerated() {
        let x = size.width * (CGFloat(index) + 0.5) / 4
        let y = size.height * 0.62
        drawInstrumentalist(
            &context,
            center: CGPoint(x: x, y: y),
            size: 56,
            color: rubberBandColors[index],
            instrument: instrument,
            time: time
        )
    }
}

// MARK: - Views

struct GameView: View {
    @StateObject private var model = GameModel()

    var body: some View {
        ZStack {
            Color(hex: 0x03090c).ignoresSafeArea()

            if model.hasWon {
                VictoryView(playAgain: { model.playAgain() })
            } else {
                gameplay
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stopMoving() }
    }

    private var gameplay: some View {
        VStack(spacing: 14) {
            header
            MazeView(model: model)
                .padding(.horizontal, 12)
            statusRow
            DPadView(model: model)
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }

    private var header: some View {
        HStack {
            Text("Rubber Band Ball")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Text("Level \(model.level.number)/\(levels.count)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            Button(model.isMuted ? "Unmute" : "Mute") {
                model.toggleMute()
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(.horizontal, 18)
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            Text("\(model.collected) collected")
            Text("\(model.remaining.count) left")
            Text("\(model.moves) moves")
            Button("Restart") {
                model.restartLevel()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0xf24f38))
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 16)
    }
}

private struct MazeView: View {
    let model: GameModel
    @State private var swipeAnchor: CGPoint?

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let level = model.level
            let ballPosition = model.visualPosition(at: time)

            ZStack {
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()

                Color(hex: 0x03090c, opacity: 0.18)

                Canvas { context, size in
                    var scaledContext = scaled(context, to: size)
                    drawSnow(&scaledContext, time: time)
                }

                Canvas { context, size in
                    var scaledContext = scaled(context, to: size)
                    drawMaze(
                        &scaledContext,
                        level: level,
                        remaining: model.remaining,
                        ballPosition: ballPosition,
                        collected: model.collected,
                        bandColor: rubberBandColors[model.levelIndex % 4],
                        time: time
                    )
                }
            }
            .aspectRatio(logicalWidth / logicalHeight, contentMode: .fit)
            .clipped()
            .contentShape(Rectangle())
            .gesture(swipeGesture)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let anchor = swipeAnchor ?? value.location
                swipeAnchor = anchor

                let dx = value.location.x - anchor.x
                let dy = value.location.y - anchor.y
                guard max(abs(dx), abs(dy)) >= swipeTurnThreshold else { return }

                let direction: Direction
                if abs(dx) > abs(dy) {
                    direction = dx < 0 ? .left : .right
                } else {
                    direction = dy < 0 ? .up : .down
                }

                swipeAnchor = value.location
                model.startMoving(direction)
            }
            .onEnded { _ in
                swipeAnchor = nil
                model.stopMoving()
            }
    }
}

private struct DPadView: View {
    let model: GameModel

    var body: some View {
        VStack(spacing: 8) {
            DPadButton(symbol: "chevron.up", label: "Move up", direction: .up, model: model)
            HStack(spacing: 8) {
                DPadButton(symbol: "chevron.left", label: "Move left", direction: .left, model: model)
                Color.clear.frame(width: 64, height: 64)
                DPadButton(symbol: "chevron.right", label: "Move right", direction: .right, model: model)
            }
            DPadButton(symbol: "chevron.down", label: "Move down", direction: .down, model: model)
        }
    }
}

private struct DPadButton: View {
    let symbol: String
    let label: String
    let direction: Direction
    let model: GameModel
    @State private var isPressed = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(Circle().fill(Color.white.opacity(isPressed ? 0.28 : 0.12)))
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        model.startMoving(direction)
                    }
                    .onEnded { _ in
                        isPressed = false
                        model.stopMoving()
                    }
            )
            .accessibilityLabel(label)
    }
}

private struct VictoryView: View {
    let playAgain: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Welcome to")
                .font(.system(.title3, design: .rounded, weight: .semibold))

            Text("The Rubber Band Ball!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)

            VictoryStage()
                .frame(height: 260)

            Text("You win!\nEnjoy the Ball!")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                Text("Painting: Nicholas in the Snow by Bo Elder")
                Text("Music: St. Nick's Theme by Eric Elder")
                Text("Orchestration: by Matt Ludwig")
                Text("Produced: by Eric Elder")
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.75))

            Button(action: playAgain) {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0xf24f38))
        }
        .foregroundStyle(.white)
        .padding(24)
    }
}

private struct VictoryStage: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geometry in
                let ballBox: CGFloat = 48
                let maxX = Double(max(0, geometry.size.width - ballBox - 16))
                let maxY = Double(max(0, geometry.size.height * 0.55))
                let x = bounce(time * 130, limit: maxX) + 8
                let y = bounce(time * 95 + 40, limit: maxY) + 8

                ZStack {
                    Canvas { context, _ in
                        var ballContext = context
                        drawBall(&ballContext, center: CGPoint(x: 24, y: 24), radius: 22, collected: 0)
                    }
                    .frame(width: ballBox, height: ballBox)
                    .position(x: x + ballBox / 2, y: y + ballBox / 2)

                    Canvas { context, size in
                        var danceContext = context
                        drawDancers(&danceContext, size: size, time: time)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
