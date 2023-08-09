//
//  RoutingTests.swift
//  Arrival-GTFSTests
//
//  Created by Ronan Furuta on 8/9/23.
//

import Foundation
import XCTest
@testable import ArrivalGTFS
class RoutingTests: XCTestCase {
    let agtfs = ArrivalGTFS()
   
    let at = Date(bartTime: "10:00:00")
    func testAllPossibleRoutes() throws {
        let at = at
        DispatchQueue.concurrentPerform(iterations: agtfs.db.stations.all.count - 1) { (index) in
             print("current: \(index)")
            let startStation = agtfs.db.stations.all[index]
            print("----- startiing \(startStation.stopId) ---------")
            DispatchQueue.concurrentPerform(iterations: agtfs.db.stations.all.count - 1) { (index) in
                Task {
                    let endStation = agtfs.db.stations.all[index]
                    guard startStation != endStation else {
                        return
                    }
                    
                    var workingStopTimes: [StopTime] = agtfs.db.stopTimes.all
                    
                    let first = workingStopTimes.firstIndex(where: {stopTime in
                        Date(bartTime: stopTime.departureTime) > at
                    }) ?? 0
                    let last = workingStopTimes.lastIndex(where: {stopTime in
                        Date(bartTime: stopTime.departureTime) > at + 60*60*3
                    }) ?? 0
                    //  print("first index", first, "last index", last)
                    workingStopTimes = Array(workingStopTimes.dropLast(workingStopTimes.count - last))
                    workingStopTimes = Array(workingStopTimes.dropFirst(first - 0))
                    
                    workingStopTimes = workingStopTimes.filter({stopTime in
                        
                        self.agtfs.inSerivce(stopTime: stopTime, at: at)
                    })
                    var res: [Connection] = []
                    
                    
                    res = await agtfs.path(from: startStation, to: endStation, at: at, stopTimes: workingStopTimes)
                    
                    
                    
                    print("\(startStation.stopId) to \(endStation.stopId) \(res.count)", time)
                    XCTAssertFalse(res.isEmpty)
                }
            }
            print("----- finishing \(startStation.stopId) ---------")
        }
       
            
        
    }
    func testOneOptionSpeed() {
        var at = at
        let startStation = agtfs.db.stations.byStopID("WARM")!
        let endStation = agtfs.db.stations.byStopID("SFIA")!
        var workingStopTimes: [StopTime] = agtfs.db.stopTimes.all
   
           let first = workingStopTimes.firstIndex(where: {stopTime in
               Date(bartTime: stopTime.departureTime) > at
           }) ?? 0
           let last = workingStopTimes.lastIndex(where: {stopTime in
               Date(bartTime: stopTime.departureTime) > at + 60*60*3
           }) ?? 0
         //  print("first index", first, "last index", last)
           workingStopTimes = Array(workingStopTimes.dropLast(workingStopTimes.count - last))
           workingStopTimes = Array(workingStopTimes.dropFirst(first - 0))
          
            workingStopTimes = workingStopTimes.filter({stopTime in
                
                self.agtfs.inSerivce(stopTime: stopTime, at: at)
            })
        
        var res: [Connection] = []
        self.measure {
            Task {
                res = await agtfs.path(from: startStation, to: endStation, at: at, stopTimes: workingStopTimes)
            }
        }
        print(trip: res)
    }
    func testFourOptionsSpeed() {
        var res: [[Connection]] = []
        let startStation = agtfs.db.stations.byStopID("WARM")!
        let endStation = agtfs.db.stations.byStopID("SFIA")!
        self.measure {
            Task {
                res = await agtfs.findPaths(from: startStation, to: endStation, at: at)
            }
        }
        res.forEach({trip in
            guard trip.count >= 1 else {
                return
            }
            print("-------STARTING TRIP at \(trip.first!.startTime.formatted(date: .omitted, time: .shortened)) with \(trip.count) LEGS arrives at \(trip.last!.endTime.formatted(date: .omitted, time: .shortened))--------")
            trip.forEach({con in
                print(con.description)
            })
            print("-------ENDING TRIP with \(trip.count) LEGS--------")
        })
    }
}
