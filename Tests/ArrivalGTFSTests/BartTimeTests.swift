//
//  BartTimeTests.swift
//  Arrival-GTFSTests
//
//  Created by Ronan Furuta on 8/8/23.
//

import Foundation
import XCTest
@testable import ArrivalGTFS
class BartTimeTests: XCTestCase {
    let agtfs = ArrivalGTFSCore()
    func testTime() throws {
        var formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "PST")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        agtfs.db.stopTimes.all.forEach({time in
            let date = Date(bartTime: time.arrivalTime)
            print(date.bayTime)
        })
       
    }
}
