import Foundation

/// Maps command identifiers to their runnable handlers. The palette resolves
/// activations through this registry so command declarations
/// (``CommandPaletteCommandContribution``) stay separate from host behavior.
public struct CommandPaletteHandlerRegistry {
    private var handlers: [String: CmuxActionHandler] = [:]

    /// Creates an empty registry.
    public init() {}

    /// Registers `handler` for `commandId`, replacing any existing handler.
    public mutating func register(
        commandId: String,
        handler: @escaping @MainActor () -> Void
    ) {
        handlers[commandId] = { _ in
            handler()
            return .completed
        }
    }

    /// Registers an argument-aware action handler for `commandId`.
    public mutating func register(
        commandId: String,
        handler: @escaping CmuxActionHandler
    ) {
        handlers[commandId] = handler
    }

    /// The handler registered for `commandId`, when any.
    public func handler(for commandId: String) -> CmuxActionHandler? {
        handlers[commandId]
    }
}
