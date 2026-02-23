import UIKit

/// Generates a share card UIImage for daily challenge results.
struct ShareCardRenderer {

    /// Renders a share card image for the given daily result.
    /// - Parameters:
    ///   - result: The daily challenge result
    ///   - challengeNumber: The daily challenge number (days since epoch)
    /// - Returns: A rendered UIImage of the share card
    static func render(result: DailyResult, challengeNumber: Int) -> UIImage {
        let width: CGFloat = 400
        let height: CGFloat = 320
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        return renderer.image { context in
            let ctx = context.cgContext

            // Dark background with rounded corners
            let bgColor = UIColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1.0)
            let bgRect = CGRect(x: 0, y: 0, width: width, height: height)
            let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 24)
            bgColor.setFill()
            bgPath.fill()

            // Subtle border
            UIColor.white.withAlphaComponent(0.12).setStroke()
            bgPath.lineWidth = 1
            bgPath.stroke()

            // Title: "Flood It Daily #N"
            let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold).rounded()
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            let title = "Flood It Daily #\(challengeNumber)"
            let titleSize = title.size(withAttributes: titleAttrs)
            title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: 28), withAttributes: titleAttrs)

            // Moves: "X / Y moves"
            let movesFont = UIFont.systemFont(ofSize: 40, weight: .bold).rounded()
            let movesSmallFont = UIFont.systemFont(ofSize: 18, weight: .medium).rounded()

            let bigText = "\(result.movesUsed)"
            let bigAttrs: [NSAttributedString.Key: Any] = [
                .font: movesFont,
                .foregroundColor: UIColor.white
            ]
            let bigSize = bigText.size(withAttributes: bigAttrs)

            let smallText = " / \(result.moveBudget) moves"
            let smallAttrs: [NSAttributedString.Key: Any] = [
                .font: movesSmallFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            let smallSize = smallText.size(withAttributes: smallAttrs)

            let totalMovesWidth = bigSize.width + smallSize.width
            let movesX = (width - totalMovesWidth) / 2
            let movesY: CGFloat = 80
            bigText.draw(at: CGPoint(x: movesX, y: movesY), withAttributes: bigAttrs)
            smallText.draw(at: CGPoint(x: movesX + bigSize.width, y: movesY + bigSize.height - smallSize.height - 4), withAttributes: smallAttrs)

            // Stars: ★★★
            let starY: CGFloat = 148
            let starSize: CGFloat = 28
            let starSpacing: CGFloat = 8
            let totalStarWidth = starSize * 3 + starSpacing * 2
            var starX = (width - totalStarWidth) / 2

            for i in 0..<3 {
                let filled = i < result.starsEarned
                let starColor = filled ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) : UIColor.white.withAlphaComponent(0.3)
                drawStar(in: ctx, center: CGPoint(x: starX + starSize / 2, y: starY + starSize / 2), size: starSize, color: starColor)
                starX += starSize + starSpacing
            }

            // Mini-grid: 5 colored squares showing first 5 colors used
            let gridY: CGFloat = 208
            let cellSize: CGFloat = 36
            let cellSpacing: CGFloat = 8
            let colorCount = min(result.colorsUsed.count, 5)
            let totalGridWidth = CGFloat(colorCount) * cellSize + CGFloat(max(0, colorCount - 1)) * cellSpacing
            var cellX = (width - totalGridWidth) / 2

            for i in 0..<colorCount {
                let rawValue = result.colorsUsed[i]
                let gameColor = GameColor(rawValue: rawValue) ?? .coral
                let rect = CGRect(x: cellX, y: gridY, width: cellSize, height: cellSize)
                let cellPath = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                gameColor.uiLightColor.setFill()
                cellPath.fill()
                // Darker bottom half for depth
                ctx.saveGState()
                cellPath.addClip()
                let bottomRect = CGRect(x: cellX, y: gridY + cellSize / 2, width: cellSize, height: cellSize / 2)
                gameColor.uiDarkColor.setFill()
                ctx.fill(bottomRect)
                ctx.restoreGState()

                cellX += cellSize + cellSpacing
            }

            // App name footer
            let footerFont = UIFont.systemFont(ofSize: 12, weight: .medium).rounded()
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.35)
            ]
            let footer = "floodit.app"
            let footerSize = footer.size(withAttributes: footerAttrs)
            footer.draw(at: CGPoint(x: (width - footerSize.width) / 2, y: height - 36), withAttributes: footerAttrs)
        }
    }

    /// Draws a 5-pointed star at the given center.
    private static func drawStar(in ctx: CGContext, center: CGPoint, size: CGFloat, color: UIColor) {
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4
        let path = UIBezierPath()
        let angleOffset = -CGFloat.pi / 2

        for i in 0..<10 {
            let angle = angleOffset + CGFloat(i) * .pi / 5
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        color.setFill()
        path.fill()
    }
}

// MARK: - UIFont rounded helper

private extension UIFont {
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
