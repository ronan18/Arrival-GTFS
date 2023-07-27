//
//  ArrivalGTFSDBTests.swift
//  Arrival-GTFSTests
//
//  Created by Ronan Furuta on 7/27/23.
//

import Foundation
import XCTest
@testable import Arrival_GTFS

class Arrival_GTFSDBTests: XCTestCase {
    private let cachePath = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/google_transit_20230213-20230813_v7.json")
    var gtfs: GTFS?
    var db: GTFSDB?
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        do {
            let data = try Data(contentsOf: cachePath)
            self.gtfs = try JSONDecoder().decode(GTFS.self, from: data)
            self.db = GTFSDB(from: gtfs!)
        } catch {
            
        }
        
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testDBInitializer() throws {
        let db = GTFSDB(from: gtfs!)
        XCTAssertFalse(db.trips.all.isEmpty)
        let tripsForLake = (db.trips.byStopID["LAKE"]) ?? []
        XCTAssertFalse(tripsForLake.isEmpty)
        
        let data = try? JSONEncoder().encode(db)
        
        try? data?.write(to: URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/db.json"))
        
        
    }
    func testDBIntalizerSpeed() {
        self.measure {
            let _ = GTFSDB(from: gtfs!)
        }
    }
    func testTripsDBSpeed() {
        self.measure {
            var tripsDB = TripsDB(from: self.gtfs!.trips, stopTimes: self.gtfs!.stopTimes)
           
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
