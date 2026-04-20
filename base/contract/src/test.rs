//! Chain simulation — `cw-multi-test` + Sylvia multitest (`sv::mt`) for the `.rice` runtime.

use cosmwasm_std::{Binary, Uint128, to_hex};
use cw_multi_test::{AppResponse, IntoBech32};
use ed25519_dalek::Signer;
use rand::rngs::OsRng;
use sylvia::multitest::App;

use crate::contract::Contract;
use crate::contract::sv::mt::{CodeId, ContractProxy};
use crate::crypto;
use crate::error::ContractError;
use crate::event::{EVENT_NAMESPACE, WASM_EVENT_TYPE};
use crate::msg::BalanceAdjustment;
use crate::r#type::{IdentityPrincipal, ProofStatus, TokenAmount};

#[test]
fn types_helpers_smoke() {
    let _ = crate::r#type::big_zero();
    assert_eq!(crate::crypto::sha256_digest(b"rice").len(), 32);
}

macro_rules! deploy_sandbox {
    ($app:expr, $label:expr) => {{
        let admin = $label.into_bech32();
        let code_id = CodeId::<Contract, _>::store_code($app);
        code_id
            .instantiate(Some(admin.to_string()), None, true, true)
            .with_label("rice-sandbox")
            .call(&admin)
            .expect("instantiate sandbox")
    }};
}

fn intent_action_tag() -> String {
    format!("{EVENT_NAMESPACE}/intent")
}

fn event_attr<'a>(ev: &'a cosmwasm_std::Event, key: &str) -> Option<&'a str> {
    ev.attributes.iter().find(|a| a.key == key).map(|a| a.value.as_str())
}

fn assert_intent_event(resp: &AppResponse, trace_id: &str) {
    let intent_action = intent_action_tag();
    let mut saw = false;
    for ev in &resp.events {
        let ty_ok = ev.ty == WASM_EVENT_TYPE || ev.ty.ends_with(WASM_EVENT_TYPE);
        if !ty_ok {
            continue;
        }
        if event_attr(ev, "action") != Some(intent_action.as_str()) {
            continue;
        }
        assert_eq!(event_attr(ev, "trace_id"), Some(trace_id), "trace_id attr");
        saw = true;
        break;
    }
    assert!(saw, "expected wasm event {WASM_EVENT_TYPE} with intent action and trace_id");
}

#[test]
fn intent_flow_verify_trace_and_events() {
    let app = App::default();
    let admin = deploy_sandbox!(&app, "sandbox-admin");

    let cfg = admin.get_config().expect("config");
    assert!(cfg.zk_enabled && cfg.pq_enabled, "ZK/PQ flags from instantiate");

    let signing_key = ed25519_dalek::SigningKey::generate(&mut OsRng);
    let verifying_key = signing_key.verifying_key();
    let payload = b"dummy-rice-intent-payload";
    let trace_id = to_hex(crypto::sha256_digest(payload.as_slice()));

    let sig = signing_key.sign(payload.as_slice());
    let mut proof = Vec::with_capacity(96);
    proof.extend_from_slice(verifying_key.as_bytes());
    proof.extend_from_slice(&sig.to_bytes());

    let sender = "intent-sender".into_bech32();
    let resp = admin
        .execute_intent(Binary::from(payload.as_slice()), Some(Binary::from(proof.as_slice())))
        .call(&sender)
        .expect("execute_intent with valid ed25519 proof");

    assert_intent_event(&resp, &trace_id);

    let st = admin.verify_trace(trace_id.clone()).expect("verify_trace");
    assert_eq!(st, ProofStatus::Verified);
}

#[test]
fn manage_balance_insufficient_funds_on_debit() {
    let app = App::default();
    let admin_addr = "balance-admin".into_bech32();
    let admin = deploy_sandbox!(&app, "balance-admin");

    let holder = "holder".into_bech32();
    admin
        .manage_balance(
            IdentityPrincipal::Contract(holder.clone()),
            TokenAmount::new(Uint128::new(100)),
            BalanceAdjustment::Credit,
        )
        .call(&admin_addr)
        .expect("credit");

    let bal = admin
        .check_balance(IdentityPrincipal::Contract(holder.clone()))
        .expect("check_balance");
    assert_eq!(bal.amount, Uint128::new(100));

    let err = admin
        .manage_balance(
            IdentityPrincipal::Contract(holder.clone()),
            TokenAmount::new(Uint128::new(101)),
            BalanceAdjustment::Debit,
        )
        .call(&admin_addr)
        .unwrap_err();

    assert_eq!(
        err,
        ContractError::InsufficientFunds {
            required: "101".into(),
            found: "100".into(),
        }
    );
}

#[test]
fn update_config_unauthorized_for_non_admin() {
    let app = App::default();
    let admin = deploy_sandbox!(&app, "gate-admin");
    let hacker = "hacker".into_bech32();

    let err = admin.update_config(None, None, None, None, None).call(&hacker).unwrap_err();

    assert!(
        matches!(err, ContractError::Unauthorized { .. }),
        "expected Unauthorized, got {err:?}"
    );
}

#[test]
fn paused_contract_blocks_execute_intent() {
    let app = App::default();
    let admin_addr = "pause-admin".into_bech32();
    let admin = deploy_sandbox!(&app, "pause-admin");

    admin
        .update_config(None, None, None, None, Some(true))
        .call(&admin_addr)
        .expect("pause");

    let err = admin
        .execute_intent(Binary::from(b"paused-check"), None)
        .call(&admin_addr)
        .unwrap_err();

    assert_eq!(err, ContractError::ContractPaused);
}
