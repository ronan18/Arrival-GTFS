import Foundation

@available(macOS 13.0, *)
@available(iOS 16.0, *)
public class ArrivalGTFSCore {
    private let gftsURL = URL(string: "https://www.bart.gov/dev/schedules/google_transit.zip")!
    private let gtfsrtURL = URL(string: "http://api.bart.gov/gtfsrt/tripupdate.aspx")!
    private let cachePath = URL(fileURLWithPath: "/Users/ronanfuruta/Desktop/Dev/RonanFuruta/ios/Arrival/Arrival-GTFS/Sources/ArrivalGTFS/db/google_transit_20230213-20230813_v7.json")
   // private let dbCachePath = Bundle.module.url(forResource: "db", withExtension: "json")!
    private var lastGTFSRTHash: Int? = nil
    public var db: GTFSDB
  
    public var defaultResultLength: Int = 15
    
    public init() {
       
    //    let data = try! Data(contentsOf: dbCachePath)
      //  self.db = try! JSONDecoder().decode(GTFSDB.self, from: data)
        self.db = GTFSDB(from: GTFS())
      
    }
    
    public func readPrebuilt() throws {
        
        do {
            let data = try Data(contentsOf: cachePath)
            let gtfs = try JSONDecoder().decode(GTFS.self, from: data)
            self.db = .init(from: gtfs)
        } catch {
            print(error)
            throw error
        }
    }
    public func build() throws {
        do {
            let gtfs = try GTFS(path: "/Users/ronanfuruta/Desktop/Dev/iOS/Arrival-GTFS/db/google_transit_20230213-20230813_v7")
            //print("built gtfs", gtfs, gtfs.routes)
            
            let data = try JSONEncoder().encode(gtfs)
            
            do {
                try data.write(to: cachePath)
            }
            catch {
                print("Failed to write JSON data: \(error.localizedDescription)")
            }
            self.db = .init(from: gtfs)
        } catch {
            // print("error", error)
            throw ArrivalGTFSError.failedToBuild
        }
        
        
    }
    
    
    public func arrivals(for stop: Stop, at: Date = Date()) async -> [StopTime] {
        print("arrival for", stop.stopId, "at", at)
        
        var end = String((Int(self.hour(for: at)) ?? 0) + 3)
        if end.count == 1 {
            end = "0" + end
        }
        var stopTimes = self.db.stopTimes.byDepartureHour(from:self.hour(for: at), to: end)
       print("got \(stopTimes.count) stops at \(stop.stopName), ", self.hour(for: at), end)
        stopTimes = stopTimes.filter({stopTime in
            return self.inSerivce(stopTime: stopTime, at: at) && stopTime.stopId == stop.stopId
        })
        print("got \(stopTimes.count) stoptimes in service at \(stop.stopName)")
        let stopTimesSorted = stopTimes.sorted(by: {a, b in
            return Date(bartTime: a.arrivalTime) < Date(bartTime: b.arrivalTime)
        })
        guard let firstIndex = stopTimesSorted.firstIndex(where: {stopTime in
            print(stopTime.arrivalTime, "vs", at.bayTime )
            return Date(bartTime: stopTime.arrivalTime) >= at
        }) else {
            print("no first index greater than time, ", at, at.bayTime, stopTimesSorted.first, stopTimesSorted.last)
            return []
        }
       
        var lastIndex = firstIndex + defaultResultLength
        if lastIndex > stopTimesSorted.count - 1 {
            lastIndex = stopTimesSorted.count - 1
        }
        print("first index \(firstIndex) \(stopTimesSorted.count)", lastIndex)
        let selectedStopTimes = stopTimesSorted[firstIndex..<lastIndex]
       print("found \(selectedStopTimes.count) stops")
        return Array(selectedStopTimes)
        
    }
    func hour(for date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        dateFormatter.timeZone = .init(abbreviation: "PST")
       // let hour = Calendar.current.dateComponents([.hour], from: at).hour ?? 0
        var hour = dateFormatter.string(from: date)
        if (hour.count == 1) {
            hour = "0"+hour
        }
        print("hour for from dateformatter",date, date.bayTime, hour)
        return hour
    }

