//
//  DebugLaunchOptions.swift
//  StorkCore
//
//  DEBUG-only launch arguments used to verify the Year Wrap on a simulator without
//  driving the UI: a fake "today", a two-year sample data seed, and auto-opening the
//  Wrap. Compiled out of release builds entirely.
//
//    -StorkDebugNow 2026-12-05      pretend today is this date (seasonal dashboard card)
//    -StorkInMemoryStore 1          in-memory store (unsigned simulator builds cannot open CloudKit)
//    -StorkSeedWrapSample 1         seed two years of sample births when the store is empty
//    -StorkSeedPastBirths 1         seed estimated past-birth summaries (2018 to 2022) when the store is empty
//    -StorkOpenWrap 2026            present the Wrap for that year on the dashboard
//    -StorkWrapPage 3               start the Wrap on this page index
//    -StorkWrapIncludeRemembrance 1 turn the share-image remembrance toggle on
//    -StorkImportCSVPath <file>     preload this CSV into the Import from CSV screen
//    -StorkExportWrapImages 1       write the share images to Documents/WrapShare
//    -StorkOpenLink <host>          open a stork:// deep link on launch (pro, settings, calendar, deliveries, new-delivery)
//    -StorkOpenSheet <name>         present a sheet on launch: reorder, trend, filter, firstDelivery
//    -StorkDebugPro 1               force Stork Pro on (to capture Pro screens; never in release builds)
//    -StorkJarMarbleScale 1.3       multiply the dashboard jar's marble size (fuller-looking jar for store shots)
//    -StorkScrollToCard 1           scroll the stacked dashboard so this card (index in the card order) is at the top
//    -StorkHideHealthPill 1         hide the Connect Health / step pill (store screenshots)
//    -StorkSettingsPush <name>      push a Settings screen on launch: privacy, pastbirths, export, addpast, csv, roles
//

#if DEBUG
import Foundation

nonisolated public enum DebugLaunchOptions {
    private static var defaults: UserDefaults { .standard }

    public static var now: Date? {
        guard let raw = defaults.string(forKey: "StorkDebugNow") else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let day = formatter.date(from: raw) else { return nil }
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: day)
    }

    public static var inMemoryStore: Bool { defaults.bool(forKey: "StorkInMemoryStore") }
    public static var seedWrapSample: Bool { defaults.bool(forKey: "StorkSeedWrapSample") }
    public static var seedPastBirths: Bool { defaults.bool(forKey: "StorkSeedPastBirths") }
    public static var openWrapYear: Int? { defaults.object(forKey: "StorkOpenWrap") == nil ? nil : defaults.integer(forKey: "StorkOpenWrap") }
    public static var wrapPage: Int { defaults.integer(forKey: "StorkWrapPage") }
    public static var wrapIncludeRemembrance: Bool { defaults.bool(forKey: "StorkWrapIncludeRemembrance") }
    public static var importCSVPath: String? { defaults.string(forKey: "StorkImportCSVPath") }
    public static var openLink: String? { defaults.string(forKey: "StorkOpenLink") }
    public static var openSheet: String? { defaults.string(forKey: "StorkOpenSheet") }
    public static var settingsPush: String? { defaults.string(forKey: "StorkSettingsPush") }
    public static var jarMarbleScale: CGFloat? { defaults.object(forKey: "StorkJarMarbleScale") == nil ? nil : CGFloat(defaults.double(forKey: "StorkJarMarbleScale")) }
    public static var scrollToCard: Int? { defaults.object(forKey: "StorkScrollToCard") == nil ? nil : defaults.integer(forKey: "StorkScrollToCard") }
    public static var hideHealthPill: Bool { defaults.bool(forKey: "StorkHideHealthPill") }
    public static var forcePro: Bool { defaults.bool(forKey: "StorkDebugPro") }
    public static var exportWrapImages: Bool { defaults.bool(forKey: "StorkExportWrapImages") }
}
#endif
