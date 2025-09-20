using Grpc.Net.Client;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace ChainRice.Bridge;

/// <summary>
/// Main client for connecting to ChainRice Go services
/// </summary>
public class ChainRiceClient
{
    private readonly HttpClient _httpClient;
    private readonly GrpcChannel _grpcChannel;
    private readonly ILogger<ChainRiceClient> _logger;
    private readonly ChainRiceOptions _options;

    public ChainRiceClient(
        HttpClient httpClient,
        GrpcChannel grpcChannel,
        ILogger<ChainRiceClient> logger,
        ChainRiceOptions options)
    {
        _httpClient = httpClient;
        _grpcChannel = grpcChannel;
        _logger = logger;
        _options = options;
    }

    /// <summary>
    /// Accounting API client for invoice and financial operations
    /// </summary>
    public AccountingApiClient Accounting => new(_httpClient, _logger, _options);

    /// <summary>
    /// Tax API client for tax calculations and operations
    /// </summary>
    public TaxApiClient Tax => new(_httpClient, _logger, _options);

    /// <summary>
    /// Blockchain client for Cosmos SDK operations
    /// </summary>
    public BlockchainClient Blockchain => new(_grpcChannel, _logger, _options);

    /// <summary>
    /// Health check for all services
    /// </summary>
    public async Task<HealthStatus> CheckHealthAsync(CancellationToken cancellationToken = default)
    {
        var healthStatus = new HealthStatus();

        try
        {
            // Check Accounting API
            var accountingHealth = await _httpClient.GetAsync($"{_options.AccountingApiUrl}/health", cancellationToken);
            healthStatus.AccountingApi = accountingHealth.IsSuccessStatusCode;

            // Check Tax API
            var taxHealth = await _httpClient.GetAsync($"{_options.TaxApiUrl}/health", cancellationToken);
            healthStatus.TaxApi = taxHealth.IsSuccessStatusCode;

            // Check Blockchain
            healthStatus.Blockchain = _grpcChannel.State == Grpc.Core.ConnectivityState.Ready;

            healthStatus.Overall = healthStatus.AccountingApi && healthStatus.TaxApi && healthStatus.Blockchain;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Health check failed");
            healthStatus.Overall = false;
        }

        return healthStatus;
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
        _grpcChannel?.Dispose();
    }
}

/// <summary>
/// Configuration options for ChainRice client
/// </summary>
public class ChainRiceOptions
{
    public string AccountingApiUrl { get; set; } = "http://localhost:8080";
    public string TaxApiUrl { get; set; } = "http://localhost:8081";
    public string BlockchainUrl { get; set; } = "http://localhost:26657";
    public string ApiKey { get; set; } = string.Empty;
    public TimeSpan Timeout { get; set; } = TimeSpan.FromSeconds(30);
}

/// <summary>
/// Health status of ChainRice services
/// </summary>
public class HealthStatus
{
    public bool Overall { get; set; }
    public bool AccountingApi { get; set; }
    public bool TaxApi { get; set; }
    public bool Blockchain { get; set; }
}
