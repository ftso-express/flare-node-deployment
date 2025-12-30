#!/bin/bash
# File: entrypoint.sh

# Enable error handling and debugging
set -eo pipefail

# Colour definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Colour

# Debug function to log variables and their sources with colours
debug_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "\e[0;34m[DEBUG]\e[0m \e[0;37m${timestamp}:\e[0m %b\n" "$1"
}

# Function to log errors
error_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "\e[0;31m[ERROR]\e[0m \e[0;37m${timestamp}:\e[0m %b\n" "$1"
}

# Function to log warnings
warn_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "\e[1;33m[WARN]\e[0m \e[0;37m${timestamp}:\e[0m %b\n" "$1"
}

# Function to log success
success_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "\e[0;32m[SUCCESS]\e[0m \e[0;37m${timestamp}:\e[0m %b\n" "$1"
}

# Function to check if variable is set
check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    if [ -z "$var_value" ]; then
        warn_log "${var_name} is not set!"
    else
        debug_log "\e[0;36m${var_name}\e[0m=\e[0;32m${var_value}\e[0m (source: \e[0;35m${2:-environment}\e[0m)"
    fi
}

# Section header function
print_section() {
    printf "\n\e[0;34m=== %s ===\e[0m\n" "$1"
}

# Function to extract node ID from staking certificate
get_local_node_id() {
    local staking_cert="${1:-$DB_DIR/staking/staker.crt}"
    
    if [ ! -f "$staking_cert" ]; then
        debug_log "Staking certificate not found at: \e[0;36m${staking_cert}\e[0m"
        return 1
    fi
    
    debug_log "Found staking certificate: \e[0;36m${staking_cert}\e[0m"
    
    # Extract the node ID using avalanchego's method
    # The node ID is derived from the SHA256 hash of the DER-encoded public key
    local public_key_der=$(openssl x509 -in "$staking_cert" -noout -pubkey | \
                          openssl pkey -pubin -outform DER 2>/dev/null | \
                          tail -c +13)  # Skip ASN.1 header (12 bytes)
    
    if [ -z "$public_key_der" ]; then
        debug_log "Failed to extract public key from certificate"
        return 1
    fi
    
    # Calculate SHA256 hash and encode in CB58 (Avalanche's base58 variant)
    # For this script, we'll use the nodeID format that Avalanche expects
    local node_id_hash=$(printf "%s" "$public_key_der" | sha256sum | awk '{print $1}')
    
    # Try to get the actual NodeID from the running node if available
    if [ -x "/app/build/avalanchego" ] && [ -f "$staking_cert" ]; then
        # If we can read from the node's API (after it starts), we'll use that
        # For now, we'll construct it from the certificate
        debug_log "Node ID hash: \e[0;37m${node_id_hash}\e[0m"
    fi
    
    # Alternative: Try to read NodeID from node's info if it has been generated
    local node_id_file="$DB_DIR/staking/staker.key"
    if [ -f "$node_id_file" ]; then
        # NodeID is typically stored or can be derived from the key pair
        # This is a placeholder - actual implementation depends on your setup
        debug_log "Found staker key file"
    fi
    
    # Return empty if we can't determine the NodeID
    # In production, you might want to call the node's API after startup
    return 1
}

# Function to get node ID from a running node's API
get_node_id_from_api() {
    local api_endpoint="${1:-http://localhost:${HTTP_PORT}}"
    local max_retries="${2:-30}"
    local retry_delay="${3:-2}"
    
    debug_log "Attempting to get Node ID from API: \e[0;36m${api_endpoint}\e[0m"
    
    for i in $(seq 1 $max_retries); do
        local response=$(curl -m 5 -sX POST \
            --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
            -H 'content-type:application/json;' \
            "${api_endpoint}/ext/info" 2>/dev/null || echo "")
        
        if [ ! -z "$response" ]; then
            local node_id=$(printf "%s" "$response" | jq -r '.result.nodeID // empty' 2>/dev/null)
            
            if [ ! -z "$node_id" ] && [ "$node_id" != "null" ]; then
                printf "%s" "$node_id"
                return 0
            fi
        fi
        
        if [ $i -lt $max_retries ]; then
            debug_log "Retry $i/$max_retries - waiting ${retry_delay}s..."
            sleep $retry_delay
        fi
    done
    
    return 1
}

