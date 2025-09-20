<?php

namespace ChainRice\Bridge;

use ChainRice\Bridge\Api\AccountingApiClient;
use ChainRice\Bridge\Api\TaxApiClient;
use ChainRice\Bridge\Blockchain\BlockchainClient;
use ChainRice\Bridge\Config\ChainRiceConfig;
use ChainRice\Bridge\Model\HealthStatus;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;

/**
 * Main client for connecting to ChainRice Go services.
 */
class ChainRiceClient
{
    private AccountingApiClient $accountingApi;
    private TaxApiClient $taxApi;
    private BlockchainClient $blockchainClient;
    private ChainRiceConfig $config;
    private Logger $logger;

    public function __construct(?ChainRiceConfig $config = null)
    {
        $this->config = $config ?? new ChainRiceConfig();
        $this->logger = new Logger('chainrice-bridge');
        $this->logger->pushHandler(new StreamHandler('php://stdout', Logger::INFO));

        // Initialize HTTP client
        $httpClient = new Client([
            'timeout' => $this->config->getTimeout(),
            'headers' => [
                'Content-Type' => 'application/json',
                'Accept' => 'application/json',
                'Authorization' => 'Bearer ' . $this->config->getApiKey()
            ]
        ]);

        // Initialize API clients
        $this->accountingApi = new AccountingApiClient($httpClient, $this->config);
        $this->taxApi = new TaxApiClient($httpClient, $this->config);
        $this->blockchainClient = new BlockchainClient($this->config);
    }

    /**
     * Get the accounting API client.
     */
    public function getAccountingApi(): AccountingApiClient
    {
        return $this->accountingApi;
    }

    /**
     * Get the tax API client.
     */
    public function getTaxApi(): TaxApiClient
    {
        return $this->taxApi;
    }

    /**
     * Get the blockchain client.
     */
    public function getBlockchainClient(): BlockchainClient
    {
        return $this->blockchainClient;
    }

    /**
     * Check health of all ChainRice services.
     */
    public function healthCheck(): HealthStatus
    {
        try {
            $accountingHealth = $this->accountingApi->healthCheck();
            $taxHealth = $this->taxApi->healthCheck();
            $blockchainHealth = $this->blockchainClient->healthCheck();

            $overallHealth = $accountingHealth && $taxHealth && $blockchainHealth;

            return new HealthStatus($overallHealth, $accountingHealth, $taxHealth, $blockchainHealth);
        } catch (\Exception $e) {
            $this->logger->error('Health check failed', ['error' => $e->getMessage()]);
            return new HealthStatus(false, false, false, false);
        }
    }

    /**
     * Get the configuration.
     */
    public function getConfig(): ChainRiceConfig
    {
        return $this->config;
    }
}
