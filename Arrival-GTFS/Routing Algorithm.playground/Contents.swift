//: A Cocoa based Playground to present user interface
import Cocoa
import SwiftUI
import PlaygroundSupport
@testable import Arrival_GTFS
  
let agtfs = ArrivalGTFS()
print(agtfs.db.stations.all.map({i in return i.stopId}))


struct Connection: Codable {
    let startStation: String
    let endStation: String
    let startTime: Date
    let endTime: Date
    let tripID: String
    var routeID: String {
        agtfs.db.trips.byTripID(self.tripID)!.routeId
    }
    var trip: Trip {
        agtfs.db.trips.byTripID(tripID)!
    }
    var route: Route {
        agtfs.db.routes.byRouteID(routeID)!
    }
    //let routeID: String
    init(start: StopTime, end: StopTime) {
        self.startTime = Date(bartTime: start.departureTime)
        self.endTime = Date(bartTime: end.arrivalTime)
        self.startStation = start.stopId
        self.endStation = end.stopId
        self.tripID = start.tripId
        
    }
    var description: String {
        return "\(self.startStation) at \(self.startTime.formatted(date: .omitted, time: .shortened)) to \(self.endStation) at \(self.endTime.formatted(date: .omitted, time: .shortened)) \(self.route.routeShortName!)"
    }
}

var connections: [Connection] = []
let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/stopTimes.json"))
let stopTimes = try JSONDecoder().decode([StopTime].self, from: data)
/*let stopTimes = agtfs.db.stopTimes.all.sorted(by: {a,b in
    a.departureTime < b.departureTime
})
let data = try! JSONEncoder().encode(stopTimes)
try! data.write(to: URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/stopTimes.json"))
*/
func path(from: Stop, to: Stop, at: Date = Date()) -> [Connection] {
    var route: [Connection] = []
    var arrivalTimestamp: [String: Date] = [:]
    var inConnection: [String: Connection?] = [:]
    agtfs.db.stations.all.forEach({station in
        arrivalTimestamp[station.id] = Date(timeIntervalSinceNow: 1e10)
        inConnection[station.id] = nil
    })
    arrivalTimestamp[from.stopId] = at
    var sameStation: [String] = []
    var noPrevious: [StopTime] = []
    let first = stopTimes.firstIndex(where: {time in
        Date(bartTime: time.departureTime) > at
    }) ?? 0
    
    print("first index", first)
    for i in first..<stopTimes.count{
        let current = stopTimes[i]
        guard current.stopSequence >= 1 else {
            continue
        }
            guard let previous = agtfs.db.stopTimes.byTripID(current.tripId)!.first(where: {time in
                time.stopSequence == current.stopSequence - 1
            }) else {
              //  print("No previous", current.stopSequence)
                noPrevious.append(current)
                continue
            }
            let connection = Connection(start: previous, end: current)
            if (connection.startStation == connection.endStation) {
              //  print("ERROR", connection.description, current.stopSequence, previous.stopSequence)
                sameStation.append("\(connection.description), \(current.stopSequence), \(previous.stopSequence)")
               
            }
            if connection.startTime < at || connection.endStation == from.stopId {
                continue
            }
            if let final = inConnection[to.stopId], connection.startTime > final!.endTime {
                break
            }
            if let current = inConnection[connection.endStation], connection.endTime > current!.endTime {
                continue
            }
            if connection.startStation == from.stopId {
                inConnection[connection.endStation] = connection
            } else if let previous = inConnection[connection.startStation] {
                var transferTime: TimeInterval = 120
                if let transfers = agtfs.db.transfers.byStopID(connection.startStation) {
                   if let transfer = transfers.first(where: {transfer in
                        return transfer.toRouteID == connection.routeID && transfer.fromRouteID == previous!.routeID
                   }) {
                       //print("TRANSFER FOUND \(connection.startStation) from \(previous!.routeID) to \(connection.routeID)", transfer.minTransferTime)
                       transferTime = Double(transfer.minTransferTime ?? 20 )
                   } else {
                       if let transfer = transfers.first(where: {transfer in
                            return transfer.toRouteID == "" && transfer.fromRouteID == ""
                       }) {
                         //  print("DEFAULT TRANSFER FOUND \(connection.startStation)", transfer.minTransferTime)
                           transferTime = Double(transfer.minTransferTime ?? 20 )
                       }
                   }
                }
                
                if connection.startTime > previous!.endTime + transferTime || connection.tripID == previous!.tripID {
                    inConnection[connection.endStation] = connection
                }
            }
            /*
            if (arrivalTimestamp[connection.startStation]! < connection.startTime && arrivalTimestamp[connection.endStation]! > connection.endTime) {
                arrivalTimestamp[connection.endStation] = connection.endTime
                inConnection[connection.endStation] = connection
               
            }*/
        
    }
    sameStation
    noPrevious
  //  print(arrivalTimestamp)
    inConnection.count
    
    //print(inConnection)
    //print(skipped, logged)
    var currentStation = to.stopId
    //print(inConnection)
    var i = 0
    while let connection = inConnection[currentStation] {
        route.insert(connection!, at: 0)
        currentStation = connection!.startStation
        
        
        if (currentStation == from.stopId || i > inConnection.keys.count) {
            print("done found route", i)
            break
        }
        i += 1
    }
    print(route.map({route in
        return route.description
    }))
    /*inConnection.values.forEach({con in
        
        print(con!.description)
    })*/
    return route
   //
}
let clock = ContinuousClock()
let startStation = agtfs.db.stations.byStopID("ASHB")!
let endStation = agtfs.db.stations.byStopID("DALY")!

func findPaths(from: Stop, to: Stop, at: Date = Date(), count: Int = 5) -> [[Connection]] {
    var at = at
    var results: [[Connection]] = []
    var i = 0
    while (i < count) {
        let res =  path(from: startStation, to: endStation, at: at)
        results.append(res)
        if let first = res.first?.startTime {
            at = Date(timeInterval: 60, since: first)
        } else {
            i = count
        }
        
        i += 1
    }
    return results
}
func compare(_ a: [Connection], _ b: [Connection]) -> Bool {
    var aScore = 0
    var bScore = 0
    
    if (a.first!.startTime > b.first!.startTime) {
        aScore += 1
    } else {
        bScore += 1
    }
    
    if (a.last!.endTime < b.last!.endTime) {
        aScore += 1
    } else {
        bScore += 1
    }
    
    return aScore > bScore
}
/*
  f
let time = clock.measure {
    let at = Date(bartTime: "10:00")
    print(at.formatted(date: .omitted, time: .shortened))
    let firstPath = path(from: startStation, to: endStation, at: at)
    if let firstTime = firstPath.first?.startTime {
        path(from: startStation, to: endStation, at: Date(timeInterval: 60, since: firstTime))
    }
}*/
let time = clock.measure {
    let at = Date(bartTime: "10:00")
    print(at.formatted(date: .omitted, time: .shortened))
    var res = findPaths(from: startStation, to: endStation, at: at)
   res.sort(by: {a, b in
       return compare(a, b)
    })
 
    res.forEach({trip in
        print("-------STARTING TRIP at \(trip.first!.startTime.formatted(date: .omitted, time: .shortened)) with \(trip.count) LEGS arrives at \(trip.last!.endTime.formatted(date: .omitted, time: .shortened))--------")
        trip.forEach({con in
            print(con.description)
        })
        print("-------ENDING TRIP with \(trip.count) LEGS--------")
    })
}
print(time, "run time")
