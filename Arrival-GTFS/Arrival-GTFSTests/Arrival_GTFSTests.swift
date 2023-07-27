//
//  Arrival_GTFSTests.swift
//  Arrival-GTFSTests
//
//  Created by Ronan Furuta on 7/26/23.
//

import XCTest
@testable import Arrival_GTFS

class Arrival_GTFSTests: XCTestCase {
    let agtfs = ArrivalGTFS()
   

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
      
        
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBuildGTFSData() throws {
        
        XCTAssertNoThrow(try ArrivalGTFS().build())
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    func testReadPrebuiltData() throws {
        XCTAssertNoThrow(try ArrivalGTFS().readPrebuilt())
    }
    func testRoutesByStopID() throws {
        self.agtfs.stations.forEach({stop in
            print("routes for \(stop.stopName ?? stop.stopId) starting")
            let res = (agtfs.routeIDsByStopID[stop.stopId] ?? [])
            print("Routes for \(stop.stopName ?? "ERROR") \(res.count)")
            print("res")
            XCTAssertFalse(res.isEmpty)
        })
    }
    func testGetRoutesForStop() throws {
       let testStop = agtfs.stations.randomElement()!
        print("Routes for \(testStop.stopName ?? "ERROR") starting")
        let res = agtfs.routeIDs(for: testStop)
        print("Routes for \(testStop.stopName ?? "ERROR") \(res.count)")
        XCTAssertFalse(res.isEmpty)
        
    }
    func testGetTripsForStop() throws {
       
        let res = agtfs.tripIDs(for: agtfs.stations.randomElement()!)
        
        XCTAssertFalse(res.isEmpty)
        
    }
    func testGetStopTimesForStop() throws {
       
        let res = agtfs.stopTimes(for: agtfs.stations.randomElement()!)
        
        XCTAssertFalse(res.isEmpty)
        
    }
    
    func testStopTimesByStopID() throws {
        self.agtfs.stations.forEach({stop in
            XCTAssertFalse((agtfs.stopTimesByStopID[stop.stopId] ?? []).isEmpty)
        })
    }
    
    
    
    func testGTFSBuildSpeed() {
       
        self.measure {
            try? agtfs.build()
        }
    }
    func testGTFSReadSpeed() {
        
        self.measure {
            try? agtfs.readPrebuilt()
        }
    }
    func testRoutesForStopSpeed() {
        
        self.measure {
            let _ = agtfs.routeIDs(for: agtfs.gtfs.stops.first(where: {stop in
                stop.stopId == "EMBR"
            })!)
        }
        
    }
    func testTripsForStopSpeed() {
        
        self.measure {
            let _ = agtfs.tripIDs(for: agtfs.gtfs.stops.first(where: {stop in
                stop.stopId == "EMBR"
            })!)
        }
        
    }
    func testStopTimesForStopSpeed() {
        
        self.measure {
            let _ = agtfs.stopTimes(for: agtfs.gtfs.stops.first(where: {stop in
                stop.stopId == "EMBR"
            })!)
        }
        
    }
    func testArrivalGTFSIntSpeed() {
        self.measure {
            let _ = ArrivalGTFS()
        }
    }
    func testComputedSpeed() {
        self.measure {
            agtfs.computeComputed()
        }
    }

}
