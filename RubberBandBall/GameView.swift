import SwiftUI

private struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

private enum Direction: Equatable {
    case up
    case down
    case left
    case right
}

private struct Level {
    let number: Int
    let width: Int = 11
    let height: Int = 13
    let start: GridPoint
    let exit: GridPoint
    let bands: Set<GridPoint>
    let walls: Set<GridPoint>
}

private struct GameState {
    var levelIndex = 0
    var ballPosition: GridPoint
    var collectedBands = 0
    var moveCount = 0
    var remainingBands: Set<GridPoint>
    var hasWon = false

    init(levels: [Level]) {
        let firstLevel = levels[0]
        ballPosition = firstLevel.start
        remainingBands = firstLevel.bands
    }
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
        ]
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
        ]
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
        ]
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
        ]
    )
]

private func makeLevel(
    _ number: Int,
    start: GridPoint,
    exit: GridPoint,
    bands: Set<GridPoint>,
    innerWalls: Set<GridPoint>
) -> Level {
    var walls = innerWalls

    for x in 0..<11 {
        walls.insert(GridPoint(x: x, y: 0))
        walls.insert(GridPoint(x: x, y: 12))
    }

    for y in 0..<13 {
        walls.insert(GridPoint(x: 0, y: y))
        walls.insert(GridPoint(x: 10, y: y))
    }

    walls.remove(start)
    walls.remove(exit)
    bands.forEach { walls.remove($0) }

    return Level(
        number: number,
        start: start,
        exit: exit,
        bands: bands,
        walls: walls
    )
}

struct GameView: View {
    @State private var game = GameState(levels: levels)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.08, blue: 0.12), Color(red: 0.08, green: 0.16, blue: 0.17)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if game.hasWon {
                VictoryView {
                    game = GameState(levels: levels)
                }
            } else {
                VStack(spacing: 18) {
                    header
                    MazeView(level: currentLevel, game: game)
                        .aspectRatio(CGFloat(currentLevel.width) / CGFloat(currentLevel.height), contentMode: .fit)
                        .padding(.horizontal, 18)
                    status
                    levelActions
                    JoystickControl { direction in
                        move(direction)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.top, 18)
            }
        }
    }

    private var currentLevel: Level {
        levels[game.levelIndex]
    }

    private var header: some View {
        HStack {
            Text("Rubber Band Ball")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Text("Level \(currentLevel.number)/\(levels.count)")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 22)
    }

    private var status: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                Label("\(game.collectedBands)", systemImage: "circle.hexagongrid.circle")
                Label("\(game.remainingBands.count) left", systemImage: "target")
                Label("\(game.moveCount) moves", systemImage: "shoeprints.fill")
            }

            if game.remainingBands.isEmpty {
                Label("Find exit", systemImage: "flag.checkered")
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.1), in: Capsule())
    }

    private var levelActions: some View {
        Button {
            resetCurrentLevel()
        } label: {
            Label("Restart Level", systemImage: "arrow.counterclockwise")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(red: 0.93, green: 0.31, blue: 0.22).opacity(0.88), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Returns the ball to the start of this level.")
    }

    private func move(_ direction: Direction) {
        let nextPoint: GridPoint

        switch direction {
        case .up:
            nextPoint = GridPoint(x: game.ballPosition.x, y: game.ballPosition.y - 1)
        case .down:
            nextPoint = GridPoint(x: game.ballPosition.x, y: game.ballPosition.y + 1)
        case .left:
            nextPoint = GridPoint(x: game.ballPosition.x - 1, y: game.ballPosition.y)
        case .right:
            nextPoint = GridPoint(x: game.ballPosition.x + 1, y: game.ballPosition.y)
        }

        guard !currentLevel.walls.contains(nextPoint) else {
            return
        }

        withAnimation(.linear(duration: 0.15)) {
            game.ballPosition = nextPoint
            game.moveCount += 1

            if game.remainingBands.remove(nextPoint) != nil {
                game.collectedBands += 1
            }
        }

        if game.remainingBands.isEmpty && nextPoint == currentLevel.exit {
            completeLevel()
        }
    }

    private func completeLevel() {
        if game.levelIndex == levels.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                game.hasWon = true
            }
            return
        }

        let nextIndex = game.levelIndex + 1
        let nextLevel = levels[nextIndex]

        withAnimation(.easeInOut(duration: 0.25)) {
            game.levelIndex = nextIndex
            game.ballPosition = nextLevel.start
            game.collectedBands = 0
            game.moveCount = 0
            game.remainingBands = nextLevel.bands
        }
    }

    private func resetCurrentLevel() {
        let level = currentLevel

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            game.ballPosition = level.start
            game.collectedBands = 0
            game.moveCount = 0
            game.remainingBands = level.bands
        }
    }
}

