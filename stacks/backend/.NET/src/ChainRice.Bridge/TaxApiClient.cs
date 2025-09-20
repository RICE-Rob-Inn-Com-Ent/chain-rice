using Microsoft.Extensions.Logging;
using System.Text;
using System.Text.Json;

namespace ChainRice.Bridge;

/// <summary>
/// Client for ChainRice Tax API operations
/// </summary>
public class TaxApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<TaxApiClient> _logger;
    private readonly ChainRiceOptions _options;

    public TaxApiClient(HttpClient httpClient, ILogger<TaxApiClient> logger, ChainRiceOptions options)
    {
        _httpClient = httpClient;
        _logger = logger;
        _options = options;
    }

    /// <summary>
    /// Calculate tax for given amount and tax type
    /// </summary>
    public async Task<TaxCalculationResponse> CalculateTaxAsync(TaxCalculationRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{_options.TaxApiUrl}/api/v1/tax/calculate", content, cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<TaxCalculationResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to calculate tax");
            throw;
        }
    }

    /// <summary>
    /// Get tax rates for different categories
    /// </summary>
    public async Task<TaxRatesResponse> GetTaxRatesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.TaxApiUrl}/api/v1/tax/rates", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<TaxRatesResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get tax rates");
            throw;
        }
    }

    /// <summary>
    /// Create a new contractor
    /// </summary>
    public async Task<ContractorResponse> CreateContractorAsync(CreateContractorRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{_options.TaxApiUrl}/api/v1/contractors", content, cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<ContractorResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create contractor");
            throw;
        }
    }

    /// <summary>
    /// Get contractor by ID
    /// </summary>
    public async Task<ContractorResponse> GetContractorAsync(string contractorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.TaxApiUrl}/api/v1/contractors/{contractorId}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<ContractorResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get contractor {ContractorId}", contractorId);
            throw;
        }
    }

    /// <summary>
    /// List contractors with pagination
    /// </summary>
    public async Task<ContractorListResponse> ListContractorsAsync(int page = 1, int pageSize = 10, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.TaxApiUrl}/api/v1/contractors?page={page}&pageSize={pageSize}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<ContractorListResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list contractors");
            throw;
        }
    }

    /// <summary>
    /// Get calculation history
    /// </summary>
    public async Task<CalculationHistoryResponse> GetCalculationHistoryAsync(int page = 1, int pageSize = 10, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.TaxApiUrl}/api/v1/calculations/history?page={page}&pageSize={pageSize}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<CalculationHistoryResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get calculation history");
            throw;
        }
    }
}

// Data models for Tax API
public class TaxCalculationRequest
{
    public decimal Amount { get; set; }
    public string TaxType { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Currency { get; set; } = "PLN";
    public DateTime CalculationDate { get; set; } = DateTime.UtcNow;
}

public class TaxCalculationResponse
{
    public string Id { get; set; } = string.Empty;
    public decimal OriginalAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public string TaxType { get; set; } = string.Empty;
    public decimal TaxRate { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Currency { get; set; } = string.Empty;
    public DateTime CalculatedAt { get; set; }
}

public class TaxRatesResponse
{
    public List<TaxRate> Rates { get; set; } = new();
    public DateTime LastUpdated { get; set; }
}

public class TaxRate
{
    public string Type { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Rate { get; set; }
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class CreateContractorRequest
{
    public string Name { get; set; } = string.Empty;
    public string TaxId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string Country { get; set; } = "PL";
    public string Type { get; set; } = "individual"; // individual, company
}

public class ContractorResponse
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string TaxId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string Country { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class ContractorListResponse
{
    public List<ContractorResponse> Contractors { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

public class CalculationHistoryResponse
{
    public List<TaxCalculationResponse> Calculations { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}
