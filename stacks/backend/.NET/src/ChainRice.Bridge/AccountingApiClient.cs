using Microsoft.Extensions.Logging;
using System.Text;
using System.Text.Json;

namespace ChainRice.Bridge;

/// <summary>
/// Client for ChainRice Accounting API operations
/// </summary>
public class AccountingApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AccountingApiClient> _logger;
    private readonly ChainRiceOptions _options;

    public AccountingApiClient(HttpClient httpClient, ILogger<AccountingApiClient> logger, ChainRiceOptions options)
    {
        _httpClient = httpClient;
        _logger = logger;
        _options = options;
    }

    /// <summary>
    /// Create a new invoice
    /// </summary>
    public async Task<InvoiceResponse> CreateInvoiceAsync(CreateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{_options.AccountingApiUrl}/api/v1/invoices", content, cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<InvoiceResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create invoice");
            throw;
        }
    }

    /// <summary>
    /// Get invoice by ID
    /// </summary>
    public async Task<InvoiceResponse> GetInvoiceAsync(string invoiceId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.AccountingApiUrl}/api/v1/invoices/{invoiceId}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<InvoiceResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get invoice {InvoiceId}", invoiceId);
            throw;
        }
    }

    /// <summary>
    /// List invoices with pagination
    /// </summary>
    public async Task<InvoiceListResponse> ListInvoicesAsync(int page = 1, int pageSize = 10, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.AccountingApiUrl}/api/v1/invoices?page={page}&pageSize={pageSize}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<InvoiceListResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list invoices");
            throw;
        }
    }

    /// <summary>
    /// Update an existing invoice
    /// </summary>
    public async Task<InvoiceResponse> UpdateInvoiceAsync(string invoiceId, UpdateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PutAsync($"{_options.AccountingApiUrl}/api/v1/invoices/{invoiceId}", content, cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<InvoiceResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update invoice {InvoiceId}", invoiceId);
            throw;
        }
    }

    /// <summary>
    /// Delete an invoice
    /// </summary>
    public async Task<bool> DeleteInvoiceAsync(string invoiceId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"{_options.AccountingApiUrl}/api/v1/invoices/{invoiceId}", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete invoice {InvoiceId}", invoiceId);
            throw;
        }
    }

    /// <summary>
    /// Get dashboard statistics
    /// </summary>
    public async Task<DashboardStatsResponse> GetDashboardStatsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"{_options.AccountingApiUrl}/api/v1/dashboard/stats", cancellationToken);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);
            return JsonSerializer.Deserialize<DashboardStatsResponse>(responseJson) ?? throw new InvalidOperationException("Failed to deserialize response");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get dashboard stats");
            throw;
        }
    }
}

// Data models for Accounting API
public class CreateInvoiceRequest
{
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "PLN";
    public DateTime DueDate { get; set; }
    public string Description { get; set; } = string.Empty;
    public List<InvoiceItemRequest> Items { get; set; } = new();
}

public class UpdateInvoiceRequest
{
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "PLN";
    public DateTime DueDate { get; set; }
    public string Description { get; set; } = string.Empty;
    public List<InvoiceItemRequest> Items { get; set; } = new();
}

public class InvoiceItemRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TaxRate { get; set; }
}

public class InvoiceResponse
{
    public string Id { get; set; } = string.Empty;
    public string InvoiceNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public DateTime DueDate { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<InvoiceItemResponse> Items { get; set; } = new();
}

public class InvoiceItemResponse
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TaxRate { get; set; }
    public decimal TotalAmount { get; set; }
}

public class InvoiceListResponse
{
    public List<InvoiceResponse> Invoices { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

public class DashboardStatsResponse
{
    public decimal TotalRevenue { get; set; }
    public int TotalInvoices { get; set; }
    public int PendingInvoices { get; set; }
    public int PaidInvoices { get; set; }
    public int OverdueInvoices { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public decimal YearlyRevenue { get; set; }
}
