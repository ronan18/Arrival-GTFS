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
    
    public var stations: [Stop] = []
    public var stationByStopID: [String: Stop] = [:]
    
    public var stopTimesByStopID: [String: [StopTime]] = [:]
    public var stopTimeIDsByTripID: [String: [String]] = [:]
    
    public var tripsByTripID: [String: Trip] = [:]
    public var tripIDsByStopID: [String: [String]] = [:]

    
    public var routeByID: [String: Route] = [:]
    public var routeIDsByStopID: [String: [String]] = [:]

    
    public init() {
        let data = try! Data(contentsOf: cachePath)
        self.gtfs = try! JSONDecoder().decode(GTFS.self, from: data)
        print("AGTFS INIT trips: \(gtfs.trips.count) agencies: \(gtfs.agencies.count) stops: \(gtfs.stops.count) routes: \(gtfs.routes.count), stopTimes: \(gtfs.stopTimes.count)")
        self.computeComputed()
    }
    
    public func readPrebuilt() throws {
        do {
            let data = try Data(contentsOf: cachePath)
            self.gtfs = try JSONDecoder().decode(GTFS.self, from: data)
            self.computeComputed()
        } catch {
            throw ArrivalGTFSError.failedToBuild
        }
    }
    public func build() throws {
        do {
            self.gtfs = try GTFS(path: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/google_transit_20230213-20230813_v7")
            //print("built gtfs", gtfs, gtfs.routes)
            self.computeComputed()
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
    
    func computeComputed() {
        print("starting statistics compute")
        let startDate = Date()
        var timerDate = Date()
        
        //MARK: Route by ID
        self.gtfs.routes.forEach({route in
            routeByID[route.routeId] = route
        })
        print("computed \(self.routeByID.count) routes by id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        //MARK: Stations
        self.stations = gtfs.stops.filter({stop in
            return stop.locationType == .stop
        })
        self.stations.forEach {station in
            self.stationByStopID[station.stopId] = station
        }
        print("computed \(self.stations.count) stations in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        //MARK: Stop times by stop id
        var stopTimesByStopIDCompute: [String: [StopTime]] = [:]
        self.stations.forEach({stop in
            let stopTimes = self.stopTimes(for: stop)
            stopTimesByStopIDCompute[stop.stopId] = stopTimes
            self.tripIDsByStopID[stop.stopId] = self.tripIDs(for: stop)
        })
        self.stopTimesByStopID = stopTimesByStopIDCompute
        print("computed \(self.stopTimesByStopID.count) stop times by id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        //MARK: Stop time id by trip id
        self.gtfs.stopTimes.forEach({stopTime in
            if var current = self.stopTimeIDsByTripID[stopTime.tripId] {
                self.stopTimeIDsByTripID[stopTime.tripId] = [stopTime.stopId] + current
            } else {
                self.stopTimeIDsByTripID[stopTime.tripId] = [stopTime.stopId]
            }
        })
        print("computed \(self.stopTimeIDsByTripID.count) stop times by trip id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        //MARK: Trips by trip ids
        self.gtfs.trips.forEach({trip in
            self.tripsByTripID[trip.tripId] = trip
         
        })
        print("computed \(self.tripsByTripID.count) trips by id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
    }
    
    
    
   /* func computeComputed() {
        print("starting statistics compute")
        let startDate = Date()
        var timerDate = Date()
        //MARK: Route by ID
        self.gtfs.routes.forEach({route in
            routeByID[route.routeId] = route
        })
        print("computed \(self.routeByID.count) routes by id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        //MARK: Stations
        self.stations = gtfs.stops.filter({stop in
            return stop.locationType == .stop
        })
        print("computed \(self.stations.count) stations in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        //MARK: Stop times by stop id
        var stopTimesByStopIDCompute: [String: [StopTime]] = [:]
        self.stations.forEach({stop in
            let stopTimes = self.stopTimes(for: stop)
            stopTimesByStopIDCompute[stop.stopId] = stopTimes
            //print("Stoptimes for \(stop.stopName ?? "ERROR") \(stopTimes.count)")
        })
        self.stopTimesByStopID = stopTimesByStopIDCompute
        print("computed \(self.stopTimesByStopID.count) stop times by id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        
        //MARK: tripsByStopID
        var tripsByStopID: [String: [Trip]] = [:]
        self.stations.forEach({stop in
            let trips = self.trips(for: stop)
            tripsByStopID[stop.stopId] = trips
            //print("Stoptimes for \(stop.stopName ?? "ERROR") \(stopTimes.count)")
        })
        self.tripsByStopID = tripsByStopID
        print("computed \(self.tripsByStopID.count) trips by stop id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        
        //MARK: routesByStopID
        var routesByStopID: [String: [Route]] = [:]
        self.stations.forEach({stop in
            let routes = self.routes(for: stop)
            routesByStopID[stop.stopId] = routes
            //print("Stoptimes for \(stop.stopName ?? "ERROR") \(stopTimes.count)")
        })
        self.routesByStopID = routesByStopID
        print("computed \(self.routeByID.count) routes by id in \(timerDate.timeIntervalSinceNow)")
        timerDate = Date()
        
        
        print("computed in \(startDate.timeIntervalSinceNow)")
    }
  */

    public func routeIDs(for stop: Stop) -> [String] {
        let date = Date()
        var routesForStop: [String] = []
        //print("getting routes for \(stop.stopId)")
        let trips = tripIDsByStopID[stop.stopId] ?? []
        
     
        trips.forEach({trip in
            if let trip = tripsByTripID[trip] {
                routesForStop.append(trip.routeId)
            }
            
            
        })
     
        return routesForStop
    }
    public func tripIDs(for stop: Stop) -> [String] {
        let startDate = Date()
       // print("getting trips for", stop.stopId)
        var trips: [String] = []
        let stopTimes = stopTimesByStopID[stop.stopId] ?? []
       // print("got \(stopTimes.count) stops at \(stop.stopId)")
        stopTimes.forEach({stopTime in
           // print(stopTime.tripId)
            trips.append(stopTime.tripId)
        })
        /*
        trips = gtfs.trips.filter({trip in
          return stopTimes.contains(where: {stopTime in
                
                stopTime.tripId == trip.tripId
            })
        })*/
       // print(trips.randomElement() ?? nil)
        print("got \(trips.count) trips for \(stop.stopName ?? stop.stopId) in \(startDate.timeIntervalSinceNow)")
        
        return trips
    }
    public func stopTimes(for stop: Stop) -> [StopTime] {
      //  print("getting stopTimes for", stop.stopId)
      
       let stopTimes = gtfs.stopTimes.filter({stopTime in
            return stopTime.stopId == stop.stopId
                   
        })
      
       // print(stopTimes.randomElement() ?? nil)
       // print("got \(stopTimes.count) stop times for \(stop.stopName ?? stop.stopId)")
        
        return stopTimes
    }
 
    
}

public enum ArrivalGTFSError: Error {
    case failedToBuild
    case failedToReadPrebuiltData
}