    func inSerivce(stopTime: StopTime, at: Date) -> Bool {
        guard let service = self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)?.serviceId ?? "ERROR") else {
            print("ERROR COULD NOT FIND SERVICE", stopTime.tripId, self.db.trips.byTripID(stopTime.tripId))
            return false
        }
        guard service.startDate < at && service.endDate > at else {
            //print("\(service.serviceId) service not currently in service")
            return false
        }
        let dow = Calendar.current.component(.weekday, from: at)
        switch dow {
            
        case 1:
            return service.sunday == .availableForAll
        case 2:
            return self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)!.serviceId)!.monday == .availableForAll
        case 3:
            return self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)!.serviceId)!.tuesday == .availableForAll
        case 4:
            return self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)!.serviceId)!.wednesday == .availableForAll
        case 5:
            return self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)!.serviceId)!.thursday == .availableForAll
        case 6:
            return self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)!.serviceId)!.friday == .availableForAll
        case 7:
            return self.db.calendar.byServiceID(self.db.trips.byTripID(stopTime.tripId)!.serviceId)!.saturday == .availableForAll
        default:
            return true
        }
    }
    public func directRoutes(from: Stop, to: Stop) -> [Route] {
        let fromStationRoutes: [Route] = self.db.routes.byStopID(from.stopId) ?? []
        let toStationRoutes: [Route] = self.db.routes.byStopID(to.stopId) ?? []
        var similarRoutes: [Route] = []
        fromStationRoutes.forEach({ route in
            if (toStationRoutes.contains(route)) {
                similarRoutes.append(route)
            }
        })
        similarRoutes = similarRoutes.filter({route in
            let trips = (self.db.trips.byRouteID(route.id) ?? [])
            guard !trips.isEmpty else {
                return false
            }
            let stopTimes = (self.db.stopTimes.byTripID(trips.first!.id) ?? [])
            
            //print("\(trips.count) trips for route, \(stopTimes.count) stop times")
            let startIndex = stopTimes.first(where: {stopTime in
                stopTime.stopId == from.stopId
            })?.stopSequence ?? 0
            let stopIndex = stopTimes.first(where: {stopTime in
                stopTime.stopId == to.stopId
            })?.stopSequence ?? 0
            //print(startIndex,stopIndex, route.routeShortName,  stopIndex > startIndex)
            return stopIndex > startIndex
        })
        return similarRoutes
    }
    public func arrivals(for routes: [Route], stop: Stop, at: Date = Date()) async -> [StopTime] {
        let stopArrivals = await self.arrivals(for: stop, at: at)
        return stopArrivals.filter({stopTime in
            return routes.contains(where: {route in
                route.routeId == self.db.trips.byTripID(stopTime.tripId)?.routeId
            })
        })
        
    }
    public func path(from: Stop, to: Stop, at: Date = Date(), stopTimes: [StopTime]) async -> [Connection] {
        var route: [Connection] = []
        var arrivalTimestamp: [String: Date] = [:]
        var inConnection: [String: Connection?] = [:]
        self.db.stations.all.forEach({station in
            arrivalTimestamp[station.id] = Date(timeIntervalSinceNow: 1e10)
            inConnection[station.id] = nil
        })
        arrivalTimestamp[from.stopId] = at
        var sameStation: [String] = []
        var noPrevious: [StopTime] = []
       /* let first = stopTimes.firstIndex(where: {time in
            Date(bartTime: time.departureTime) > at
        }) ?? 0*/
        
        for i in 0..<stopTimes.count{
            let current = stopTimes[i]
            guard current.stopSequence >= 1 else {
                continue
            }
                guard let previous = self.db.stopTimes.byTripID(current.tripId)!.last(where: {time in
                    time.stopSequence <= current.stopSequence - 1
                }) else {
                  //  print("No previous", current.stopSequence)
                    noPrevious.append(current)
                    continue
                }
            let connection = Connection(start: previous, end: current, tripId:current.tripId, routeId: self.db.trips.byTripID(current.tripId)!.routeId)
                if (connection.startStation == connection.endStation) {
                  //  print("ERROR", connection.description, current.stopSequence, previous.stopSequence)
                    sameStation.append("\(connection.description), \(current.stopSequence), \(previous.stopSequence)")
                   
                }
        
            //if the connection happens before the query time or the connection returns to the initial station
                if connection.startTime < at || connection.endStation == from.stopId {
                   
                    continue
                }
            //connection comes after already arriving at the destitnation station
                if let final = inConnection[to.stopId], connection.startTime > final!.endTime {
                  //  print("connection comes after already arriving at the destitnation station")
                 
                    break
                }
            //arrives at the station after the current best arrives there
                if let current = inConnection[connection.endStation], connection.endTime > current!.endTime {
                   
                    continue
                }
                if connection.startStation == from.stopId {
                    inConnection[connection.endStation] = connection
                } else if let previous = inConnection[connection.startStation] {
                    var transferTime: TimeInterval = 60
                    if let transfers = self.db.transfers.byStopID(connection.startStation) {
                       if let transfer = transfers.first(where: {transfer in
                           return transfer.toRouteID == connection.routeId && transfer.fromRouteID == previous!.routeId
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
                    if connection.startTime > previous!.endTime + transferTime + 60 || connection.tripId == previous!.tripId {
                        inConnection[connection.endStation] = connection
                       
                    }
                }
             
            
        }
    
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
        return route

    }
    public func findPaths(from: Stop, to: Stop, at: Date = Date(), count: Int = 5) async -> [[Connection]] {
        var at = at
        var results: [[Connection]] = []
        var i = 0
       let time = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh"
        dateFormatter.timeZone = .init(identifier: "PST")
       // let hour = Calendar.current.dateComponents([.hour], from: at).hour ?? 0
        let hour = dateFormatter.string(from: at)
       // print(at.bayTime, hour)
        var workingStopTimes: [StopTime] = []
        let indexTime = ContinuousClock().measure {
        workingStopTimes = self.db.stopTimes.byDepartureHour(from:String(hour) , to: String(hour + String(3)))
        print("initial count", workingStopTimes.count)
      
       /*    let first = workingStopTimes.firstIndex(where: {stopTime in
               Date(bartTime: stopTime.departureTime) > at
           }) ?? 0
           let last = workingStopTimes.lastIndex(where: {stopTime in
               Date(bartTime: stopTime.departureTime) > at + 60*60*3
           }) ?? 0
           //print("first index", first, "last index", last)
           workingStopTimes = Array(workingStopTimes.dropLast(workingStopTimes.count - last))
           workingStopTimes = Array(workingStopTimes.dropFirst(first - 0)) */
          
            workingStopTimes = workingStopTimes.filter({stopTime in
                
                self.inSerivce(stopTime: stopTime, at: at)
            })
        }
       print("initial pruning time", indexTime)
        print("working stoptimes count", workingStopTimes.count)
        var byArrivalTimeRes: [TimeInterval: [Connection]] = [:]
        while (byArrivalTimeRes.values.count < count && Date().timeIntervalSince(time) < 5) {
           // let time = await ContinuousClock().measure {
                let first = workingStopTimes.firstIndex(where: {time in
                    Date(bartTime: time.departureTime) > at
                }) ?? 0
                workingStopTimes = Array(workingStopTimes.dropFirst(first - 0))
                //print("working stoptimes count", workingStopTimes.count, first)
                let res = await path(from: from, to: to, at: at, stopTimes: workingStopTimes)
            if let last = res.last {
                byArrivalTimeRes[last.endTime.timeIntervalSince1970] = res
                results.append(res)
            }
                if let first = res.first?.startTime {
                    at = Date(timeInterval: 30, since: first)
                } else {
                    i = count
                }
                
                i += 1
           // }
           // print("PATH SEARCH TIME", time)
            
            
        }
        print("plan creation time", Date().timeIntervalSince(time))
        return Array(byArrivalTimeRes.values)
    }
    
    
}

public enum ArrivalGTFSError: Error {
    case failedToBuild
    case failedToReadPrebuiltData
}
public func print(trip: [Connection]) {
    guard trip.count >= 1 else {
        return
    }
    print("-------STARTING TRIP at \(trip.first!.startTime.bayTime) with \(trip.count) LEGS arrives at \(trip.last!.endTime.bayTime)--------")
    trip.forEach({con in
        print(con.description)
    })
    print("-------ENDING TRIP with \(trip.count) LEGS--------")
}
