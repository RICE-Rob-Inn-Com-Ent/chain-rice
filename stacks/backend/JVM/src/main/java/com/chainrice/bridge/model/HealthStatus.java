package com.chainrice.bridge.model;

/**
 * Health status model for ChainRice services.
 */
public class HealthStatus {
    private final boolean overall;
    private final boolean accountingApi;
    private final boolean taxApi;
    private final boolean blockchain;

    public HealthStatus(boolean overall, boolean accountingApi, boolean taxApi, boolean blockchain) {
        this.overall = overall;
        this.accountingApi = accountingApi;
        this.taxApi = taxApi;
        this.blockchain = blockchain;
    }

    public boolean isOverall() {
        return overall;
    }

    public boolean isAccountingApi() {
        return accountingApi;
    }

    public boolean isTaxApi() {
        return taxApi;
    }

    public boolean isBlockchain() {
        return blockchain;
    }

    @Override
    public String toString() {
        return "HealthStatus{" +
                "overall=" + overall +
                ", accountingApi=" + accountingApi +
                ", taxApi=" + taxApi +
                ", blockchain=" + blockchain +
                '}';
    }
}
