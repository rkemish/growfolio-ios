//
//  BasketsViewModel.swift
//  Growfolio
//
//  ViewModel for managing user baskets list.
//

import Foundation

@Observable
final class BasketsViewModel: @unchecked Sendable {

    // MARK: - Properties

    var baskets: [Basket] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let basketRepository: BasketRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol

    // WebSocket Tasks
    nonisolated(unsafe) private var basketUpdatesTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        basketRepository: BasketRepositoryProtocol = RepositoryContainer.basketRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.basketRepository = basketRepository
        self.webSocketService = webSocketService ?? WebSocketService.shared
    }

    // MARK: - Methods

    @MainActor
    func loadBaskets() async {
        isLoading = true
        errorMessage = nil

        do {
            baskets = try await basketRepository.fetchBaskets()

            // After successful data load, start real-time updates
            await startBasketUpdates()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    @MainActor
    func deleteBasket(_ basket: Basket) async {
        do {
            try await basketRepository.deleteBasket(id: basket.id)
            baskets.removeAll { $0.id == basket.id }
        } catch {
            errorMessage = "Failed to delete basket: \(error.localizedDescription)"
            showError = true
        }
    }

    @MainActor
    func refreshBaskets() async {
        await loadBaskets()
    }

    // MARK: - Computed Properties

    var activeBaskets: [Basket] {
        baskets.filter { $0.status == .active }
    }

    var pausedBaskets: [Basket] {
        baskets.filter { $0.status == .paused }
    }

    var hasBaskets: Bool {
        !baskets.isEmpty
    }

    var totalValue: Decimal {
        baskets.reduce(0) { $0 + $1.summary.currentValue }
    }

    var totalInvested: Decimal {
        baskets.reduce(0) { $0 + $1.summary.totalInvested }
    }

    var totalGainLoss: Decimal {
        baskets.reduce(0) { $0 + $1.summary.totalGainLoss }
    }

    // MARK: - WebSocket Real-Time Updates

    @MainActor
    private func startBasketUpdates() async {
        // Subscribe to baskets channel
        await webSocketService.subscribe(channels: [WebSocketChannel.baskets.rawValue])

        // Start event listener
        startBasketUpdatesListener()
    }

    @MainActor
    private func startBasketUpdatesListener() {
        guard basketUpdatesTask == nil else { return }

        basketUpdatesTask = Task { [weak self] in
            guard let self else { return }

            let stream = await webSocketService.eventUpdates()
            for await event in stream {
                await MainActor.run {
                    self.handleWebSocketEvent(event)
                }
            }
        }
    }

    @MainActor
    private func handleWebSocketEvent(_ event: WebSocketEvent) {
        switch event.name {
        case .basketValueChanged:
            if let payload = try? event.decodeData(WebSocketBasketValuePayload.self) {
                handleBasketValueUpdate(payload)
            }
        default:
            break
        }
    }

    @MainActor
    private func handleBasketValueUpdate(_ payload: WebSocketBasketValuePayload) {
        // Find matching basket by ID
        guard let index = baskets.firstIndex(where: { $0.id == payload.basketId }) else {
            // Basket not in local state - refresh list
            Task {
                await loadBaskets()
            }
            return
        }

        // Create new basket summary with updated values
        var basket = baskets[index]
        basket.summary = BasketSummary(
            currentValue: payload.currentValue.value,
            totalInvested: payload.totalInvested.value,
            totalGainLoss: payload.totalGainLoss.value
        )

        baskets[index] = basket

        // Computed properties (activeBaskets, totalValue, etc.) will auto-update
    }

    deinit {
        basketUpdatesTask?.cancel()

        // Note: Cannot await in deinit, but WebSocketService handles cleanup internally
        // The unsubscribe will happen when the service is deallocated or connection closes
    }
}