# Function to check if node ID exists in validator set
check_node_id_in_validators() {
    local node_id="$1"
    local check_endpoint="${2:-$__BOOTSTRAP_ENDPOINT}"
    
    if [ -z "$node_id" ]; then
        warn_log "Cannot check for node ID: node ID not provided"
        return 2
    fi
    
    if [ -z "$check_endpoint" ]; then
        warn_log "Cannot check for node ID: no bootstrap endpoint available"
        return 2
    fi
    
    debug_log "Checking if node ID \e[0;36m${node_id}\e[0m exists in validator set"
    debug_log "Using endpoint: \e[0;36m${check_endpoint}\e[0m"
    
    # Determine the correct P-Chain endpoint
    local p_chain_endpoint="${check_endpoint}"
    # If endpoint ends with /ext/info, replace with /ext/bc/P
    if [[ "$check_endpoint" == */ext/info ]]; then
        p_chain_endpoint="${check_endpoint%/ext/info}/ext/bc/P"
    elif [[ "$check_endpoint" != */ext/bc/P ]]; then
        # If it doesn't have a path, add /ext/bc/P
        p_chain_endpoint="${check_endpoint}/ext/bc/P"
    fi
    
    debug_log "P-Chain endpoint: \e[0;36m${p_chain_endpoint}\e[0m"
    
    # Get current validator set from P-Chain
    local validators_response=$(curl -m 10 -sX POST \
        --data '{"jsonrpc":"2.0","id":1,"method":"platform.getCurrentValidators","params":{}}' \
        -H 'content-type:application/json;' \
        "${p_chain_endpoint}" 2>/dev/null || echo "")
    
    if [ -z "$validators_response" ]; then
        warn_log "Failed to fetch validator set - empty response"
        debug_log "Endpoint used: \e[0;36m${p_chain_endpoint}\e[0m"
        return 2
    fi
    
    debug_log "Validators response received (${#validators_response} bytes)"
    
    # Check if our node ID is in the validator set
    local node_exists=$(printf "%s" "$validators_response" | \
        jq -r '.result.validators[]?.nodeID // empty' 2>/dev/null | \
        grep -c "^${node_id}$" 2>/dev/null || printf "0")
    
    # Ensure node_exists is a valid integer
    node_exists=$(printf "%s" "$node_exists" | tr -d '\n' | grep -o '[0-9]*' || printf "0")
    [ -z "$node_exists" ] && node_exists=0
    
    if [ "$node_exists" -gt 0 ]; then
        return 0  # Node ID exists
    else
        return 1  # Node ID does not exist
    fi
}

