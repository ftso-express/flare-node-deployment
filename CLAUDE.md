# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository manages Flare network observation node deployments using Docker Compose. Each node runs the Avalanche-based Flare blockchain software (`flarefoundation/go-flare`) and is configured with network-specific settings for the Flare mainnet.

## Quick Start

### Multi-Node Orchestration (Recommended)

Manage all nodes from a single location:

```bash
cd network/flare/observation-nodes

# See all nodes and their status
make help

# List detailed configuration
make list

# Check all node configurations
make check-all

# Initialize volumes for enabled nodes
make init-volumes

# Start all enabled nodes
make up

# View status of all nodes
make status

# Stop all nodes
make down
```

### Single Node Management

Manage an individual node directly:

```bash
cd network/flare/observation-nodes/node-004

# Create volumes
make init-volumes

# Start the node (colorized output)
make up

# Follow logs (auto-resets terminal)
make logs

# Check status
make status
```

**For FSP indexing:** Use **node-004** - it's optimized for 42-day historical data with state-sync + pruning.

## Architecture

### Directory Structure

```
network/flare/observation-nodes/
├── node-001/
├── node-002/
├── node-003/
├── node-004/
```

Each node directory is self-contained with:
- `Makefile` - Node management with ENABLED flag enforcement
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

### Node Enable/Disable Management

Each node has an `ENABLED` flag in its `.env` file that controls whether it can be started:
- `ENABLED=true` - Node can be started via Makefile
- `ENABLED=false` - Makefile prevents node startup with clear error message

The Makefile enforces this flag for `make up` and `make restart` commands, preventing accidental startup of disabled nodes. The `make down` command always works regardless of the flag to allow stopping nodes.

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
4. Ensure `ENABLED=true` in `.env` if you want the node to be startable
5. Create volume directories: `make init-volumes`
6. Generate or copy staking certificates to `node/certs/staking/`
7. Launch: `make up` (or `docker compose up -d`)

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

### State-Sync and Pruning Configuration

**IMPORTANT**: Understanding the relationship between state-sync, pruning, and historical data is critical for FSP (Flare Systems Protocol) indexing and other applications requiring historical blockchain data.

#### Flare Network Block Time

Flare Network operates with approximately **1.8 seconds per block**. This is essential for calculating historical data retention:

- **42 days of data** ≈ 2,016,000 blocks
- **7 days of data** ≈ 336,000 blocks
- **24 hours of data** ≈ 48,000 blocks

#### Critical C-Chain Configuration Parameters

| Parameter | Type | Default | Recommended for 42-Day FSP |
|-----------|------|---------|----------------------------|
| `state-sync-enabled` | bool | `false` | `true` |
| `state-sync-min-blocks` | uint64 | `300000` | `2100000` |
| `pruning-enabled` | bool | `true` | `true` |
| `allow-missing-tries` | bool | `false` | `true` (**required** with pruning) |
| `tx-lookup-limit` | uint64 | varies | `2100000` |
| `transaction-history` | uint64 | `0` | `0` (unlimited) |

**Key findings from Avalanche documentation**:
- **"If you need historical data, state sync isn't the right option"** - However, with proper configuration, you can retain enough recent history for most use cases
- `allow-missing-tries: true` is **mandatory** when enabling pruning to override archival mode protection
- State-sync bootstraps from a recent snapshot, potentially skipping historical blocks before the sync point

#### The "GetTimestamp" Error Issue

When using state-sync with insufficient block retention, queries for historical blocks will fail with "gettimestamp" errors.

**Root Cause**:
- State-sync downloads chain state from a recent snapshot near the chain tip
- Historical blocks older than the sync point are never downloaded
- Queries for timestamps on missing blocks fail

**Solution**:
- Set `state-sync-min-blocks` to match or exceed your historical data requirements
- For 42 days of FSP data: `state-sync-min-blocks: 2100000` (43.75 days with buffer)
- Set `tx-lookup-limit` to the same value to retain transaction indices

#### Node Configuration Examples

**Node-001 (Archive Mode)**:
```json
{
  "pruning-enabled": false,
  "state-sync-enabled": false
}
```
- Full archival node with complete historical data
- No state-sync, no pruning
- High disk usage (>2TB)
- Best for: Complete historical queries, blockchain explorers

