//! Link `libclerk-security.a` when the `zig-warden` feature is enabled.
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-env-changed=RICE_CLERK_SECURITY_LIB_DIR");

    if std::env::var("CARGO_FEATURE_ZIG_WARDEN").ok().as_deref() != Some("1") {
        return;
    }
    if !cfg!(unix) {
        println!("cargo:warning=zig-warden is only wired for unix static linking");
        return;
    }

    let manifest_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let lib_dir = std::env::var("RICE_CLERK_SECURITY_LIB_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| manifest_dir.join("..").join("zig-out").join("lib"));

    let lib_a = lib_dir.join("libclerk-security.a");
    if !lib_a.is_file() {
        panic!(
            "zig-warden enabled but {} is missing — run `zig build` from the `base/` directory (Zig 0.15+; see base/ZIG_WARDEN.md).",
            lib_a.display()
        );
    }

    println!("cargo:rustc-link-search=native={}", lib_dir.display());
    println!("cargo:rustc-link-lib=static=clerk-security");
    println!("cargo:rustc-link-lib=c");
}
