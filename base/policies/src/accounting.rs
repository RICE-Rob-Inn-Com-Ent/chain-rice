//! **Steel ledger** — double-entry movements over [`BalancePartition`] buckets, settlement metadata,
//! optional **auto-split** hooks (fees, tax, zakat, DAO routing), and an append-only **journal** keyed
//! by [`EntryId`] and optional **policy id**. All quantities are [`Amount`] / [`AssetTag`]; no ISO
//! currency tables or baked-in tax rates.
//!
//! ## Settlement
//!
//! [`SettlementMode`] is recorded on every journal row. This module treats **all** modes as
//! immediately affecting stored balances for the legs you post; orchestration layers use the mode
//! for deferred netting, batch close, or regulatory reporting.

use std::collections::{HashMap, HashSet};

use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::currency::{Amount, AssetTag};
use crate::error::{AccountingError, PolicyError, PolicyResult};

// --- Identifiers --------------------------------------------------------------

/// Monotonic journal id assigned by [`Ledger`].
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct EntryId(pub u64);

// --- Period (agnostic) --------------------------------------------------------

/// Fiscal or reporting window in UTC. Optional `unit_hint` names the unit of account (any label).
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct LedgerPeriod {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub unit_hint: Option<String>,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
}

impl LedgerPeriod {
    #[must_use]
    pub fn contains(&self, t: DateTime<Utc>) -> bool {
        t >= self.period_start && t <= self.period_end
    }
}

// --- Partitions & balances ----------------------------------------------------

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BalancePartition {
    Available,
    Reserved,
    Staked,
}

/// Per-account, per-asset bucket split (all amounts ≥ 0).
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubAccountBalances {
    pub available: Decimal,
    pub reserved: Decimal,
    pub staked: Decimal,
}

impl SubAccountBalances {
    #[must_use]
    pub fn get(&self, p: BalancePartition) -> Decimal {
        match p {
            BalancePartition::Available => self.available,
            BalancePartition::Reserved => self.reserved,
            BalancePartition::Staked => self.staked,
        }
    }

    fn mut_ref(&mut self, p: BalancePartition) -> &mut Decimal {
        match p {
            BalancePartition::Available => &mut self.available,
            BalancePartition::Reserved => &mut self.reserved,
            BalancePartition::Staked => &mut self.staked,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Flow {
    /// Increases the partition balance (value enters the bucket).
    In,
    /// Decreases the partition balance (value leaves the bucket).
    Out,
}

// --- Settlement -------------------------------------------------------------

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SettlementMode {
    Instant,
    Deferred {
        #[serde(default, skip_serializing_if = "Option::is_none")]
        settle_by: Option<DateTime<Utc>>,
    },
    Batched {
        batch_id: String,
    },
}

// --- Legs & journal -----------------------------------------------------------

/// One directed posting. All legs in a [`JournalRecord`] share the same [`AssetTag`] on [`Amount`].
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct LedgerLeg {
    pub account: String,
    pub partition: BalancePartition,
    pub flow: Flow,
    pub amount: Amount,
}

/// Immutable audit row: unique [`EntryId`], timestamp, settlement mode, optional [`Policy`] linkage.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct JournalRecord {
    pub entry_id: EntryId,
    pub posted_at: DateTime<Utc>,
    pub settlement: SettlementMode,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub policy_id: Option<String>,
    pub purpose: String,
    pub legs: Vec<LedgerLeg>,
}

// --- Transfer + auto-split ----------------------------------------------------

/// High-level movement: value leaves `source` / `source_partition`, enters `destination` /
/// `destination_partition`, same nominal asset throughout (including splits).
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Transfer {
    pub source: String,
    pub source_partition: BalancePartition,
    pub destination: String,
    pub destination_partition: BalancePartition,
    pub amount: Amount,
    pub purpose: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub policy_id: Option<String>,
    pub settlement: SettlementMode,
}

/// Policy-driven extra legs (fees, withholding, treasury sweeps). Implementations return **additional**
/// [`LedgerLeg`]s only; the primary pair (payer → payee) is built by [`Ledger::apply_transfer`].
pub trait AutoSplit: Send + Sync {
    fn additional_legs(&self, primary: &Transfer) -> PolicyResult<Vec<LedgerLeg>>;
}

// --- Ledger -------------------------------------------------------------------

/// In-memory ledger: partition balances + append-only journal.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct Ledger {
    next_entry: u64,
    balances: HashMap<(String, AssetTag), SubAccountBalances>,
    journal: Vec<JournalRecord>,
    /// Accounts that may post `Flow::Out` without a prior balance and may run negative (nominal
    /// issuance, migration sources, treasury void). **Never** hardcode real user ids here — inject at runtime.
    #[serde(default)]
    pub issuance_sources: HashSet<String>,
}

impl Ledger {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    #[must_use]
    pub fn journal(&self) -> &[JournalRecord] {
        &self.journal
    }

