//
//  BasketDetailViewModel.swift
//  Growfolio
//
//  ViewModel for basket detail view.
//

import Foundation

@Observable
final class BasketDetailViewModel: @unchecked Sendable {

    // MARK: - Properties

    var basket: Basket
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let basketRepository: BasketRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol

    // WebSocket Tasks
    nonisolated(unsafe) private var basketUpdatesTask: Task<Void, Never>?

    // MARK: - Initialization

    nonisolated(unsafe) init(
        basket: Basket,
        basketRepository: BasketRepositoryProtocol = RepositoryContainer.basketRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.basket = basket
        self.basketRepository = basketRepository
        self.webSocketService = webSocketService ?? MainActor.assumeIsolated { WebSocketService.shared }
    }

    // MARK: - Methods

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            basket = try await basketRepository.fetchBasket(id: basket.id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    @MainActor
    func startRealtimeUpdates() async {
        // Subscribe to baskets channel
        await webSocketService.subscribe(channels: [WebSocketChannel.baskets.rawValue])

        // Start event listener
        startBasketUpdatesListener()
    }

    @MainActor
    func toggleStatus() async {
        let newStatus: BasketStatus = basket.status == .active ? .paused : .active

        do {
            let updatedBasket = try await basketRepository.updateBasket(
                id: basket.id,
                BasketCreate(
                    name: basket.name,
                    description: basket.description,
                    category: basket.category,
                    icon: basket.icon,
                    color: basket.color,
                    allocations: basket.allocations,
                    isShared: basket.isShared
                )
            )
            basket = updatedBasket
        } catch {
            errorMessage = "Failed to update basket: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Computed Properties

    var returnPercentage: Decimal {
        basket.summary.returnPercentage
    }

    var isGaining: Bool {
        basket.summary.totalGainLoss > 0
    }

    var performanceColor: String {
        isGaining ? "#34C759" : "#FF3B30"
    }

    // MARK: - WebSocket Real-Time Updates

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
        // Only update if this is the current basket
        guard basket.id == payload.basketId else { return }

        // Create new basket summary with updated values
        basket.summary = BasketSummary(
            currentValue: payload.currentValue.value,
            totalInvested: payload.totalInvested.value,
            totalGainLoss: payload.totalGainLoss.value
        )

        // Computed properties (returnPercentage, isGaining) will auto-update
    }

    deinit {
        basketUpdatesTask?.cancel()

        // Note: Cannot await in deinit, but WebSocketService handles cleanup internally
        // The unsubscribe will happen when the service is deallocated or connection closes
    }
}