**Node-002 (State-Sync with Historical Window)**:
```json
{
  "pruning-enabled": false,
  "state-sync-enabled": true,
  "state-sync-min-blocks": 2240000
}
```
- Retains ~46.7 days of historical data
- Fast initial sync via state-sync
- No pruning (higher disk usage but complete state)
- Best for: Historical analysis with known time window

**Node-003 (Pruning with Transaction Indexing)**:
```json
{
  "pruning-enabled": true,
  "tx-lookup-limit": 3240000,
  "state-sync-enabled": false
}
```
- Maintains ~67.5 days of transaction history
- Uses pruning to save disk space
- Full sync from genesis (slower initial sync)
- Best for: Long-term transaction lookups with disk efficiency

**Node-004 (Optimized for 42-Day FSP Indexing)** ⭐ **RECOMMENDED**:
```json
{
  "snowman-api-enabled": false,
  "coreth-admin-api-enabled": false,
  "eth-apis": ["eth", "eth-filter", "net", "web3", "internal-eth", "internal-blockchain", "internal-transaction"],
  "rpc-gas-cap": 50000000,
  "rpc-tx-fee-cap": 100,
  "pruning-enabled": true,
  "allow-missing-tries": true,
  "tx-lookup-limit": 2100000,
  "state-sync-enabled": true,
  "state-sync-min-blocks": 2100000,
  "local-txs-enabled": false,
  "api-max-duration": 0,
  "api-max-blocks-per-request": 0,
  "allow-unfinalized-queries": false,
  "allow-unprotected-txs": false,
  "log-level": "info"
}
```

**Why Node-004 is optimal for FSP indexing**:
- ✅ **Fast initial sync** via state-sync
- ✅ **43.75 days of historical data** (2,100,000 blocks) - exceeds 42-day requirement with buffer
- ✅ **Disk space efficiency** via pruning
- ✅ **Complete transaction indices** for the retention window
- ✅ **No "gettimestamp" errors** for blocks within the 42-day window
- ✅ **Production-ready** with security features (admin APIs disabled)

#### Configuration Strategy Decision Matrix

| Use Case | State-Sync | Pruning | Retention Period | Recommended Node |
|----------|------------|---------|------------------|------------------|
| FSP indexing (42 days) | ✅ Yes | ✅ Yes | 43.75 days | **Node-004** |
| Full blockchain history | ❌ No | ❌ No | Unlimited | Node-001 |
| Fast sync + moderate history | ✅ Yes | ❌ No | 46.7 days | Node-002 |
| Long transaction history | ❌ No | ✅ Yes | 67.5 days | Node-003 |
| Development/Testing | ✅ Yes | ✅ Yes | 7-14 days | Custom |

#### Deployment Checklist for Node-004

1. ✅ C-Chain config updated with `state-sync-min-blocks: 2100000`
2. ✅ `allow-missing-tries: true` set (required for pruning)
3. ✅ `.env` file created with unique ports (9652/9653)
4. ✅ Volume paths configured (`/var/lib/flare/volumes/flare-ftso-observation-node-004-*`)
5. ✅ Makefile updated with `init-volumes` target
6. ⚠️ **TODO**: Update `NODE_ID` in `node/node.env`
7. ⚠️ **TODO**: Generate/copy staking certificates to `node/certs/staking/`
8. ⚠️ **TODO**: Create volume directories: `make init-volumes`

#### Avalanche 1.12.0 Changes

Flare v1.12.0 is based on Avalanche 1.12.0 ("Etna" release):
- Reduced C-Chain minimum base fee from 25 nAVAX to 1 nAVAX (ACP-125)
- Activated Cancun EIPs on C-Chain (ACP-131)
- No breaking changes to state-sync/pruning behavior
- Offline pruning process remains unchanged

