# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository manages Flare network observation node deployments using Docker Compose. Each node runs the Avalanche-based Flare blockchain software (`flarefoundation/go-flare`) and is configured with network-specific settings for the Flare mainnet.

## Architecture

### Directory Structure

```
network/flare/observation-nodes/
├── node-001/
├── node-002/
├── node-003/
```

Each node directory is self-contained with:
- `compose.yaml` - Docker Compose configuration with extensive YAML anchors for logging/settings
- `.env.example` - Docker Compose environment variables (X_* prefixed)
- `node/node.env.example` - Node runtime configuration
- `node/entrypoint.sh` - Sophisticated startup script with auto-configuration
- `node/configs/flare/C/config.json` - C-Chain (EVM) configuration
- `node/certs/staking/` - TLS certificates for node identity (gitignored)

### Configuration Layers

The system uses two separate environment variable namespaces:

1. **Docker Compose variables** (`.env`): Prefixed with `X_*`, controls container setup, ports, volumes, labels, and logging drivers
2. **Node runtime variables** (`node/node.env`): Controls avalanchego behavior, bootstrap settings, and auto-configuration features

### Entrypoint Script Features

The `entrypoint.sh` script provides:
- **Auto-configuration**: Automatically fetches public IP and bootstrap node information from Flare network endpoints
- **Node ID conflict detection**: Checks if the node's identity already exists in the validator set before startup to prevent conflicts
- **Fallback bootstrap endpoints**: Tries multiple endpoints if primary fails
- **Colored logging**: Structured debug/info/warn/error logging with timestamps
- **Environment validation**: Checks all required variables before launch

Key environment variables for entrypoint:
- `AUTOCONFIGURE_PUBLIC_IP=1` - Auto-fetch public IP from flare.network
- `AUTOCONFIGURE_BOOTSTRAP=1` - Auto-fetch bootstrap IPs/IDs from network
- `CHECK_NODE_ID_CONFLICT=1` - Validate node ID uniqueness (default: enabled)
- `ALLOW_NODE_ID_CONFLICT=0` - Override to allow duplicate node IDs (default: disabled)

## Working with Nodes

### Setup a New Node

1. Copy `.env.example` to `.env` in the node directory
2. Copy `node/node.env.example` to `node/node.env`
3. Update configuration values (container name, ports, volume paths, node ID)
4. Generate or copy staking certificates to `node/certs/staking/`
5. Launch: `docker compose up -d`

### Configuration Files

**C-Chain config** (`node/configs/flare/C/config.json`):
- Controls EVM chain behavior
- Sets enabled APIs: eth, eth-filter, net, web3, internal-*
- Disables admin APIs for security
- Controls pruning, state sync, and query limits

**Docker Compose config** (`compose.yaml`):
- Uses YAML anchors extensively for DRY configuration
- Supports multiple logging drivers: local, json-file, journald, fluentd, gelf
- Binds host directories as Docker volumes (not Docker-managed volumes)
- Exposes HTTP (9650) and staking (9651) ports

## Important Notes

### Security

- Never commit `.env` files or staking certificates (enforced by `.gitignore`)
- Staking certificates (`staker.crt`, `staker.key`) define node identity
- Duplicate node IDs across the network will cause conflicts - the entrypoint script checks this by default
- Admin APIs are disabled in C-Chain config for security

### Bootstrap Configuration

When `AUTOCONFIGURE_BOOTSTRAP=1`:
- Connects to `https://flare-bootstrap.flare.network/ext/info` by default
- Fetches bootstrap node IPs and IDs via JSON-RPC
- Falls back to `AUTOCONFIGURE_FALLBACK_ENDPOINTS` if primary fails
- Validates endpoints return HTTP 200 before use

### Volume Management

Volumes use bind mounts to specific host paths (not Docker-managed):
- `X_VOLUME_NODE_DATA_DEVICE` - Blockchain database storage
- `X_VOLUME_NODE_LOGS_DEVICE` - Application logs
- Must exist on host before starting containers

### Port Configuration

Each node needs unique port mappings:
- HTTP API: `X_PORT_HTTP_PUBLISHED` (external) -> `X_PORT_HTTP_TARGETED` (container)
- Staking: `X_PORT_STAKING_PUBLISHED` (external) -> `X_PORT_STAKING_TARGETED` (container)
- Default: both use 9650/9651

## Development Commands

Start a specific node:
```bash
cd network/flare/observation-nodes/node-001
docker compose up -d
```

View logs:
```bash
docker compose logs -f
```

Stop node:
```bash
docker compose down
```

Check node status via API:
```bash
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
  -H 'content-type:application/json;' http://localhost:9650/ext/info
```

## Node Types

The configuration files reference different node roles in `_config` directories:
- `config.json.observer` - Read-only observation nodes (no validation)
- `config.json.validator` - Active validator nodes (stake required)
- `config.json.dev` - Development/testing configurations

Current deployments use observer configuration with state-sync disabled for full historical data.
