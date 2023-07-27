//
//  ArrivalGTFSDB.struct.swift
//  Arrival-GTFS
//
//  Created by Ronan Furuta on 7/27/23.
//

import Foundation
import GTFS

public struct GTFSDB: Codable, Hashable {
    
    public var stations: StationsDB
    public var routes: RoutesDB
    public var trips: TripsDB
    public var stopTimes: StopTimesDB
    
    public let agencies: [Agency]
    public let stops: [Stop]
    public let calendar: [GTFSCalendar]?
    public let calendarDates: [CalendarDate]?
    public let fareAttributes: [FareAttribute]?
    public let fareRules: [FareRule]?
    public let frequencies: [Frequency]?
    public let transfers: [Transfer]?
    public let feedInformation: [FeedInfo]?
    
    public init(from gtfs: GTFS) {
        self.agencies = gtfs.agencies
        self.stops = gtfs.stops
      
        
        self.calendar = gtfs.calendar
        self.calendarDates = gtfs.calendarDates
        self.fareAttributes = gtfs.fareAttributes
        self.fareRules = gtfs.fareRules
        self.frequencies = gtfs.frequencies
        self.transfers = gtfs.transfers
        self.feedInformation = gtfs.feedInformation
        
        let stations: StationsDB = .init(from: gtfs.stops)
        self.stations = stations
        self.stopTimes = .init(from: gtfs.stopTimes)
        let trips = TripsDB.init(from: gtfs.trips, stopTimes: gtfs.stopTimes)
        self.trips = trips
        self.routes = .init(from: gtfs.routes, trips: trips, stations: stations)
        
       
    
    }
    
}

public struct StationsDB: Codable, Hashable, Equatable {
    public let all: [Stop]
    public let byStopID: [String: Stop]
    public var ready: DBReady = .ready
    public init(from stops: [Stop]) {
        let all = stops.filter({ stop in
            return stop.locationType == .stop
        })
        self.all = all
        
        var byStopID: [String: Stop] = [:]
        all.forEach({station in
            byStopID[station.stopId] = station
        })
        self.byStopID = byStopID
        
    }
}

public struct StopTimesDB: Codable, Hashable, Equatable {
    public let all: [StopTime]
    public let byStopTimeID: [String: StopTime]
    public var ready: DBReady = .notReady
    
    public init(from stopTimes: [StopTime]) {
        self.all = stopTimes
        var byStopTimeID: [String: StopTime] = [:]
        var byStopID: [String: StopTime] = [:]
        var byTripID: [String: [StopTime]] = [:]
        
        stopTimes.forEach({stopTime in
            byStopTimeID[stopTime.stopId] = stopTime
            byStopID[stopTime.stopId] = stopTime
            var currentByTripID: [StopTime] = byTripID[stopTime.tripId] ?? []
            currentByTripID.append(stopTime)
            byTripID[stopTime.tripId] = currentByTripID
        })
        self.byStopTimeID = byStopTimeID
        self.byStopID = byStopID
        
        self.byTripID = byTripID
        
    
        self.ready = .ready
    }
    
    ///Shows all stop times for a particular stop
    public var byStopID: [String: StopTime]
    ///Shows all stops timesfor a partidular trip
    public var byTripID: [String: [StopTime]]
}

public struct TripsDB: Codable, Hashable, Equatable {
    public var all: [Trip]
    public var byTripID: [String: Trip]
    public var ready: DBReady = .notReady
    
    public init(from trips: [Trip], stopTimes: [StopTime]) {
        self.all = trips
        var inProgress: [String: Trip] = [:]
        trips.forEach({trip in
            inProgress[trip.tripId] = trip
        })
        self.byTripID = inProgress
        
        
        var byStopID: [String: [Trip]] = [:]
        stopTimes.forEach({stopTime in
            if let tripForStopTime = inProgress[stopTime.tripId] {
                var currentIndexed = (byStopID[stopTime.stopId] ?? [])
                currentIndexed.append(tripForStopTime)
                byStopID[stopTime.stopId] = currentIndexed
            }
            
        })
        self.byStopID = byStopID
        
        self.ready = .ready
    }
    

    ///Shows all trips that pass through a particular stop
    public var byStopID: [String: [Trip]]
    
}

public struct RoutesDB: Codable, Hashable, Equatable {
    public var all: [Route]
    public var byRouteID: [String: Route]
    public var ready: DBReady = .notReady
    
    public init(from routes: [Route], trips: TripsDB, stations: StationsDB) {
        self.all = routes
        var inProgress: [String: Route] = [:]
        routes.forEach({route in
            inProgress[route.routeId] = route
        })
        self.byRouteID = inProgress
        
        var inProgressByStopID: [String: [Route]] = [:]
        stations.all.forEach({station in
            var routes: [Route] = []
            if let trips = trips.byStopID[station.stopId] {
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
        
        self.byStopID = inProgressByStopID
        
        self.ready = .ready
    }

    
    ///Shows all routes that a stop has
    public var byStopID: [String: [Route]]
}

public enum DBReady: Codable, Hashable, Equatable {
    case notReady
    case ready
}
