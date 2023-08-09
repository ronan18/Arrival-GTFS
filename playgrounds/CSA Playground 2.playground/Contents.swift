
import Foundation
import Arrival_GTFS
  print("init")
let agtfs = ArrivalGTFS()
print(agtfs.db.stations.all.map({i in return i.stopId}))


let clock = ContinuousClock()
let startStation = agtfs.db.stations.byStopID("WARM")!
let endStation = agtfs.db.stations.byStopID("SFIA")!
let at = Date(bartTime: "10:00:00")



var res: [[Connection]] = []

print(at.formatted(date: .omitted, time: .shortened))
print("trip from", startStation.id, endStation.id)
let time = clock.measure {
   
    res = agtfs.findPaths(from: startStation, to: endStation, at: at)
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


