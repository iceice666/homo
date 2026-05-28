import Foundation

// MARK: - Column IDs (spec order from CONTRACT.md)
enum ColumnID: String, CaseIterable, Hashable, Sendable {
    case pitched
    case specced
    case ready
    case building
    case reviewing
    case awaitingInput = "awaiting_input"
    case done
}

// MARK: - Connection state
enum Connection: Sendable {
    case disconnected
    case connecting
    case connected
}

// MARK: - Selection
enum Selection: Sendable {
    case none
    case ticket(String)
    case run(ticketId: String, runId: String)
}

// MARK: - App model (spec/app-flow.md)
struct AppModel: Sendable {
    var connection: Connection = .disconnected
    var projects: [Project] = []
    var activeProject: String? = nil
    var board: [ColumnID: [Ticket]] = [:]
    var selection: Selection = .none
    var runtimes: [Runtime] = []
    /// Ticket IDs with an in-flight Harmony request — cleared on server ack.
    var pendingOps: Set<String> = []
}

// MARK: - Messages (spec/app-flow.md)
enum Msg: Sendable {
    // Lifecycle
    case appStarted
    case harmonyConnected
    case harmonyDisconnected(String)
    case harmonyError(String)

    // Server → UI (Harmony push)
    case projectsReceived([Project])
    case ticketChanged(Ticket)
    case runStarted(Run)
    case runProgress(runId: String, chunk: String)
    case runFinished(runId: String, report: RunReport)
    case wipWarning(column: ColumnID, limit: Int)

    // UI → Harmony (user intent)
    case selectProject(String)
    case selectTicket(String)
    case selectRun(String)
    case dispatchRun(ticketId: String, agentId: String)
    case cancelRun(String)
    case moveTicket(ticketId: String, to: ColumnID)
    case markBlocked(ticketId: String, reason: String)
    case unblock(String)
}

// MARK: - Update (returns side-effect commands as closures)
typealias Cmd = @Sendable () -> Void

func update(msg: Msg, model: inout AppModel) -> [Cmd] {
    switch msg {
    case .appStarted:
        model.connection = .connecting
        return []

    case .harmonyConnected:
        model.connection = .connected
        return []

    case .harmonyDisconnected:
        model.connection = .disconnected
        return []

    case .harmonyError:
        model.pendingOps = []
        return []

    case .projectsReceived(let projects):
        model.projects = projects
        return []

    case .ticketChanged(let ticket):
        model.pendingOps.remove(ticket.id)
        var board = model.board
        if let col = ColumnID(rawValue: ticket.status) {
            var column = board[col] ?? []
            if let idx = column.firstIndex(where: { $0.id == ticket.id }) {
                column[idx] = ticket
            } else {
                column.append(ticket)
            }
            board[col] = column
        }
        model.board = board
        return []

    case .dispatchRun(let ticketId, _):
        model.pendingOps.insert(ticketId)
        return []

    case .moveTicket(let ticketId, _):
        model.pendingOps.insert(ticketId)
        return []

    case .selectProject(let id):
        model.activeProject = id
        model.board = [:]
        model.selection = .none
        return []

    case .selectTicket(let id):
        model.selection = .ticket(id)
        return []

    default:
        return []
    }
}
