# .NET Connection Service Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8084

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["ConnectionService.csproj", "."]
RUN dotnet restore "./ConnectionService.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "ConnectionService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ConnectionService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8084/health || exit 1

ENTRYPOINT ["dotnet", "ConnectionService.dll"]
