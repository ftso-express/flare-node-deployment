.PHONY: help up down restart logs status health ps init-volumes list check-all

# Color definitions
COLOR_RESET   := \033[0m
COLOR_BOLD    := \033[1m
COLOR_RED     := \033[31m
COLOR_GREEN   := \033[32m
COLOR_YELLOW  := \033[33m
COLOR_BLUE    := \033[34m
COLOR_MAGENTA := \033[35m
COLOR_CYAN    := \033[36m

# Auto-discover all node-* directories
NODE_DIRS := $(sort $(dir $(wildcard node-*/)))

help:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔═══════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║     Flare Observation Nodes - Orchestration Makefile         ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚═══════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make list$(COLOR_RESET)         - List all nodes and their enabled status"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make init-volumes$(COLOR_RESET) - Initialize volumes for all enabled nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_GREEN)make up$(COLOR_RESET)           - Start all enabled nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_YELLOW)make down$(COLOR_RESET)         - Stop all running nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_YELLOW)make restart$(COLOR_RESET)      - Restart all enabled nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)make logs$(COLOR_RESET)         - Follow logs from all running nodes (combined)"
	@echo -e "  $(COLOR_BOLD)$(COLOR_MAGENTA)make status$(COLOR_RESET)       - Show status of all nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_GREEN)make health$(COLOR_RESET)       - Check health of all running nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make ps$(COLOR_RESET)           - Show all running containers"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make check-all$(COLOR_RESET)    - Check configuration of all nodes"
	@echo ""
	@echo -e "$(COLOR_BOLD)Individual node commands:$(COLOR_RESET)"
	@echo -e "  cd node-001 && make <target>  - Execute command on specific node"
	@echo ""
	@echo -e "$(COLOR_BOLD)Discovered nodes:$(COLOR_RESET)"
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) $$node $(COLOR_GREEN)(enabled)$(COLOR_RESET)"; \
			else \
				echo -e "  $(COLOR_RED)✗$(COLOR_RESET) $$node $(COLOR_RED)(disabled)$(COLOR_RESET)"; \
			fi; \
		else \
			echo -e "  $(COLOR_YELLOW)⚠$(COLOR_RESET) $$node $(COLOR_YELLOW)(no .env file)$(COLOR_RESET)"; \
		fi; \
	done

list:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)Flare Observation Nodes:$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_BOLD)$$node:$(COLOR_RESET)"; \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			container=$$(grep '^X_DOCKER_COMPOSE_NAME=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			staking_port=$$(grep '^X_PORT_STAKING_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "  Status: $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
			else \
				echo -e "  Status: $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
			fi; \
			echo -e "  Container: $$container"; \
			echo -e "  HTTP Port: $$http_port"; \
			echo -e "  Staking Port: $$staking_port"; \
		else \
			echo -e "  Status: $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
		fi; \
		echo ""; \
	done

init-volumes:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Initializing volumes for enabled nodes...$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_CYAN)▶$(COLOR_RESET) $$node: Initializing volumes..."; \
				$(MAKE) -C $$dir init-volumes || echo -e "  $(COLOR_RED)✗ Failed$(COLOR_RESET)"; \
				echo ""; \
			fi; \
		fi; \
	done
	@echo -e "$(COLOR_GREEN)$(COLOR_BOLD)✓ Volume initialization complete$(COLOR_RESET)"

up:
	@echo -e "$(COLOR_BOLD)$(COLOR_GREEN)Starting enabled nodes...$(COLOR_RESET)"
	@echo ""
	@started=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_GREEN)▶$(COLOR_RESET) $$node: Starting..."; \
				$(MAKE) -C $$dir up && started=$$((started + 1)) || echo -e "  $(COLOR_RED)✗ Failed to start$(COLOR_RESET)"; \
				echo ""; \
			else \
				echo -e "$(COLOR_YELLOW)⊘$(COLOR_RESET) $$node: Skipped (disabled)"; \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)⊘$(COLOR_RESET) $$node: Skipped (no .env file)"; \
		fi; \
	done; \
	echo -e "$(COLOR_GREEN)$(COLOR_BOLD)✓ Started $$started node(s)$(COLOR_RESET)"

down:
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)Stopping all nodes...$(COLOR_RESET)"
	@echo ""
	@stopped=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_YELLOW)■$(COLOR_RESET) $$node: Stopping..."; \
		$(MAKE) -C $$dir down 2>/dev/null && stopped=$$((stopped + 1)) || echo -e "  $(COLOR_YELLOW)⚠ Not running or failed$(COLOR_RESET)"; \
		echo ""; \
	done; \
	echo -e "$(COLOR_YELLOW)$(COLOR_BOLD)✓ Stopped $$stopped node(s)$(COLOR_RESET)"

restart:
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)Restarting enabled nodes...$(COLOR_RESET)"
	@echo ""
	@restarted=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_YELLOW)⟳$(COLOR_RESET) $$node: Restarting..."; \
				$(MAKE) -C $$dir restart && restarted=$$((restarted + 1)) || echo -e "  $(COLOR_RED)✗ Failed to restart$(COLOR_RESET)"; \
				echo ""; \
			else \
				echo -e "$(COLOR_YELLOW)⊘$(COLOR_RESET) $$node: Skipped (disabled)"; \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)⊘$(COLOR_RESET) $$node: Skipped (no .env file)"; \
		fi; \
	done; \
	echo -e "$(COLOR_YELLOW)$(COLOR_BOLD)✓ Restarted $$restarted node(s)$(COLOR_RESET)"

