//! Language Server Protocol — IDE integration via `tower-lsp`.

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use async_trait::async_trait;
use std::collections::{HashMap, HashSet};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use tower_lsp::jsonrpc::Result as JsonRpcResult;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer as TowerLanguageServer, LspService, Server};

use crate::rice_infra_fmt;
use crate::rice_lsp::{self, RiceDiagnostic};

#[cfg(feature = "lsp-perf")]
use std::borrow::Cow;
#[cfg(feature = "lsp-perf")]
use tower_lsp::jsonrpc::Error;
#[cfg(feature = "lsp-perf")]
use tower_lsp::jsonrpc::ErrorCode;

const DIAG_DEBOUNCE_MS: u64 = 400;

/// LSP backend for CHIEF infra `.rice` diagnostics and formatting.
pub struct MintLspBackend {
    client: Client,
    allowed_tf: HashSet<String>,
    documents: Arc<Mutex<HashMap<Url, String>>>,
    diag_seq: Arc<AtomicU64>,
    #[cfg(feature = "lsp-perf")]
    perf_seq: Arc<AtomicU64>,
}

impl MintLspBackend {
    pub fn new(client: Client) -> Self {
        let allowed_tf = crate::overlay::terraform_rice_variable_names()
            .into_iter()
            .collect();
        Self {
            client,
            allowed_tf,
            documents: Arc::new(Mutex::new(HashMap::new())),
            diag_seq: Arc::new(AtomicU64::new(0)),
            #[cfg(feature = "lsp-perf")]
            perf_seq: Arc::new(AtomicU64::new(0)),
        }
    }

    fn is_chief_infra_uri(&self, uri: &Url) -> bool {
        if uri.scheme() != "file" {
            return false;
        }
        let Ok(path) = uri.to_file_path() else {
            return false;
        };
        rice_lsp::classify_chief_path(&path).is_some()
    }

    fn schedule_validate(&self, uri: Url) {
        if !self.is_chief_infra_uri(&uri) {
            return;
        }
        let seq = self.diag_seq.fetch_add(1, Ordering::Relaxed) + 1;
        let client = self.client.clone();
        let documents = self.documents.clone();
        let allowed_tf = self.allowed_tf.clone();
        let diag_seq = self.diag_seq.clone();
        tokio::spawn(async move {
            tokio::time::sleep(std::time::Duration::from_millis(DIAG_DEBOUNCE_MS)).await;
            if diag_seq.load(Ordering::Relaxed) != seq {
                return;
            }
            let (path, src) = {
                let docs = documents.lock().ok();
                let Some(docs) = docs else {
                    return;
                };
                let Some(src) = docs.get(&uri).cloned() else {
                    return;
                };
                let Ok(path) = uri.to_file_path() else {
                    return;
                };
                (path, src)
            };
            let diags = tokio::task::spawn_blocking(move || {
                rice_lsp::validate_chief_rice(&path, &src, &allowed_tf)
            })
            .await
            .unwrap_or_default();
            let lsp_diags: Vec<Diagnostic> = diags.iter().map(to_lsp_diagnostic).collect();
            client.publish_diagnostics(uri, lsp_diags, None).await;
        });
    }
}

fn to_lsp_diagnostic(d: &RiceDiagnostic) -> Diagnostic {
    Diagnostic {
        range: Range {
            start: Position {
                line: d.line,
                character: d.col,
            },
            end: Position {
                line: d.line,
                character: d.col.saturating_add(1),
            },
        },
        severity: Some(match d.severity {
            rice_lsp::DiagnosticSeverity::Error => DiagnosticSeverity::ERROR,
            rice_lsp::DiagnosticSeverity::Warning => DiagnosticSeverity::WARNING,
        }),
        message: d.message.clone(),
        source: Some("rice-lsp".into()),
        ..Default::default()
    }
}

