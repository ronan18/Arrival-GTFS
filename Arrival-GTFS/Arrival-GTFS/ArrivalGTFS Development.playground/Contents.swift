import Cocoa
@testable import Arrival_GTFS

var greeting = "Hello, playground"

//ArrivalGTFS.gftsURL
let agtfs = ArrivalGTFS()

let routes = agtfs.routesByStopID["ROCK"] ?? []

print(routes.count)
print(routes)
