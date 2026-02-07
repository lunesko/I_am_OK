#[cfg(test)]
mod udp_tests {
    use crate::transport::{Transport, TransportType, TransportError};
    use crate::transport::udp::{UdpTransport, UdpTransportConfig};

    #[test]
    fn test_udp_transport_default_config() {
        let transport = UdpTransport::new();
        assert_eq!(transport.config.relay_url, "i-am-ok-relay.fly.dev:40100");
        assert_eq!(transport.config.tls_disabled, false);
        assert!(transport.config.pinned_cert_fingerprint.is_none());
    }

    #[test]
    fn test_udp_transport_custom_config() {
        let config = UdpTransportConfig {
            relay_url: "custom-relay.example.com:8443".to_string(),
            pinned_cert_fingerprint: Some("A1:B2:C3:D4:E5:F6".to_string()),
            tls_disabled: false,
        };
        
        let transport = UdpTransport::with_config(config);
        assert_eq!(transport.config.relay_url, "custom-relay.example.com:8443");
        assert_eq!(
            transport.config.pinned_cert_fingerprint,
            Some("A1:B2:C3:D4:E5:F6".to_string())
        );
    }

    #[test]
    fn test_certificate_pinning_success() {
        let config = UdpTransportConfig {
            relay_url: "relay.example.com:40100".to_string(),
            pinned_cert_fingerprint: Some("AA:BB:CC:DD:EE:FF".to_string()),
            tls_disabled: false,
        };
        
        let transport = UdpTransport::with_config(config);
        
        // Correct fingerprint - should succeed
        let result = transport.verify_certificate_pin("AA:BB:CC:DD:EE:FF");
        assert!(result.is_ok());
    }

    #[test]
    fn test_certificate_pinning_failure() {
        let config = UdpTransportConfig {
            relay_url: "relay.example.com:40100".to_string(),
            pinned_cert_fingerprint: Some("AA:BB:CC:DD:EE:FF".to_string()),
            tls_disabled: false,
        };
        
        let transport = UdpTransport::with_config(config);
        
        // Wrong fingerprint - should fail
        let result = transport.verify_certificate_pin("11:22:33:44:55:66");
        assert!(result.is_err());
        
        if let Err(TransportError::SecurityError(msg)) = result {
            assert!(msg.contains("Certificate pinning failed"));
            assert!(msg.contains("AA:BB:CC:DD:EE:FF")); // Expected pin
            assert!(msg.contains("11:22:33:44:55:66")); // Actual pin
        } else {
            panic!("Expected SecurityError");
        }
    }

    #[test]
    fn test_certificate_pinning_no_pin_configured() {
        let config = UdpTransportConfig {
            relay_url: "relay.example.com:40100".to_string(),
            pinned_cert_fingerprint: None,
            tls_disabled: false,
        };
        
        let transport = UdpTransport::with_config(config);
        
        // No pin configured - any fingerprint should succeed
        let result = transport.verify_certificate_pin("11:22:33:44:55:66");
        assert!(result.is_ok());
    }

    #[test]
    fn test_transport_type() {
        let transport = UdpTransport::new();
        assert_eq!(transport.transport_type(), TransportType::Udp);
    }

    #[tokio::test]
    async fn test_is_available_checks_network() {
        let transport = UdpTransport::new();
        
        // With default relay URL, should attempt to resolve
        // Result depends on network connectivity (may be true or false)
        let _available = transport.is_available().await;
        
        // Test with invalid URL - should be false
        let config = UdpTransportConfig {
            relay_url: "invalid-host-that-does-not-exist.local:40100".to_string(),
            pinned_cert_fingerprint: None,
            tls_disabled: false,
        };
        let transport = UdpTransport::with_config(config);
        assert!(!transport.is_available().await, "Invalid hostname should not be available");
    }
}
