//! Language Server Protocol — IDE integration via `tower-lsp`.

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use async_trait::async_trait;
use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer, LspService, Server};

#[cfg(feature = "lsp-perf")]
use std::borrow::Cow;
#[cfg(feature = "lsp-perf")]
use std::path::{Path, PathBuf};
#[cfg(feature = "lsp-perf")]
use std::sync::atomic::{AtomicU64, Ordering};
#[cfg(feature = "lsp-perf")]
use std::sync::Arc;
#[cfg(feature = "lsp-perf")]
use tower_lsp::jsonrpc::Error;
#[cfg(feature = "lsp-perf")]
use tower_lsp::jsonrpc::ErrorCode;

/// Minimal LSP backend — extend with workspace symbols, hover, etc.
pub struct RiceLanguageServer {
    client: Client,
    /// Debounce generation for `did_save` → `bench --json-smoke` (feature `lsp-perf`).
    #[cfg(feature = "lsp-perf")]
    perf_seq: Arc<AtomicU64>,
}

impl RiceLanguageServer {
    pub fn new(client: Client) -> Self {
        Self {
            client,
            #[cfg(feature = "lsp-perf")]
            perf_seq: Arc::new(AtomicU64::new(0)),
        }
    }
}

#[async_trait]
impl LanguageServer for RiceLanguageServer {
    async fn initialize(&self, _: InitializeParams) -> Result<InitializeResult> {
        #[cfg(feature = "lsp-perf")]
        let capabilities = ServerCapabilities {
            text_document_sync: Some(TextDocumentSyncCapability::Options(TextDocumentSyncOptions {
                open_close: Some(true),
                change: Some(TextDocumentSyncKind::INCREMENTAL),
                save: Some(
                    SaveOptions {
                        include_text: Some(false),
                    }
                    .into(),
                ),
                ..Default::default()
            })),
            execute_command_provider: Some(ExecuteCommandOptions {
                commands: vec![String::from(lsp_perf::REFRESH_BASE_PERF_CMD)],
                work_done_progress_options: Default::default(),
            }),
            ..Default::default()
        };

        #[cfg(not(feature = "lsp-perf"))]
        let capabilities = ServerCapabilities {
            text_document_sync: Some(TextDocumentSyncCapability::Kind(
                TextDocumentSyncKind::INCREMENTAL,
            )),
            ..Default::default()
        };

        Ok(InitializeResult {
            capabilities,
            ..Default::default()
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, ".rice language server ready")
            .await;
        #[cfg(feature = "lsp-perf")]
        self.client
            .log_message(
                MessageType::INFO,
                "lsp-perf: command `rice.refreshBasePerf`; optional save-hook set RICE_LSP_PERF=1 (debounced); RICE_BENCH_BIN or target/{debug,release}/bench",
            )
            .await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
    }

    async fn did_save(&self, params: DidSaveTextDocumentParams) {
        #[cfg(feature = "lsp-perf")]
        {
            if std::env::var_os("RICE_LSP_PERF").is_none() {
                return;
            }
            let uri = params.text_document.uri;
            if uri.scheme() != "file" {
                return;
            }
            let Ok(path) = uri.to_file_path() else {
                return;
            };
            if path.extension().and_then(|s| s.to_str()) != Some("rice") {
                return;
            }
            self.schedule_refresh_base_perf(path);
        }
        #[cfg(not(feature = "lsp-perf"))]
        let _ = params;
    }

    async fn execute_command(&self, params: ExecuteCommandParams) -> Result<Option<serde_json::Value>> {
        #[cfg(feature = "lsp-perf")]
        if params.command == lsp_perf::REFRESH_BASE_PERF_CMD {
            return self.run_refresh_base_perf_command(None).await;
        }
        #[cfg(not(feature = "lsp-perf"))]
        let _ = &params;
        Err(tower_lsp::jsonrpc::Error::method_not_found())
    }
}

#[cfg(feature = "lsp-perf")]
mod lsp_perf {
    use std::path::{Path, PathBuf};
    use std::process::Command;

    pub const REFRESH_BASE_PERF_CMD: &str = "rice.refreshBasePerf";

    pub const DEBOUNCE_MS: u64 = 900;
    pub const LOG_CHUNK: usize = 3500;

    pub fn bench_exe_name() -> &'static str {
        if cfg!(windows) {
            "bench.exe"
        } else {
            "bench"
        }
    }

    pub fn resolve_bench_binary(walk_from_dir: Option<&Path>) -> Option<PathBuf> {
        if let Ok(p) = std::env::var("RICE_BENCH_BIN") {
            let pb = PathBuf::from(p);
            if pb.is_file() {
                return Some(pb);
            }
        }
        let mut dir = walk_from_dir
            .map(Path::to_path_buf)
            .or_else(|| std::env::current_dir().ok())?;
        loop {
            for profile in ["release", "debug"] {
                let candidate = dir.join("target").join(profile).join(bench_exe_name());
                if candidate.is_file() {
                    return Some(candidate);
                }
            }
            if !dir.pop() {
                break;
            }
        }
        None
    }