**References**:
- [Avalanche C-Chain Configuration](https://build.avax.network/docs/nodes/chain-configs/c-chain)
- [Avalanche 1.12.0 Release Notes](https://github.com/ava-labs/avalanchego/releases/tag/v1.12.0)
- [Flare Network Overview](https://dev.flare.network/network/overview/)

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

### Orchestration Makefile (Multi-Node Management)

A top-level Makefile at `network/flare/observation-nodes/Makefile` provides orchestration across all nodes:

```bash
cd network/flare/observation-nodes

# Show help and discovered nodes
make help

# List all nodes with detailed configuration
make list

# Check configuration of all nodes
make check-all

# Initialize volumes for all enabled nodes
make init-volumes

# Start all enabled nodes (cascades through directories)
make up

# Stop all nodes
make down

# Restart all enabled nodes
make restart

# Show status of all nodes
make status

# Show all running containers
make ps

# Follow combined logs from all running nodes
make logs
```

**Key Features:**

- **Auto-discovery**: Automatically finds all `node-*` directories
- **ENABLED check**: Only acts on nodes with `ENABLED=true` in `.env` (for up/restart)
- **Cascading execution**: Delegates to individual node Makefiles for actual operations
- **Error handling**: Continues with other nodes if one fails
- **Colorized output**: Clear visual feedback for each node's status
- **Aggregate views**: See status of all nodes at once

### Individual Node Makefile

Each node directory has a Makefile with the following targets:

```bash
cd network/flare/observation-nodes/node-001

# Show available commands and current ENABLED status
make help

# Create volume directories from .env configuration
make init-volumes

# Start node (only if ENABLED=true)
make up

# View logs
make logs

# Check node status and query API
make status

# Show running containers
make ps

# Restart node (only if ENABLED=true)
make restart

# Stop node (works regardless of ENABLED flag)
make down
```

**New: Automated Volume Setup**

The `make init-volumes` target automatically:
- Reads `X_VOLUME_NODE_DATA_DEVICE` and `X_VOLUME_NODE_LOGS_DEVICE` from `.env`
- Creates the directories if they don't exist
- Provides clear status messages
- Safe to run multiple times (idempotent)

This eliminates the need to manually create directories with `mkdir -p`.

**Terminal Reset After Logs**

The `make logs` target includes automatic terminal reset via `trap 'stty sane'` to prevent terminal corruption when you `Ctrl+C` out of log following. Container logs sometimes contain control characters that mess up terminal state.

If your terminal becomes corrupted when using direct `docker compose` commands:
- Run `reset` or `stty sane` to restore terminal settings
- Use `make logs` instead - it handles cleanup automatically

**Colorized Output**

All Makefile targets use color-coded output for improved readability:

- 🟢 **Green** - Success messages, enabled status, start operations
- 🔴 **Red** - Error messages, disabled status, failures
- 🟡 **Yellow** - Warnings, stop/restart operations
- 🔵 **Blue** - Info messages, utility commands
- 🔷 **Cyan** - Headers, logs, general information
- 🟣 **Magenta** - Status displays
- **Bold** - Important text, section headers

Direct Docker Compose commands can also be used:
```bash
docker compose up -d
docker compose logs -f
docker compose down
```

Query node API directly:
```bash
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
  -H 'content-type:application/json;' http://localhost:9650/ext/info
```

## Node Types

The configuration files reference different node roles in `_config` directories:
- `config.json.observer` - Read-only observation nodes (no validation)
- `config.json.validator` - Active validator nodes (stake required)
- `config.json.dev` - Development/testing configurations

Current deployments include:
- **Node-001**: Archive mode (full history, no state-sync, no pruning)
- **Node-002**: State-sync enabled with 46.7-day retention window
- **Node-003**: Pruning enabled with 67.5-day transaction history
- **Node-004**: Optimized for FSP indexing (state-sync + pruning, 43.75-day retention) ⭐ **RECOMMENDED for 42-day FSP data**

## Recent Enhancements

### Orchestration Makefile (Multi-Node Management)

**Location:** `network/flare/observation-nodes/Makefile`

A top-level Makefile provides centralized control over all nodes:

**Features:**
- **Auto-discovery**: Automatically finds all `node-*` directories
- **Smart ENABLED checks**: Only acts on nodes with `ENABLED=true` (for up/restart operations)
- **Cascading execution**: Delegates to individual node Makefiles for validation and operations
- **Error resilience**: Continues with other nodes if one fails
- **Colorized aggregate output**: Beautiful visual feedback across all nodes
- **Batch operations**: Start, stop, restart, or check status of all nodes at once

**Key Commands:**
```bash
make list       # Detailed configuration of all nodes
make check-all  # Validate configuration (volumes, certs, NODE_ID, etc.)
make up         # Start all enabled nodes
make down       # Stop all nodes
make status     # View status of all nodes
make logs       # Combined logs from all running nodes
```

### Colorized Makefile Output

All Makefile commands (orchestration and individual nodes) use consistent color coding:

- 🟢 **Green**: Success messages, enabled status, start operations
- 🔴 **Red**: Error messages, disabled status, failures
- 🟡 **Yellow**: Warnings, stop/restart operations
- 🔵 **Blue**: Info messages, utility commands
- 🔷 **Cyan**: Headers, borders, logs
- 🟣 **Magenta**: Status displays
- **Bold**: Section headers, important text

**Benefits:**
- Quickly identify successes vs errors at a glance
- Clear visual hierarchy in output
- Consistent experience across all commands
- Professional, production-ready appearance

### Automatic Volume Initialization

**Command:** `make init-volumes`

**Features:**
- Reads volume paths from `.env` file automatically
- Creates `X_VOLUME_NODE_DATA_DEVICE` and `X_VOLUME_NODE_LOGS_DEVICE` directories
- Idempotent (safe to run multiple times)
- Works at both orchestration level (all enabled nodes) and individual node level
- Clear visual feedback showing which directories were created vs already exist

**Replaces:** Manual `mkdir -p /var/lib/flare/volumes/...` commands

### Terminal Reset on Log Exit

**Issue Fixed:** Docker container logs contain control characters that corrupt terminal state when you `Ctrl+C` out of `docker compose logs -f`, causing invisible cursor and garbled output.

**Solution:** All `make logs` commands (orchestration and individual nodes) automatically run `stty sane` via a trap on exit.

**Manual Fix (if using direct docker compose):**
```bash
reset       # Full terminal reset
stty sane   # Restore terminal settings only
```

### Comprehensive Documentation

**README.adoc for each node:**
- Configuration summary tables
- Use case analysis
- Detailed parameter explanations
- Quick start guides
- Performance characteristics
- Data retention calculations
- Comparison matrices between nodes
- Troubleshooting guides
- Makefile command reference

**Individual node documentation:**
- `node-001/README.adoc`: Archive mode documentation
- `node-002/README.adoc`: State-sync mode documentation
- `node-003/README.adoc`: Pruning mode documentation
- `node-004/README.adoc`: FSP-optimized configuration (⭐ recommended for FSP indexing)

Each README includes sections on:
- Overview and node type
- Configuration summary
- Use cases (best for / not ideal for)
- Key parameters explained
- Quick start guide
- **NEW:** Makefile commands with color coding
- **NEW:** Multi-node orchestration reference
- Performance characteristics
- Troubleshooting
- Known limitations

## Summary: Complete Feature Set

### Configuration Management
✅ Four distinct node configurations (archive, state-sync, pruning, FSP-optimized)
✅ ENABLED flag enforcement in Makefiles
✅ Environment variable validation
✅ Auto-configuration via entrypoint.sh
✅ Node ID conflict detection

### Operational Tools
✅ Orchestration Makefile for multi-node management
✅ Colorized output across all commands
✅ Automatic volume initialization
✅ Terminal reset on log exit
✅ Comprehensive health checks (`make check-all`)

### Documentation
✅ Detailed CLAUDE.md for AI code assistants
✅ Individual README.adoc for each node
✅ Configuration decision matrices
✅ State-sync + pruning research and recommendations
✅ FSP indexing optimization guide

### Node Configurations
✅ **Node-001**: Full archive (unlimited history)
✅ **Node-002**: Fast state-sync (46.7 days)
✅ **Node-003**: Efficient pruning (67.5 days tx history)
✅ **Node-004**: FSP-optimized (42+ days, state-sync + pruning) ⭐ **RECOMMENDED**

### Developer Experience
✅ Single-command deployment (`make up`)
✅ Batch operations across all nodes
✅ Clear visual feedback with colors
✅ Automatic error handling
✅ Comprehensive validation before operations