private struct MazeView: View {
    let level: Level
    let game: GameState

    var body: some View {
        GeometryReader { geometry in
            let tileSize = min(
                geometry.size.width / CGFloat(level.width),
                geometry.size.height / CGFloat(level.height)
            )
            let gridSize = CGSize(
                width: tileSize * CGFloat(level.width),
                height: tileSize * CGFloat(level.height)
            )
            let origin = CGPoint(
                x: (geometry.size.width - gridSize.width) / 2,
                y: (geometry.size.height - gridSize.height) / 2
            )

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.02, green: 0.04, blue: 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.18), lineWidth: 2)
                    )

                ForEach(0..<level.height, id: \.self) { y in
                    ForEach(0..<level.width, id: \.self) { x in
                        let point = GridPoint(x: x, y: y)

                        TileView(
                            point: point,
                            level: level,
                            game: game,
                            tileSize: tileSize,
                            bandColor: rubberBandColors[game.levelIndex % 4]
                        )
                        .frame(width: tileSize, height: tileSize)
                        .position(
                            x: origin.x + CGFloat(x) * tileSize + tileSize / 2,
                            y: origin.y + CGFloat(y) * tileSize + tileSize / 2
                        )
                    }
                }

                BallView(collectedBands: game.collectedBands, size: tileSize * 0.82)
                    .position(
                        x: origin.x + CGFloat(game.ballPosition.x) * tileSize + tileSize / 2,
                        y: origin.y + CGFloat(game.ballPosition.y) * tileSize + tileSize / 2
                    )
            }
            .frame(width: gridSize.width, height: gridSize.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

private struct TileView: View {
    let point: GridPoint
    let level: Level
    let game: GameState
    let tileSize: CGFloat
    let bandColor: Color

    var body: some View {
        ZStack {
            if level.walls.contains(point) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.08, green: 0.38, blue: 0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(red: 0.31, green: 0.78, blue: 0.84).opacity(0.45), lineWidth: 1)
                    )
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.035))
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                    )
            }

            if point == level.exit {
                Image(systemName: "flag.checkered")
                    .font(.system(size: tileSize * 0.46, weight: .bold))
                    .foregroundStyle(game.remainingBands.isEmpty ? .green : .white.opacity(0.45))
            }

            if game.remainingBands.contains(point) {
                RubberBandView(size: tileSize * 0.58, color: bandColor)
            }
        }
    }
}

private struct BallView: View {
    let collectedBands: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.yellow.opacity(0.95), Color.orange, Color.red.opacity(0.85)],
                        center: .topLeading,
                        startRadius: 3,
                        endRadius: size
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 8, y: 3)

            ForEach(0..<max(3, collectedBands + 3), id: \.self) { index in
                Capsule()
                    .stroke(rubberBandColors[index % rubberBandColors.count], lineWidth: max(2, size * 0.07))
                    .frame(width: size * 0.86, height: size * 0.38)
                    .rotationEffect(.degrees(Double(index) * 31))
            }
        }
        .frame(
            width: size + CGFloat(collectedBands) * 0.7,
            height: size + CGFloat(collectedBands) * 0.7
        )
    }
}

private struct RubberBandView: View {
    let size: CGFloat
    let color: Color
    @State private var isSpinning = false

