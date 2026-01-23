import Foundation
import Network

final class UdpService {
    private let port: NWEndpoint.Port = 45678
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "yaok.udp")
    var onMessage: ((Data, String) -> Void)?

    func start() {
        do {
            let listener = try NWListener(using: .udp, on: port)
            listener.newConnectionHandler = { [weak self] connection in
                connection.start(queue: self?.queue ?? .global())
                self?.receive(on: connection)
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            listener = nil
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    func send(data: Data) {
        let connection = NWConnection(host: "255.255.255.255", port: port, using: .udp)
        connection.start(queue: queue)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            if let data = data, !data.isEmpty {
                let addr = connection.endpoint.debugDescription
                self?.onMessage?(data, addr)
            }
            if error == nil {
                self?.receive(on: connection)
            }
        }
    }
}
