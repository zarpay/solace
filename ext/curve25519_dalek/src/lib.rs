use curve25519_dalek::edwards::CompressedEdwardsY;

/// Exposed to Ruby via FFI — returns:
/// - 1 for on-curve
/// - 0 for off-curve
/// - -1 for null input
#[no_mangle]
pub extern "C" fn is_on_curve(pubkey_ptr: *const u8) -> i32 {
    if pubkey_ptr.is_null() {
        return -1;
    }

    let pubkey = unsafe { std::slice::from_raw_parts(pubkey_ptr, 32) };

    match CompressedEdwardsY::from_slice(pubkey) {
        Ok(compressed) => match compressed.decompress() {
            Some(_) => 1, // on-curve and safe
            _ => 0, // decompress failed or invalid point
        },
        Err(_) => 0, // not even a valid 32-byte input
    }
}
