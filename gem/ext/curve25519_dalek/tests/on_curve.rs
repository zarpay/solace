use curve25519_dalek::edwards::CompressedEdwardsY;
use bs58;
use std::fs;
use std::convert::TryFrom;

fn decode(b58: &str) -> [u8; 32] {
    let decoded = bs58::decode(b58).into_vec().unwrap();
    assert_eq!(decoded.len(), 32);
    let mut buf = [0u8; 32];
    buf.copy_from_slice(&decoded);
    buf
}

fn check_on_curve(bytes: &[u8; 32]) -> bool {
    match CompressedEdwardsY::try_from(bytes.as_slice()) {
        Ok(c) => match c.decompress() {
            Some(point) => point.is_torsion_free(),
            None => false,
        },
        Err(_) => false,
    }
}

#[test]
fn test_regular_wallet_key() {
    let key = decode("AjVmYouQBusntGW4iGA5h3whxnN6r9wrQb5Ds5Ky7sqt");
    assert!(check_on_curve(&key));
}

#[test]
fn test_known_pda_key() {
    let key = decode("2FXrCXJhBNG4mJp3cKyUuzrxEGRACxJP6DP2YB5mfVxJ");
    assert!(!check_on_curve(&key));
}

#[test]
fn test_all_zero_key() {
    let key = [0u8; 32];
    assert!(!check_on_curve(&key));
}
