//
//  BasketAllocationRow.swift
//  Growfolio
//
//  Row component for displaying a stock allocation.
//

import SwiftUI

struct BasketAllocationRow: View {
    let allocation: BasketAllocation
    let showPercentage: Bool

    init(allocation: BasketAllocation, showPercentage: Bool = true) {
        self.allocation = allocation
        self.showPercentage = showPercentage
    }

    var body: some View {
        HStack(spacing: 12) {
            // Symbol badge
            Text(allocation.symbol)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Stock info
            VStack(alignment: .leading, spacing: 4) {
                Text(allocation.symbol)
                    .font(.headline)
                Text(allocation.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if showPercentage {
                // Percentage
                Text(allocation.percentage.rawPercentString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BasketAllocationRow(
            allocation: BasketAllocation(
                symbol: "AAPL",
                name: "Apple Inc.",
                percentage: 40,
                targetShares: nil
            )
        )

        BasketAllocationRow(
            allocation: BasketAllocation(
                symbol: "MSFT",
                name: "Microsoft Corporation",
                percentage: 30,
                targetShares: nil
            )
        )

        BasketAllocationRow(
            allocation: BasketAllocation(
                symbol: "GOOGL",
                name: "Alphabet Inc.",
                percentage: 30,
                targetShares: nil
            )
        )
    }
    .padding()
}