    var body: some View {
        Capsule()
            .stroke(color, lineWidth: max(3, size * 0.16))
            .frame(width: size, height: size * 0.48)
            .rotationEffect(.degrees(isSpinning ? 336 : -24))
            .shadow(color: color.opacity(0.45), radius: 4)
            .onAppear {
                withAnimation(.linear(duration: 1.9).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
    }
}

private struct JoystickControl: View {
    let onMove: (Direction) -> Void
    @State private var knobOffset: CGSize = .zero
    @State private var activeDirection: Direction?

    private let controlSize: CGFloat = 166
    private let knobSize: CGFloat = 72
    private let maxOffset: CGFloat = 46
    private let deadZone: CGFloat = 14
    private let repeatTimer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.1))
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 2))

            VStack {
                Image(systemName: "chevron.up")
                Spacer()
                Image(systemName: "chevron.down")
            }
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.vertical, 16)

            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.horizontal, 16)

            Circle()
                .fill(Color(red: 0.17, green: 0.55, blue: 0.62))
                .overlay(Circle().stroke(.white.opacity(0.28), lineWidth: 2))
                .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
                .frame(width: knobSize, height: knobSize)
                .offset(knobOffset)
        }
        .frame(width: controlSize, height: controlSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateJoystick(translation: value.translation)
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                        knobOffset = .zero
                        activeDirection = nil
                    }
                }
        )
        .onReceive(repeatTimer) { _ in
            if let activeDirection {
                onMove(activeDirection)
            }
        }
        .accessibilityLabel("Movement joystick")
        .accessibilityHint("Drag and hold up, down, left, or right to keep the ball moving.")
    }

    private func updateJoystick(translation: CGSize) {
        let clamped = clampedOffset(for: translation)
        let nextDirection = direction(for: clamped)

        knobOffset = clamped

        if nextDirection != activeDirection {
            activeDirection = nextDirection

            if let nextDirection {
                onMove(nextDirection)
            }
        }
    }

    private func clampedOffset(for translation: CGSize) -> CGSize {
        let distance = hypot(translation.width, translation.height)

        guard distance > maxOffset else {
            return translation
        }

        let scale = maxOffset / distance
        return CGSize(width: translation.width * scale, height: translation.height * scale)
    }

    private func direction(for offset: CGSize) -> Direction? {
        guard max(abs(offset.width), abs(offset.height)) >= deadZone else {
            return nil
        }

        if abs(offset.width) > abs(offset.height) {
            return offset.width < 0 ? .left : .right
        }

        return offset.height < 0 ? .up : .down
    }
}

private struct VictoryView: View {
    let restart: () -> Void
    @State private var isDancing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("The Rubber Band Ball")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    DancingBand(index: index, isDancing: isDancing)
                }
            }
            .frame(height: 260)

            Text("You won! Have a ball!")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button(action: restart) {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .background(Color(red: 0.93, green: 0.31, blue: 0.22), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(24)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                isDancing = true
            }
        }
    }
}

private struct DancingBand: View {
    let index: Int
    let isDancing: Bool

    var body: some View {
        Capsule()
            .stroke(rubberBandColors[index % rubberBandColors.count], lineWidth: 7)
            .frame(width: 82, height: 38)
            .rotationEffect(.degrees(Double(index) * 28 + (isDancing ? 18 : -18)))
            .offset(
                x: cos(Double(index) * .pi / 6) * 92,
                y: sin(Double(index) * .pi / 6) * 76 + (isDancing ? -16 : 16)
            )
            .scaleEffect(isDancing ? 1.14 : 0.9)
            .shadow(color: rubberBandColors[index % rubberBandColors.count].opacity(0.55), radius: 10)
    }
}

private let rubberBandColors: [Color] = [
    Color(red: 0.98, green: 0.78, blue: 0.22),
    Color(red: 0.95, green: 0.28, blue: 0.25),
    Color(red: 0.25, green: 0.73, blue: 0.95),
    Color(red: 0.36, green: 0.78, blue: 0.42),
    Color(red: 0.85, green: 0.43, blue: 0.95)
]
