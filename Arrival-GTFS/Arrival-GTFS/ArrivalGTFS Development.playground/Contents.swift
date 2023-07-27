import Cocoa
@testable import Arrival_GTFS

var greeting = "Hello, playground"
 let cachePath = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/google_transit_20230213-20230813_v7.json")
public extension Date {
    init(bartTime: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .init(abbreviation: "PST")
        dateFormatter.dateFormat = "HH:mm:ss"
        let date = dateFormatter.date(from: bartTime) ?? Date()
        print("DATE: for \(bartTime) as \(date.formatted(date: .abbreviated, time: .complete))")
        self = date
    }
}

let date = Date(bartTime: "06:41:00")

print(date.formatted())
