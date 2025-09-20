<?php

namespace ChainRice\Bridge\Config;

/**
 * Configuration class for ChainRice client.
 */
class ChainRiceConfig
{
    private string $accountingApiUrl = 'http://localhost:8080';
    private string $taxApiUrl = 'http://localhost:8081';
    private string $blockchainUrl = 'http://localhost:26657';
    private string $apiKey = '';
    private int $timeout = 30;

    public function __construct(
        ?string $accountingApiUrl = null,
        ?string $taxApiUrl = null,
        ?string $blockchainUrl = null,
        ?string $apiKey = null,
        ?int $timeout = null
    ) {
        if ($accountingApiUrl !== null) {
            $this->accountingApiUrl = $accountingApiUrl;
        }
        if ($taxApiUrl !== null) {
            $this->taxApiUrl = $taxApiUrl;
        }
        if ($blockchainUrl !== null) {
            $this->blockchainUrl = $blockchainUrl;
        }
        if ($apiKey !== null) {
            $this->apiKey = $apiKey;
        }
        if ($timeout !== null) {
            $this->timeout = $timeout;
        }
    }

    public function getAccountingApiUrl(): string
    {
        return $this->accountingApiUrl;
    }

    public function setAccountingApiUrl(string $accountingApiUrl): self
    {
        $this->accountingApiUrl = $accountingApiUrl;
        return $this;
    }

    public function getTaxApiUrl(): string
    {
        return $this->taxApiUrl;
    }

    public function setTaxApiUrl(string $taxApiUrl): self
    {
        $this->taxApiUrl = $taxApiUrl;
        return $this;
    }

    public function getBlockchainUrl(): string
    {
        return $this->blockchainUrl;
    }

    public function setBlockchainUrl(string $blockchainUrl): self
    {
        $this->blockchainUrl = $blockchainUrl;
        return $this;
    }

    public function getApiKey(): string
    {
        return $this->apiKey;
    }

    public function setApiKey(string $apiKey): self
    {
        $this->apiKey = $apiKey;
        return $this;
    }

    public function getTimeout(): int
    {
        return $this->timeout;
    }

    public function setTimeout(int $timeout): self
    {
        $this->timeout = $timeout;
        return $this;
    }
}
