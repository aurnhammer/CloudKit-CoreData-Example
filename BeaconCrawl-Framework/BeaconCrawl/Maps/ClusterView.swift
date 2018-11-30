/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A subclass of MKAnnotationView that configures itself for representing a MKClusterAnnotation with only Bike member annotations.
*/
import MapKit
import Foundation

open class ClusterView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
		if #available(iOS 11.0, *) {
			displayPriority = .defaultHigh
		} else {
			// Fallback on earlier versions
		}
		if #available(iOS 11.0, *) {
			collisionMode = .circle
		} else {
			// Fallback on earlier versions
		}
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }
    
	required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	override open var annotation: MKAnnotation? {
        willSet {
			if #available(iOS 11.0, *) {
				if let cluster = newValue as? MKClusterAnnotation {
					let radius: CGFloat = 28.0
					let renderer = UIGraphicsImageRenderer(size: CGSize(width: radius*2, height: radius*2))
					let count = cluster.memberAnnotations.count
					let placeCount = cluster.memberAnnotations.filter { member -> Bool in
						return (member as! Annotation).type == .place
						}.count
					Log.message("place count \(placeCount)")
					
					let gameCount = cluster.memberAnnotations.filter { member -> Bool in
						return (member as! Annotation).type == .game
						}.count
					
					Log.message("game count \(gameCount)")

					
					let eventCount = cluster.memberAnnotations.filter { member -> Bool in
						return (member as! Annotation).type == .event
						}.count
					Log.message("event count \(eventCount)")

					let tourCount = cluster.memberAnnotations.filter { member -> Bool in
						return (member as! Annotation).type == .tour
						}.count
					
					Log.message("tour count \(tourCount)")


					image = renderer.image { _ in
						// Fill full circle with place color
						var piePath = UIBezierPath()
						var startAngle: CGFloat = 0.0
						var endAngle: CGFloat = 0.0


						if placeCount > 0 {
							UIColor(named:"green")?.setFill()
							endAngle = (CGFloat.pi * 2.0 * CGFloat(placeCount)) / CGFloat(count)
							piePath.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
							piePath.addLine(to: CGPoint(x: radius, y: radius))
							piePath.close()
							piePath.fill()
						}
						if gameCount > 0 {
							UIColor(named:"blue")?.setFill()
							piePath = UIBezierPath()
							startAngle = endAngle
							Log.message("StartAngle: \(startAngle)")
							endAngle = (CGFloat.pi * 2.0 * CGFloat(gameCount)) / CGFloat(count) + startAngle
							Log.message("StartAngle: \(startAngle)")

							piePath.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
							piePath.addLine(to: CGPoint(x: radius, y: radius))
							piePath.close()
							piePath.fill()
						}

						if tourCount > 0 {
							UIColor(named:"purple")?.setFill()
							
							piePath = UIBezierPath()
							startAngle = endAngle
							endAngle = (CGFloat.pi * 2.0 * CGFloat(tourCount)) / CGFloat(count) + startAngle
							
							piePath.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius,
										   startAngle: startAngle, endAngle: endAngle,
										   clockwise: true)
							piePath.addLine(to: CGPoint(x: radius, y: radius))
							piePath.close()
							piePath.fill()
						}

						if eventCount > 0 {
							UIColor(named:"orange")?.setFill()
							
							piePath = UIBezierPath()
							startAngle = endAngle
							endAngle = (CGFloat.pi * 2.0 * CGFloat(eventCount)) / CGFloat(count) + startAngle
							
							piePath.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius,
										   startAngle: startAngle, endAngle: endAngle,
										   clockwise: true)
							piePath.addLine(to: CGPoint(x: radius, y: radius))
							piePath.close()
							piePath.fill()
						}
						
						// Fill inner circle with white color
						UIColor.white.setFill()
						UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 40, height: 40)).fill()
						
						// Finally draw count text vertically and horizontally centered
						let attributes = [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 20)]
						let text = "\(count)"
						let size = text.size(withAttributes: attributes)
						let rect = CGRect(x: radius - size.width / 2, y: radius - size.height / 2, width: size.width, height: size.height)
						text.draw(in: rect, withAttributes: attributes)
					}
				}
			} else {
				// Fallback on earlier versions
			}
        }
    }

}
