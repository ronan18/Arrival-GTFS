//
//  ArrivalGTFSDBTests.swift
//  Arrival-GTFSTests
//
//  Created by Ronan Furuta on 7/27/23.
//

import Foundation
import XCTest
@testable import ArrivalGTFS

class Arrival_GTFSDBTests: XCTestCase {
    private let cachePath = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/RonanFuruta/ios/Arrival/Arrival-GTFS/Sources/ArrivalGTFS/db/google_transit_lts.json")
    var gtfs: GTFS?
    var db: GTFSDB?
    override func setUpWithError() throws {
        
        if self.gtfs == nil || self.db == nil{
            do {
                self.gtfs = try GTFS(path: "/Users/ronanfuruta/Desktop/Dev/RonanFuruta/ios/Arrival/Arrival-GTFS/Sources/ArrivalGTFS/db/google_transit_lts")
                print("built gtfs", gtfs, gtfs!.routes.count)
                
                let data = try JSONEncoder().encode(gtfs)
                
                do {
                    try data.write(to: cachePath)
                    print("cached gtfs data files as json")
                }
                catch {
                    print("Failed to write JSON data: \(error.localizedDescription)")
                }
                self.db = .init(from: gtfs!)
                print("built DB")
                return
            } catch {
                 print("error", error)
                throw ArrivalGTFSError.failedToBuild
            }
        }
        return
        
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testDBInitializer() throws {
        print("test DB Intalizer")
        let db = GTFSDB(from: GTFS())
        XCTAssertFalse(db.trips.all.isEmpty)
        let tripsForLake = (db.trips.byStopID("LAKE")) ?? []
        XCTAssertFalse(tripsForLake.isEmpty)
        
        let data = try JSONEncoder().encode(db)
        
        try data.write(to: URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/RonanFuruta/ios/Arrival/Arrival-GTFS/Sources/ArrivalGTFS/db/db.json"))
        let bcf = ByteCountFormatter()
               bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
               bcf.countStyle = .file
               let size = bcf.string(fromByteCount: Int64(data.count))
        
        print("cached db to json", size)
        
       // try saveDBToFile(db)
        
        
        
    }
    func testdepartureHourTest() throws {
        let db = StopTimesDB(from: self.gtfs!.stopTimes)
        let initialByHour = db.byDepartureHour("10")
        initialByHour.forEach({i in
            XCTAssertEqual(i.departureTime.prefix(2), "10")
            print(i.departureTime)
        })
    }
    
    func testTransfersDB() throws {
        let db = TransfersDB(from: self.gtfs!.transfers!)
        print(db.byStopID("MCAR"))
    }
    
    func testStationsDB() throws {
        let db = StationsDB(from: self.gtfs!.stops)
        self.gtfs!.stops.forEach({stop in
            if stop.locationType == .stop {
                XCTAssertEqual(stop, db.byStopID(stop.stopId))
                XCTAssertTrue(db.all.contains(stop))
            } else {
                XCTAssertFalse(db.all.contains(stop))
                XCTAssertTrue(db.byStopID(stop.stopId) == nil)
            }
            
        })
        let data = try JSONEncoder().encode(db)
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB] // optional: restricts the units to MB only
               bcf.countStyle = .file
               let size = bcf.string(fromByteCount: Int64(data.count))
        
        print("stations db", size)
    }
    
    func testStopTimesDB() throws {
        print("testing stop times DB")
        let db = StopTimesDB(from: self.gtfs!.stopTimes)
        var i = 0
       self.db!.stations.all.forEach({station in
            i += 1
            //print("testing stoptimes by stop id for \(station.stopId)")
            let stopTimesForStation = self.gtfs!.stopTimes.filter({stopTime in
                return stopTime.stopId == station.stopId
            }).sorted(by: { a, b in
                a.stopSequence < b.stopSequence
            })
           
           print("got \(stopTimesForStation.count) stop times vs \(db.byStopID(station.stopId)!.count) indexed for \(station.stopId)")
          // print("equal", stopTimesForStation == db.byStopID[station.stopId]!)
          // print(stopTimesForStation.hashValue, db.byStopID.hashValue)
            print("by stopID \(i)/\(self.db!.stations.all.count)")
           XCTAssertEqual(stopTimesForStation, db.byStopID(station.stopId)!)
        })
        i = 0
        self.db!.trips.all.forEach({trip in
            i += 1
            
           // print("testing stoptimes by trip id for \(trip.tripHeadsign ?? "error")")
            let stopTimesForTrip = self.gtfs!.stopTimes.filter({stopTime in
                return stopTime.tripId == trip.tripId
            }).sorted(by: { a, b in
                a.stopSequence < b.stopSequence
            })
            //print("got \(stopTimesForTrip.count) stop times vs \(db.byTripID[trip.tripId]!.count) indexed")
            print("by trip ID \(i)/\(self.db!.trips.all.count)")
            XCTAssertEqual(stopTimesForTrip, db.byTripID(trip.tripId)!)
        })
        let data = try JSONEncoder().encode(db)
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB] // optional: restricts the units to MB only
               bcf.countStyle = .file
               let size = bcf.string(fromByteCount: Int64(data.count))
        
        print("stop times db", size)
    }
    
