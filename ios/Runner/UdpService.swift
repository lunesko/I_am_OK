import Foundation
import Network

final class UdpService {
    private let port: NWEndpoint.Port = 45678
    private let relayHost: NWEndpoint.Host
    private let relayPort: NWEndpoint.Port
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "yaok.udp")
    private let securityManager = RelaySecurityManager()
    var onMessage: ((Data, String) -> Void)?
    
    init() {
        // Load relay configuration from Config.plist
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: configPath),
           let relayConfig = config["RelayConfiguration"] as? [String: Any],
           let host = relayConfig["PrimaryHost"] as? String,
           let port = relayConfig["PrimaryPort"] as? Int {
            self.relayHost = NWEndpoint.Host(host)
            self.relayPort = NWEndpoint.Port(rawValue: UInt16(port)) ?? 40100
        } else {
            // Fallback to default values if config not found
            self.relayHost = NWEndpoint.Host("213.188.195.83")
            self.relayPort = 40100
        }
    }

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
        
        // Security: Validate relay endpoint before sending
        let relayEndpoint = NWEndpoint.hostPort(host: relayHost, port: relayPort)
        if securityManager.validateRelayEndpoint(relayEndpoint) {
            send(to: relayHost, port: relayPort, data: data)
        } else {
            print("⚠️ Relay endpoint validation failed")
        }
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
                
                // Security: Validate incoming packets from relay
                if let self = self, !self.securityManager.validateIncomingPacket(from: connection.endpoint, data: data) {
                    print("⚠️ Relay packet validation failed from \(addr)")
                } else {
                    self?.onMessage?(data, addr)
                }
            }
            if error == nil {
                self?.receive(on: connection)
            }
        }
    }
}
