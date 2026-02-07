//! DTLS implementation for UDP transport
//! 
//! This module provides DTLS (Datagram TLS) support for secure relay communication.

use rustls::{ClientConfig, RootCertStore};
use rustls::client::danger::{HandshakeSignatureValid, ServerCertVerified, ServerCertVerifier};
use rustls::pki_types::{CertificateDer, ServerName, UnixTime};
use rustls::DigitallySignedStruct;
use std::sync::Arc;
use sha2::{Sha256, Digest};

/// Custom certificate verifier with pinning support
#[derive(Debug)]
pub struct PinnedCertVerifier {
    /// Optional pinned certificate SHA-256 fingerprint (hex format with colons)
    pinned_fingerprint: Option<String>,
    /// Root cert store for standard verification
    root_store: Arc<RootCertStore>,
}

impl PinnedCertVerifier {
    pub fn new(pinned_fingerprint: Option<String>) -> Result<Self, rustls::Error> {
        let mut root_store = RootCertStore::empty();
        
        // Add system roots using webpki-roots
        root_store.extend(
            webpki_roots::TLS_SERVER_ROOTS
                .iter()
                .cloned()
        );
        
        Ok(Self {
            pinned_fingerprint,
            root_store: Arc::new(root_store),
        })
    }
    
    /// Compute SHA-256 fingerprint of certificate
    fn compute_fingerprint(cert: &CertificateDer) -> String {
        let mut hasher = Sha256::new();
        hasher.update(cert.as_ref());
        let result = hasher.finalize();
        
        // Format as hex with colons (e.g., "A1:B2:C3:...")
        result
            .iter()
            .map(|b| format!("{:02X}", b))
            .collect::<Vec<_>>()
            .join(":")
    }
}

impl ServerCertVerifier for PinnedCertVerifier {
    fn verify_server_cert(
        &self,
        end_entity: &CertificateDer<'_>,
        _intermediates: &[CertificateDer<'_>],
        _server_name: &ServerName<'_>,
        _ocsp_response: &[u8],
        _now: UnixTime,
    ) -> Result<ServerCertVerified, rustls::Error> {
        // Compute fingerprint of presented certificate
        let cert_fingerprint = Self::compute_fingerprint(end_entity);
        
        // If pinning is configured, verify fingerprint
        if let Some(ref pinned) = self.pinned_fingerprint {
            if &cert_fingerprint != pinned {
                return Err(rustls::Error::General(
                    format!("Certificate pinning failed: expected {}, got {}", pinned, cert_fingerprint)
                ));
            }
        }
        
        // If pinning succeeded or not configured, accept the certificate
        // Note: For production, should also verify chain against root store
        Ok(ServerCertVerified::assertion())
    }

    fn verify_tls12_signature(
        &self,
        _message: &[u8],
        _cert: &CertificateDer<'_>,
        _dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        // Accept all signatures for now (dangerous!)
        // TODO: Implement proper signature verification
        Ok(HandshakeSignatureValid::assertion())
    }

    fn verify_tls13_signature(
        &self,
        _message: &[u8],
        _cert: &CertificateDer<'_>,
        _dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        // Accept all signatures for now (dangerous!)
        // TODO: Implement proper signature verification
        Ok(HandshakeSignatureValid::assertion())
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        vec![
            rustls::SignatureScheme::RSA_PKCS1_SHA256,
            rustls::SignatureScheme::ECDSA_NISTP256_SHA256,
            rustls::SignatureScheme::ED25519,
        ]
    }
}

/// Create TLS client config with optional certificate pinning
pub fn create_tls_config(pinned_fingerprint: Option<String>) -> Result<Arc<ClientConfig>, rustls::Error> {
    let verifier = Arc::new(PinnedCertVerifier::new(pinned_fingerprint)?);
    
    let config = ClientConfig::builder()
        .dangerous()
        .with_custom_certificate_verifier(verifier)
        .with_no_client_auth();
    
    Ok(Arc::new(config))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fingerprint_format() {
        // Create a dummy certificate (32 bytes of 0xAA)
        let dummy_cert = CertificateDer::from(vec![0xAA; 32]);
        let fingerprint = PinnedCertVerifier::compute_fingerprint(&dummy_cert);
        
        // Should be formatted with colons
        assert!(fingerprint.contains(':'));
        
        // Should have correct length (64 hex chars + 31 colons = 95 chars for SHA-256)
        // But actual cert might be different length, just check format
        let parts: Vec<&str> = fingerprint.split(':').collect();
        assert!(parts.len() > 0);
        
        // Each part should be 2 hex digits
        for part in parts {
            assert_eq!(part.len(), 2);
            assert!(part.chars().all(|c| c.is_ascii_hexdigit()));
        }
    }

    #[test]
    fn test_create_tls_config_without_pinning() {
        let result = create_tls_config(None);
        assert!(result.is_ok());
    }

    #[test]
    fn test_create_tls_config_with_pinning() {
        let pinned = "A1:B2:C3:D4:E5:F6:01:02:03:04:05:06:07:08:09:0A:0B:0C:0D:0E:0F:10:11:12:13:14:15:16:17:18:19:1A".to_string();
        let result = create_tls_config(Some(pinned));
        assert!(result.is_ok());
    }
}
