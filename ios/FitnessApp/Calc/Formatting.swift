import Foundation

/// Local-day key helpers. All entries are bucketed by the device's local calendar day.
enum DayKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date = Date()) -> String { formatter.string(from: date) }
    static func date(from key: String) -> Date { formatter.date(from: key) ?? Date() }
    static var today: String { key(for: Date()) }
}

/// Unit conversions. Canonical storage is metric; these convert for display/entry only.
enum Units {
    static let kgPerLb = 0.45359237
    static let mlPerOz = 29.5735

    static func kg(fromLb lb: Double) -> Double { lb * kgPerLb }
    static func lb(fromKg kg: Double) -> Double { kg / kgPerLb }
    static func ml(fromOz oz: Double) -> Double { oz * mlPerOz }
    static func oz(fromMl ml: Double) -> Double { ml / mlPerOz }

    /// Weight in the user's chosen unit, rounded to 1 decimal.
    static func displayWeight(kg: Double, system: UnitSystem) -> Double {
        let v = system == .metric ? kg : lb(fromKg: kg)
        return (v * 10).rounded() / 10
    }
    static func kgFromDisplay(_ value: Double, system: UnitSystem) -> Double {
        system == .metric ? value : kg(fromLb: value)
    }
    static func displayVolume(ml: Int, system: UnitSystem) -> Int {
        system == .metric ? ml : Int(oz(fromMl: Double(ml)).rounded())
    }
}
