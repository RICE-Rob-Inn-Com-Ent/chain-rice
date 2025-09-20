package com.chainrice.bridge;

import com.chainrice.bridge.api.AccountingApiClient;
import com.chainrice.bridge.api.TaxApiClient;
import com.chainrice.bridge.blockchain.BlockchainClient;
import com.chainrice.bridge.config.ChainRiceConfig;
import com.chainrice.bridge.model.HealthStatus;
import okhttp3.OkHttpClient;
import io.grpc.Channel;
import io.grpc.Grpc;
import io.grpc.InsecureChannelCredentials;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

/**
 * Main client for connecting to ChainRice Go services.
 */
public class ChainRiceClient {
    private static final Logger logger = LoggerFactory.getLogger(ChainRiceClient.class);

    private final AccountingApiClient accountingApi;
    private final TaxApiClient taxApi;
    private final BlockchainClient blockchainClient;
    private final ChainRiceConfig config;

    /**
     * Create a new ChainRice client with default configuration.
     */
    public ChainRiceClient() {
        this(new ChainRiceConfig());
    }

    /**
     * Create a new ChainRice client with custom configuration.
     */
    public ChainRiceClient(ChainRiceConfig config) {
        this.config = config;

        // Initialize HTTP client
        OkHttpClient httpClient = new OkHttpClient.Builder()
                .connectTimeout(config.getTimeout(), TimeUnit.SECONDS)
                .readTimeout(config.getTimeout(), TimeUnit.SECONDS)
                .writeTimeout(config.getTimeout(), TimeUnit.SECONDS)
                .build();

        // Initialize gRPC channel
        Channel grpcChannel = Grpc.newChannelBuilder(config.getBlockchainUrl(), InsecureChannelCredentials.create())
                .build();

        // Initialize API clients
        this.accountingApi = new AccountingApiClient(httpClient, config);
        this.taxApi = new TaxApiClient(httpClient, config);
        this.blockchainClient = new BlockchainClient(grpcChannel, config);
    }

    /**
     * Get the accounting API client.
     */
    public AccountingApiClient getAccountingApi() {
        return accountingApi;
    }

    /**
     * Get the tax API client.
     */
    public TaxApiClient getTaxApi() {
        return taxApi;
    }

    /**
     * Get the blockchain client.
     */
    public BlockchainClient getBlockchainClient() {
        return blockchainClient;
    }

    /**
     * Check health of all ChainRice services.
     */
    public HealthStatus healthCheck() {
        try {
            boolean accountingHealth = accountingApi.healthCheck();
            boolean taxHealth = taxApi.healthCheck();
            boolean blockchainHealth = blockchainClient.healthCheck();

            boolean overallHealth = accountingHealth && taxHealth && blockchainHealth;

            return new HealthStatus(overallHealth, accountingHealth, taxHealth, blockchainHealth);
        } catch (Exception e) {
            logger.error("Health check failed", e);
            return new HealthStatus(false, false, false, false);
        }
    }

    /**
     * Get the configuration.
     */
    public ChainRiceConfig getConfig() {
        return config;
    }
}
