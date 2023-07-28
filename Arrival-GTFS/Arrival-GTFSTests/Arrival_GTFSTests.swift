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
        XCTAssertNoThrow(try agtfs.readPrebuilt())
    }
    func testGTFSRTFetch() async throws {
          try await self.agtfs.getGTFSRT()
          
      
    }
    func testArrivalsForStop() throws {
        let date = Date()
        self.agtfs.db.stations.all.forEach({
            station in
            let res = agtfs.arrivals(for: station, at: date)
            XCTAssertFalse(res.isEmpty)
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "PST")
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            res.forEach({arrival in
                let condition = Date(bartTime: arrival.arrivalTime) <= date
                if (condition) {
                    print(arrival.arrivalTime, dateFormatter.string(from: Date(bartTime: arrival.arrivalTime)), "vs",  dateFormatter.string(from:date))
                  //  print(arrival.stopSequence, arrival.tripId, self.agtfs.db.stopTimes.byTripID[arrival.tripId]!)
                }
                XCTAssertFalse(condition)
            })
            
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

}
