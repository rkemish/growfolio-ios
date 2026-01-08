//
//  InvestView.swift
//  Growfolio
//
//  Container view for investing tools: Watchlist, Baskets, and DCA schedules.
//  Uses segmented control for iPhone navigation.
//

import SwiftUI

struct InvestView: View {
    @State private var selectedSegment: InvestSegment = .watchlist

    enum InvestSegment: String, CaseIterable {
        case watchlist = "Watchlist"
        case baskets = "Baskets"
        case dca = "DCA"

        var iconName: String {
            switch self {
            case .watchlist: return "star.fill"
            case .baskets: return "basket.fill"
            case .dca: return "arrow.triangle.2.circlepath"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for switching between investment tools
                Picker("Investment Type", selection: $selectedSegment) {
                    ForEach(InvestSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue)
                            .tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                // Content switcher using TabView for swipe gestures
                TabView(selection: $selectedSegment) {
                    WatchlistView()
                        .tag(InvestSegment.watchlist)

                    BasketsListView()
                        .tag(InvestSegment.baskets)

                    DCASchedulesView()
                        .tag(InvestSegment.dca)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Invest")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    InvestView()
}
