import CoreFoundation
import Foundation

public enum GeometryError: Error, Equatable {
    case malformedQuery
    case missingBoundingRects
    case noUsableFrame
}

public struct DisplayFrame: Equatable, Sendable {
    public let identifier: String
    public let frame: Rect

    public init(identifier: String, frame: Rect) {
        self.identifier = identifier
        self.frame = frame
    }
}

public enum DisplayFrameSelector {
    public static func select(
        from candidates: [DisplayFrame],
        pointer: Point? = nil
    ) throws -> WidgetGeometry {
        let usable = candidates.filter {
            $0.frame.x.isFinite && $0.frame.y.isFinite
                && $0.frame.width.isFinite && $0.frame.height.isFinite
                && $0.frame.width > 0 && $0.frame.height > 0
        }
        guard !usable.isEmpty else { throw GeometryError.noUsableFrame }

        let selected: DisplayFrame
        if let pointer {
            selected = usable.first(where: { contains($0.frame, pointer) })
                ?? usable.min(by: { distanceSquared($0.frame.midpoint, pointer) < distanceSquared($1.frame.midpoint, pointer) })!
        } else {
            selected = usable.sorted { $0.identifier.localizedStandardCompare($1.identifier) == .orderedAscending }[0]
        }

        return WidgetGeometry(frame: selected.frame, displayID: selected.identifier)
    }

    private static func contains(_ rect: Rect, _ point: Point) -> Bool {
        point.x >= rect.x && point.x <= rect.x + rect.width
            && point.y >= rect.y && point.y <= rect.y + rect.height
    }

    private static func distanceSquared(_ lhs: Point, _ rhs: Point) -> Double {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }
}

public enum SketchyBarQueryParser {
    public static func boundingRects(from data: Data) throws -> [DisplayFrame] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeometryError.malformedQuery
        }
        guard let rawRects = root["bounding_rects"] as? [String: Any] else {
            throw GeometryError.missingBoundingRects
        }

        let frames = rawRects.compactMap { identifier, value -> DisplayFrame? in
            guard let dictionary = value as? [String: Any], let rect = parseRect(dictionary) else { return nil }
            return DisplayFrame(identifier: identifier, frame: rect)
        }
        guard !frames.isEmpty else { throw GeometryError.noUsableFrame }
        return frames
    }

    private static func parseRect(_ value: [String: Any]) -> Rect? {
        if let origin = numberPair(value["origin"]), let size = numberPair(value["size"]) {
            return Rect(x: origin.0, y: origin.1, width: size.0, height: size.1)
        }

        guard let x = number(value["x"]),
              let y = number(value["y"]),
              let width = number(value["width"]),
              let height = number(value["height"]) else { return nil }
        return Rect(x: x, y: y, width: width, height: height)
    }

    private static func numberPair(_ value: Any?) -> (Double, Double)? {
        if let pair = value as? [Any], pair.count >= 2,
           let first = number(pair[0]), let second = number(pair[1]) {
            return (first, second)
        }
        if let pair = value as? [String: Any],
           let first = number(pair["x"] ?? pair["width"]),
           let second = number(pair["y"] ?? pair["height"]) {
            return (first, second)
        }
        return nil
    }

    private static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.doubleValue
    }
}
