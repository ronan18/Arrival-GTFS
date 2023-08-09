import Cocoa
import PlaygroundSupport
@testable import Arrival_GTFS
import Foundation

let agtfs = ArrivalGTFS()
print(agtfs.db.stations.all.map({i in return i.stopId}))
let stopTimes = agtfs.db.stopTimes.all

func path(from: Stop, to: Stop, at: Date = Date(), stopTimes: [StopTime]) -> [Connection] {
    var route: [Connection] = []
    var timeToStops: [String: Date] = [:]
    var connections: [String: [Connection]] = [:]
    var improved: [String] = [from.stopId]
    timeToStops[from.stopId] = at
    
    var transferLimit = 5
    
    for k in 1..<transferLimit + 1 {
        let time = clock.measure {
            print("TRANSFER LIMIT ROUND", k, improved)
            
            var stopIDs = timeToStops.keys.filter({stopid in
                return improved.contains(stopid)
               // return true
            })
            improved = []
            print("initial qualifying stop ids count", stopIDs.count)
            for refStop in stopIDs {
                var baselineCost = timeToStops[refStop]
                var potentialTrips = agtfs.arrivals(for: agtfs.db.stations.byStopID(refStop)!, at: timeToStops[refStop]!).map({i in return i.tripId})
                for potentialTrip in potentialTrips {
                    var stopTimesSub = agtfs.db.stopTimes.byTripID(potentialTrip)!
                    var fromHereIndex = stopTimesSub.firstIndex(where: {time in
                        time.stopId == refStop
                    })!
                    for i in (fromHereIndex + 1)..<stopTimesSub.count {
                        let stopTime = stopTimesSub[i]
                        if let bestDestTime = timeToStops[to.stopId] {
                            
                            if Date(bartTime: stopTime.arrivalTime) > bestDestTime {
                                print("arrives at stop after the best arrival time", bestDestTime.bayTime)
                                continue
                               // print("check")
                            }
                        }
                        if let current = timeToStops[stopTime.stopId] {
                            if (current > Date(bartTime: stopTime.arrivalTime)) {
                                let connection = Connection(start: stopTimesSub[i - 1], end: stopTime)
                                timeToStops[stopTime.stopId] = Date(bartTime: stopTime.arrivalTime)
                               var currentC = connections[connection.startStation] ?? []
                                currentC.append(connection)
                                connections[connection.endStation] = currentC
                                improved.append(stopTime.stopId)
                            }
                        } else {
                            let connection = Connection(start: stopTimesSub[i - 1], end: stopTime)
                            timeToStops[stopTime.stopId] = Date(bartTime: stopTime.arrivalTime)
                            var currentC = connections[connection.startStation] ?? []
                             currentC.append(connection)
                             connections[connection.endStation] = currentC
                            improved.append(stopTime.stopId)
                        }
                        
                    }
                }
            }
        }
        print("ran round", k,"in", time)
        if let res = timeToStops[to.stopId] {
            print("arrive at", to.stopId, "at", res.bayTime)
            print("start at", from.stopId, "at", timeToStops[from.stopId]!.bayTime )
            timeToStops
            connections
           // let trip = connections[to.stopId]!
           // print(trip: trip)
            route = connections[to.stopId]!
            break
            
        }
        
    }
    timeToStops
    //var inConnection: [String: Connection?] = [:]
   
    return route
   //
}


func trip(from: Stop, to: Stop, inConnection: [String: Connection]) -> [Connection] {
    var route: [Connection] = []
    var currentStation = to.stopId
    var i = 0
    while let connection = inConnection[currentStation] {
        route.insert(connection, at: 0)
        currentStation = connection.startStation
        
        
        if (currentStation == from.stopId || i > inConnection.keys.count) {
           // print("done found route", i)
            break
        }
        i += 1
    }
    return route
}

let clock = ContinuousClock()
let startStation = agtfs.db.stations.byStopID("SFIA")!
let endStation = agtfs.db.stations.byStopID("OAKL")!
let at = Date(bartTime: "10:00:00")
let workingTimes = stopTimes.filter({time in
    return inSerivce(stopTime: time, at: at )
})
var res: [Connection] = []
let time = clock.measure {
   
    res = path(from: startStation, to: endStation, at: at, stopTimes: workingTimes)
    /* res.sort(by: {a, b in
     return compare(a, b)
     })*/
}
print(trip: res)

print(time, "run time")





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
        return "\(self.startStation) at \(self.startTime.bayTime) to \(self.endStation) at \(self.endTime.bayTime) \(self.route.routeShortName!) \(self.tripID)"
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
func print(trip: [Connection]) {
    guard trip.count >= 1 else {
        return
    }
    print("-------STARTING TRIP at \(trip.first!.startTime.bayTime) with \(trip.count) LEGS arrives at \(trip.last!.endTime.bayTime)--------")
    trip.forEach({con in
        print(con.description)
    })
    print("-------ENDING TRIP with \(trip.count) LEGS--------")
}
