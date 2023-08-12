//
//  ArrivalGTFSDB.struct.swift
//  Arrival-GTFS
//
//  Created by Ronan Furuta on 7/27/23.
//

import Foundation
//import GTFS

public struct GTFSDB: Codable, Hashable {
    
    public var dbVID: String
    
    public let stations: StationsDB
    
    public var routes: RoutesDB
    public var trips: TripsDB
    public var stopTimes: StopTimesDB
    public let transfers: TransfersDB
    public let calendar: GTFSCalendarDB
    
    
    public let agencies: [Agency]
    public let stops: [Stop]
    public let calendarDates: [CalendarDate]?
    public let fareAttributes: [FareAttribute]?
    public let fareRules: [FareRule]?
    public let frequencies: [Frequency]?
    
    public let feedInformation: [FeedInfo]?
    
    public init(from gtfs: GTFS) {
       
        print("init DB")
        self.agencies = gtfs.agencies
        self.stops = gtfs.stops
        
        
        self.calendar = GTFSCalendarDB(from: gtfs.calendar!)
        self.calendarDates = gtfs.calendarDates
        self.fareAttributes = gtfs.fareAttributes
        self.fareRules = gtfs.fareRules
        self.frequencies = gtfs.frequencies
        self.transfers = TransfersDB(from: gtfs.transfers!)
        self.feedInformation = gtfs.feedInformation
        
        print("1:1 DB built")
        
        let stations: StationsDB = .init(from: gtfs.stops)
        self.stations = stations
        
        self.stopTimes = .init(from: gtfs.stopTimes)
        let trips = TripsDB.init(from: gtfs.trips, stopTimes: gtfs.stopTimes)
        self.trips = trips
        self.routes = .init(from: gtfs.routes, trips: trips, stations: stations)
        //self.initialStopTimes = self.stopTimes
        //self.initialTrips = self.trips
        self.dbVID = UUID().uuidString
        
        
    }

    
     func updateWithRT(_ feed: TransitRealtime_FeedMessage) throws {
        var resultingStopTimes: StopTimesDB = self.stopTimes
        
        feed.entity.forEach({entity in
            do {
                try  self.parseRTEntity(entity)
            } catch {
                //print(error, "for", entity)
            }
           
        })
        
        
    }
    func parseRTEntity(_ entity: TransitRealtime_FeedEntity) throws {
        guard entity.hasTripUpdate else {
            print("no trip updates for enetity \(entity.hasAlert) \(entity.hasVehicle) \(entity.unknownFields)")
            throw RTUpdateError.noTripUpdates
        }
        guard var trip = self.trips.byTripID(entity.tripUpdate.trip.tripID) else {
            print("no trip updates for enetity \(entity.hasAlert) \(entity.hasVehicle) \(entity.unknownFields)")
            throw RTUpdateError.specifiedTripDoesntExist
        }
        guard var stopTimes = self.stopTimes.byTripID(entity.tripUpdate.trip.tripID) else {
            throw RTUpdateError.noStopTimesExist
        }
        trip.trainType = TrainType(rawValue:  entity.tripUpdate.vehicle.label) ?? .unknown
        
        print("trip", entity.tripUpdate.trip.tripID, trip.tripHeadsign)
        print("vehicle", entity.tripUpdate.vehicle.label)
        print("delay", entity.tripUpdate.delay)
        print("stopTimeUpdates", entity.tripUpdate.stopTimeUpdate.count)
        
        entity.tripUpdate.stopTimeUpdate.forEach({update in
          
            print(update.stopID, update.stopSequence, update.arrival.delay, update.departure.delay)
            if (update.scheduleRelationship != .scheduled) {
                print(update.scheduleRelationship)
            }
            var stopTime = stopTimes[Int(update.stopSequence)]
            stopTime.arrivalDelay = TimeInterval(update.arrival.delay)
            stopTime.departureDelay = TimeInterval(update.departure.delay)
            stopTimes[Int(update.stopSequence)] = stopTime
            if (update.arrival.delay > 0 || update.departure.delay > 0) {
                //print(update)
            }
        })
       
    }
    
}
public enum RTUpdateError: Error {
    case noTripUpdates
    case specifiedTripDoesntExist
    case noStopTimesExist
}
public struct TransfersDB: Codable, Hashable, Equatable {
    public let all: [Transfer]
    private let byStopIDIndex: [String: [Int]]
    public init(from transfers: [Transfer]) {
        self.all = transfers
        var byStopID: [String: [Int]] = [:]
        for i in 0..<all.count {
           let transfer = all[i]
            var current = byStopID[transfer.topStopId] ?? []
            current.append(i)
            byStopID[transfer.fromStopId] = current
        }
        self.byStopIDIndex = byStopID
    }
    public func byStopID(_ stopId: String) -> [Transfer]? {
        guard let index = self.byStopIDIndex[stopId] else {
            return nil
        }
        return index.map({i in
            return all[i]
        })
    }
}
public struct GTFSCalendarDB: Codable, Hashable, Equatable {
    public let all: [GTFSCalendar]
    private let byServiceIDIndex: [String: Int]
    public init(from calendars: [GTFSCalendar]) {
        self.all = calendars
        var byID: [String: Int] = [:]
        for i in 0..<all.count {
           let transfer = all[i]
            
            byID[transfer.serviceId] = i
        }
        self.byServiceIDIndex = byID
    }
    public func byServiceID(_ serviceId: String) -> GTFSCalendar? {
        guard let index = self.byServiceIDIndex[serviceId] else {
            return nil
        }
        return all[index]
    }
}
public struct StationsDB: Codable, Hashable, Equatable {
    public let all: [Stop]
    private let byStopIDIndex: [String: Int]
    public var ready: DBReady = .ready
    public init(from stops: [Stop]) {
        let all = stops.filter({ stop in
            return stop.locationType == .stop
        })
        self.all = all
        
        var byStopID: [String: Int] = [:]
        for i in 0..<all.count {
           let station = all[i]
            byStopID[station.stopId] = i
        }
       
        self.byStopIDIndex = byStopID
        print("stations DB built")
    }
    public func byStopID(_ stopId: String) -> Stop? {
        guard let index = self.byStopIDIndex[stopId] else {
            return nil
        }
        return self.all[index]
    }
}

