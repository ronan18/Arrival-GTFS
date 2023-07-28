//
//  ArrivalGTFSDB.struct.swift
//  Arrival-GTFS
//
//  Created by Ronan Furuta on 7/27/23.
//

import Foundation
import GTFS

public struct GTFSDB: Codable, Hashable {
    
    public var dbVID: String
    
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
        print("init DB")
        self.agencies = gtfs.agencies
        self.stops = gtfs.stops
      
        
        self.calendar = gtfs.calendar
        self.calendarDates = gtfs.calendarDates
        self.fareAttributes = gtfs.fareAttributes
        self.fareRules = gtfs.fareRules
        self.frequencies = gtfs.frequencies
        self.transfers = gtfs.transfers
        self.feedInformation = gtfs.feedInformation
        
        print("1:1 DB built")
        
        let stations: StationsDB = .init(from: gtfs.stops)
        self.stations = stations
       
        self.stopTimes = .init(from: gtfs.stopTimes)
        let trips = TripsDB.init(from: gtfs.trips, stopTimes: gtfs.stopTimes)
        self.trips = trips
        self.routes = .init(from: gtfs.routes, trips: trips, stations: stations)
        
        self.dbVID = UUID().uuidString
       
    
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
        print("stations DB built")
    }
}
public extension Date {
    init(bartTime: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .init(abbreviation: "PST")
        dateFormatter.dateFormat = "HH:mm:ss"
       var nextDay = false
        var updatedBartString = bartTime
        
        var hourInt = Int(bartTime.prefix(2))!
        if hourInt > 23 {
            hourInt = hourInt - 24
            nextDay = true
            updatedBartString = String(updatedBartString.dropFirst(2))
            updatedBartString = "0\(hourInt)" + updatedBartString
        }
        
        
        var date = dateFormatter.date(from: updatedBartString)
        if  date == nil {
            date = Date()
           // print("ERROR DATE", bartTime)
        }
        
       
        let components = Calendar.current.dateComponents([.hour, .minute], from: date!)
        let hour = components.hour!
        let minute = components.minute!

  
       
        // get today and apply saved hour & minute
        var newComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date.now)
        newComponents.hour = hour
        newComponents.minute = minute
        newComponents.timeZone = .init(abbreviation: "PST")
        var newDate = Calendar.current.date(from: newComponents)!
        if (nextDay) {
            newDate = newDate + 60*60*24
        }
        self = newDate
    }
}
public struct StopTimesDB: Codable, Hashable, Equatable {
    public let all: [StopTime]
    public let byStopTimeID: [String: StopTime]
    public var ready: DBReady = .notReady
    
    public init(from stopTimes: [StopTime]) {
        self.all = stopTimes
        var byStopTimeID: [String: StopTime] = [:]
        var byStopID: [String: [StopTime]] = [:]
        var byTripID: [String: [StopTime]] = [:]
        
        stopTimes.forEach({stopTime in
            byStopTimeID[stopTime.stopId] = stopTime
            var current =  byStopID[stopTime.stopId] ?? []
            current.append(stopTime)
            byStopID[stopTime.stopId] = current
            var currentByTripID: [StopTime] = byTripID[stopTime.tripId] ?? []
            currentByTripID.append(stopTime)
            byTripID[stopTime.tripId] = currentByTripID
        })
        print("sorting stop times")
        byStopID.keys.forEach {key in
            byStopID[key] = byStopID[key]?.sorted(by: { a, b in
                a < b
            })
        }
        self.byStopTimeID = byStopTimeID
        self.byStopID = byStopID
        
        byTripID.keys.forEach {key in
            byTripID[key] = byTripID[key]?.sorted(by: { a, b in
                a.stopSequence < b.stopSequence
            })
        }
        self.byTripID = byTripID
        
    
        self.ready = .ready
        print("stop times DB built")
    }
    
    ///Shows all stop times for a particular Station
    public var byStopID: [String: [StopTime]]
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
        print("trips DB built")
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
        print("routes DB built")
    }

    
    ///Shows all routes that a station has
    public var byStopID: [String: [Route]]
}

public enum DBReady: Codable, Hashable, Equatable {
    case notReady
    case ready
}
