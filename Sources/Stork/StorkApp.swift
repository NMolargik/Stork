import SwiftUI

#if !SKIP
public protocol StorkApp : App {
}

/// The entry point to the Stork app.
/// The concrete implementation is in the StorkApp module.
public extension StorkApp {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }     
}
#endif