public struct StopTimesDB: Codable, Hashable, Equatable {
    public var all: [StopTime]
    
    public var ready: DBReady = .notReady
    
    private let stopTimeByIdIndex: [String: Int]
    private let byStopIdIndex: [String: [Int]]
    private let byTripIDIndex: [String: [Int]]
    private let byDepartureHourIndex: [String: [Int]]
    
    public init(from stopTimes: [StopTime]) {
        let stopTimes = stopTimes.sorted(by: {a,b in
            a.departureTime < b.departureTime
        })
        self.all = stopTimes
        var byStopTimeID: [String: Int] = [:]
        var byStopID: [String: [Int]] = [:]
        var byTripID: [String: [Int]] = [:]
        var byDepartureHourIndex: [String: [Int]] = [:]
        for i in 0..<stopTimes.count {
            let stopTime = stopTimes[i]
            byStopTimeID[stopTime.id] = i
            var current =  byStopID[stopTime.stopId] ?? []
            current.append(i)
            byStopID[stopTime.stopId] = current
            var currentByTripID: [Int] = byTripID[stopTime.tripId] ?? []
            currentByTripID.append(i)
            byTripID[stopTime.tripId] = currentByTripID
            
            var currentDepartureHourIndex = byDepartureHourIndex[String(stopTime.departureTime.prefix(2))] ?? []
            
            if currentDepartureHourIndex.count == 0 {
                currentDepartureHourIndex = [i,i]
            } else if currentDepartureHourIndex.count == 2 {
                currentDepartureHourIndex = [currentDepartureHourIndex.first!, i]
            }
            byDepartureHourIndex[String(stopTime.departureTime.prefix(2))] = currentDepartureHourIndex
            
        }
        
        print("sorting stop times")
       
        
        byTripID.keys.forEach {key in
            byTripID[key] = byTripID[key]?.sorted(by: { a, b in
                stopTimes[a].stopSequence < stopTimes[b].stopSequence
            })
        }
      
        
        self.stopTimeByIdIndex = byStopTimeID
        self.byStopIdIndex = byStopID
        self.byTripIDIndex = byTripID
        self.ready = .ready
        self.byDepartureHourIndex = byDepartureHourIndex
        print("stop times DB built")
    }
    public func byDepartureHour(_ hour: String) -> [StopTime] {
       
        let indexes = self.byDepartureHourIndex[hour] ?? []
        guard let first = indexes.first else {
            return []
        }
        let last = indexes.last ?? self.all.count - 1
        let allIndexes = self.all[first...last]
        return Array(allIndexes)
    }
    public func byDepartureHour(from: String, to: String) -> [StopTime] {
       
     //  print("by departure hour", from, to)
        guard let first = self.byDepartureHourIndex[from]?.first else {
            return []
        }
        let last = self.byDepartureHourIndex[to]?.last ?? self.all.count - 1
        let allIndexes = self.all[first...last]
        return Array(allIndexes)
    }
    public func byStopTimeID(_ stopTimeId: String) -> StopTime? {
        guard let index = self.stopTimeByIdIndex[stopTimeId] else {
            return nil
        }
        return self.all[index]
    }
    