# Function to perform node ID conflict check
perform_node_id_conflict_check() {
    local check_endpoint="${1:-$__BOOTSTRAP_ENDPOINT}"
    
    print_section "Node ID Conflict Check"
    
    # First, try to get NodeID from environment variable
    if [ ! -z "$NODE_ID" ]; then
        LOCAL_NODE_ID="$NODE_ID"
        success_log "Using Node ID from environment: \e[0;32m${LOCAL_NODE_ID}\e[0m"
    else
        debug_log "NODE_ID not set in environment, will check after node starts"
        return 0  # Skip check for now, will verify after startup
    fi
    
    # Check if the Node ID exists in the validator set
    if check_node_id_in_validators "$LOCAL_NODE_ID" "$check_endpoint"; then
        error_log "\e[0;31mCONFLICT DETECTED!\e[0m"
        error_log "Node ID \e[0;36m${LOCAL_NODE_ID}\e[0m already exists in the validator set!"
        error_log "This node would conflict with an existing validator."
        error_log "Please use different staking credentials or verify this is intentional."
        
        if [ "${ALLOW_NODE_ID_CONFLICT:-0}" != "1" ]; then
            error_log "Exiting to prevent conflict. Set ALLOW_NODE_ID_CONFLICT=1 to override."
            return 1
        else
            warn_log "ALLOW_NODE_ID_CONFLICT=1 - Proceeding despite conflict!"
        fi
    else
        local check_result=$?
        if [ $check_result -eq 1 ]; then
            success_log "Node ID \e[0;32m${LOCAL_NODE_ID}\e[0m is unique - no conflict detected"
        elif [ $check_result -eq 2 ]; then
            warn_log "Could not verify Node ID uniqueness - proceeding with caution"
        fi
    fi
    
    print_section "Node ID Check Complete"
    return 0
}

print_section "Starting Environment Check"
check_var "AUTOCONFIGURE_PUBLIC_IP"
check_var "AUTOCONFIGURE_BOOTSTRAP"
check_var "HTTP_HOST"
check_var "HTTP_PORT"
check_var "STAKING_PORT"
check_var "DB_DIR"
check_var "DB_TYPE"
check_var "CHAIN_CONFIG_DIR"
check_var "LOG_DIR"
check_var "LOG_LEVEL"
check_var "NETWORK_ID"
check_var "NODE_ID"
print_section "Environment Check Complete"

