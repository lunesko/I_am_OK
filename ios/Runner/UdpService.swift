import Foundation
import Network

final class UdpService {
    private let port: NWEndpoint.Port = 45678
    private let relayHost = NWEndpoint.Host("213.188.195.83")
    private let relayPort: NWEndpoint.Port = 40100
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
        send(to: NWEndpoint.Host("255.255.255.255"), port: port, data: data)
        send(to: relayHost, port: relayPort, data: data)
    }

    private func send(to host: NWEndpoint.Host, port: NWEndpoint.Port, data: Data) {
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        if let any = IPv4Address("0.0.0.0") {
            params.requiredLocalEndpoint = .hostPort(host: .ipv4(any), port: self.port)
        }

        let connection = NWConnection(host: host, port: port, using: params)
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
