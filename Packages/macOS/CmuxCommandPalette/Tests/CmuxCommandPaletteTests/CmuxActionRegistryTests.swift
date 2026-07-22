import Testing
@testable import CmuxCommandPalette

@MainActor
@Suite("Cmux action registry")
struct CmuxActionRegistryTests {
    @Test func automationRequiresStaticallyDeclaredArguments() {
        var didRun = false
        let command = makeCommand(arguments: [
            CmuxActionArgumentDefinition(name: "name", allowsEmpty: true),
        ]) { _ in
            didRun = true
            return .completed
        }

        #expect(command.execute(CmuxActionInvocation(source: .automation)) == .requiresArguments([
            CmuxActionArgumentDefinition(name: "name", allowsEmpty: true),
        ]))
        #expect(!didRun)
    }

    @Test func paletteMayCollectMissingArgumentsInteractively() {
        let command = makeCommand(arguments: [
            CmuxActionArgumentDefinition(name: "name"),
        ]) { invocation in
            #expect(invocation.arguments.isEmpty)
            return .presented
        }

        #expect(command.execute(CmuxActionInvocation(source: .commandPalette)) == .presented)
    }

    @Test func automationForwardsDeclaredArgumentsIncludingEmptyValues() {
        var received: CmuxActionInvocation?
        let command = makeCommand(arguments: [
            CmuxActionArgumentDefinition(name: "name", allowsEmpty: true),
        ]) { invocation in
            received = invocation
            return .completed
        }
        let invocation = CmuxActionInvocation(
            source: .automation,
            arguments: ["name": ""]
        )

        #expect(command.execute(invocation) == .completed)
        #expect(received == invocation)
    }

    @Test func undeclaredArgumentsAreRejectedBeforeExecution() {
        var didRun = false
        let command = makeCommand { _ in
            didRun = true
            return .completed
        }

        #expect(command.execute(CmuxActionInvocation(
            source: .automation,
            arguments: ["surprise": "value"]
        )) == .invalidArguments(["surprise"]))
        #expect(!didRun)
    }

    @Test func registryUsesStableStringIDsAndRejectsDuplicates() {
        let first = makeCommand(id: "custom.deploy") { _ in .completed }
        let duplicate = makeCommand(id: "custom.deploy") { _ in .presented }
        var registry = CmuxActionRegistry()

        let registeredFirst = registry.register(first)
        let registeredDuplicate = registry.register(duplicate)
        #expect(registeredFirst)
        #expect(!registeredDuplicate)
        #expect(registry.actions.map(\.id) == ["custom.deploy"])
        #expect(registry.run(
            id: "custom.deploy",
            invocation: CmuxActionInvocation(source: .automation)
        ) == .completed)
    }

    private func makeCommand(
        id: String = "palette.test",
        arguments: [CmuxActionArgumentDefinition] = [],
        handler: @escaping CmuxActionHandler
    ) -> CommandPaletteCommand {
        CommandPaletteCommand(
            id: id,
            rank: 0,
            title: "Test",
            subtitle: "Tests",
            shortcutHint: nil,
            kindLabel: nil,
            keywords: [],
            dismissOnRun: true,
            arguments: arguments,
            handler: handler
        )
    }
}