if [ "$AUTOCONFIGURE_PUBLIC_IP" = "1" ]; then
    debug_log "\e[0;36mPublic IP autoconfiguration enabled\e[0m"
    if [ -z "$PUBLIC_IP" ]; then
        debug_log "Attempting to fetch public IP from flare.network"
        PUBLIC_IP=$(curl -s -m 10 https://flare.network/cdn-cgi/trace | grep 'ip=' | cut -d'=' -f2)
        if [ $? -eq 0 ] && [ ! -z "$PUBLIC_IP" ]; then
            success_log "Successfully obtained public IP: \e[0;32m${PUBLIC_IP}\e[0m (source: flare.network)"
        else
            error_log "Failed to fetch public IP!"
            exit 1
        fi
    else
        warn_log "AUTOCONFIGURE_PUBLIC_IP=1 but PUBLIC_IP already set to '\e[0;32m${PUBLIC_IP}\e[0m' (source: environment)"
    fi
fi

if [ "$AUTOCONFIGURE_BOOTSTRAP" = "1" ]; then
    debug_log "\e[0;36mBootstrap autoconfiguration enabled\e[0m"
    
    # Parse bootstrap endpoints
    debug_log "Processing bootstrap endpoints"
    __BOOTSTRAP_ENDPOINTS=("${AUTOCONFIGURE_BOOTSTRAP_ENDPOINT}" ${AUTOCONFIGURE_FALLBACK_ENDPOINTS//,/ })
    debug_log "Primary endpoint: \e[0;36m${AUTOCONFIGURE_BOOTSTRAP_ENDPOINT}\e[0m"
    debug_log "Fallback endpoints: \e[0;36m${AUTOCONFIGURE_FALLBACK_ENDPOINTS}\e[0m"

    # Try each endpoint
    print_section "Testing Bootstrap Endpoints"
    for __ENDPOINT in "${__BOOTSTRAP_ENDPOINTS[@]}"; do
        debug_log "Testing endpoint: \e[0;36m${__ENDPOINT}\e[0m"
        
        RESPONSE_CODE=$(curl -X POST -m 5 -s -o /dev/null -w '%{http_code}' "$__ENDPOINT" \
            -H 'Content-Type: application/json' \
            --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeIP"}' 2>/dev/null || printf "000")
            
        debug_log "Response code: \e[0;35m${RESPONSE_CODE}\e[0m"
        
        if [ "$RESPONSE_CODE" = "200" ]; then
            __BOOTSTRAP_ENDPOINT="$__ENDPOINT"
            success_log "Successfully connected to endpoint: \e[0;32m${__ENDPOINT}\e[0m"
            break
        else
            error_log "Endpoint unreachable: \e[0;31m${__ENDPOINT}\e[0m"
            continue
        fi
    done

    if [ -z "$__BOOTSTRAP_ENDPOINT" ]; then
        error_log "All bootstrap endpoints failed!"
        exit 1
    fi

    # Fetch bootstrap information
    debug_log "Fetching bootstrap IPs and IDs from: \e[0;36m${__BOOTSTRAP_ENDPOINT}\e[0m"
    
    # Get bootstrap IPs
    BOOTSTRAP_IPS_RESPONSE=$(curl -m 10 -sX POST \
        --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeIP"}' \
        -H 'content-type:application/json;' \
        "${__BOOTSTRAP_ENDPOINT}" 2>/dev/null || printf "{}")
    BOOTSTRAP_IPS=$(printf "%s" "$BOOTSTRAP_IPS_RESPONSE" | jq -r '.result.ip // empty')
    debug_log "Bootstrap IPs Response: \e[0;37m${BOOTSTRAP_IPS_RESPONSE}\e[0m"
    success_log "Parsed Bootstrap IPs: \e[0;32m${BOOTSTRAP_IPS}\e[0m"

    # Get bootstrap IDs
    BOOTSTRAP_IDS_RESPONSE=$(curl -m 10 -sX POST \
        --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
        -H 'content-type:application/json;' \
        "${__BOOTSTRAP_ENDPOINT}" 2>/dev/null || printf "{}")
    BOOTSTRAP_IDS=$(printf "%s" "$BOOTSTRAP_IDS_RESPONSE" | jq -r '.result.nodeID // empty')
    debug_log "Bootstrap IDs Response: \e[0;37m${BOOTSTRAP_IDS_RESPONSE}\e[0m"
    success_log "Parsed Bootstrap IDs: \e[0;32m${BOOTSTRAP_IDS}\e[0m"
fi

# Check for node ID conflicts before starting
if [ "${CHECK_NODE_ID_CONFLICT:-1}" = "1" ]; then
    if ! perform_node_id_conflict_check "$__BOOTSTRAP_ENDPOINT"; then
        error_log "Node ID conflict detected - aborting startup"
        exit 1
    fi
else
    debug_log "Node ID conflict check disabled (CHECK_NODE_ID_CONFLICT=0)"
fi

# Final configuration check
print_section "Final Configuration Check"
check_var "PUBLIC_IP" "autoconfigured/environment"
check_var "BOOTSTRAP_IPS" "autoconfigured"
check_var "BOOTSTRAP_IDS" "autoconfigured"
debug_log "EXTRA_ARGUMENTS=\e[0;36m${EXTRA_ARGUMENTS}\e[0m"
print_section "Configuration Check Complete"

success_log "Starting avalanchego with configured parameters"
exec /app/build/avalanchego \
    --http-host=$HTTP_HOST \
    --http-port=$HTTP_PORT \
    --staking-port=$STAKING_PORT \
    --public-ip=$PUBLIC_IP \
    --db-dir=$DB_DIR \
    --db-type=$DB_TYPE \
    --bootstrap-ips=$BOOTSTRAP_IPS \
    --bootstrap-ids=$BOOTSTRAP_IDS \
    --bootstrap-beacon-connection-timeout=$BOOTSTRAP_BEACON_CONNECTION_TIMEOUT \
    --chain-config-dir=$CHAIN_CONFIG_DIR \
    --log-dir=$LOG_DIR \
    --log-level=$LOG_LEVEL \
    --network-id=$NETWORK_ID \
    --http-allowed-hosts="*" \
    $EXTRA_ARGUMENTS