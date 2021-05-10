//
//  BTC_Widget.swift
//  BTC Widget
//
//  Created by Aidan Scheer on 5/9/21.
//

import WidgetKit
import SwiftUI

class NetworkManager {
    func getWeatherData(completion: @escaping (SimpleEntry.BTCData?) -> Void) {
        guard let url = URL(string: "https://api.blockchain.com/v3/exchange/tickers/BTC-USD") else { return completion(nil) }
        
        URLSession.shared.dataTask(with: url) { d, res, err
            in
            var result: SimpleEntry.BTCData?
            
            if let data = d,
               let response = res as? HTTPURLResponse,
               response.statusCode == 200 {
                do {
                    result = try JSONDecoder().decode(SimpleEntry.BTCData.self, from: data)
                } catch {
                    print(error)
                }
            }
            
            return completion(result)
        }
        .resume()
    }
}

struct Provider: TimelineProvider {
    let networkManager = NetworkManager()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .previewData, error: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        networkManager.getWeatherData { data in
            let entry = SimpleEntry(date: Date(), data: data ?? .error , error: data == nil)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        networkManager.getWeatherData { data in
            let timeline = Timeline(entries: [SimpleEntry(date: Date(), data: data ?? .error , error: data == nil)], policy: .after(Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
                )
            )
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    var data: BTCData
    var error: Bool
    
    enum DifferenceMode: String {
        case up = "up",
             down = "down",
             error = "error"
    }
    
    var diffMode: DifferenceMode {
        if error || data.difference == 0.0 {
            return .error
        } else if data.difference > 0.0 {
            return .up
        } else {
            return .down
        }
    }
    
    struct BTCData: Decodable {
        let price_24h: Double
        let volume_24h: Double
        let last_trade_price: Double
        
        var difference: Double { price_24h - last_trade_price }
        
        static let previewData = BTCData (
            price_24h: 59183.11,
            volume_24h: 377.83100325,
            last_trade_price: 57708.33
        )
        
        static let error = BTCData (
            price_24h: 0,
            volume_24h: 0,
            last_trade_price: 0
        )
    }
}

struct BTC_WidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .unredacted()
            
            HStack {
                VStack(alignment: .leading) {
                    header
                    Spacer()
                    pricing
                    Spacer()
                    if family == .systemLarge {
                        volume
                    }
                }
                
                
                Spacer()
            }
            .padding()
        }
    }
    
    var header: some View {
        Group {
            Text("BTC Track")
                .bold()
                .font(family == .systemLarge ? .system(size: 40) : .title)
                .minimumScaleFactor(0.5)
            Text("Bitcoin")
                .font(family == .systemLarge ? .title : .headline)
                .padding(.top, family == .systemLarge ? -15 : 0)
        }
        .foregroundColor(Color("headingColor"))
    }
    
    var pricing: some View {
        Group {
            if family == .systemMedium {
                HStack (alignment: .firstTextBaseline) {
                    price
                    difference
                }
            } else {
                price
                difference
            }
           
        }
    }
    
    var price: some View {
        Text(entry.error ? "––––" : "\(String(format: "%.1f", entry.data.price_24h))")
            .font(family == .systemSmall ? .body : .system(size: CGFloat(family.rawValue * 25 + 14)))
            .bold()
    }
    
    var difference: some View {
        Text(entry.error ? "± ––––" : "\(entry.diffMode == .up ? "+" : "")\(String(format: "%.2f", entry.data.difference))")
            .font(family == .systemSmall ? .footnote : .title2)
            .bold()
            .foregroundColor(Color("\(entry.diffMode)Color"))
    }
    
    var volume: some View {
        Text("VOLUME: \(entry.error ? "––––" : "\(String(format: "%.2f", entry.data.volume_24h))")")
            .font(.title2)
            .bold()
            .foregroundColor(scheme == .dark ? .orange : .purple)
    }
}

@main
struct BTC_Widget: Widget {
    let kind: String = "BTC_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BTC_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("BTC Track")
        .description("Track Bitcoin Prices From Your Home Screen.")
    }
}

struct BTC_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BTC_WidgetEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            BTC_WidgetEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            BTC_WidgetEntryView(entry: SimpleEntry(date: Date(), data: .previewData, error: false))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
        .environment(\.colorScheme, .light)
//        .redacted(reason: .placeholder)
    }
}
