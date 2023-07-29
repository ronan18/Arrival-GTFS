import Cocoa
import SwiftUI
import PlaygroundSupport
@testable import Arrival_GTFS
  



struct TestView:  View {
    let agtfs = ArrivalGTFS()
    var body: some View {
        VStack {
            Table(agtfs.db.stopTimes.all) {
                TableColumn("Stop", value: \.stopId)
                TableColumn("Trip Head Sign") {item in
                    Text(self.agtfs.db.trips.byTripID(tripId: item.tripId)?.tripHeadsign ?? "")
                }
                TableColumn("Route") {item in
                    Text(self.agtfs.db.routes.byRouteID[self.agtfs.db.trips.byTripID(tripId: item.tripId)?.routeId ?? ""]?.routeShortName ?? "")
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


PlaygroundPage.current.setLiveView(TestView())