    func testTripsDB() throws {
        let db = TripsDB(from: self.gtfs!.trips, stopTimes: self.gtfs!.stopTimes)
        
        XCTAssertEqual(db.all, self.gtfs!.trips)
        self.gtfs!.trips.forEach({trip in
            XCTAssertEqual(db.byTripID(trip.tripId), trip)
        })
        self.db!.stations.all.forEach {station in
            let dbTripsForStop = db.byStopID(station.stopId)
            let filtered = self.gtfs!.stopTimes.filter({stopTime in
                return stopTime.stopId == station.stopId
            })
            let result = filtered.map({stopTime in
                return db.byTripID(stopTime.tripId)!
            })
            XCTAssertEqual(dbTripsForStop, result)
        }
        let data = try JSONEncoder().encode(db)
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB] // optional: restricts the units to MB only
               bcf.countStyle = .file
               let size = bcf.string(fromByteCount: Int64(data.count))
        
        print("trips db", size)
    }
    
    func testRoutesDB() throws {
        let db = RoutesDB(from: self.gtfs!.routes, trips: self.db!.trips, stations: self.db!.stations)
        XCTAssertEqual(db.all, self.gtfs!.routes)
        self.gtfs!.routes.forEach({route in
            XCTAssertEqual(db.byRouteID(route.routeId), route)
        })
        self.db!.stations.all.forEach({station in
            let dbResult = db.byStopID(station.stopId)!
            
            let stopTimesForStation = self.gtfs!.stopTimes.filter({stopTime in
                return stopTime.stopId == station.stopId
            })
            stopTimesForStation.forEach({stopTime in
                let trip = self.db!.trips.byTripID(stopTime.tripId)!
                let route = db.byRouteID(trip.routeId)
                XCTAssertTrue(dbResult.contains(route!))
            })
            
        })
        let data = try JSONEncoder().encode(db)
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB] // optional: restricts the units to MB only
               bcf.countStyle = .file
               let size = bcf.string(fromByteCount: Int64(data.count))
        
        print("routes db", size)
    }
    func testDBSizes() throws {
        let routesDB = try getSize(RoutesDB(from: self.gtfs!.routes, trips: self.db!.trips, stations: self.db!.stations))
        let tripsDB = try getSize(TripsDB(from: self.gtfs!.trips, stopTimes: self.gtfs!.stopTimes))
        let stopTimesDB = try getSize(StopTimesDB(from: self.gtfs!.stopTimes))
        let stationDB = try getSize(StationsDB(from: self.gtfs!.stops))
        let db = try getSize(self.db!)
        
        print(routesDB,tripsDB,stopTimesDB, stationDB, db)
        
        
        
    }
    func getSize(_ data: Codable) throws -> String {
        let data = try JSONEncoder().encode(data)
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB] // optional: restricts the units to MB only
               bcf.countStyle = .file
               let size = bcf.string(fromByteCount: Int64(data.count))
        return size
        
    }
    
    func testDBIntalizerSpeed() {
        self.measure {
            let _ = GTFSDB(from: gtfs!)
        }
    }
    func testTripsDBSpeed() {
        self.measure {
            var _ = TripsDB(from: self.gtfs!.trips, stopTimes: self.gtfs!.stopTimes)
           
        }
    }
    func testStopTimesDBSpeed() {
        self.measure {
            var _ = StopTimesDB(from: self.gtfs!.stopTimes)
        }
    }
    func testRoutesDBSpeed() {
        let tripsDB = TripsDB(from: self.gtfs!.trips, stopTimes: self.gtfs!.stopTimes)
        let stationsDB = StationsDB(from: self.gtfs!.stops)
        self.measure {
            let _ = RoutesDB(from: self.gtfs!.routes, trips: tripsDB, stations: stationsDB)
        }
    }
    func testStationsDBSpeed() {
        self.measure {
            let _ = StationsDB(from: self.gtfs!.stops)
        }
    }
}
