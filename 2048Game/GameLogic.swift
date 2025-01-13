import Foundation
import SwiftUI

class GameManager: ObservableObject {
    @Published var grid: [[Tile?]]
    @Published var moves: Int = 0
    @Published var gameOver: Bool = false
    @Published var tileAnimations: [UUID: TileAnimation] = [:] // Track animations

    init() {
        self.grid = Array(repeating: Array(repeating: nil, count: 4), count: 4)
        addRandomTile()
        addRandomTile()
    }

    func restart() {
        grid = Array(repeating: Array(repeating: nil, count: 4), count: 4)
        moves = 0
        gameOver = false
        addRandomTile()
        addRandomTile()
        tileAnimations.removeAll() 
    }



    func detectSwipeDirection(_ translation: CGSize) -> SwipeDirection {
        if abs(translation.width) > abs(translation.height) {
            return translation.width > 0 ? .right : .left
        } else {
            return translation.height > 0 ? .down : .up
        }
    }

    func swipeLeft() {
        var moved = false
        for row in 0..<4 {
            var newRow: [Tile?] = grid[row].compactMap { $0 }
            let previousRow = newRow
            merge(&newRow, row: row, colStart: 0, colEnd: 4, isRow: true)

            if newRow != previousRow {
                moved = true
            }

            grid[row] = newRow
        }

        if moved {makeMove()}
    }

    func swipeRight() {
        var moved = false
        for row in 0..<4 {
            var newRow: [Tile?] = grid[row].compactMap { $0 }
            newRow.reverse()
            let previousRow = newRow
            merge(&newRow, row: row, colStart: 0, colEnd: 4, isRow: true)

            newRow.reverse()

            while newRow.count < 4 {
                newRow.insert(nil, at: 0)
            }

            if newRow != previousRow {
                moved = true
            }

            grid[row] = newRow
        }

        if moved {makeMove()}    }

    func swipeUp() {
        var moved = false
        for col in 0..<4 {
            var newCol = [Tile?]()
            for row in 0..<4 {
                if let tile = grid[row][col] {
                    newCol.append(tile)
                }
            }
            let previousCol = newCol
            merge(&newCol, row: 0, colStart: col, colEnd: 4, isRow: false)

            while newCol.count < 4 {
                newCol.append(nil)
            }

            if newCol != previousCol {
                moved = true
            }

            for row in 0..<4 {
                grid[row][col] = row < newCol.count ? newCol[row] : nil
            }
        }

        if moved {makeMove()}
    }

    func swipeDown() {
        var moved = false
        for col in 0..<4 {
            var newCol = [Tile?]()
            for row in (0..<4).reversed() {
                if let tile = grid[row][col] {
                    newCol.append(tile)
                }
            }
            let previousCol = newCol
            merge(&newCol, row: 3, colStart: col, colEnd: 0, isRow: false)

            while newCol.count < 4 {
                newCol.insert(nil, at: 0)
            }

            if newCol != previousCol {
                moved = true
            }

            for row in 0..<4 {
                grid[row][col] = row < newCol.count ? newCol[row] : nil
            }
        }

        if moved {makeMove()}
    }

    func canMove() -> Bool {
        for row in 0..<4 {
            for col in 0..<4 {
                if grid[row][col] == nil {
                    return true
                }
                if col < 3, let currentTile = grid[row][col], let nextTile = grid[row][col + 1], currentTile.value == nextTile.value {
                    return true
                }
                if row < 3, let currentTile = grid[row][col], let nextTile = grid[row + 1][col], currentTile.value == nextTile.value {
                    return true
                }
            }
        }
        return false
    }

    func merge(_ line: inout [Tile?], row: Int? = nil, colStart: Int? = nil, colEnd: Int? = nil, isRow: Bool = true) {
        var newLine = [Tile?]()
        for tile in line {
            if let tile = tile {
                newLine.append(tile)
            }
        }

        var i = 0
        while i < newLine.count - 1 {
            if newLine[i]?.value == newLine[i + 1]?.value {
                let mergedTile = Tile(value: newLine[i]!.value * 2)
                newLine[i] = mergedTile
                newLine[i + 1] = nil

                // Track the animation for merging
                if let row = row, let colStart = colStart, let colEnd = colEnd {
                    let animationId = UUID()
                    tileAnimations[animationId] = TileAnimation(
                        start: positionForTile(row: row, col: colStart),
                        end: positionForTile(row: row, col: colEnd),
                        tile: mergedTile
                    )
                }

                i += 1
            }
            i += 1
        }

        line = newLine.filter { $0 != nil }.compactMap { $0 }

        while line.count < 4 {
            line.append(nil)
        }
    }

    func positionForTile(row: Int, col: Int) -> CGPoint {
        let tileSize: CGFloat = 70
        let spacing: CGFloat = 5
        let x = CGFloat(col) * (tileSize + spacing) + tileSize / 2
        let y = CGFloat(row) * (tileSize + spacing) + tileSize / 2
        return CGPoint(x: x, y: y)
    }

    func addRandomTile() {
        var emptyTiles = [(Int, Int)]()
        for row in 0..<4 {
            for col in 0..<4 {
                if grid[row][col] == nil {
                    emptyTiles.append((row, col))
                }
            }
        }

        if let randomTile = emptyTiles.randomElement() {
            let (row, col) = randomTile
            let value = Int.random(in: 1...10) == 1 ? 4 : 2
            grid[row][col] = Tile(value: value)
        }
    }
    
    func processSwipe(_ translation: CGSize) {
        let direction = detectSwipeDirection(translation)

        switch direction {
        case .up: swipeUp()
        case .down: swipeDown()
        case .left: swipeLeft()
        case .right: swipeRight()
        case .none: return
        }

        if canMove() {
            moves += 1
        } else {
            gameOver = true
        }
    }
    
    func makeMove() {
        playMoveSound()
        withAnimation(.easeInOut(duration: 0.3)) {
            addRandomTile()
        }
    }
}

struct TileAnimation {
    let start: CGPoint
    let end: CGPoint
    let tile: Tile
}

class Tile: Identifiable, Equatable {
    var id = UUID()
    var value: Int

    init(value: Int) {
        self.value = value
    }

    static func ==(lhs: Tile, rhs: Tile) -> Bool {
        lhs.value == rhs.value
    }
}


enum SwipeDirection {
    case up, down, left, right, none
}
