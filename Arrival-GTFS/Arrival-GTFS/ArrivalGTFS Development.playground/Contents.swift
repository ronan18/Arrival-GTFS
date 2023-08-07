import Cocoa
import SwiftUI
import PlaygroundSupport
@testable import Arrival_GTFS
  
let agtfs = ArrivalGTFS()
print(agtfs.db.stations.all.map({i in return i.stopId}))
let startStation = agtfs.db.stations.byStopID("ORIN")!
let endStation = agtfs.db.stations.byStopID("EMBR")!
let routesInCommon = agtfs.directRoutes(from: startStation, to: endStation)
var arrivals:[StopTime] = agtfs.arrivals(for: routesInCommon, stop: startStation )
var allArrivals: [StopTime] = agtfs.arrivals(for: startStation)
print(routesInCommon.map({ route in
    return route.routeShortName!
}))
print("found \(arrivals.count) arrivals")
struct TestView:  View {
    
    var body: some View {
        HStack {
            
            Table(arrivals) {
                TableColumn("Train") {arr in
                    Text(agtfs.db.stations.byStopID(agtfs.db.stopTimes.byTripID(arr.tripId)!.last!.stopId)?.stopName ?? "")
                }
                TableColumn("Route short name") {arr in
                    Text(agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(arr.tripId)!.routeId)!.routeShortName ?? "")
                }
                TableColumn("time", value: \.arrivalTime)
                TableColumn("Trip Headsign") {arr in
                    Text(agtfs.db.trips.byTripID(arr.tripId)!.tripHeadsign ?? "")
                }
                
                TableColumn("Route Color") {arr in
                    Text(agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(arr.tripId)!.routeId)!.routeColor ?? "")
                }
             
                
               
                TableColumn("Route long name") {arr in
                    Text(agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(arr.tripId)!.routeId)!.routeLongName ?? "")
                }
                TableColumn("arrival time", value: \.arrivalTime)
                
                TableColumn("stop", value: \.stopId)
            }
            Table(allArrivals) {
                TableColumn("All Train") {arr in
                    Text(agtfs.db.stations.byStopID(agtfs.db.stopTimes.byTripID(arr.tripId)!.last!.stopId)?.stopName ?? "")
                }
                TableColumn("Route short name") {arr in
                    Text(agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(arr.tripId)!.routeId)!.routeShortName ?? "")
                }
                TableColumn("time", value: \.arrivalTime)
                TableColumn("Trip Headsign") {arr in
                    Text(agtfs.db.trips.byTripID(arr.tripId)!.tripHeadsign ?? "")
                }
                
                TableColumn("Route Color") {arr in
                    Text(agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(arr.tripId)!.routeId)!.routeColor ?? "")
                }
             
                
               
                TableColumn("Route long name") {arr in
                    Text(agtfs.db.routes.byRouteID(agtfs.db.trips.byTripID(arr.tripId)!.routeId)!.routeLongName ?? "")
                }
                TableColumn("arrival time", value: \.arrivalTime)
                
                TableColumn("stop", value: \.stopId)
            }
        }
    }
}


PlaygroundPage.current.setLiveView(TestView())
/*
struct TestView:  View {
    let agtfs = ArrivalGTFS()
    var body: some View {
        VStack {
            Table(agtfs.db.stopTimes.all) {
                TableColumn("Stop", value: \.stopId)
                TableColumn("Trip Head Sign") {item in
                    Text(self.agtfs.db.trips.byTripID(item.tripId)?.tripHeadsign ?? "")
                }
                TableColumn("Route") {item in
                    Text(self.agtfs.db.routes.byRouteID[self.agtfs.db.trips.byTripID(item.tripId)?.routeId ?? ""]?.routeShortName ?? "")
                }
                TableColumn("Arrival Time", value: \.arrivalTime)
                TableColumn("Departure Time", value: \.departureTime)
                TableColumn("Stop Sequence") {item in
                    Text(String(item.stopSequence))
                }
             
                TableColumn("Stop Headsign", value: \.stopHeadsign)
            }
           /* Table(agtfs.db.trips.all) {
                
                TableColumn("Trip ID", value: \.tripId)
                TableColumn("Route ID", value: \.routeId)
                TableColumn("Headsign") {item in
                    Text(item.tripHeadsign ?? "")
                    
                }
                TableColumn("Route Short Name") {item in
                    Text(agtfs.db.routes.byRouteID[item.routeId]?.routeShortName ?? "")
                    
                }
                
                TableColumn("Route Long Name") {item in
                    Text(agtfs.db.routes.byRouteID[item.routeId]?.routeLongName ?? "")
                    
                }
              
            } */
        }
        }
}


//PlaygroundPage.current.setLiveView(TestView())
*/

