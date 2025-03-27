import Foundation
import WeatherKit
import CoreLocation
import SwiftUI

@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()
    private let weatherService = WeatherService()

    @Published var currentTemperature: String = "--"
    @Published var conditionSymbol: String = "cloud.sun"

    func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            let temperatureValue = Int(weather.currentWeather.temperature.value.rounded())
            self.currentTemperature = "\(temperatureValue)°C"
            let condition = weather.currentWeather.condition
            // Map weather conditions based on Apple's documentation:
            // https://developer.apple.com/documentation/weatherkit/weathercondition
            switch condition {
            case .clear:
                self.conditionSymbol = "sun.max.fill"
            case .mostlyClear:
                self.conditionSymbol = "sun.max.fill"
            case .partlyCloudy:
                self.conditionSymbol = "cloud.sun.fill"
            case .cloudy, .mostlyCloudy:
                self.conditionSymbol = "cloud.fill"
            case .foggy:
                self.conditionSymbol = "cloud.fog.fill"
            case .haze:
                self.conditionSymbol = "sun.haze.fill"
            case .smoky:
                self.conditionSymbol = "smoke.fill"
            case .drizzle:
                self.conditionSymbol = "cloud.drizzle.fill"
            case .rain, .sunShowers, .heavyRain:
                self.conditionSymbol = "cloud.rain.fill"
            case .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms, .strongStorms:
                self.conditionSymbol = "cloud.bolt.rain.fillw"
            case .blowingDust:
                self.conditionSymbol = "wind"
            case .breezy, .windy:
                self.conditionSymbol = "wind"
            case .hail:
                self.conditionSymbol = "cloud.hail"
            case .hot:
                self.conditionSymbol = "sun.max.fill"
            case .flurries, .sleet, .snow, .sunFlurries, .wintryMix, .heavySnow, .blizzard, .blowingSnow:
                self.conditionSymbol = "cloud.snow"
            case .freezingDrizzle:
                self.conditionSymbol = "wind.snow"
            case .freezingRain:
                self.conditionSymbol = "cloud.sleet.fill"
            case .hurricane:
                self.conditionSymbol = "hurricane"
            case .tropicalStorm:
                self.conditionSymbol = "tropicalstorm"
            default:
                self.conditionSymbol = "cloud.sun.fill"
            }
        } catch {
            print("WeatherManager fetchWeather error: \(error)")
        }
    }
}
