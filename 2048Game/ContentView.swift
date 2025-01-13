import SwiftUI

import SwiftUI

struct ContentView: View {
    @StateObject private var gameManager = GameManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("2048")
                .font(.largeTitle)
                .bold()

            Text("If you get 2048 - you win! Merge tiles to get bigger numbers!")
                .font(.subheadline)
                .multilineTextAlignment(.center)

            Text("Moves: \(gameManager.moves)")
                .font(.headline)

            GameBoardView(gameManager: gameManager)
                .gesture(DragGesture()
                            .onEnded { value in
                                gameManager.processSwipe(value.translation)
                            })
                .padding()

            Button("Restart") {
                gameManager.restart()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .alert(isPresented: $gameManager.gameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text("Try Again?"),
                primaryButton: .default(Text("Restart")) {
                    gameManager.restart()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct GameBoardView: View {
    @ObservedObject var gameManager: GameManager

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { row in
                ForEach(0..<4, id: \.self) { col in
                    if let tile = gameManager.grid[row][col] {
                        TileView(value: tile.value, position: positionForTile(row: row, col: col))
                            .animation(.easeInOut(duration: 0.3), value: tile.id) // Adding animation to tile movement
                    }
                }
            }
        }
        .frame(width: 300, height: 300)
        .background(Color.gray)
        .cornerRadius(10)
    }

    func positionForTile(row: Int, col: Int) -> CGPoint {
        let tileSize: CGFloat = 70
        let spacing: CGFloat = 5
        let x = CGFloat(col) * (tileSize + spacing) + tileSize / 2
        let y = CGFloat(row) * (tileSize + spacing) + tileSize / 2
        return CGPoint(x: x, y: y)
    }
}

struct TileView: View {
    let value: Int?
    let position: CGPoint

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(value == nil ? Color.white : colorForValue(value!))
                .frame(width: 70, height: 70)

            if let value = value {
                Text("\(value)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .position(position) // Position changes with animation
    }

    func colorForValue(_ value: Int) -> Color {
        switch value {
        case 2: return .green
        case 4: return .blue
        case 8: return .purple
        case 16: return .pink
        case 32: return .yellow
        case 64: return .orange
        case 128: return .red
        case 256: return .brown
        case 512: return .cyan
        case 1024: return .indigo
        case 2048: return .white
        default: return .gray
        }
    }
}
