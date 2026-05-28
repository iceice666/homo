import Foundation

struct Project: Codable, Identifiable, Sendable {
    let id: String
    let name: String
}

struct Ticket: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    var status: String
    var spec: TicketSpec?
}

struct TicketSpec: Codable, Sendable {
    var what: String?
    var respecNotes: [String]?
    var reworkNotes: [String]?
    var clarifications: [Clarification]?

    enum CodingKeys: String, CodingKey {
        case what
        case respecNotes = "respec_notes"
        case reworkNotes = "rework_notes"
        case clarifications
    }
}

struct Clarification: Codable, Sendable {
    let questionId: String
    let answer: String

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case answer
    }
}

struct Run: Codable, Identifiable, Sendable {
    let id: String
    let ticketId: String

    enum CodingKeys: String, CodingKey {
        case id = "run_id"
        case ticketId = "ticket_id"
    }
}

struct RunReport: Codable, Sendable {
    let runId: String
    let ticketId: String
    let exitReason: String

    enum CodingKeys: String, CodingKey {
        case runId = "run_id"
        case ticketId = "ticket_id"
        case exitReason = "exit_reason"
    }
}

struct Runtime: Codable, Identifiable, Sendable {
    let id: String
    let name: String
}
