//! Language Server Protocol — IDE integration via `tower-lsp`.

use async_trait::async_trait;
use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer, LspService, Server};

/// Minimal LSP backend — extend with workspace symbols, hover, etc.
pub struct RiceLanguageServer {
    client: Client,
}

impl RiceLanguageServer {
    pub fn new(client: Client) -> Self {
        Self { client }
    }
}

#[async_trait]
impl LanguageServer for RiceLanguageServer {
    async fn initialize(&self, _: InitializeParams) -> Result<InitializeResult> {
        Ok(InitializeResult {
            capabilities: ServerCapabilities {
                text_document_sync: Some(TextDocumentSyncCapability::Kind(
                    TextDocumentSyncKind::INCREMENTAL,
                )),
                ..Default::default()
            },
            ..Default::default()
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, ".rice language server ready")
            .await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
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
