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
    
    public var db: GTFSDB
    public var defaultResultLength: Int = 15
    
    public init() {
        let data = try! Data(contentsOf: dbCachePath)
        self.db = try! JSONDecoder().decode(GTFSDB.self, from: data)
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
    
    
    public func trains(for stop: Stop, at: Date = Date()) -> [StopTime] {
        guard let stopTimes = self.db.stopTimes.byStopID[stop.stopId] else {
            return []
        }
        print("got \(stopTimes.count) stops at \(stop.stopName)")
        guard let firstIndex = stopTimes.firstIndex(where: {stopTime in
            //print(stopTime.arrivalTime.formatted(), "vs", at.formatted() )
            return stopTime.arrivalTime >= at
        }) else {
            return []
        }
        print("first index \(firstIndex) \(stopTimes[firstIndex ?? 0])")
        let selectedStopTimes = stopTimes[firstIndex..<firstIndex + defaultResultLength]
        print("found \(selectedStopTimes.count) stops")
        return stopTimes
        
    }
    
    
}

public enum ArrivalGTFSError: Error {
    case failedToBuild
    case failedToReadPrebuiltData
}
