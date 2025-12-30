.PHONY: help up down restart logs status health backup-keys ps check-enabled init-volumes

# Color definitions
COLOR_RESET   := \033[0m
COLOR_BOLD    := \033[1m
COLOR_RED     := \033[31m
COLOR_GREEN   := \033[32m
COLOR_YELLOW  := \033[33m
COLOR_BLUE    := \033[34m
COLOR_MAGENTA := \033[35m
COLOR_CYAN    := \033[36m

ENV_FILE := .env
ENV_EXAMPLE := .env.example

help:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║        Flare Observation Node - Make Targets              ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make init-volumes$(COLOR_RESET) - Create volume directories from .env"
	@echo -e "  $(COLOR_BOLD)$(COLOR_GREEN)make up$(COLOR_RESET)           - Start the node (if ENABLED=true)"
	@echo -e "  $(COLOR_BOLD)$(COLOR_YELLOW)make down$(COLOR_RESET)         - Stop the node"
	@echo -e "  $(COLOR_BOLD)$(COLOR_YELLOW)make restart$(COLOR_RESET)      - Restart the node (if ENABLED=true)"
	@echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)make logs$(COLOR_RESET)         - Follow node logs"
	@echo -e "  $(COLOR_BOLD)$(COLOR_MAGENTA)make status$(COLOR_RESET)       - Show node status"
	@echo -e "  $(COLOR_BOLD)$(COLOR_GREEN)make health$(COLOR_RESET)       - Check node health endpoint"
	@echo -e "  $(COLOR_BOLD)$(COLOR_YELLOW)make backup-keys$(COLOR_RESET)  - Backup staking keys with NodeID in filename"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make ps$(COLOR_RESET)           - Show running containers"
	@echo ""
	@echo -e "$(COLOR_BOLD)Current status:$(COLOR_RESET)"
	@if [ -f "$(ENV_FILE)" ]; then \
		ENABLED=$$(grep '^ENABLED=' $(ENV_FILE) | cut -d'=' -f2); \
		if [ "$$ENABLED" = "true" ]; then \
			echo -e "  ENABLED: $(COLOR_GREEN)✓ true$(COLOR_RESET) (node will start)"; \
		else \
			echo -e "  ENABLED: $(COLOR_RED)✗ $$ENABLED$(COLOR_RESET) (node will NOT start)"; \
		fi; \
	else \
		echo -e "  $(COLOR_YELLOW)⚠ WARNING:$(COLOR_RESET) $(ENV_FILE) not found. Copy from $(ENV_EXAMPLE) first."; \
	fi

check-enabled:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) $(ENV_FILE) not found. Please create it from $(ENV_EXAMPLE)"; \
		echo -e "  $(COLOR_CYAN)cp $(ENV_EXAMPLE) $(ENV_FILE)$(COLOR_RESET)"; \
		exit 1; \
	fi
	@ENABLED=$$(grep '^ENABLED=' $(ENV_FILE) | cut -d'=' -f2); \
	if [ "$$ENABLED" != "true" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) Node is disabled (ENABLED=$$ENABLED in $(ENV_FILE))"; \
		echo -e "Set ENABLED=true in $(ENV_FILE) to enable this node."; \
		exit 1; \
	fi
	@echo -e "$(COLOR_GREEN)✓ Node is enabled$(COLOR_RESET)"

init-volumes:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) $(ENV_FILE) not found. Please create it from $(ENV_EXAMPLE)"; \
		echo -e "  $(COLOR_CYAN)cp $(ENV_EXAMPLE) $(ENV_FILE)$(COLOR_RESET)"; \
		exit 1; \
	fi
	@echo -e "$(COLOR_BLUE)Reading volume paths from $(ENV_FILE)...$(COLOR_RESET)"
	@DATA_DIR=$$(grep '^X_VOLUME_NODE_DATA_DEVICE=' $(ENV_FILE) | cut -d'=' -f2); \
	LOGS_DIR=$$(grep '^X_VOLUME_NODE_LOGS_DEVICE=' $(ENV_FILE) | cut -d'=' -f2); \
	if [ -z "$$DATA_DIR" ] || [ -z "$$LOGS_DIR" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) Volume paths not found in $(ENV_FILE)"; \
		echo -e "Required variables: X_VOLUME_NODE_DATA_DEVICE, X_VOLUME_NODE_LOGS_DEVICE"; \
		exit 1; \
	fi; \
	echo -e "  $(COLOR_CYAN)Data directory:$(COLOR_RESET) $$DATA_DIR"; \
	echo -e "  $(COLOR_CYAN)Logs directory:$(COLOR_RESET) $$LOGS_DIR"; \
	echo -e ""; \
	if [ -d "$$DATA_DIR" ]; then \
		echo -e "$(COLOR_GREEN)✓$(COLOR_RESET) Data directory already exists: $$DATA_DIR"; \
	else \
		echo -e "$(COLOR_YELLOW)Creating data directory:$(COLOR_RESET) $$DATA_DIR"; \
		mkdir -p "$$DATA_DIR" && echo "$(COLOR_GREEN)✓ Created:$(COLOR_RESET) $$DATA_DIR" || exit 1; \
	fi; \
	if [ -d "$$LOGS_DIR" ]; then \
		echo -e "$(COLOR_GREEN)✓$(COLOR_RESET) Logs directory already exists: $$LOGS_DIR"; \
	else \
		echo -e "$(COLOR_YELLOW)Creating logs directory:$(COLOR_RESET) $$LOGS_DIR"; \
		mkdir -p "$$LOGS_DIR" && echo "$(COLOR_GREEN)✓ Created:$(COLOR_RESET) $$LOGS_DIR" || exit 1; \
	fi; \
	echo -e ""; \
	echo -e "$(COLOR_GREEN)$(COLOR_BOLD)✓ Volume directories ready!$(COLOR_RESET)"

up: check-enabled
	@echo -e "$(COLOR_GREEN)▶ Starting node...$(COLOR_RESET)"
	@docker compose up -d
	@echo -e "$(COLOR_GREEN)✓ Node started$(COLOR_RESET)"

down:
	@echo -e "$(COLOR_YELLOW)■ Stopping node...$(COLOR_RESET)"
	@docker compose down
	@echo -e "$(COLOR_YELLOW)✓ Node stopped$(COLOR_RESET)"

restart: check-enabled
	@echo -e "$(COLOR_YELLOW)⟳ Restarting node...$(COLOR_RESET)"
	@docker compose restart
	@echo -e "$(COLOR_GREEN)✓ Node restarted$(COLOR_RESET)"

logs:
	@echo -e "$(COLOR_CYAN)📋 Following logs (Ctrl+C to exit)...$(COLOR_RESET)"
	@echo ""
	@trap 'stty sane' EXIT INT TERM; docker compose logs -f

status:
	@echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)Node container status:$(COLOR_RESET)"
	@docker compose ps
	@echo ""
	@if docker compose ps | grep -q "Up"; then \
		echo -e "$(COLOR_CYAN)Fetching node info...$(COLOR_RESET)"; \
		CONTAINER=$$(docker compose ps -q); \
		HTTP_PORT=$$(grep '^X_PORT_HTTP_PUBLISHED=' $(ENV_FILE) | cut -d'=' -f2); \
		echo -e "$(COLOR_GREEN)HTTP API:$(COLOR_RESET) http://localhost:$$HTTP_PORT"; \
		echo -e ""; \
		curl -sX POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
			-H 'content-type:application/json;' \
			http://localhost:$$HTTP_PORT/ext/info 2>/dev/null | jq . || echo "$(COLOR_YELLOW)⚠ Node API not responding yet$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_RED)✗ Node is not running$(COLOR_RESET)"; \
	fi

health:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) $(ENV_FILE) not found"; \
		exit 1; \
	fi
	@HTTP_PORT=$$(grep '^X_PORT_HTTP_PUBLISHED=' $(ENV_FILE) | cut -d'=' -f2); \
	if [ -z "$$HTTP_PORT" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) X_PORT_HTTP_PUBLISHED not found in $(ENV_FILE)"; \
		exit 1; \
	fi; \
	echo -e "$(COLOR_BOLD)$(COLOR_GREEN)Checking node health:$(COLOR_RESET) http://localhost:$$HTTP_PORT/ext/health"; \
	echo -e ""; \
	curl -v http://localhost:$$HTTP_PORT/ext/health

backup-keys:
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)Backing up staking keys...$(COLOR_RESET)"
	@echo ""
	@CERTS_DIR="node/certs/staking"; \
	BACKUP_DIR="backups/$$(date +%Y%m%d-%H%M%S)"; \
	if [ ! -f "$$CERTS_DIR/staker.crt" ] || [ ! -f "$$CERTS_DIR/staker.key" ]; then \
		echo -e "$(COLOR_RED)✗ ERROR:$(COLOR_RESET) Staking certificates not found in $$CERTS_DIR"; \
		echo -e "  Run the node first to generate certificates, or copy existing ones."; \
		exit 1; \
	fi; \
	echo -e "$(COLOR_CYAN)Validating certificate...$(COLOR_RESET)"; \
	CERT_VALID=$$(openssl x509 -in "$$CERTS_DIR/staker.crt" -noout -checkend 0 2>/dev/null && echo "valid" || echo "invalid"); \
	if [ "$$CERT_VALID" = "invalid" ]; then \
		echo -e "  $(COLOR_YELLOW)⚠ Warning:$(COLOR_RESET) Certificate may be expired or invalid"; \
	else \
		CERT_SUBJECT=$$(openssl x509 -in "$$CERTS_DIR/staker.crt" -noout -subject 2>/dev/null | sed 's/subject=//'); \
		CERT_FINGERPRINT=$$(openssl x509 -in "$$CERTS_DIR/staker.crt" -noout -fingerprint -sha256 2>/dev/null | cut -d'=' -f2); \
		CERT_DATES=$$(openssl x509 -in "$$CERTS_DIR/staker.crt" -noout -dates 2>/dev/null); \
		echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) Certificate is valid"; \
		echo -e "  Subject: $$CERT_SUBJECT"; \
		echo -e "  SHA256: $$(echo $$CERT_FINGERPRINT | cut -c1-32)..."; \
	fi; \
	echo -e ""; \
	echo -e "$(COLOR_CYAN)Getting Node ID...$(COLOR_RESET)"; \
	if [ -f "$(ENV_FILE)" ]; then \
		HTTP_PORT=$$(grep '^X_PORT_HTTP_PUBLISHED=' $(ENV_FILE) | cut -d'=' -f2); \
		if docker compose ps 2>/dev/null | grep -q "Up"; then \
			NODE_ID=$$(curl -s -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
				-H 'content-type:application/json;' http://localhost:$$HTTP_PORT/ext/info 2>/dev/null | \
				jq -r '.result.nodeID // empty' 2>/dev/null); \
		fi; \
	fi; \
	if [ -z "$$NODE_ID" ]; then \
		if [ -f "node/node.env" ]; then \
			NODE_ID=$$(grep '^NODE_ID=' node/node.env 2>/dev/null | cut -d'=' -f2); \
		fi; \
	fi; \
	if [ -z "$$NODE_ID" ] || [ "$$NODE_ID" = "<NodeID-ABC....>" ]; then \
		echo -e "$(COLOR_YELLOW)⚠ Could not determine Node ID$(COLOR_RESET)"; \
		echo -e "  Using timestamp-only backup names"; \
		NODE_ID="unknown"; \
	else \
		echo -e "  $(COLOR_GREEN)Node ID:$(COLOR_RESET) $$NODE_ID"; \
	fi; \
	mkdir -p "$$BACKUP_DIR"; \
	echo -e ""; \
	echo -e "$(COLOR_CYAN)Backing up certificates to:$(COLOR_RESET) $$BACKUP_DIR"; \
	cp "$$CERTS_DIR/staker.crt" "$$BACKUP_DIR/$${NODE_ID}_staker.crt" && \
		echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) staker.crt -> $${NODE_ID}_staker.crt"; \
	cp "$$CERTS_DIR/staker.key" "$$BACKUP_DIR/$${NODE_ID}_staker.key" && \
		echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) staker.key -> $${NODE_ID}_staker.key"; \
	if [ -f "$$CERTS_DIR/signer.key" ]; then \
		cp "$$CERTS_DIR/signer.key" "$$BACKUP_DIR/$${NODE_ID}_signer.key" && \
			echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) signer.key -> $${NODE_ID}_signer.key"; \
	fi; \
	chmod 600 "$$BACKUP_DIR"/*_staker.key 2>/dev/null || true; \
	chmod 600 "$$BACKUP_DIR"/*_signer.key 2>/dev/null || true; \
	echo -e ""; \
	echo -e "$(COLOR_GREEN)$(COLOR_BOLD)✓ Backup complete!$(COLOR_RESET)"; \
	echo -e "  Location: $$BACKUP_DIR"; \
	echo -e "  Files: $$(ls -1 $$BACKUP_DIR | wc -l)"; \
	echo -e ""; \
	echo -e "$(COLOR_YELLOW)⚠ Keep this backup secure - it contains your node's private keys!$(COLOR_RESET)"

ps:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Running containers:$(COLOR_RESET)"
	@docker compose ps
