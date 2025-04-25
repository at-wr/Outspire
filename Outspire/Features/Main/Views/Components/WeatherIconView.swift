import SwiftUI

struct WeatherIconView: View {
    let conditionSymbol: String

    var body: some View {
        Image(systemName: conditionSymbol)
            .symbolRenderingMode(renderingMode)
            .foregroundStyle(colors)
    }

    private var renderingMode: SymbolRenderingMode {
        // Use hierarchical for single-layer symbols like cloud.fill
        if conditionSymbol == "cloud.fill" || conditionSymbol == "wind" || conditionSymbol == "cloud.hail" || conditionSymbol == "cloud.snow" || conditionSymbol == "wind.snow" || conditionSymbol == "hurricane" || conditionSymbol == "tropicalstorm" {
            return .hierarchical
        } else {
            return .palette
        }
    }

    private var colors: AnyShapeStyle {
        // Use hierarchical for single-layer symbols like cloud.fill
        if conditionSymbol == "cloud.fill" || conditionSymbol == "wind" || conditionSymbol == "cloud.hail" || conditionSymbol == "cloud.snow" || conditionSymbol == "wind.snow" || conditionSymbol == "hurricane" || conditionSymbol == "tropicalstorm" {
            // For hierarchical, just use the accent color
            return AnyShapeStyle(accentColor)
        } else {
            // For palette, use cloud and accent colors
            return AnyShapeStyle(LinearGradient(gradient: Gradient(colors: [cloudColor, accentColor]), startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private var cloudColor: Color {
        // Use secondary label color for cloud to adapt to light/dark mode
        Color(UIColor.secondaryLabel)
    }

    private var accentColor: Color {
        switch conditionSymbol {
        case "sun.max.fill":
            return .weatherSun
        case "cloud.sun.fill":
            return .weatherSun
        case "cloud.fill":
            return .weatherCloud
        case "cloud.fog.fill":
            return .weatherFog
        case "sun.haze.fill":
            return .weatherHaze
        case "smoke.fill":
            return .weatherSmoke
        case "cloud.drizzle.fill":
            return .weatherDrizzle
        case "cloud.rain.fill":
            return .weatherRain
        case "cloud.bolt.rain.fillw": // Note: This symbol name seems incorrect, should be cloud.bolt.rain.fill
            return .weatherThunderstorm
        case "wind":
            return .weatherWind
        case "cloud.hail":
            return .weatherHail
        case "cloud.snow":
            return .weatherSnow
        case "wind.snow":
            return .weatherFreezingDrizzle
        case "cloud.sleet.fill":
            return .weatherFreezingRain
        case "hurricane":
            return .weatherHurricane
        case "tropicalstorm":
            return .weatherTropicalStorm
        default:
            return .primary // Default to primary color if symbol not matched
        }
    }
}

struct WeatherIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WeatherIconView(conditionSymbol: "sun.max.fill")
            WeatherIconView(conditionSymbol: "cloud.sun.fill")
            WeatherIconView(conditionSymbol: "cloud.fill")
            WeatherIconView(conditionSymbol: "cloud.rain.fill")
            WeatherIconView(conditionSymbol: "cloud.bolt.rain.fillw") // Check this symbol
            WeatherIconView(conditionSymbol: "cloud.snow")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light Mode")

        VStack {
            WeatherIconView(conditionSymbol: "sun.max.fill")
            WeatherIconView(conditionSymbol: "cloud.sun.fill")
            WeatherIconView(conditionSymbol: "cloud.fill")
            WeatherIconView(conditionSymbol: "cloud.rain.fill")
            WeatherIconView(conditionSymbol: "cloud.bolt.rain.fillw") // Check this symbol
            WeatherIconView(conditionSymbol: "cloud.snow")
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark Mode")
    }
}
