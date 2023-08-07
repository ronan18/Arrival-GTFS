//
//  ArrivalGTFSManager.swift
//  
//
//  Created by Ronan Furuta on 7/26/23.
//

import Foundation
import GTFS

public class ArrivalGTFS {
    private let gftsURL = URL(string: "https://www.bart.gov/dev/schedules/google_transit.zip")!
    private let gtfsrtURL = URL(string: "http://api.bart.gov/gtfsrt/tripupdate.aspx")!
    private let cachePath = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/google_transit_20230213-20230813_v7.json")
    private let dbCachePath = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/db.json")
    private var lastGTFSRTHash: Int? = nil
    public var db: GTFSDB
    public var rtDB: GTFSDB
    public var defaultResultLength: Int = 15
    
    public init() {
        let data = try! Data(contentsOf: dbCachePath)
        self.db = try! JSONDecoder().decode(GTFSDB.self, from: data)
        self.rtDB = self.db
        //print("AGTFS INIT trips: \(gtfs.trips.count) agencies: \(gtfs.agencies.count) stops: \(gtfs.stops.count) routes: \(gtfs.routes.count), stopTimes: \(gtfs.stopTimes.count)")
       // self.gtfs = .init(from: gtfs)
      
    }
    
    public func readPrebuilt() throws {
        do {
            let data = try Data(contentsOf: cachePath)
            let gtfs = try JSONDecoder().decode(GTFS.self, from: data)
            self.db = .init(from: gtfs)
        } catch {
            throw ArrivalGTFSError.failedToBuild
        }
    }
    public func build() throws {
        do {
            let gtfs = try GTFS(path: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/google_transit_20230213-20230813_v7")
            //print("built gtfs", gtfs, gtfs.routes)
            
            let data = try JSONEncoder().encode(gtfs)
            
            do {
                try data.write(to: cachePath)
            }
            catch {
                print("Failed to write JSON data: \(error.localizedDescription)")
            }
            self.db = .init(from: gtfs)
        } catch {
            // print("error", error)
            throw ArrivalGTFSError.failedToBuild
        }
        
        
    }
    public func getGTFSRT() async throws {
        print("fetching gtfs-rt")
        do {
            
            let (data, response) = try await URLSession.shared.data(from: self.gtfsrtURL)
            print("fetch result", data, response)
            let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)
            //print(feedMessage)
            guard feedMessage.hashValue != self.lastGTFSRTHash else {
                return
            }
            self.lastGTFSRTHash = feedMessage.hashValue
            
            try self.rtDB.updateWithRT(feedMessage)
            
            return
        } catch {
            print("errpr", error)
           throw error
        }
       
    }
    
    
    public func arrivals(for stop: Stop, at: Date = Date()) -> [StopTime] {
        guard let stopTimes = self.db.stopTimes.byStopID(stop.stopId) else {
            return []
        }
        
        print("got \(stopTimes.count) stops at \(stop.stopName)")
        var stopTimesSorted = stopTimes.sorted(by: {a, b in
            return Date(bartTime: a.arrivalTime) < Date(bartTime: b.arrivalTime)
        })
        guard let firstIndex = stopTimesSorted.firstIndex(where: {stopTime in
            //print(stopTime.arrivalTime.formatted(), "vs", at.formatted() )
            return Date(bartTime: stopTime.arrivalTime) >= at
        }) else {
            return []
        }
        print("first index \(firstIndex) \(stopTimes[firstIndex])")
        let selectedStopTimes = stopTimesSorted[firstIndex..<firstIndex + defaultResultLength]
        print("found \(selectedStopTimes.count) stops")
        return Array(selectedStopTimes)
        
    }
    
    public func directRoutes(from: Stop, to: Stop) -> [Route] {
        let fromStationRoutes: [Route] = self.db.routes.byStopID(from.stopId) ?? []
        let toStationRoutes: [Route] = self.db.routes.byStopID(to.stopId) ?? []
        var similarRoutes: [Route] = []
        fromStationRoutes.forEach({ route in
            if (toStationRoutes.contains(route)) {
                similarRoutes.append(route)
            }
        })
        similarRoutes = similarRoutes.filter({route in
            let trips = (self.db.trips.byRouteID(route.id) ?? [])
            guard !trips.isEmpty else {
                return false
            }
            let stopTimes = (self.db.stopTimes.byTripID(trips.first!.id) ?? [])
            
            //print("\(trips.count) trips for route, \(stopTimes.count) stop times")
            let startIndex = stopTimes.first(where: {stopTime in
                stopTime.stopId == from.stopId
            })?.stopSequence ?? 0
            let stopIndex = stopTimes.first(where: {stopTime in
                stopTime.stopId == to.stopId
            })?.stopSequence ?? 0
            //print(startIndex,stopIndex, route.routeShortName,  stopIndex > startIndex)
            return stopIndex > startIndex
        })
        return similarRoutes
    }
    public func arrivals(for routes: [Route], stop: Stop, at: Date = Date()) -> [StopTime] {
        let stopArrivals = self.arrivals(for: stop, at: at)
        return stopArrivals.filter({stopTime in
            return routes.contains(where: {route in
                route.routeId == self.db.trips.byTripID(stopTime.tripId)?.routeId
            })
        })
        
    }
    
    
}

public enum ArrivalGTFSError: Error {
    case failedToBuild
    case failedToReadPrebuiltData
}
