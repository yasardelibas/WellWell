# syntax=docker/dockerfile:1

# The SDK stage runs on the builder's native architecture (fast, no emulation) and produces
# portable framework-dependent DLLs, so cross-building for the amd64 droplet stays cheap.
ARG BUILDPLATFORM
FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the central build/version files first so restore can be cached independently of source churn.
COPY global.json Directory.Build.props Directory.Packages.props ./
COPY src/ ./src/

RUN dotnet restore src/MedGuard.Api/MedGuard.Api.csproj
RUN dotnet publish src/MedGuard.Api/MedGuard.Api.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./

# Workstation GC keeps the memory footprint small enough for a 512MB droplet (paired with swap).
ENV ASPNETCORE_URLS=http://0.0.0.0:8080 \
    DOTNET_gcServer=0

EXPOSE 8080
ENTRYPOINT ["dotnet", "MedGuard.Api.dll"]
