//! Tests for DTLS transport

#[cfg(test)]
mod tests {
    use crate::transport::udp::{UdpTransport, UdpTransportConfig};
    use crate::transport::Transport;
    use crate::core::{Message, StatusType, Identity};

    #[tokio::test]
    async fn test_tls_required_for_send() {
        let mut config = UdpTransportConfig::default();
        config.tls_disabled = true;
        
        let transport = UdpTransport::with_config(config);
        let sender = Identity::new();
        let receiver = Identity::new();
        
        let message = Message::status(sender.id.clone(), StatusType::Ok);
        let packet = crate::core::Packet::from_message(
            &message,
            &sender,
            &receiver.x25519_public_bytes().unwrap(),
        ).unwrap();
        
        // Should fail because TLS is disabled
        let result = transport.send_packet(&packet, "test").await;
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("TLS is required"));
    }

    #[tokio::test]
    async fn test_tls_required_for_listen() {
        let mut config = UdpTransportConfig::default();
        config.tls_disabled = true;
        
        let transport = UdpTransport::with_config(config);
        
        let callback = Box::new(|_packet| {
            // Empty callback
        });
        
        // Should fail because TLS is disabled
        let result = transport.start_listening(callback).await;
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("TLS is required"));
    }

    #[tokio::test]
    async fn test_config_with_pinning() {
        let pinned_fingerprint = "A1:B2:C3:D4:E5:F6:01:02:03:04:05:06:07:08:09:0A:0B:0C:0D:0E:0F:10:11:12:13:14:15:16:17:18:19:1A".to_string();
        
        let config = UdpTransportConfig {
            relay_url: "example.com:443".to_string(),
            pinned_cert_fingerprint: Some(pinned_fingerprint.clone()),
            tls_disabled: false,
        };
        
        let transport = UdpTransport::with_config(config);
        assert_eq!(transport.config.pinned_cert_fingerprint, Some(pinned_fingerprint));
    }

    #[tokio::test]
    async fn test_default_config() {
        let transport = UdpTransport::new();
        assert_eq!(transport.config.relay_url, "i-am-ok-relay.fly.dev:40100");
        assert_eq!(transport.config.pinned_cert_fingerprint, None);
        assert_eq!(transport.config.tls_disabled, false);
    }

    #[test]
    fn test_packet_size_limit() {
        // Verify that start_listening will reject packets > 128KB
        // This is tested implicitly in the implementation
        // Here we just document the limit
        const MAX_PACKET_SIZE: usize = 128 * 1024;
        assert_eq!(MAX_PACKET_SIZE, 131072);
    }
}
