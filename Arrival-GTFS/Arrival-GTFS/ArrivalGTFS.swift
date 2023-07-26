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
    public var gtfs: GTFS
    public init() {
       // print("AGTFS Init")
        let data = try! Data(contentsOf: cachePath)
        self.gtfs = try! JSONDecoder().decode(GTFS.self, from: data)
    }
    public func readPrebuilt() throws {
        do {
            let data = try Data(contentsOf: cachePath)
            self.gtfs = try JSONDecoder().decode(GTFS.self, from: data)
        } catch {
            throw ArrivalGTFSError.failedToBuild
        }
    }
    public func build() throws {
        do {
            self.gtfs = try GTFS(path: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/google_transit_20230213-20230813_v7")
            //print("built gtfs", gtfs, gtfs.routes)
            let data = try JSONEncoder().encode(gtfs)
           
            do {
                try data.write(to: cachePath)
            }
            catch {
                print("Failed to write JSON data: \(error.localizedDescription)")
            }
        } catch {
           // print("error", error)
            throw ArrivalGTFSError.failedToBuild
        }
        
        
    }
    public func routes(for stop: Stop) -> [Route] {
        var routesForStop: [Route] = []
        gtfs.stopTimes.forEach({stopTime in
            guard stopTime.stopId == stop.stopId else {
                return
            }
             guard let trip = gtfs.trips.filter({trip in
                trip.tripId == stopTime.tripId
             }).first else {
                 return
             }
                   
            if !routesForStop.contains(where: {route in
                return route.routeId == trip.routeId
            }) {
                if let route = self.gtfs.routes.first(where: {route in
                    route.routeId == trip.routeId
                }) {
                    routesForStop.append(route)
                }
            }
        })

        
        return routesForStop
    }
 
    
}

public enum ArrivalGTFSError: Error {
    case failedToBuild
    case failedToReadPrebuiltData
}
