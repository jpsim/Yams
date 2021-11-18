import Backtrace
import Foundation
import Yams

@_cdecl("LLVMFuzzerTestOneInput") public func fuzzerEntry(data: UnsafePointer<CChar>, size: CInt) -> CInt {
    Backtrace.install()
    let string = String(cString: data)
    _ = try? Yams.load(yaml: string)
    return 0
}
