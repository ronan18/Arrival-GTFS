import Foundation

public class GTFS: Codable {
    public let agencies: [Agency]
    public let stops: [Stop]
    public let routes: [Route]
    public let trips: [Trip]
    public let stopTimes: [StopTime]
    public let calendar: [GTFSCalendar]?
    public let calendarDates: [CalendarDate]?
    public let fareAttributes: [FareAttribute]?
    public let fareRules: [FareRule]?
    public let shapes: [Shape]?
    public let frequencies: [Frequency]?
    public let transfers: [Transfer]?
    public let pathways: [Pathway]?
    public let levels: [Level]?
    public let feedInformation: [FeedInfo]?
    public let translations: [Translation]?
    public let attributions: [Attribution]?
    
    public init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        
        /// Required
        self.agencies = try initializeFile(url.appendingPathComponent("agency.txt"))
        self.stops = try initializeFile(url.appendingPathComponent("stops.txt"))
        self.routes = try initializeFile(url.appendingPathComponent("routes.txt"))
        self.trips = try initializeFile(url.appendingPathComponent("trips.txt"))
        self.stopTimes = try initializeFile(url.appendingPathComponent("stop_times.txt"))
        
        /// Conditionally required and optional
        self.calendar = initializeOptionalFile(url.appendingPathComponent("calendar.txt"))
        self.calendarDates = initializeOptionalFile(url.appendingPathComponent("calendar_dates.txt"))
        self.fareAttributes = initializeOptionalFile(url.appendingPathComponent("fare_attributes.txt"))
        self.fareRules = initializeOptionalFile(url.appendingPathComponent("fare_rules.txt"))
        //self.shapes = initializeOptionalFile(url.appendingPathComponent("shapes.txt"))
        self.frequencies = initializeOptionalFile(url.appendingPathComponent("frequencies.txt"))
        self.transfers = initializeOptionalFile(url.appendingPathComponent("transfers.txt"))
        //self.pathways = initializeOptionalFile(url.appendingPathComponent("pathways.txt"))
        self.levels = initializeOptionalFile(url.appendingPathComponent("levels.txt"))
        self.feedInformation = initializeOptionalFile(url.appendingPathComponent("feed_info.txt"))
       // self.translations = initializeOptionalFile(url.appendingPathComponent("translations.txt"))
        self.attributions = initializeOptionalFile(url.appendingPathComponent("attributions.txt"))
        self.translations = nil
        self.pathways = nil
        self.shapes = nil
    
    }
    public init() {
        /// Required
       
        self.agencies = try! initializeFile(Bundle.module.url(forResource: "agency", withExtension: "txt")!)
        self.stops = try! initializeFile( Bundle.module.url(forResource: "stops", withExtension: "txt")!)
        self.routes = try! initializeFile(Bundle.module.url(forResource: "routes", withExtension: "txt")!)
        self.trips = try! initializeFile(Bundle.module.url(forResource: "trips", withExtension: "txt")!)
        self.stopTimes = try! initializeFile(Bundle.module.url(forResource: "stop_times", withExtension: "txt")!)
        
        /// Conditionally required and optional
        self.calendar = initializeOptionalFile(Bundle.module.url(forResource: "calendar", withExtension: "txt")!)
        self.calendarDates = initializeOptionalFile(Bundle.module.url(forResource: "calendar_dates", withExtension: "txt")!)
        self.fareAttributes = initializeOptionalFile(Bundle.module.url(forResource: "fare_attributes", withExtension: "txt")!)
        self.fareRules = initializeOptionalFile(Bundle.module.url(forResource: "fare_rules", withExtension: "txt")!)
        //self.shapes = initializeOptionalFile(url.appendingPathComponent("shapes.txt"))
       // self.frequencies = initializeOptionalFile(Bundle.module.url(forResource: "frequencies", withExtension: "txt")!)
        self.transfers = initializeOptionalFile(Bundle.module.url(forResource: "transfers", withExtension: "txt")!)
        //self.pathways = initializeOptionalFile(url.appendingPathComponent("pathways.txt"))
//        self.levels = initializeOptionalFile(Bundle.module.url(forResource: "levels", withExtension: "txt")!)
        self.feedInformation = initializeOptionalFile(Bundle.module.url(forResource: "feed_info", withExtension: "txt")!)
       // self.translations = initializeOptionalFile(url.appendingPathComponent("translations.txt"))
//        self.attributions = initializeOptionalFile(Bundle.module.url(forResource: "attributions", withExtension: "txt")!)
        self.translations = nil
        self.pathways = nil
        self.shapes = nil
        self.frequencies = nil
        self.levels = nil
        self.attributions = nil
    }
    
}

func initializeFile<T: FromCSVLine>(_ path: URL) throws -> [T] {
    let reader = try CSVReader(path: path)
    
    return reader.map { line -> T in
        T(line: line)
    }
}

func initializeOptionalFile<T: FromCSVLine>(_ path: URL) -> [T]? {
    let reader = try? CSVReader(path: path)
    
    return reader.map { reader -> [T] in
        reader.map { line -> T in
            T(line: line)
        }
    }
}
