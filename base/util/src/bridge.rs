//! Native FFI bridge: Haskell CALC (`calc-bridge`) and Zig `clerk-security` (`zig-warden`).
//!
//! Linking for the Zig static library is configured in `build.rs` at the crate root.

#[cfg(all(feature = "zig-warden", unix))]
pub mod warden {
//! Thin Rust bindings for Zig [`rice_warden_*`](../../security/src/warden.zig) exports (`clerk-security` static lib).

#[link(name = "clerk-security", kind = "static")]
unsafe extern "C" {
    fn rice_warden_check_leverage_limit(
        principal_len: usize,
        max_principal_len: usize,
        bps: i64,
        max_bps: i64,
    ) -> i32;
    fn rice_warden_prune_memory_remnants(ptr: *mut u8, len: usize);
    fn rice_warden_secure_wipe(ptr: *mut u8, len: usize);
}

/// Returns `true` if principal length and basis points are within caps (defense-in-depth vs CALC Haskell).
#[inline]
pub fn check_leverage_limit(
    principal_len: usize,
    max_principal_len: usize,
    bps: i64,
    max_bps: i64,
) -> bool {
    // SAFETY: C ABI exported from Zig `warden.zig`; no Rust invariants.
    unsafe { rice_warden_check_leverage_limit(principal_len, max_principal_len, bps, max_bps) == 0 }
}

/// Zero `len` bytes at `ptr` before releasing FFI-owned buffers (no-op if `ptr` is null or `len == 0`).
#[inline]
pub unsafe fn prune_memory_remnants(ptr: *mut u8, len: usize) {
    if ptr.is_null() || len == 0 {
        return;
    }
    // SAFETY: `ptr`/`len` describe a live allocation the caller owns (Haskell FFI out-buffer).
    unsafe { rice_warden_prune_memory_remnants(ptr, len) };
}

/// Volatile secure wipe (same semantics as [`prune_memory_remnants`]; stable Zig `export fn` symbol).
#[inline]
pub unsafe fn secure_wipe(ptr: *mut u8, len: usize) {
    if ptr.is_null() || len == 0 {
        return;
    }
    unsafe { rice_warden_secure_wipe(ptr, len) };
}

}

#[cfg(all(feature = "zig-warden", unix))]
pub mod stress {
//! Sovereign stress suite — C ABI [`rice_security_stress_test`](../../security/src/chaos.zig) from `clerk-security`.

#[link(name = "clerk-security", kind = "static")]
unsafe extern "C" {
    fn rice_security_stress_test() -> i32;
}

/// Run all Zig chaos / penetration checks; writes the audit trail to **stderr**. Returns `true` on success.
#[must_use]
pub fn run_security_stress_test() -> bool {
    // SAFETY: Zig `export fn` with no Rust invariants beyond return code.
    unsafe { rice_security_stress_test() == 0 }
}

}

