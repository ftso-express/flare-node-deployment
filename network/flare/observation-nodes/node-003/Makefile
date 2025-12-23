.PHONY: help up down restart logs status ps check-enabled

ENV_FILE := .env
ENV_EXAMPLE := .env.example

help:
	@echo "Flare Observation Node - Make targets:"
	@echo "  make up       - Start the node (if ENABLED=true)"
	@echo "  make down     - Stop the node"
	@echo "  make restart  - Restart the node (if ENABLED=true)"
	@echo "  make logs     - Follow node logs"
	@echo "  make status   - Show node status"
	@echo "  make ps       - Show running containers"
	@echo ""
	@echo "Current status:"
	@if [ -f "$(ENV_FILE)" ]; then \
		ENABLED=$$(grep '^ENABLED=' $(ENV_FILE) | cut -d'=' -f2); \
		if [ "$$ENABLED" = "true" ]; then \
			echo "  ENABLED: ✓ true (node will start)"; \
		else \
			echo "  ENABLED: ✗ $$ENABLED (node will NOT start)"; \
		fi; \
	else \
		echo "  WARNING: $(ENV_FILE) not found. Copy from $(ENV_EXAMPLE) first."; \
	fi

check-enabled:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "ERROR: $(ENV_FILE) not found. Please create it from $(ENV_EXAMPLE)"; \
		echo "  cp $(ENV_EXAMPLE) $(ENV_FILE)"; \
		exit 1; \
	fi
	@ENABLED=$$(grep '^ENABLED=' $(ENV_FILE) | cut -d'=' -f2); \
	if [ "$$ENABLED" != "true" ]; then \
		echo "ERROR: Node is disabled (ENABLED=$$ENABLED in $(ENV_FILE))"; \
		echo "Set ENABLED=true in $(ENV_FILE) to enable this node."; \
		exit 1; \
	fi
	@echo "✓ Node is enabled"

up: check-enabled
	@echo "Starting node..."
	docker compose up -d

down:
	@echo "Stopping node..."
	docker compose down

restart: check-enabled
	@echo "Restarting node..."
	docker compose restart

logs:
	docker compose logs -f

status:
	@echo "Node container status:"
	@docker compose ps
	@echo ""
	@if docker compose ps | grep -q "Up"; then \
		echo "Fetching node info..."; \
		CONTAINER=$$(docker compose ps -q); \
		HTTP_PORT=$$(grep '^X_PORT_HTTP_PUBLISHED=' $(ENV_FILE) | cut -d'=' -f2); \
		echo "HTTP API: http://localhost:$$HTTP_PORT"; \
		echo ""; \
		curl -sX POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
			-H 'content-type:application/json;' \
			http://localhost:$$HTTP_PORT/ext/info 2>/dev/null | jq . || echo "Node API not responding yet"; \
	fi

ps:
	docker compose ps
