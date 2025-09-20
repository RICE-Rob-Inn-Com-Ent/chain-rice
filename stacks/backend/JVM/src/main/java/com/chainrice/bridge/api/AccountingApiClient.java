package com.chainrice.bridge.api;

import com.chainrice.bridge.config.ChainRiceConfig;
import com.chainrice.bridge.model.*;
import com.google.gson.Gson;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * Client for ChainRice Accounting API operations.
 */
public class AccountingApiClient {
    private static final Logger logger = LoggerFactory.getLogger(AccountingApiClient.class);

    private final OkHttpClient httpClient;
    private final ChainRiceConfig config;
    private final Gson gson;

    public AccountingApiClient(OkHttpClient httpClient, ChainRiceConfig config) {
        this.httpClient = httpClient;
        this.config = config;
        this.gson = new Gson();
    }

    /**
     * Create a new invoice.
     */
    public InvoiceResponse createInvoice(CreateInvoiceRequest request) throws IOException {
        String url = config.getAccountingApiUrl() + "/api/v1/invoices";
        String json = gson.toJson(request);

        RequestBody body = RequestBody.create(json, MediaType.get("application/json"));
        Request httpRequest = new Request.Builder()
                .url(url)
                .post(body)
                .addHeader("Authorization", "Bearer " + config.getApiKey())
                .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Failed to create invoice: " + response.code());
            }

            String responseBody = response.body().string();
            return gson.fromJson(responseBody, InvoiceResponse.class);
        }
    }

    /**
     * Get invoice by ID.
     */
    public InvoiceResponse getInvoice(String invoiceId) throws IOException {
        String url = config.getAccountingApiUrl() + "/api/v1/invoices/" + invoiceId;

        Request httpRequest = new Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer " + config.getApiKey())
                .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Failed to get invoice: " + response.code());
            }

            String responseBody = response.body().string();
            return gson.fromJson(responseBody, InvoiceResponse.class);
        }
    }

    /**
     * List invoices with pagination.
     */
    public InvoiceListResponse listInvoices(int page, int pageSize) throws IOException {
        String url = config.getAccountingApiUrl() + "/api/v1/invoices?page=" + page + "&pageSize=" + pageSize;

        Request httpRequest = new Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer " + config.getApiKey())
                .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Failed to list invoices: " + response.code());
            }

            String responseBody = response.body().string();
            return gson.fromJson(responseBody, InvoiceListResponse.class);
        }
    }

    /**
     * Update an existing invoice.
     */
    public InvoiceResponse updateInvoice(String invoiceId, UpdateInvoiceRequest request) throws IOException {
        String url = config.getAccountingApiUrl() + "/api/v1/invoices/" + invoiceId;
        String json = gson.toJson(request);

        RequestBody body = RequestBody.create(json, MediaType.get("application/json"));
        Request httpRequest = new Request.Builder()
                .url(url)
                .put(body)
                .addHeader("Authorization", "Bearer " + config.getApiKey())
                .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Failed to update invoice: " + response.code());
            }

            String responseBody = response.body().string();
            return gson.fromJson(responseBody, InvoiceResponse.class);
        }
    }

    /**
     * Delete an invoice.
     */
    public boolean deleteInvoice(String invoiceId) throws IOException {
        String url = config.getAccountingApiUrl() + "/api/v1/invoices/" + invoiceId;

        Request httpRequest = new Request.Builder()
                .url(url)
                .delete()
                .addHeader("Authorization", "Bearer " + config.getApiKey())
                .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            return response.isSuccessful();
        }
    }

    /**
     * Get dashboard statistics.
     */
    public DashboardStatsResponse getDashboardStats() throws IOException {
        String url = config.getAccountingApiUrl() + "/api/v1/dashboard/stats";

        Request httpRequest = new Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer " + config.getApiKey())
                .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Failed to get dashboard stats: " + response.code());
            }

            String responseBody = response.body().string();
            return gson.fromJson(responseBody, DashboardStatsResponse.class);
        }
    }

    /**
     * Health check for accounting API.
     */
    public boolean healthCheck() {
        try {
            String url = config.getAccountingApiUrl() + "/health";

            Request httpRequest = new Request.Builder()
                    .url(url)
                    .get()
                    .build();

            try (Response response = httpClient.newCall(httpRequest).execute()) {
                return response.isSuccessful();
            }
        } catch (Exception e) {
            logger.error("Health check failed for accounting API", e);
            return false;
        }
    }
}