    #[must_use]
    pub fn partition_balance(&self, account: &str, partition: BalancePartition, asset: &AssetTag) -> Decimal {
        self.balances
            .get(&(account.to_string(), asset.clone()))
            .map(|b| b.get(partition))
            .unwrap_or(Decimal::ZERO)
    }

    /// Deterministic SHA-256 digest of partition balances (sorted) and append-only journal.
    ///
    /// Used by [`crate::audit::AuditEvent`] before/after snapshots. Version the prefix if the
    /// encoding ever changes.
    #[must_use]
    pub fn state_digest(&self) -> [u8; 32] {
        let mut hasher = Sha256::new();
        hasher.update(b"rice.ledger.state_digest.v1");
        hasher.update(self.next_entry.to_le_bytes());

        let mut keys: Vec<&(String, AssetTag)> = self.balances.keys().collect();
        keys.sort_by(|a, b| {
            a.0.cmp(&b.0)
                .then_with(|| a.1.label.cmp(&b.1.label))
                .then_with(|| a.1.precision.cmp(&b.1.precision))
        });
        for k in keys {
            let row = &self.balances[k];
            hasher.update(k.0.as_bytes());
            hasher.update(&[0x00]);
            hasher.update(k.1.label.as_bytes());
            hasher.update(&[0x00]);
            hasher.update([k.1.precision]);
            hasher.update(format!("{}|{}|{}", row.available, row.reserved, row.staked).as_bytes());
            hasher.update(&[0xfe]);
        }

        let mut iss: Vec<&String> = self.issuance_sources.iter().collect();
        iss.sort();
        hasher.update((iss.len() as u64).to_le_bytes());
        for s in iss {
            hasher.update(s.as_bytes());
            hasher.update(&[0xfd]);
        }

        hasher.update((self.journal.len() as u64).to_le_bytes());
        for rec in &self.journal {
            if let Ok(bytes) = serde_json::to_vec(rec) {
                hasher.update(&bytes);
                hasher.update(&[0xfc]);
            }
        }

        hasher.finalize().into()
    }

    /// Apply a balanced set of legs atomically (all succeed or none). Prefer [`apply_transfer`](Self::apply_transfer) for the common case.
    pub fn apply_legs(
        &mut self,
        legs: Vec<LedgerLeg>,
        posted_at: DateTime<Utc>,
        settlement: SettlementMode,
        policy_id: Option<String>,
        purpose: impl Into<String>,
    ) -> PolicyResult<EntryId> {
        if legs.is_empty() {
            return Err(AccountingError::EmptyLedgerEntry.into());
        }
        validate_same_asset(&legs)?;
        validate_conservation(&legs)?;
        validate_accounts(&legs)?;
        validate_sufficient(self, &legs)?;

        for leg in &legs {
            apply_one_leg(&mut self.balances, leg, &self.issuance_sources)?;
        }

        self.next_entry = self.next_entry.saturating_add(1);
        let entry_id = EntryId(self.next_entry);
        self.journal.push(JournalRecord {
            entry_id,
            posted_at,
            settlement,
            policy_id,
            purpose: purpose.into(),
            legs,
        });
        Ok(entry_id)
    }

