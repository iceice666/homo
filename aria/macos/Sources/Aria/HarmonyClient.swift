import Foundation
import Observation

/// Thin Phoenix Channels client over URLSessionWebSocketTask.
/// Sends/receives JSON-encoded Phoenix message envelopes.
@Observable
@MainActor
final class HarmonyClient {
    var connectionState: Connection = .disconnected

    private var webSocketTask: URLSessionWebSocketTask?
    private var msgHandler: (@MainActor (Msg) -> Void)?

    func connect(wsURL: URL, token: String, onMsg: @escaping @MainActor (Msg) -> Void) {
        self.msgHandler = onMsg
        var components = URLComponents(url: wsURL, resolvingAgainstBaseURL: false)!
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "token", value: token))
        components.queryItems = items
        guard let url = components.url else { return }

        let task = URLSession.shared.webSocketTask(with: url)
        webSocketTask = task
        connectionState = .connecting
        task.resume()
        // TODO: send Phoenix join heartbeat, listen for incoming messages
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }

    /// Push a Phoenix Channels message to Harmony.
    func push(topic: String, event: String, payload: [String: Any] = [:]) {
        guard connectionState == .connected,
              let task = webSocketTask else { return }
        let envelope: [String: Any] = [
            "topic": topic,
            "event": event,
            "payload": payload,
            "ref": NSNull()
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: envelope),
              let text = String(data: data, encoding: .utf8) else { return }
        task.send(.string(text)) { _ in }
    }
}