logs:
	@echo -e "$(COLOR_CYAN)📋 Following logs from all running nodes (Ctrl+C to exit)...$(COLOR_RESET)"
	@echo -e "$(COLOR_YELLOW)Note: Logs will be combined from all containers$(COLOR_RESET)"
	@echo ""
	@compose_dirs=""; \
	for dir in $(NODE_DIRS); do \
		if docker compose -f $$dir/compose.yaml ps 2>/dev/null | grep -q "Up"; then \
			compose_dirs="$$compose_dirs -f $$dir/compose.yaml"; \
		fi; \
	done; \
	if [ -n "$$compose_dirs" ]; then \
		trap 'stty sane' EXIT INT TERM; \
		docker compose $$compose_dirs logs -f; \
	else \
		echo -e "$(COLOR_YELLOW)⚠ No running nodes found$(COLOR_RESET)"; \
	fi

status:
	@echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)Status of all nodes:$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "  Config: $(COLOR_GREEN)Enabled$(COLOR_RESET)"; \
			else \
				echo -e "  Config: $(COLOR_RED)Disabled$(COLOR_RESET)"; \
			fi; \
			if docker compose -f $$dir/compose.yaml ps 2>/dev/null | grep -q "Up"; then \
				echo -e "  Runtime: $(COLOR_GREEN)Running$(COLOR_RESET)"; \
				http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
				echo -e "  API: $(COLOR_CYAN)http://localhost:$$http_port$(COLOR_RESET)"; \
			else \
				echo -e "  Runtime: $(COLOR_YELLOW)Stopped$(COLOR_RESET)"; \
			fi; \
		else \
			echo -e "  Config: $(COLOR_YELLOW)No .env file$(COLOR_RESET)"; \
		fi; \
		echo ""; \
	done

