//
//  BuyStockSheet.swift
//  Growfolio
//
//  Sheet for buying a stock with GBP amount input and estimated shares preview.
//

import SwiftUI

struct BuyStockSheet: View {

    // MARK: - Properties

    let symbol: String
    let stockName: String?
    let currentPriceUSD: Decimal?
    let onDismiss: () -> Void

    @State private var viewModel: BuyStockSheetViewModel

    @FocusState private var isAmountFocused: Bool

    // MARK: - Initialization

    init(
        symbol: String,
        stockName: String? = nil,
        currentPriceUSD: Decimal? = nil,
        stocksRepository: StocksRepositoryProtocol = StocksRepository(),
        fundingRepository: FundingRepositoryProtocol = FundingRepository(),
        onDismiss: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.stockName = stockName
        self.currentPriceUSD = currentPriceUSD
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: BuyStockSheetViewModel(
            symbol: symbol,
            stockName: stockName,
            initialPriceUSD: currentPriceUSD,
            stocksRepository: stocksRepository,
            fundingRepository: fundingRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.orderState == .review {
                    reviewView
                } else if viewModel.orderState == .success {
                    successView
                } else {
                    inputView
                }
            }
            .navigationTitle("Buy \(symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.orderState != .success {
                        Button("Cancel") {
                            if viewModel.orderState == .review {
                                viewModel.goBackToInput()
                            } else {
                                onDismiss()
                            }
                        }
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isAmountFocused = false
                    }
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .overlay {
                if viewModel.isSubmitting {
                    submittingOverlay
                }
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        Form {
            // Stock Info Section
            stockInfoSection

            // Amount Section
            amountSection

            // FX Conversion Section
            fxConversionSection

            // Estimated Shares Section
            if viewModel.canShowEstimate {
                estimatedSharesSection
            }

            // Account Balance Section
            accountBalanceSection

            // Review Button Section
            reviewButtonSection
        }
    }

    // MARK: - Stock Info Section

    private var stockInfoSection: some View {
        Section {
            HStack(spacing: 12) {
                // Stock Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(String(symbol.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.positive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(symbol)
                        .font(.headline)

                    if let name = stockName {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Current Price
                VStack(alignment: .trailing, spacing: 4) {
                    if viewModel.isLoadingPrice {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let price = viewModel.currentPriceUSD {
                        Text(price.currencyString)
                            .font(.headline)
                        Text("per share")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("--")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        Section {
            HStack {
                Text("GBP")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)

                TextField("0.00", text: $viewModel.amountGBP)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .multilineTextAlignment(.trailing)
                    .focused($isAmountFocused)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Amount to Invest")
        } footer: {
            Text("Enter the amount in GBP you wish to invest in \(symbol).")
        }
    }

    // MARK: - FX Conversion Section

    private var fxConversionSection: some View {
        Section {
            // Current Rate
            HStack {
                Text("Exchange Rate")
                Spacer()
                if viewModel.isLoadingFXRate {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(viewModel.fxRateDisplayString)
                        .foregroundStyle(.secondary)
                }
            }

            // Rate Status
            HStack {
                Text("Rate Status")
                Spacer()
                if viewModel.isFXRateValid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.positive)
                        Text("Live")
                            .foregroundStyle(Color.positive)
                    }
                    .font(.subheadline)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.prosperityGold)
                        Text("Expired")
                            .foregroundStyle(Color.prosperityGold)
                    }
                    .font(.subheadline)
                }
            }

            // Converted Amount
            if let amountUSD = viewModel.amountUSD, amountUSD > 0 {
                HStack {
                    Text("Investment Amount (USD)")
                    Spacer()
                    Text(amountUSD.currencyString)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.positive)
                }
            }

            // Refresh Rate Button
            Button {
                Task {
                    await viewModel.refreshFXRate()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Refresh Rate")
                }
            }
            .disabled(viewModel.isLoadingFXRate)
        } header: {
            Text("Currency Conversion")
        }
    }

    // MARK: - Estimated Shares Section

    private var estimatedSharesSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Shares")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.estimatedShares.sharesString)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("at")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(viewModel.currentPriceUSD?.currencyString ?? "--")
                        .font(.headline)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Order Preview")
        } footer: {
            Text("This is an estimate based on the current price. The actual number of shares may vary slightly at the time of execution.")
        }
    }

    // MARK: - Account Balance Section

    private var accountBalanceSection: some View {
        Section("Account Balance") {
            if viewModel.isLoadingBalance {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading balance...")
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Text("Available (GBP)")
                    Spacer()
                    Text(viewModel.availableBalanceGBP.currencyString(code: "GBP"))
                        .foregroundStyle(viewModel.hasInsufficientFunds ? Color.negative : .secondary)
                }

                HStack {
                    Text("Available (USD)")
                    Spacer()
                    Text(viewModel.availableBalanceUSD.currencyString)
                        .foregroundStyle(.secondary)
                }

                if viewModel.hasInsufficientFunds {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.negative)
                        Text("Insufficient funds for this order")
                            .font(.caption)
                            .foregroundStyle(Color.negative)
                    }
                }
            }
        }
    }

    // MARK: - Review Button Section

    private var reviewButtonSection: some View {
        Section {
            Button {
                viewModel.reviewOrder()
            } label: {
                HStack {
                    Spacer()
                    Text("Review Order")
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .disabled(!viewModel.canReview)
        }
    }

    // MARK: - Review View

    private var reviewView: some View {
        Form {
            // Order Summary
            Section("Order Summary") {
                HStack {
                    Text("Stock")
                    Spacer()
                    Text(symbol)
                        .fontWeight(.semibold)
                }

                if let name = stockName {
                    HStack {
                        Text("Company")
                        Spacer()
                        Text(name)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Order Type")
                    Spacer()
                    Text("Market Buy")
                        .foregroundStyle(.secondary)
                }
            }

            // Investment Details
            Section("Investment Details") {
                HStack {
                    Text("Amount (GBP)")
                    Spacer()
                    Text((viewModel.amountGBPValue ?? 0).currencyString(code: "GBP"))
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Exchange Rate")
                    Spacer()
                    Text(viewModel.fxRateDisplayString)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Amount (USD)")
                    Spacer()
                    Text((viewModel.amountUSD ?? 0).currencyString)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.positive)
                }
            }

            // Estimated Shares
            Section("Estimated Purchase") {
                HStack {
                    Text("Current Price")
                    Spacer()
                    Text(viewModel.currentPriceUSD?.currencyString ?? "--")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Estimated Shares")
                    Spacer()
                    Text(viewModel.estimatedShares.sharesString)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            // Disclaimer
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.trustBlue)

                        Text("Market orders are executed at the best available price. The actual number of shares and final price may vary slightly.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Confirm Button
            Section {
                Button {
                    Task {
                        await viewModel.submitOrder()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "cart.fill")
                        Text("Confirm Buy")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(viewModel.isSubmitting)
            }
            .listRowBackground(Color.green)
            .foregroundStyle(.white)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.positive)
            }

            // Success Message
            VStack(spacing: 8) {
                Text("Order Submitted!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your order to buy \(symbol) has been submitted")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Order Details
            VStack(spacing: 12) {
                HStack {
                    Text("Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text((viewModel.amountUSD ?? 0).currencyString)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Estimated Shares")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.estimatedShares.sharesString)
                        .fontWeight(.semibold)
                }

                if let orderId = viewModel.orderId {
                    HStack {
                        Text("Order ID")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(orderId.prefix(8) + "...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            // Done Button
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.positive)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Submitting Overlay

    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Submitting order...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Order State

enum BuyOrderState {
    case input
    case review
    case success
}

// MARK: - View Model

@Observable
final class BuyStockSheetViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Input Data
    let symbol: String
    let stockName: String?

    // User Input
    var amountGBP: String = ""

    // Loaded Data
    var currentPriceUSD: Decimal?
    var fxRate: Decimal?
    var fxRateTimestamp: Date?
    var availableBalanceGBP: Decimal = 0
    var availableBalanceUSD: Decimal = 0

    // State
    var orderState: BuyOrderState = .input
    var isLoadingPrice = false
    var isLoadingFXRate = false
    var isLoadingBalance = false
    var isSubmitting = false
    var showError = false
    var errorMessage: String?
    var orderId: String?

    // Repositories
    private let stocksRepository: StocksRepositoryProtocol
    private let fundingRepository: FundingRepositoryProtocol

    // MARK: - Computed Properties

    var amountGBPValue: Decimal? {
        Decimal(string: amountGBP)
    }

    var amountUSD: Decimal? {
        guard let gbp = amountGBPValue, let rate = fxRate, gbp > 0, rate > 0 else {
            return nil
        }
        return (gbp * rate).rounded(places: 2)
    }

    var estimatedShares: Decimal {
        guard let usd = amountUSD, let price = currentPriceUSD, price > 0 else {
            return 0
        }
        return (usd / price).rounded(places: 6)
    }

    var fxRateDisplayString: String {
        guard let rate = fxRate else {
            return "--"
        }
        return "1 GBP = \(rate.rounded(places: 4)) USD"
    }

    var isFXRateValid: Bool {
        guard let timestamp = fxRateTimestamp else { return false }
        // Rate is valid for 5 minutes
        return Date().timeIntervalSince(timestamp) < 300
    }

    var canShowEstimate: Bool {
        guard let usd = amountUSD, let price = currentPriceUSD else { return false }
        return usd > 0 && price > 0
    }

    var hasInsufficientFunds: Bool {
        guard let gbp = amountGBPValue else { return false }
        return gbp > availableBalanceGBP
    }

    var canReview: Bool {
        guard let gbp = amountGBPValue, gbp > 0 else { return false }
        guard let _ = amountUSD else { return false }
        guard let _ = currentPriceUSD else { return false }
        guard !hasInsufficientFunds else { return false }
        guard isFXRateValid else { return false }
        return true
    }

    // MARK: - Initialization

    init(
        symbol: String,
        stockName: String?,
        initialPriceUSD: Decimal?,
        stocksRepository: StocksRepositoryProtocol,
        fundingRepository: FundingRepositoryProtocol
    ) {
        self.symbol = symbol
        self.stockName = stockName
        self.currentPriceUSD = initialPriceUSD
        self.stocksRepository = stocksRepository
        self.fundingRepository = fundingRepository
    }

    // MARK: - Data Loading

    @MainActor
    func loadInitialData() async {
        // Load all data in parallel
        async let priceTask: () = loadPrice()
        async let fxTask: () = loadFXRate()
        async let balanceTask: () = loadBalance()

        _ = await (priceTask, fxTask, balanceTask)
    }

    @MainActor
    func loadPrice() async {
        guard currentPriceUSD == nil else { return }

        isLoadingPrice = true

        do {
            let quote = try await stocksRepository.getQuote(symbol: symbol)
            currentPriceUSD = quote.price
        } catch {
            // Price loading failed - will show placeholder
        }

        isLoadingPrice = false
    }

    @MainActor
    func loadFXRate() async {
        isLoadingFXRate = true

        do {
            let rate = try await fundingRepository.fetchFXRate()
            fxRate = rate.rate
            fxRateTimestamp = rate.timestamp
        } catch {
            // FX rate loading failed - will show error state
        }

        isLoadingFXRate = false
    }

    @MainActor
    func refreshFXRate() async {
        await loadFXRate()
    }

    @MainActor
    func loadBalance() async {
        isLoadingBalance = true

        do {
            let balance = try await fundingRepository.fetchBalance()
            availableBalanceGBP = balance.availableGBP
            availableBalanceUSD = balance.availableUSD
        } catch {
            // Balance loading failed - will show 0
        }

        isLoadingBalance = false
    }

    // MARK: - Order Flow

    func reviewOrder() {
        guard canReview else { return }
        orderState = .review
    }

    func goBackToInput() {
        orderState = .input
    }

    @MainActor
    func submitOrder() async {
        guard canReview else { return }
        guard let notionalUSD = amountUSD else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            // Submit the order via the stocks repository
            let order = try await stocksRepository.submitBuyOrder(
                symbol: symbol,
                notionalUSD: notionalUSD
            )

            orderId = order.id
            orderState = .success
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}

// MARK: - Preview

#Preview {
    BuyStockSheet(
        symbol: "AAPL",
        stockName: "Apple Inc.",
        currentPriceUSD: 185.92,
        onDismiss: {}
    )
}