    ///Shows all stop times for a particular Station
    ///Sorted by time
    public func byStopID(_ stopId: String) -> [StopTime]? {
        return self.byStopIdIndex[stopId].map{stopTimeIndexes in
            return stopTimeIndexes.map({i in
                return all[i]
            })
        }
    }
    ///Shows all stops timesfor a partidular trip
    public func byTripID(_ tripId: String) -> [StopTime]? {
        return self.byTripIDIndex[tripId].map{stopTimeIndexes in
            return stopTimeIndexes.map({i in
                return all[i]
            })
        }
    }
    
    mutating
    public func update(_ stopTime: StopTime) {
        guard let index = self.stopTimeByIdIndex[stopTime.id] else {
            return
        }
        self.all[index] = stopTime
    }
}

public struct TripsDB: Codable, Hashable, Equatable {
    public var all: [Trip]
    
    private var byTripIDIndex: [String: Int]
    private var byStopIDIndex: [String: [Int]]
    private var byRouteIDIndex: [String: [Int]]
    public var ready: DBReady = .notReady
    
    public init(from trips: [Trip], stopTimes: [StopTime]) {
        self.all = trips
        var inProgress: [String: Int] = [:]
        var byRouteIDIndex: [String: [Int]] = [:]
        for i in 0..<trips.count {
            let trip = trips[i]
            inProgress[trip.tripId] = i
            if let currentRoute = byRouteIDIndex[trip.routeId] {
                var currentRouteI = currentRoute
                currentRouteI.append(i)
                byRouteIDIndex[trip.routeId] =  currentRouteI
            } else {
                byRouteIDIndex[trip.routeId] = [i]
            }
        }
        self.byRouteIDIndex = byRouteIDIndex
        /*
         trips.forEach({trip in
         inProgress[trip.tripId] = trip
         })*/
        self.byTripIDIndex = inProgress
        
        
        var byStopID: [String: [Int]] = [:]
        stopTimes.forEach({stopTime in
            if let tripForStopTime = inProgress[stopTime.tripId] {
                var currentIndexed = (byStopID[stopTime.stopId] ?? [])
                currentIndexed.append(tripForStopTime)
                byStopID[stopTime.stopId] = currentIndexed
            }
            
        })
        self.byStopIDIndex = byStopID
        
        self.ready = .ready
        print("trips DB built")
    }
    
    public func byTripID(_ tripId: String) -> Trip? {
        guard let index = self.byTripIDIndex[tripId] else {
            return nil
        }
        return self.all[index]
    }
    ///Shows all trips that pass through a particular stop
    public func byStopID(_ stopId: String) -> [Trip]? {
        return self.byStopIDIndex[stopId].map({tripIndexs in
            return tripIndexs.map({index in
                return all[index]
            })
        })
    }
    public func byRouteID(_ routeId: String) -> [Trip]? {
        return self.byRouteIDIndex[routeId].map({trips in
            return trips.map({i in
                return all[i]
            })
        })
    }
    mutating public func insert(_ trip: Trip, stopTimes: [StopTime]) {
        guard !self.all.contains(trip) else {
            return
        }
        self.all.append(trip)
        var inProgress: [String: Int] =  self.byTripIDIndex
        var byRouteIDIndex: [String: [Int]] = [:]
       var  i = self.all.count - 1
            let trip = self.all[i]
            inProgress[trip.tripId] = i
            if let currentRoute = byRouteIDIndex[trip.routeId] {
                var currentRouteI = currentRoute
                currentRouteI.append(i)
                byRouteIDIndex[trip.routeId] =  currentRouteI
            } else {
                byRouteIDIndex[trip.routeId] = [i]
            }
        
        self.byRouteIDIndex = byRouteIDIndex
        /*
         trips.forEach({trip in
         inProgress[trip.tripId] = trip
         })*/
        self.byTripIDIndex = inProgress
        
        
        var byStopID: [String: [Int]] = self.byStopIDIndex
        stopTimes.forEach({stopTime in
            guard stopTime.tripId == trip.tripId else {
                return
            }
            if let tripForStopTime = inProgress[stopTime.tripId] {
                var currentIndexed = (byStopID[stopTime.stopId] ?? [])
                currentIndexed.append(tripForStopTime)
                byStopID[stopTime.stopId] = currentIndexed
            }
            
        })
        self.byStopIDIndex = byStopID
        
        self.ready = .ready
        print("TRIPS DB: inserted \(trip.tripId)")
    }
    
}

