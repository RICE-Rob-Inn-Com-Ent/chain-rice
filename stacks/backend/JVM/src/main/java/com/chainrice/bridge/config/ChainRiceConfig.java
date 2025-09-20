package com.chainrice.bridge.config;

/**
 * Configuration class for ChainRice client.
 */
public class ChainRiceConfig {
    private String accountingApiUrl = "http://localhost:8080";
    private String taxApiUrl = "http://localhost:8081";
    private String blockchainUrl = "http://localhost:26657";
    private String apiKey = "";
    private int timeout = 30;

    public ChainRiceConfig() {
    }

    public ChainRiceConfig(String accountingApiUrl, String taxApiUrl, String blockchainUrl, String apiKey,
            int timeout) {
        this.accountingApiUrl = accountingApiUrl;
        this.taxApiUrl = taxApiUrl;
        this.blockchainUrl = blockchainUrl;
        this.apiKey = apiKey;
        this.timeout = timeout;
    }

    public String getAccountingApiUrl() {
        return accountingApiUrl;
    }

    public void setAccountingApiUrl(String accountingApiUrl) {
        this.accountingApiUrl = accountingApiUrl;
    }

    public String getTaxApiUrl() {
        return taxApiUrl;
    }

    public void setTaxApiUrl(String taxApiUrl) {
        this.taxApiUrl = taxApiUrl;
    }

    public String getBlockchainUrl() {
        return blockchainUrl;
    }

    public void setBlockchainUrl(String blockchainUrl) {
        this.blockchainUrl = blockchainUrl;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public int getTimeout() {
        return timeout;
    }

    public void setTimeout(int timeout) {
        this.timeout = timeout;
    }
}