#[cfg(all(feature = "calc-bridge", unix))]
pub mod calc {
//! **CALC / Haskell FFI (native targets only).**
//!
//! # Mathematical audit (Phase Alpha) — `policies` hot paths
//!
//! These sites are candidates to delegate to `base/calc` (Haskell + hledger-lib) instead of
//! duplicating arithmetic in Rust:
//!
//! - [`policies::finance`](../../policies/src/finance.rs): `validate_basis_points`, `amount_from_basis_points`,
//!   `amount_from_unit_ratio`, `marginal_scalar_from_brackets`, velocity / quota helpers later in the same file.
//! - [`policies::engine`](../../policies/src/engine.rs): `convert` host uses `rust_decimal` mul/div; oracle **price** is a
//!   CEL string or non-negative int (no `f64`).
//! - [`policies::currency`](../../policies/src/currency.rs): keep wire types; semantic transforms should match CALC.
//! - [`policies::accounting`](../../policies/src/accounting.rs): journal conservation vs Haskell `Ledger` + QuickCheck laws.
//!
//! **CosmWasm [`contract`](../../contract)** stays `Uint128` + attested deltas (no GHC in wasm).
//!
//! # Wire format
//!
//! ## Fast path (binary v1) — when `RICE_CALC_USE_BINARY=1`
//!
//! Request layout (little-endian, same as `FFI` in `base/calc/lib`):
//!
//! - bytes `0..4`: `u32` magic `1`
//! - bytes `4..8`: `u32` principal UTF-8 length (max 4096)
//! - bytes `8..16`: `i64` basis points
//! - bytes `16..`: principal decimal ASCII (minor units), UTF-8
//!
//! Response: magic `1`, `u32` fee UTF-8 length, fee bytes.
//!
//! ## Slow path (JSON) — default
//!
//! Request JSON: `{"principal_minor_units":"<decimal>","basis_points":<i64>}`; response fields match
//! `Wire` in `base/calc/lib` (`fee_minor_units`, `journal_line`, `rounding_mode`).
//!
//! # Runtime
//!
//! Load the shared library from **`RICE_CALC_LIB`**. `rice_calc_init` runs once per loaded library; [`shutdown`]
//! calls `rice_calc_shutdown` then `dlclose`.
//!
//! With **`zig-warden`** (in addition to **`calc-bridge`**), Zig `rice_warden_*` runs input caps and
//! secure wipe of Haskell-owned output buffers around JSON/binary calls.

use std::sync::Mutex;

use libc::{c_int, size_t};
use libloading::{Library, Symbol};
use serde::Deserialize;
use serde_json::json;

use crate::error::{RiceError, RiceResult};

#[cfg(feature = "zig-warden")]
use super::warden;

const RICE_BPS_BIN_MAGIC_V1: u32 = 1;
const RICE_BPS_BIN_MAX_PRINCIPAL: usize = 4096;

/// Zig warden: reject out-of-range inputs before crossing into Haskell RTS (defense-in-depth).
#[cfg(feature = "zig-warden")]
fn warden_guard_calc_input(principal_minor_units: &str, basis_points: i64) -> RiceResult<()> {
    const MAX_BPS: i64 = 1_000_000;
    if !warden::check_leverage_limit(
        principal_minor_units.len(),
        RICE_BPS_BIN_MAX_PRINCIPAL,
        basis_points,
        MAX_BPS,
    ) {
        return Err(RiceError::finance(String::from(
            "calc-bridge: warden rejected principal length or basis_points range",
        )));
    }
    Ok(())
}

struct Inner {
    lib: Library,
    rts_inited: bool,
}

static CALC: Mutex<Option<Inner>> = Mutex::new(None);

fn with_inner<T>(f: impl FnOnce(&Library) -> RiceResult<T>) -> RiceResult<T> {
    let mut slot = CALC.lock().map_err(|_| RiceError::message("calc-bridge: state mutex poisoned"))?;
    if slot.is_none() {
        let path = std::env::var_os("RICE_CALC_LIB").ok_or_else(|| {
            RiceError::message(
                "calc-bridge: set RICE_CALC_LIB to the path of librice_calc_ffi.so (from `cabal build foreign-library:rice_calc_ffi`)",
            )
        })?;
        let lib = unsafe { Library::new(path.as_os_str()) }.map_err(|e| RiceError::message(format!("calc-bridge dlopen: {e}")))?;
        *slot = Some(Inner {
            lib,
            rts_inited: false,
        });
    }
    let inner = slot.as_mut().expect("set above");
    if !inner.rts_inited {
        type InitFn = unsafe extern "C" fn();
        let init: Symbol<InitFn> = unsafe { inner.lib.get(b"rice_calc_init\0") }.map_err(|e| {
            RiceError::message(format!("calc-bridge: symbol rice_calc_init: {e}"))
        })?;
        unsafe { init() };
        inner.rts_inited = true;
    }
    f(&inner.lib)
}

/// Release the GHC RTS and unload the shared library.
pub fn shutdown() -> RiceResult<()> {
    let mut slot = CALC.lock().map_err(|_| RiceError::message("calc-bridge: state mutex poisoned"))?;
    if let Some(inner) = slot.take() {
        type ShutdownFn = unsafe extern "C" fn();
        if let Ok(sym) = unsafe { inner.lib.get::<ShutdownFn>(b"rice_calc_shutdown\0") } {
            unsafe { sym() };
        }
        drop(inner.lib);
    }
    Ok(())
}

#[derive(Debug, Deserialize)]
struct BasisPointsFeeResponse {
    fee_minor_units: String,
    #[allow(dead_code)]
    journal_line: String,
    #[allow(dead_code)]
    rounding_mode: String,
}

fn pack_bps_binary_v1(principal_minor_units: &str, basis_points: i64) -> RiceResult<Vec<u8>> {
    let pb = principal_minor_units.as_bytes();
    let plen = pb.len();
    if plen > RICE_BPS_BIN_MAX_PRINCIPAL {
        return Err(RiceError::message(format!(
            "calc-bridge binary v1: principal length {plen} exceeds {RICE_BPS_BIN_MAX_PRINCIPAL}"
        )));
    }
    let mut v = Vec::with_capacity(16 + plen);
    v.extend_from_slice(&RICE_BPS_BIN_MAGIC_V1.to_le_bytes());
    v.extend_from_slice(&(plen as u32).to_le_bytes());
    v.extend_from_slice(&basis_points.to_le_bytes());
    v.extend_from_slice(pb);
    Ok(v)
}

fn parse_bps_binary_response_v1(slice: &[u8]) -> RiceResult<String> {
    if slice.len() < 8 {
        return Err(RiceError::message(format!(
            "calc-bridge binary v1: response too short ({} bytes)",
            slice.len()
        )));
    }
    let magic = u32::from_le_bytes(slice[0..4].try_into().expect("len >= 8"));
    if magic != RICE_BPS_BIN_MAGIC_V1 {
        return Err(RiceError::message(format!("calc-bridge binary v1: bad magic {magic}")));
    }
    let fee_len = u32::from_le_bytes(slice[4..8].try_into().expect("len >= 8")) as usize;
    if slice.len() < 8 + fee_len {
        return Err(RiceError::message("calc-bridge binary v1: truncated fee"));
    }
    let fee = std::str::from_utf8(&slice[8..8 + fee_len]).map_err(|e| RiceError::message(format!("calc-bridge binary v1: fee UTF-8: {e}")))?;
    Ok(fee.to_string())
}

fn call_calc_fee_json(lib: &Library, principal_minor_units: &str, basis_points: i64) -> RiceResult<String> {
    type FeeJsonFn = unsafe extern "C" fn(*const u8, size_t, *mut *mut u8, *mut size_t) -> c_int;
    type FreeFn = unsafe extern "C" fn(*mut u8);

    let fee_json: Symbol<FeeJsonFn> = unsafe { lib.get(b"rice_calc_amount_from_basis_points_json\0") }.map_err(|e| {
        RiceError::message(format!("calc-bridge: symbol rice_calc_amount_from_basis_points_json: {e}"))
    })?;
    let free: Symbol<FreeFn> =
        unsafe { lib.get(b"rice_calc_free\0") }.map_err(|e| RiceError::message(format!("calc-bridge: symbol rice_calc_free: {e}")))?;

    let body = json!({
        "principal_minor_units": principal_minor_units,
        "basis_points": basis_points,
    });
    let input = serde_json::to_vec(&body).map_err(|e| RiceError::message(format!("calc-bridge encode: {e}")))?;

    #[cfg(feature = "zig-warden")]
    warden_guard_calc_input(principal_minor_units, basis_points)?;

    unsafe {
        let mut out_ptr: *mut u8 = std::ptr::null_mut();
        let mut out_len: size_t = 0;
        let rc = fee_json(input.as_ptr(), input.len(), &mut out_ptr, &mut out_len);
        if rc != 0 {
            if !out_ptr.is_null() {
                #[cfg(feature = "zig-warden")]
                warden::prune_memory_remnants(out_ptr, out_len);
                free(out_ptr);
            }
            return Err(RiceError::finance(format!(
                "calc-bridge rice_calc_amount_from_basis_points_json rc={rc}"
            )));
        }
        if out_ptr.is_null() || out_len == 0 {
            return Err(RiceError::finance(String::from(
                "calc-bridge: empty response from rice_calc_amount_from_basis_points_json",
            )));
        }
        let slice = std::slice::from_raw_parts(out_ptr, out_len);
        let parsed: BasisPointsFeeResponse = serde_json::from_slice(slice).map_err(|e| {
            #[cfg(feature = "zig-warden")]
            warden::prune_memory_remnants(out_ptr, out_len);
            free(out_ptr);
            RiceError::message(format!("calc-bridge decode: {e}"))
        })?;
        #[cfg(feature = "zig-warden")]
        warden::prune_memory_remnants(out_ptr, out_len);
        free(out_ptr);
        Ok(parsed.fee_minor_units)
    }
}

fn call_calc_fee_binary(lib: &Library, principal_minor_units: &str, basis_points: i64) -> RiceResult<String> {
    type FeeBinFn = unsafe extern "C" fn(*const u8, size_t, *mut *mut u8, *mut size_t) -> c_int;
    type FreeFn = unsafe extern "C" fn(*mut u8);

    let fee_bin: Symbol<FeeBinFn> = unsafe { lib.get(b"rice_calc_basis_points_fee_binary\0") }.map_err(|e| {
        RiceError::message(format!("calc-bridge: symbol rice_calc_basis_points_fee_binary: {e}"))
    })?;
    let free: Symbol<FreeFn> =
        unsafe { lib.get(b"rice_calc_free\0") }.map_err(|e| RiceError::message(format!("calc-bridge: symbol rice_calc_free: {e}")))?;

    let input = pack_bps_binary_v1(principal_minor_units, basis_points)?;

    #[cfg(feature = "zig-warden")]
    warden_guard_calc_input(principal_minor_units, basis_points)?;

    unsafe {
        let mut out_ptr: *mut u8 = std::ptr::null_mut();
        let mut out_len: size_t = 0;
        let rc = fee_bin(input.as_ptr(), input.len(), &mut out_ptr, &mut out_len);
        if rc != 0 {
            if !out_ptr.is_null() {
                #[cfg(feature = "zig-warden")]
                warden::prune_memory_remnants(out_ptr, out_len);
                free(out_ptr);
            }
            return Err(RiceError::finance(format!(
                "calc-bridge rice_calc_basis_points_fee_binary rc={rc}"
            )));
        }
        if out_ptr.is_null() || out_len == 0 {
            return Err(RiceError::finance(String::from(
                "calc-bridge: empty response from rice_calc_basis_points_fee_binary",
            )));
        }
        let slice = std::slice::from_raw_parts(out_ptr, out_len);
        let fee = parse_bps_binary_response_v1(slice).map_err(|e| {
            #[cfg(feature = "zig-warden")]
            warden::prune_memory_remnants(out_ptr, out_len);
            free(out_ptr);
            e
        })?;
        #[cfg(feature = "zig-warden")]
        warden::prune_memory_remnants(out_ptr, out_len);
        free(out_ptr);
        Ok(fee)
    }
}

/// Call CALC for `principal * bps / 10_000` and return the fee as a decimal **string** (minor units).
///
/// When **`RICE_CALC_USE_BINARY=1`**, uses the binary v1 ABI (`rice_calc_basis_points_fee_binary`).
/// Otherwise uses JSON (`rice_calc_amount_from_basis_points_json`).
pub fn basis_points_fee_minor_units(principal_minor_units: &str, basis_points: i64) -> RiceResult<String> {
    with_inner(|lib| {
        if std::env::var("RICE_CALC_USE_BINARY").ok().as_deref() == Some("1") {
            call_calc_fee_binary(lib, principal_minor_units, basis_points)
        } else {
            call_calc_fee_json(lib, principal_minor_units, basis_points)
        }
    })
}

#[cfg(test)]
mod tests {
    use super::{pack_bps_binary_v1, parse_bps_binary_response_v1, RICE_BPS_BIN_MAGIC_V1};

    #[test]
    fn binary_v1_pack_len_matches_layout() {
        let v = pack_bps_binary_v1("10000", 250).unwrap();
        assert_eq!(v.len(), 16 + 5);
        assert_eq!(u32::from_le_bytes(v[0..4].try_into().unwrap()), RICE_BPS_BIN_MAGIC_V1);
    }

    #[test]
    fn binary_v1_parse_response_matches_haskell_layout() {
        let mut out = Vec::new();
        out.extend_from_slice(&RICE_BPS_BIN_MAGIC_V1.to_le_bytes());
        let fee = b"250";
        out.extend_from_slice(&(fee.len() as u32).to_le_bytes());
        out.extend_from_slice(fee);
        assert_eq!(parse_bps_binary_response_v1(&out).unwrap(), "250");
    }
}

}
