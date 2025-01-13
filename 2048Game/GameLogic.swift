// Updated GameManager class with fixes for swipe functionality
import Foundation
import SwiftUI

class GameManager: ObservableObject {
    @Published var grid: [[Tile?]]
    @Published var moves: Int = 0
    @Published var gameOver: Bool = false

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
            let (newRow, hasMoved) = compactAndMerge(line: grid[row])
            grid[row] = newRow
            moved = moved || hasMoved
        }
        if moved { makeMove() }
    }

    func swipeRight() {
        var moved = false
        for row in 0..<4 {
            let reversedRow = grid[row].reversed()
            let (newRow, hasMoved) = compactAndMerge(line: Array(reversedRow))
            grid[row] = Array(newRow.reversed())
            moved = moved || hasMoved
        }
        if moved { makeMove() }
    }

    func swipeUp() {
        var moved = false
        for col in 0..<4 {
            let column = (0..<4).map { grid[$0][col] }
            let (newCol, hasMoved) = compactAndMerge(line: column)
            for row in 0..<4 {
                grid[row][col] = newCol[row]
            }
            moved = moved || hasMoved
        }
        if moved { makeMove() }
    }

    func swipeDown() {
        var moved = false
        for col in 0..<4 {
            let column = (0..<4).map { grid[$0][col] }.reversed()
            let (newCol, hasMoved) = compactAndMerge(line: Array(column))
            let finalCol = Array(newCol.reversed())
            for row in 0..<4 {
                grid[row][col] = finalCol[row]
            }
            moved = moved || hasMoved
        }
        if moved { makeMove() }
    }

    func compactAndMerge(line: [Tile?]) -> ([Tile?], Bool) {
        var compacted = line.compactMap { $0 }
        var merged = [Tile?]()
        var moved = false

        var i = 0
        while i < compacted.count {
            if i < compacted.count - 1, compacted[i].value == compacted[i + 1].value {
                let mergedTile = Tile(value: compacted[i].value * 2)
                merged.append(mergedTile)
                i += 2
                moved = true
            } else {
                merged.append(compacted[i])
                i += 1
            }
        }

        while merged.count < 4 {
            merged.append(nil)
        }

        if merged != line { moved = true }
        return (merged, moved)
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

        if !canMove() {
            gameOver = true
        }
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

    func makeMove() {
        playMoveSound()
        withAnimation(.easeInOut(duration: 0.3)) {
            addRandomTile()
        }
        moves += 1
    }
}

class Tile: Identifiable, Equatable {
    var id = UUID()
    var value: Int

    init(value: Int) {
        self.value = value
    }

    static func == (lhs: Tile, rhs: Tile) -> Bool {
        lhs.value == rhs.value
    }
}

enum SwipeDirection {
    case up, down, left, right, none
}
