import UIKit

public struct PieChartEntity {
    public let value: Decimal
    public let label: String
    
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}

public class PieChartView: UIView {

    public var entities: [PieChartEntity] = [] {
        didSet {
            if oldValue.isEmpty {
                self.processedEntities = processEntities(entities)
                setNeedsDisplay()
            }
        }
    }

    private var processedEntities: [PieChartEntity] = []
    
    private let colors: [UIColor] = [
        .systemYellow,
        UIColor(red: 0.29, green: 0.82, blue: 0.49, alpha: 1.00),
        .systemOrange, .systemBlue, .systemIndigo, .systemGray
    ]

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext(), !processedEntities.isEmpty else { return }
        
        let totalValue = processedEntities.reduce(0) { $0 + $1.value }
        guard totalValue > 0 else { return }

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.9 // Тонкий график
        
        var startAngle: CGFloat = -CGFloat.pi / 2

        for (index, entity) in processedEntities.enumerated() {
            let endAngle = startAngle + 2 * .pi * CGFloat(truncating: (entity.value / totalValue) as NSNumber)
            let color = colors[index % colors.count]
            context.setFillColor(color.cgColor)
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.addArc(withCenter: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
            path.close()
            path.fill()
            startAngle = endAngle
        }
        drawLegend(in: rect, center: center, innerRadius: innerRadius)
    }
    
    private func drawLegend(in rect: CGRect, center: CGPoint, innerRadius: CGFloat) {
        let totalValue = processedEntities.reduce(0) { $0 + $1.value }
        let legendContainerRect = CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)
        let lineCount = processedEntities.count
        let lineHeight: CGFloat = 16
        let totalHeight = CGFloat(lineCount) * lineHeight
        var currentY = center.y - totalHeight / 2
        
        for (index, entity) in processedEntities.enumerated() {
            let percentage = (entity.value / totalValue) * 100
            let percentageString = String(format: "%.0f%%", NSDecimalNumber(decimal: percentage).doubleValue)
            let circleX = legendContainerRect.minX + 28
            let circleY = currentY + 3
            let color = colors[index % colors.count]
            let circleRect = CGRect(x: circleX, y: circleY, width: 8, height: 8)
            let circlePath = UIBezierPath(ovalIn: circleRect)
            color.setFill()
            circlePath.fill()
            let text = "\(percentageString) \(entity.label)"
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byTruncatingTail
            let attributes: [NSAttributedString.Key: Any] = [ .font: UIFont.systemFont(ofSize: 10, weight: .regular), .foregroundColor: UIColor.label, .paragraphStyle: paragraphStyle ]
            let textRect = CGRect(x: circleRect.maxX + 8, y: currentY, width: legendContainerRect.width - 45, height: lineHeight)
            (text as NSString).draw(in: textRect, withAttributes: attributes)
            currentY += lineHeight
        }
    }

    public func animateUpdate(to newEntities: [PieChartEntity]) {
        let newProcessedEntities = processEntities(newEntities)
        
        guard newProcessedEntities.map({$0.label}) != self.processedEntities.map({$0.label}) ||
              newProcessedEntities.map({$0.value}) != self.processedEntities.map({$0.value}) else {
            return
        }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = CGFloat.pi
        rotationAnimation.duration = 0.5
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = 0.5
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        self.layer.add(rotationAnimation, forKey: "rotationAnimation")
        self.layer.add(fadeOutAnimation, forKey: "fadeOutAnimation")
        self.layer.opacity = 0.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.layer.removeAnimation(forKey: "rotationAnimation")
            self.layer.removeAnimation(forKey: "fadeOutAnimation")

            self.processedEntities = newProcessedEntities
            self.setNeedsDisplay()

            let rotationInAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationInAnimation.fromValue = CGFloat.pi // Начинаем с 180
            rotationInAnimation.toValue = CGFloat.pi * 2 // Заканчиваем на 360
            rotationInAnimation.duration = 0.5
            rotationInAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
            fadeInAnimation.fromValue = 0.0
            fadeInAnimation.toValue = 1.0
            fadeInAnimation.duration = 0.5
            fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            self.layer.add(rotationInAnimation, forKey: "rotationInAnimation")
            self.layer.add(fadeInAnimation, forKey: "fadeInAnimation")
            self.layer.opacity = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.layer.removeAnimation(forKey: "rotationInAnimation")
                self.layer.removeAnimation(forKey: "fadeInAnimation")
                self.transform = .identity
            }
        }
    }
    
    private func processEntities(_ entities: [PieChartEntity]) -> [PieChartEntity] {
        let sortedEntities = entities.sorted { $0.value > $1.value }
        if sortedEntities.count <= 5 {
            return sortedEntities
        } else {
            let top5 = Array(sortedEntities.prefix(5))
            let othersValue = sortedEntities.dropFirst(5).reduce(0) { $0 + $1.value }
            let othersEntity = PieChartEntity(value: othersValue, label: "Остальные")
            return top5 + [othersEntity]
        }
    }
}
