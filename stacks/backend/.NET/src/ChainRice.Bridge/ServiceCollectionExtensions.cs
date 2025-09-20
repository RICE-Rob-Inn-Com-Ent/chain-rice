using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ChainRice.Bridge;

/// <summary>
/// Extension methods for registering ChainRice services
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Add ChainRice services to the dependency injection container
    /// </summary>
    public static IServiceCollection AddChainRice(this IServiceCollection services, IConfiguration configuration)
    {
        // Configure options
        services.Configure<ChainRiceOptions>(configuration.GetSection("ChainRice"));

        // Register HTTP client for REST APIs
        services.AddHttpClient<ChainRiceClient>((serviceProvider, client) =>
        {
            var options = configuration.GetSection("ChainRice").Get<ChainRiceOptions>() ?? new ChainRiceOptions();
            client.BaseAddress = new Uri(options.AccountingApiUrl);
            client.Timeout = options.Timeout;

            if (!string.IsNullOrEmpty(options.ApiKey))
            {
                client.DefaultRequestHeaders.Add("Authorization", $"Bearer {options.ApiKey}");
            }
        });

        // Register gRPC channel for blockchain operations
        services.AddSingleton<GrpcChannel>(serviceProvider =>
        {
            var options = configuration.GetSection("ChainRice").Get<ChainRiceOptions>() ?? new ChainRiceOptions();
            return GrpcChannel.ForAddress(options.BlockchainUrl);
        });

        // Register main client
        services.AddScoped<ChainRiceClient>();

        // Register individual API clients
        services.AddScoped<AccountingApiClient>();
        services.AddScoped<TaxApiClient>();
        services.AddScoped<BlockchainClient>();

        return services;
    }

    /// <summary>
    /// Add ChainRice services with custom options
    /// </summary>
    public static IServiceCollection AddChainRice(this IServiceCollection services, Action<ChainRiceOptions> configureOptions)
    {
        services.Configure(configureOptions);

        // Register HTTP client for REST APIs
        services.AddHttpClient<ChainRiceClient>((serviceProvider, client) =>
        {
            var options = new ChainRiceOptions();
            configureOptions(options);

            client.BaseAddress = new Uri(options.AccountingApiUrl);
            client.Timeout = options.Timeout;

            if (!string.IsNullOrEmpty(options.ApiKey))
            {
                client.DefaultRequestHeaders.Add("Authorization", $"Bearer {options.ApiKey}");
            }
        });

        // Register gRPC channel for blockchain operations
        services.AddSingleton<GrpcChannel>(serviceProvider =>
        {
            var options = new ChainRiceOptions();
            configureOptions(options);
            return GrpcChannel.ForAddress(options.BlockchainUrl);
        });

        // Register main client
        services.AddScoped<ChainRiceClient>();

        // Register individual API clients
        services.AddScoped<AccountingApiClient>();
        services.AddScoped<TaxApiClient>();
        services.AddScoped<BlockchainClient>();

        return services;
    }
}