    pub fn run_bench_json_smoke(walk_from_dir: Option<&Path>) -> Result<String, String> {
        let bench = resolve_bench_binary(walk_from_dir)
            .ok_or_else(|| "bench: could not resolve binary (set RICE_BENCH_BIN or build with `cargo build -p bench` from a workspace ancestor)".to_string())?;
        let out = Command::new(&bench)
            .arg("--json-smoke")
            .output()
            .map_err(|e| format!("bench: failed to spawn {}: {e}", bench.display()))?;
        if !out.status.success() {
            let stderr = String::from_utf8_lossy(&out.stderr);
            return Err(format!(
                "bench --json-smoke exited {}: {stderr}",
                out.status
            ));
        }
        Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
    }
}

#[cfg(feature = "lsp-perf")]
impl RiceLanguageServer {
    async fn run_refresh_base_perf_command(
        &self,
        walk_from_dir: Option<PathBuf>,
    ) -> Result<Option<serde_json::Value>> {
        let walk_from = walk_from_dir;
        let json_str = tokio::task::spawn_blocking(move || {
            lsp_perf::run_bench_json_smoke(walk_from.as_deref())
        })
            .await
            .map_err(|e| Error {
                code: ErrorCode::InternalError,
                message: Cow::Owned(format!("bench join error: {e}")),
                data: None,
            })?
            .map_err(|msg| Error {
                code: ErrorCode::InternalError,
                message: Cow::Owned(msg),
                data: None,
            })?;

        self.emit_base_perf_logs(&json_str).await;

        let summary = summarize_bench_json(&json_str);
        self.client
            .show_message(
                MessageType::INFO,
                format!("base perf smoke: {summary}"),
            )
            .await;

        let v = serde_json::from_str(&json_str).map_err(|e| Error {
            code: ErrorCode::InternalError,
            message: Cow::Owned(format!("bench JSON parse error: {e}")),
            data: None,
        })?;
        Ok(Some(v))
    }

    fn schedule_refresh_base_perf(&self, saved_file: PathBuf) {
        let seq = self.perf_seq.fetch_add(1, Ordering::Relaxed) + 1;
        let client = self.client.clone();
        let perf_seq = self.perf_seq.clone();
        let walk_dir = saved_file.parent().map(Path::to_path_buf);
        tokio::spawn(async move {
            tokio::time::sleep(std::time::Duration::from_millis(lsp_perf::DEBOUNCE_MS)).await;
            if perf_seq.load(Ordering::Relaxed) != seq {
                return;
            }
            let json_res = tokio::task::spawn_blocking(move || {
                lsp_perf::run_bench_json_smoke(walk_dir.as_deref())
            })
            .await;

            let json_str = match json_res {
                Ok(Ok(s)) => s,
                Ok(Err(msg)) => {
                    client.log_message(MessageType::ERROR, msg).await;
                    return;
                }
                Err(e) => {
                    client
                        .log_message(MessageType::ERROR, format!("bench task join: {e}"))
                        .await;
                    return;
                }
            };

            emit_base_perf_logs_static(&client, &json_str).await;
            let summary = summarize_bench_json(&json_str);
            client
                .show_message(
                    MessageType::INFO,
                    format!("base perf smoke (on save): {summary}"),
                )
                .await;
        });
    }

    async fn emit_base_perf_logs(&self, json: &str) {
        emit_base_perf_logs_static(&self.client, json).await;
    }
}

#[cfg(feature = "lsp-perf")]
async fn emit_base_perf_logs_static(client: &Client, json: &str) {
    if json.len() <= lsp_perf::LOG_CHUNK {
        client
            .log_message(MessageType::INFO, format!("base/bench smoke JSON:\n{json}"))
            .await;
        return;
    }
    client
        .log_message(
            MessageType::INFO,
            format!(
                "base/bench smoke JSON ({} bytes, split across logs):",
                json.len()
            ),
        )
        .await;
    for (i, chunk) in json.as_bytes().chunks(lsp_perf::LOG_CHUNK).enumerate() {
        let piece = String::from_utf8_lossy(chunk);
        client
            .log_message(MessageType::INFO, format!("base/bench smoke part {}:\n{piece}", i + 1))
            .await;
    }
}

#[cfg(feature = "lsp-perf")]
fn summarize_bench_json(json: &str) -> String {
    match serde_json::from_str::<serde_json::Value>(json) {
        Ok(v) => {
            let n = v
                .get("rows")
                .and_then(|r| r.as_array())
                .map(|a| a.len())
                .unwrap_or(0);
            format!("{n} row(s)")
        }
        Err(_) => "unparsed JSON".to_string(),
    }
}

// Binary entrypoint for `rice-lsp`; unused when `lsp` is built as part of the library.
#[allow(dead_code)]
#[tokio::main]
async fn main() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();
    let (service, socket) = LspService::new(|client| RiceLanguageServer::new(client));
    Server::new(stdin, stdout, socket).serve(service).await;
}
