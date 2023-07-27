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

    func testTrainsForStop() throws {
        let res = agtfs.trains(for: agtfs.db.stations.byStopID["EMBR"]!)
        XCTAssertFalse(res.isEmpty)
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