public struct RoutesDB: Codable, Hashable, Equatable {
    public var all: [Route]
    
    private var byRouteIDIndex: [String: Int]
    private var byStopIDIndex: [String: [Int]]
    
    public var ready: DBReady = .notReady
    
    public init(from routes: [Route], trips: TripsDB, stations: StationsDB) {
        self.all = routes
        var inProgress: [String: Int] = [:]
        for i in 0..<routes.count {
            let route = all[i]
            inProgress[route.routeId] = i
        }
       
        self.byRouteIDIndex = inProgress
        
        var inProgressByStopID: [String: [Int]] = [:]
        stations.all.forEach({station in
            var routes: [Int] = []
            if let trips = trips.byStopID(station.stopId) {
                trips.forEach({trip in
                    if let route = inProgress[trip.routeId] {
                        if !routes.contains(route) {
                            routes.append(route)
                        }
                    }
                })
            }
            inProgressByStopID[station.stopId] = routes
        })
        
        self.byStopIDIndex = inProgressByStopID
        
        self.ready = .ready
        print("routes DB built")
    }
    
    public func byRouteID(_ routeID: String) -> Route? {
        guard let id = self.byRouteIDIndex[routeID] else {
            return nil
        }
        return self.all[id]
    }
    
    ///Shows all routes that a station has
    public func byStopID(_ stopId: String) -> [Route]? {
        guard let indexes = self.byStopIDIndex[stopId] else {
            return nil
        }
        return indexes.map({i in
            return self.all[i]
        })
    }
}

public enum DBReady: Codable, Hashable, Equatable {
    case notReady
    case ready
}

public func saveDBToFile(_ db: GTFSDB, container: URL = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/RonanFuruta/ios/Arrival/Arrival-GTFS/Sources/ArrivalGTFS/db/dbjsons", isDirectory: true)) throws {
    
    do {
        try writeToFile(data: db.agencies, container: container, file: "agencies.json")
        try writeToFile(data: db.calendar, container: container, file: "calendar.json")
        try writeToFile(data: db.calendarDates, container: container, file: "calendarDates.json")
        try writeToFile(data: db.dbVID, container: container, file: "dbVID.json")
        try writeToFile(data: db.fareAttributes, container: container, file: "fareAttributes.json")
        try writeToFile(data: db.fareRules, container: container, file: "fareRules.json")
        try writeToFile(data: db.feedInformation, container: container, file: "feedInformation.json")
        try writeToFile(data: db.frequencies, container: container, file: "frequencies.json")
        try writeToFile(data: db.routes, container: container, file: "routes.json")
        try writeToFile(data: db.stations, container: container, file: "stations.json")
        try writeToFile(data: db.stopTimes.all, container: container, file: "stopTimesAll.json")
        try writeToFile(data: db.stops, container: container, file: "stops.json")
        try writeToFile(data: db.transfers, container: container, file: "transfers.json")
        try writeToFile(data: db.trips, container: container, file: "trips.json")
    } catch {
        print(error)
    }
   
}

func writeToFile(data: any Codable, container: URL, file: String ) throws {
    do {
        
        let data = try JSONEncoder().encode(data)
        
        try data.write(to: container.appending(path: file))
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
        bcf.countStyle = .file
        let size = bcf.string(fromByteCount: Int64(data.count))
        
        print("cached \(file) to json", size)
    } catch {
        print(error)
        throw error
    }
}
