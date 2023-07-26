import Cocoa
@testable import Arrival_GTFS

var greeting = "Hello, playground"

//ArrivalGTFS.gftsURL
let agtfs = ArrivalGTFS()

try? agtfs.build()