health:
	@echo -e "$(COLOR_BOLD)$(COLOR_GREEN)Checking health of all running nodes:$(COLOR_RESET)"
	@echo ""
	@checked=0; \
	healthy=0; \
	unhealthy=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ] && docker compose -f $$dir/compose.yaml ps 2>/dev/null | grep -q "Up"; then \
			http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node$(COLOR_RESET) (http://localhost:$$http_port/ext/health):"; \
			response=$$(curl -s http://localhost:$$http_port/ext/health 2>/dev/null); \
			if echo "$$response" | jq -e '.healthy == true' > /dev/null 2>&1; then \
				echo -e "  $(COLOR_GREEN)✓ HEALTHY$(COLOR_RESET)"; \
				healthy=$$((healthy + 1)); \
				echo "$$response" | jq -r '.checks | to_entries[] | "    \(.key): \(.value.message.engine.consensus.lastAcceptedHeight // "N/A") blocks"' 2>/dev/null || true; \
			else \
				echo -e "  $(COLOR_RED)✗ UNHEALTHY or not responding$(COLOR_RESET)"; \
				unhealthy=$$((unhealthy + 1)); \
			fi; \
			checked=$$((checked + 1)); \
			echo ""; \
		fi; \
	done; \
	if [ $$checked -eq 0 ]; then \
		echo -e "$(COLOR_YELLOW)⚠ No running nodes found$(COLOR_RESET)"; \
	else \
		echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
		echo -e "  $(COLOR_GREEN)Healthy: $$healthy$(COLOR_RESET)"; \
		echo -e "  $(COLOR_RED)Unhealthy: $$unhealthy$(COLOR_RESET)"; \
		echo -e "  Total checked: $$checked"; \
	fi

ps:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)All node containers:$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if docker compose -f $$dir/compose.yaml ps 2>/dev/null | tail -n +2 | grep -q .; then \
			echo -e "$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
			docker compose -f $$dir/compose.yaml ps; \
			echo ""; \
		fi; \
	done

check-all:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Checking configuration of all nodes...$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
		\
		if [ ! -f "$$dir/.env" ]; then \
			echo -e "  $(COLOR_RED)✗ Missing .env file$(COLOR_RESET)"; \
		else \
			echo -e "  $(COLOR_GREEN)✓ .env file exists$(COLOR_RESET)"; \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "    ENABLED: $(COLOR_GREEN)true$(COLOR_RESET)"; \
			else \
				echo -e "    ENABLED: $(COLOR_RED)$$enabled$(COLOR_RESET)"; \
			fi; \
		fi; \
		\
		if [ ! -f "$$dir/node/node.env" ]; then \
			echo -e "  $(COLOR_RED)✗ Missing node/node.env file$(COLOR_RESET)"; \
		else \
			echo -e "  $(COLOR_GREEN)✓ node.env file exists$(COLOR_RESET)"; \
			node_id=$$(grep '^NODE_ID=' "$$dir/node/node.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$node_id" = "<NodeID-ABC....>" ] || [ -z "$$node_id" ]; then \
				echo -e "    $(COLOR_YELLOW)⚠ NODE_ID not configured$(COLOR_RESET)"; \
			else \
				echo -e "    $(COLOR_GREEN)✓ NODE_ID: $$node_id$(COLOR_RESET)"; \
			fi; \
		fi; \
		\
		if [ ! -f "$$dir/node/certs/staking/staker.crt" ] || [ ! -f "$$dir/node/certs/staking/staker.key" ]; then \
			echo -e "  $(COLOR_YELLOW)⚠ Missing staking certificates$(COLOR_RESET)"; \
		else \
			echo -e "  $(COLOR_GREEN)✓ Staking certificates present$(COLOR_RESET)"; \
		fi; \
		\
		if [ -f "$$dir/.env" ]; then \
			data_vol=$$(grep '^X_VOLUME_NODE_DATA_DEVICE=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			logs_vol=$$(grep '^X_VOLUME_NODE_LOGS_DEVICE=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ -d "$$data_vol" ] && [ -d "$$logs_vol" ]; then \
				echo -e "  $(COLOR_GREEN)✓ Volume directories exist$(COLOR_RESET)"; \
			else \
				echo -e "  $(COLOR_YELLOW)⚠ Volume directories missing (run: make init-volumes)$(COLOR_RESET)"; \
			fi; \
		fi; \
		\
		echo ""; \
	done
