//: A Cocoa based Playground to present user interface

import SwiftUI
import PlaygroundSupport
@testable import Arrival_GTFS
  
let agtfs = ArrivalGTFS()
print(agtfs.db.stations.all.map({i in return i.stopId}))



var connections: [Connection] = []
/*
let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/stopTimes.json"))
let stopTimes = try JSONDecoder().decode([StopTime].self, from: data)*/
let stopTimes = agtfs.db.stopTimes.all

func path(from: Stop, to: Stop, at: Date = Date(), stopTimes: [StopTime]) -> [Connection] {
   let db = StopTimesDB(from: stopTimes)
    var route: [Connection] = []
    
    var endTime = at + 60*60*24
    
    
    var checked: [String: Bool] = [:]
    var stopHistory: [String: [Connection]] = [:]
    var arrivalTime: [String: Date] = [:]
    agtfs.db.stations.all.forEach({station in
        checked[station.stopId] = false
        stopHistory[station.stopId] = []
        arrivalTime[station.stopId] = Date(timeInterval: 1e5, since: at)
    })
    
    arrivalTime[from.stopId] = at
    var checkStop: Stop? = from
    var minTime: Date = at
    while (true) {
       
       
        guard let checkStopVal = checkStop else {
            print("breaking off due to no stop to check")
            break
        }
       // print("checking", checkStopVal.stopId, minTime.formatted(date: .abbreviated, time: .shortened))
        db.byStopID(checkStopVal.stopId)?.forEach({stopTime in
        
            do {
                let connection = try Connection(start: stopTime)
                //print("checking connection", connection.description)
                guard connection.startTime < endTime else {
                    
                   // print("start time is not before the end time", endTime.formatted(date: .abbreviated, time: .shortened), connection.startTime.formatted(date: .abbreviated, time: .shortened))
                    return
                }
                guard connection.startTime > minTime + 120  else {
                   // print("start time is not after the min time", minTime.formatted(date: .abbreviated, time: .shortened), connection.startTime.formatted(date: .abbreviated, time: .shortened), connection.startTime > minTime)
                    return
                }
                if (connection.endTime < arrivalTime[connection.endStation] ??  Date(timeInterval: 1e10, since: at) && connection.endTime > at) {
                  //  print("improvement for", connection.description, connection.endTime.formatted(date: .abbreviated, time: .shortened))
                    arrivalTime[connection.endStation] = connection.endTime
                    var current = stopHistory[connection.startStation] ?? []
                    current.append(connection)
                    stopHistory[connection.endStation] = current
                    
                } else {
                   // print("not and improvement for \(connection.endStation)", connection.endTime.formatted(date: .abbreviated, time: .shortened), arrivalTime[checkStopVal.stopId]!.formatted(date: .abbreviated, time: .shortened))
                }
            } catch {
              //  print("Errorrrr", stopTime.stopSequence, agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(stopTime.tripId)!.routeId)!.routeShortName)
            }
            
        })
        checked[checkStopVal.stopId] = true
        arrivalTime
        stopHistory
        checked
       // print("checked off", checkStopVal.stopId)
        minTime = Date(timeInterval: 1e5, since: at)
       // print("running again", minTime.formatted(date: .abbreviated, time: .shortened))
        checkStop = nil
        agtfs.db.stations.all.forEach({stop in
           // print("should I check", stop.id)
            if checked[stop.stopId] ?? false {
             //   print("stop already checked", stop.id)
                
            } else {
                //print(minTime.formatted(date: .abbreviated, time: .shortened), arrivalTime[stop.stopId]!.formatted(date: .abbreviated, time: .shortened))
                if (minTime > arrivalTime[stop.stopId] ?? Date(timeInterval: 1e10, since: at)) {
                    minTime = arrivalTime[stop.stopId]!;
                    checkStop = stop;
                }
            }
            if (checkStop?.id == to.id) {
                checkStop = nil
            }
            
        })
        
    }
    
    if let trip = stopHistory[to.stopId] {
        print(trip: trip)
    }
    
    return route
   //
}
let clock = ContinuousClock()
let startStation = agtfs.db.stations.byStopID("ROCK")!
let endStation = agtfs.db.stations.byStopID("BALB")!

enum AError: Error {
    case error
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
    public init(end: StopTime) throws {
        guard end.stopSequence >= 1 else {
            throw AError.error
        }
        guard let tripTimes = agtfs.db.stopTimes.byTripID(end.tripId) else {
            throw AError.error
        }
       guard let previous = tripTimes.last(where: {stopTime in
            stopTime.stopSequence <= end.stopSequence - 1
       }) else {
           throw AError.error
       }
        
        self.init(start: previous, end: end)
        
    }
    public init(start: StopTime) throws {
       
        guard let tripTimes = agtfs.db.stopTimes.byTripID(start.tripId) else {
            throw AError.error
        }
       guard let end = tripTimes.first(where: {stopTime in
            stopTime.stopSequence > start.stopSequence
       }) else {
           throw AError.error
       }
        guard end.arrivalTime > start.departureTime else {
            print("ERRORRRRRR", end, start)
            var x = 0/100
            throw AError.error
        }
        self.init(start: start, end: end)
        
    }
    public var description: String {
        return "\(self.startStation) at \(self.startTime.bayTime) to \(self.endStation) at \(self.endTime.bayTime) \(self.route.routeShortName!)"
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


var res: [Connection] = []
let at = Date(bartTime: "10:00:00")
print(at.formatted(date: .omitted, time: .shortened))
let time = clock.measure {
    var stopTimes = stopTimes.filter({stop in
        inSerivce(stopTime: stop, at: at)
    })
    res = path(from: startStation, to: endStation, at: at, stopTimes: stopTimes)
 
}
   
print(trip: res)

print(time, "run time")


func print(trip: [Connection]) {
    guard trip.count >= 1 else {
        return
    }
    print("-------STARTING TRIP at \(trip.first!.startTime.formatted(date: .omitted, time: .shortened)) with \(trip.count) LEGS arrives at \(trip.last!.endTime.formatted(date: .omitted, time: .shortened))--------")
    trip.forEach({con in
        print(con.description)
    })
    print("-------ENDING TRIP with \(trip.count) LEGS--------")
}
