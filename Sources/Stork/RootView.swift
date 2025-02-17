import Foundation
import OSLog
import SwiftUI
import SkipRevenueCat
import StorkModel

let logger: Logger = Logger(subsystem: "com.nickmolargik.stork", category: "Stork")
let androidSDK = ProcessInfo.processInfo.environment["android.os.Build.VERSION.SDK_INT"].flatMap({ Int($0) })

public struct RootView : View {
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    @StateObject var dailyResetManager = DailyResetManager()

    public init() {
        #if os(iOS) || SKIP
        if (Purchases.isConfigured) {
            print("Purchases already initialized")
            return
        }
        
        print("Configuring Purchases")
        Purchases.configure(apiKey: StoreConstants.apiKey)
        Purchases.sharedInstance.delegate = PurchasesDelegateHandler.shared
        #endif
    }

    public var body: some View {
        AppStateControllerView()
            .preferredColorScheme(useDarkMode ? .dark : .light)
            .task {
                logger.log("Welcome to Stork on \(androidSDK != nil ? "Android" : "Darwin")!")
                logger.warning("Skip app logs are viewable in the Xcode console for iOS; Android logs can be viewed in Studio or using adb logcat")
            }
            .environmentObject(dailyResetManager)
    }
}