    /// Primary payer→payee transfer plus optional [`AutoSplit`] legs (tax, fees, …). One [`EntryId`] covers the full atomic batch.
    pub fn apply_transfer(
        &mut self,
        tx: Transfer,
        posted_at: DateTime<Utc>,
        auto_split: Option<&dyn AutoSplit>,
    ) -> PolicyResult<EntryId> {
        if tx.amount.value() <= Decimal::ZERO {
            return Err(AccountingError::NonPositiveAmount.into());
        }
        if tx.source.is_empty() || tx.destination.is_empty() {
            return Err(AccountingError::EmptyAccountId.into());
        }

        let mut legs = Vec::new();
        legs.push(LedgerLeg {
            account: tx.source.clone(),
            partition: tx.source_partition,
            flow: Flow::Out,
            amount: tx.amount.clone(),
        });
        legs.push(LedgerLeg {
            account: tx.destination.clone(),
            partition: tx.destination_partition,
            flow: Flow::In,
            amount: tx.amount.clone(),
        });

        if let Some(split) = auto_split {
            legs.extend(split.additional_legs(&tx)?);
            validate_same_asset(&legs)?;
            validate_conservation(&legs)?;
        }

        self.apply_legs(legs, posted_at, tx.settlement.clone(), tx.policy_id.clone(), tx.purpose)
    }
}

/// Pre-flight the same **balanced double-entry** checks as [`Ledger::apply_legs`] (same asset, in = out).
///
/// Use with the [`clerk_balanced_leg_vec`] macro to refuse “ghost money” before commit.
pub fn assert_double_entry_balanced(legs: &[LedgerLeg]) -> PolicyResult<()> {
    if legs.is_empty() {
        return Err(AccountingError::EmptyLedgerEntry.into());
    }
    validate_accounts(legs)?;
    validate_same_asset(legs)?;
    validate_conservation(legs)?;
    Ok(())
}

fn validate_accounts(legs: &[LedgerLeg]) -> PolicyResult<()> {
    for leg in legs {
        if leg.account.is_empty() {
            return Err(AccountingError::EmptyAccountId.into());
        }
    }
    Ok(())
}

fn validate_same_asset(legs: &[LedgerLeg]) -> PolicyResult<()> {
    let tag = legs[0].amount.tag();
    for leg in legs.iter().skip(1) {
        if leg.amount.tag() != tag {
            return Err(AccountingError::CrossAssetInEntry.into());
        }
    }
    Ok(())
}

fn validate_conservation(legs: &[LedgerLeg]) -> PolicyResult<()> {
    let tag = legs[0].amount.tag();
    let mut sum_in = Decimal::ZERO;
    let mut sum_out = Decimal::ZERO;
    for leg in legs {
        match leg.flow {
            Flow::In => {
                sum_in = sum_in.checked_add(leg.amount.value()).ok_or_else(|| {
                    PolicyError::Finance(crate::error::FinanceError::Overflow { operation: "ledger_sum_in".into() })
                })?;
            },
            Flow::Out => {
                sum_out = sum_out.checked_add(leg.amount.value()).ok_or_else(|| {
                    PolicyError::Finance(crate::error::FinanceError::Overflow { operation: "ledger_sum_out".into() })
                })?;
            },
        }
    }
    if sum_in != sum_out {
        return Err(AccountingError::UnbalancedLegs {
            asset: tag.to_string(),
            sum_in: sum_in.to_string(),
            sum_out: sum_out.to_string(),
        }
        .into());
    }
    Ok(())
}

fn validate_sufficient(ledger: &Ledger, legs: &[LedgerLeg]) -> PolicyResult<()> {
    for leg in legs {
        if matches!(leg.flow, Flow::Out) && !ledger.issuance_sources.contains(&leg.account) {
            let have = ledger.partition_balance(&leg.account, leg.partition, leg.amount.tag());
            let need = leg.amount.value();
            if have < need {
                return Err(AccountingError::InsufficientBalance {
                    account: leg.account.clone(),
                    partition: format!("{:?}", leg.partition),
                    asset: leg.amount.tag().to_string(),
                    need: need.to_string(),
                    have: have.to_string(),
                }
                .into());
            }
        }
    }
    Ok(())
}

fn apply_one_leg(
    balances: &mut HashMap<(String, AssetTag), SubAccountBalances>,
    leg: &LedgerLeg,
    issuance_sources: &HashSet<String>,
) -> PolicyResult<()> {
    let key = (leg.account.clone(), leg.amount.tag().clone());
    let slot = balances.entry(key).or_default();
    let cell = slot.mut_ref(leg.partition);
    match leg.flow {
        Flow::In => {
            *cell = cell.checked_add(leg.amount.value()).ok_or_else(|| {
                PolicyError::Finance(crate::error::FinanceError::Overflow { operation: "partition_credit".into() })
            })?;
        },
        Flow::Out => {
            *cell = cell.checked_sub(leg.amount.value()).ok_or_else(|| {
                PolicyError::Accounting(AccountingError::InsufficientBalance {
                    account: leg.account.clone(),
                    partition: format!("{:?}", leg.partition),
                    asset: leg.amount.tag().to_string(),
                    need: leg.amount.value().to_string(),
                    have: cell.to_string(),
                })
            })?;
        },
    }
    if *cell < Decimal::ZERO && !issuance_sources.contains(&leg.account) {
        return Err(AccountingError::InsufficientBalance {
            account: leg.account.clone(),
            partition: format!("{:?}", leg.partition),
            asset: leg.amount.tag().to_string(),
            need: leg.amount.value().to_string(),
            have: cell.to_string(),
        }
        .into());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::currency::Asset;

    fn usd(v: &str) -> PolicyResult<Amount> {
        Amount::from_decimal_str_exact(v, Asset::new("USD", 2)?)
    }

    #[test]
    fn transfer_moves_available() {
        let mut ledger = Ledger::new();
        ledger.issuance_sources.insert("issuance".into());
        let seed = usd("1000.00").unwrap();
        ledger
            .apply_legs(
                vec![
                    LedgerLeg {
                        account: "alice".into(),
                        partition: BalancePartition::Available,
                        flow: Flow::In,
                        amount: seed.clone(),
                    },
                    LedgerLeg {
                        account: "issuance".into(),
                        partition: BalancePartition::Available,
                        flow: Flow::Out,
                        amount: seed.clone(),
                    },
                ],
                Utc::now(),
                SettlementMode::Instant,
                None,
                "seed",
            )
            .unwrap();

        let pay = usd("100.00").unwrap();
        let tx = Transfer {
            source: "alice".into(),
            source_partition: BalancePartition::Available,
            destination: "bob".into(),
            destination_partition: BalancePartition::Available,
            amount: pay,
            purpose: "payment".into(),
            policy_id: Some("pol_pay_1".into()),
            settlement: SettlementMode::Instant,
        };
        let eid = ledger.apply_transfer(tx, Utc::now(), None).unwrap();
        assert_eq!(eid.0, 2);
        let usd_tag = Asset::new("USD", 2).unwrap();
        assert_eq!(
            ledger.partition_balance("alice", BalancePartition::Available, &usd_tag),
            Decimal::from_str_exact("900.00").unwrap()
        );
        assert_eq!(
            ledger.partition_balance("bob", BalancePartition::Available, &usd_tag),
            Decimal::from_str_exact("100.00").unwrap()
        );
        assert_eq!(ledger.journal().last().unwrap().policy_id.as_deref(), Some("pol_pay_1"));
    }

    struct TenPercentFeeToTreasury;

    impl AutoSplit for TenPercentFeeToTreasury {
        fn additional_legs(&self, primary: &Transfer) -> PolicyResult<Vec<LedgerLeg>> {
            let fee_val = primary
                .amount
                .value()
                .checked_div(Decimal::from(10))
                .ok_or_else(|| AccountingError::NonPositiveAmount)?;
            if fee_val <= Decimal::ZERO {
                return Ok(vec![]);
            }
            let fee_amt = Amount::new(fee_val, primary.amount.tag().clone())?;
            Ok(vec![
                LedgerLeg {
                    account: primary.source.clone(),
                    partition: primary.source_partition,
                    flow: Flow::Out,
                    amount: fee_amt.clone(),
                },
                LedgerLeg {
                    account: "treasury".into(),
                    partition: BalancePartition::Available,
                    flow: Flow::In,
                    amount: fee_amt,
                },
            ])
        }
    }

    #[test]
    fn auto_split_balances() {
        let mut ledger = Ledger::new();
        ledger.issuance_sources.insert("issuance".into());
        let seed = usd("1000.00").unwrap();
        ledger
            .apply_legs(
                vec![
                    LedgerLeg {
                        account: "alice".into(),
                        partition: BalancePartition::Available,
                        flow: Flow::In,
                        amount: seed,
                    },
                    LedgerLeg {
                        account: "issuance".into(),
                        partition: BalancePartition::Available,
                        flow: Flow::Out,
                        amount: usd("1000.00").unwrap(),
                    },
                ],
                Utc::now(),
                SettlementMode::Instant,
                None,
                "seed",
            )
            .unwrap();

        let tx = Transfer {
            source: "alice".into(),
            source_partition: BalancePartition::Available,
            destination: "merchant".into(),
            destination_partition: BalancePartition::Available,
            amount: usd("100.00").unwrap(),
            purpose: "sale".into(),
            policy_id: Some("tax_policy".into()),
            settlement: SettlementMode::Batched { batch_id: "b1".into() },
        };
        ledger.apply_transfer(tx, Utc::now(), Some(&TenPercentFeeToTreasury)).unwrap();

        let usd_tag = Asset::new("USD", 2).unwrap();
        assert_eq!(
            ledger.partition_balance("alice", BalancePartition::Available, &usd_tag),
            Decimal::from_str_exact("890.00").unwrap()
        );
        assert_eq!(
            ledger.partition_balance("merchant", BalancePartition::Available, &usd_tag),
            Decimal::from_str_exact("100.00").unwrap()
        );
        assert_eq!(
            ledger.partition_balance("treasury", BalancePartition::Available, &usd_tag),
            Decimal::from_str_exact("10.00").unwrap()
        );
    }

    #[test]
    fn rejects_insufficient_and_unbalanced() {
        let mut ledger = Ledger::new();
        let tx = Transfer {
            source: "nobody".into(),
            source_partition: BalancePartition::Available,
            destination: "bob".into(),
            destination_partition: BalancePartition::Available,
            amount: usd("1.00").unwrap(),
            purpose: "x".into(),
            policy_id: None,
            settlement: SettlementMode::Instant,
        };
        assert!(ledger.apply_transfer(tx, Utc::now(), None).is_err());

        let bad = vec![
            LedgerLeg {
                account: "a".into(),
                partition: BalancePartition::Available,
                flow: Flow::In,
                amount: usd("1.00").unwrap(),
            },
            LedgerLeg {
                account: "b".into(),
                partition: BalancePartition::Available,
                flow: Flow::Out,
                amount: usd("2.00").unwrap(),
            },
        ];
        assert!(
            ledger
                .apply_legs(bad, Utc::now(), SettlementMode::Instant, None, "bad")
                .is_err()
        );
    }

    #[test]
    fn state_digest_stable_for_empty_ledger() {
        let a = Ledger::new();
        let b = Ledger::new();
        assert_eq!(a.state_digest(), b.state_digest());
    }

    #[test]
    fn ledger_period_contains() {
        let p = LedgerPeriod {
            unit_hint: Some("PTS@0".into()),
            period_start: DateTime::parse_from_rfc3339("2026-01-01T00:00:00Z")
                .unwrap()
                .with_timezone(&Utc),
            period_end: DateTime::parse_from_rfc3339("2026-12-31T00:00:00Z")
                .unwrap()
                .with_timezone(&Utc),
        };
        assert!(
            p.contains(
                DateTime::parse_from_rfc3339("2026-06-01T00:00:00Z")
                    .unwrap()
                    .with_timezone(&Utc)
            )
        );
    }
}