#[async_trait]
impl TowerLanguageServer for MintLspBackend {
    async fn initialize(&self, _: InitializeParams) -> JsonRpcResult<InitializeResult> {
        let capabilities = ServerCapabilities {
            text_document_sync: Some(TextDocumentSyncCapability::Options(TextDocumentSyncOptions {
                open_close: Some(true),
                change: Some(TextDocumentSyncKind::FULL),
                save: Some(
                    SaveOptions {
                        include_text: Some(true),
                    }
                    .into(),
                ),
                ..Default::default()
            })),
            document_formatting_provider: Some(OneOf::Left(true)),
            ..Default::default()
        };
        #[cfg(feature = "lsp-perf")]
        {
            capabilities.execute_command_provider = Some(ExecuteCommandOptions {
                commands: vec![String::from(lsp_perf::REFRESH_BASE_PERF_CMD)],
                work_done_progress_options: Default::default(),
            });
        }

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
                "lsp-perf: command `clerk.refreshBasePerf`; optional save-hook set CLERK_LSP_PERF=1 (debounced); CLERK_BENCH_BIN or target/{debug,release}/bench",
            )
            .await;
    }

    async fn shutdown(&self) -> JsonRpcResult<()> {
        Ok(())
    }

    async fn did_open(&self, params: DidOpenTextDocumentParams) {
        let uri = params.text_document.uri;
        if let Ok(mut docs) = self.documents.lock() {
            docs.insert(uri.clone(), params.text_document.text);
        }
        self.schedule_validate(uri);
    }

    async fn did_change(&self, params: DidChangeTextDocumentParams) {
        let uri = params.text_document.uri;
        if let Some(change) = params.content_changes.into_iter().next() {
            if let Ok(mut docs) = self.documents.lock() {
                docs.insert(uri.clone(), change.text);
            }
        }
        self.schedule_validate(uri);
    }

    async fn did_close(&self, params: DidCloseTextDocumentParams) {
        if let Ok(mut docs) = self.documents.lock() {
            docs.remove(&params.text_document.uri);
        }
    }

    async fn did_save(&self, params: DidSaveTextDocumentParams) {
        let uri = params.text_document.uri.clone();
        if let Some(text) = params.text {
            if let Ok(mut docs) = self.documents.lock() {
                docs.insert(uri.clone(), text);
            }
        }
        self.schedule_validate(uri.clone());

        #[cfg(feature = "lsp-perf")]
        if std::env::var_os("CLERK_LSP_PERF").is_some() {
            if uri.scheme() == "file" {
                if let Ok(path) = uri.to_file_path() {
                    if path.extension().and_then(|s| s.to_str()) == Some("rice") {
                        self.schedule_refresh_base_perf(path);
                    }
                }
            }
        }
    }

    async fn formatting(
        &self,
        params: DocumentFormattingParams,
    ) -> JsonRpcResult<Option<Vec<TextEdit>>> {
        let uri = params.text_document.uri;
        let src = {
            let docs = self.documents.lock().map_err(|_| {
                tower_lsp::jsonrpc::Error::internal_error()
            })?;
            docs.get(&uri).cloned()
        };
        let Some(src) = src else {
            return Ok(None);
        };
        let formatted = rice_infra_fmt::format_rice_infra(&src);
        if formatted == src {
            return Ok(None);
        }
        let range = Range {
            start: Position::new(0, 0),
            end: Position::new(u32::MAX, 0),
        };
        Ok(Some(vec![TextEdit {
            range,
            new_text: formatted,
        }]))
    }

    async fn execute_command(
        &self,
        params: ExecuteCommandParams,
    ) -> JsonRpcResult<Option<serde_json::Value>> {
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

    pub const REFRESH_BASE_PERF_CMD: &str = "clerk.refreshBasePerf";

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
        if let Ok(p) = std::env::var("CLERK_BENCH_BIN") {
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
            .ok_or_else(|| "bench: could not resolve binary (set CLERK_BENCH_BIN or build with `cargo build -p bench` from a workspace ancestor)".to_string())?;
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
impl MintLspBackend {
    async fn run_refresh_base_perf_command(
        &self,
        walk_from_dir: Option<PathBuf>,
    ) -> JsonRpcResult<Option<serde_json::Value>> {
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

/// Start the Rice LSP (stdio transport).
pub async fn run_server() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();
    let (service, socket) = LspService::new(|client| MintLspBackend::new(client));
    Server::new(stdin, stdout, socket).serve(service).await;
}
