//: A Cocoa based Playground to present user interface

import Foundation
import Arrival_GTFS
  print("init")
let agtfs = ArrivalGTFS()
print(agtfs.db.stations.all.map({i in return i.stopId}))

let stopTimes = agtfs.db.stopTimes.all

func path(from: Stop, to: Stop, at: Date = Date(), stopTimes: [StopTime]) -> [Connection] {
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
   /* let first = stopTimes.firstIndex(where: {time in
        Date(bartTime: time.departureTime) > at
    }) ?? 0*/
    first = 0
    for i in first..<stopTimes.count{
        let current = stopTimes[i]
        guard current.stopSequence >= 1 else {
            continue
        }
            guard let previous = agtfs.db.stopTimes.byTripID(current.tripId)!.last(where: {time in
                time.stopSequence <= current.stopSequence - 1
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
        if log(connection) {
            print("WARM SPRINGS CONNECTION", connection.description)
        }
        //if the connection happens before the query time or the connection returns to the initial station
            if connection.startTime < at || connection.endStation == from.stopId {
                if log(connection) {
                    print("! if the connection happens before the query time or the connection returns to the initial station")
                }
                continue
            }
        //connection comes after already arriving at the destitnation station
            if let final = inConnection[to.stopId], connection.startTime > final!.endTime {
              //  print("connection comes after already arriving at the destitnation station")
                if log(connection) {
                    print("! connection comes after already arriving at the destitnation station")
                }
                break
            }
        //arrives at the station after the current best arrives there
            if let current = inConnection[connection.endStation], connection.endTime > current!.endTime {
                if log(connection) {
                    print("! arrives at the station after the current best arrives there")
                }
                continue
            }
            if connection.startStation == from.stopId {
                inConnection[connection.endStation] = connection
            } else if let previous = inConnection[connection.startStation] {
                var transferTime: TimeInterval = 60
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
                
                //if you're already on the train or the train your on arrives + a buffer before the next connection leaves
                if connection.startTime > previous!.endTime + transferTime || connection.tripID == previous!.tripID {
                    inConnection[connection.endStation] = connection
                    if log(connection) {
                        print("train or the train your on arrives + a buffer before the next connection leaves")
                    }
                } else {
                    if log(connection) {
                        print("! you're already on the train or the train your on arrives + a buffer before the next connection leaves")
                    }
                }
            } else {
               /* print(connection.description, "fell through")
                inConnection[connection.endStation] = connection*/
            }
         
        
    }
    sameStation
    noPrevious

    inConnection.count
    
    var currentStation = to.stopId
    var i = 0
    while let connection = inConnection[currentStation] {
        route.insert(connection!, at: 0)
        currentStation = connection!.startStation
        
        
        if (currentStation == from.stopId || i > inConnection.keys.count) {
           // print("done found route", i)
            break
        }
        i += 1
    }

    if route.count == 0 {
        inConnection.values.forEach({con in
            
            print(con!.description)
        })
    }
    return route
   //
}
let clock = ContinuousClock()
let startStation = agtfs.db.stations.byStopID("WARM")!
let endStation = agtfs.db.stations.byStopID("SFIA")!

func log(_ connection: Connection) -> Bool {
    //let stat = ["WARM", "FRMT", "UCTY"]
    let stat = [""]
    return stat.contains(connection.endStation)
}

func findPaths(from: Stop, to: Stop, at: Date = Date(), count: Int = 5) -> [[Connection]] {
    var at = at
    var results: [[Connection]] = []
    var i = 0
   
    var workingStopTimes: [StopTime] = stopTimes
   let indexTime = clock.measure {
       let first = workingStopTimes.firstIndex(where: {stopTime in
           Date(bartTime: stopTime.departureTime) > at
       })
       let last = workingStopTimes.firstIndex(where: {stopTime in
           Date(bartTime: stopTime.departureTime) < at + 60*60*3
       })
       workingStopTimes = Array(workingStopTimes.dropLast(workingStopTimes.count - last))
       workingStopTimes = Array(workingStopTimes.dropFirst(first - 0))
      
        workingStopTimes = workingStopTimes.filter({stopTime in
            
            inSerivce(stopTime: stopTime, at: at)
        })
    }
   print("initial pruning time", indexTime)
    print("working stoptimes count", workingStopTimes.count)
    while (i < count) {
        let time = ContinuousClock().measure {
            let first = workingStopTimes.firstIndex(where: {time in
                Date(bartTime: time.departureTime) > at
            }) ?? 0
            workingStopTimes = Array(workingStopTimes.dropFirst(first - 0))
            print("working stoptimes count", workingStopTimes.count, first)
            let res =  path(from: startStation, to: endStation, at: at, stopTimes: workingStopTimes)
            results.append(res)
            if let first = res.first?.startTime {
                at = Date(timeInterval: 60, since: first)
            } else {
                i = count
            }
            
            i += 1
        }
        print("PATH SEARCH TIME", time)
        
        
    }
    return results
}
public struct Connection: Codable {
    public let startStation: String
    public let endStation: String
    public let startTime: Date
    public let endTime: Date
    public let tripID: String
    public var routeID: String {
        agtfs.db.trips.byTripID(self.tripID)!.routeId
    }
    public var trip: Trip {
        agtfs.db.trips.byTripID(tripID)!
    }
    public  var route: Route {
        agtfs.db.routes.byRouteID(routeID)!
    }
    //let routeID: String
    public init(start: StopTime, end: StopTime) {
        self.startTime = Date(bartTime: start.departureTime)
        self.endTime = Date(bartTime: end.arrivalTime)
        self.startStation = start.stopId
        self.endStation = end.stopId
        self.tripID = start.tripId
        
    }
    public var description: String {
        return "\(self.startStation) at \(self.startTime.formatted(date: .omitted, time: .shortened)) to \(self.endStation) at \(self.endTime.formatted(date: .omitted, time: .shortened)) \(self.route.routeShortName!)"
    }
}
func inSerivce(stopTime: StopTime, at: Date) -> Bool {
    let service = agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!
    guard service.startDate < at && service.endDate > at else {
        //print("\(service.serviceId) service not currently in service")
        return false
    }
    let dow = Calendar.current.component(.weekday, from: at)
    switch dow {
        
    case 1:
        return service.sunday == .availableForAll
    case 2:
        return agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!.monday == .availableForAll
    case 3:
        return agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!.tuesday == .availableForAll
    case 4:
        return agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!.wednesday == .availableForAll
    case 5:
        return agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!.thursday == .availableForAll
    case 6:
        return agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!.friday == .availableForAll
    case 7:
        return agtfs.db.calendar.byServiceID(agtfs.db.trips.byTripID(stopTime.tripId)!.serviceId)!.saturday == .availableForAll
    default:
        return true
    }
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

var res: [[Connection]] = []
let at = Date(bartTime: "10:00:00")
print(at.formatted(date: .omitted, time: .shortened))
print("trip from", startStation.id, endStation.id)
let time = clock.measure {
   
     res = findPaths(from: startStation, to: endStation, at: at)
    /* res.sort(by: {a, b in
     return compare(a, b)
     })*/
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

print(time, "run time")

