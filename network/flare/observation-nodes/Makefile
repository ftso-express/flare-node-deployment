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
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║     Flare Observation Nodes - Orchestration Makefile          ║$(COLOR_RESET)"
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
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║          Flare Observation Nodes - Configuration          ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			container=$$(grep '^X_DOCKER_COMPOSE_NAME=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			staking_port=$$(grep '^X_PORT_STAKING_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "  $(COLOR_GREEN)Status:$(COLOR_RESET)       $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
			else \
				echo -e "  $(COLOR_RED)Status:$(COLOR_RESET)       $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
			fi; \
			echo -e "  $(COLOR_CYAN)Container:$(COLOR_RESET)    $$container"; \
			echo -e "  $(COLOR_CYAN)HTTP Port:$(COLOR_RESET)    $$http_port"; \
			echo -e "  $(COLOR_CYAN)Staking Port:$(COLOR_RESET) $$staking_port"; \
		else \
			echo -e "  $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
		fi; \
		echo ""; \
	done

init-volumes:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║        Initializing Volumes for Enabled Nodes             ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@count=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
				$(MAKE) -C $$dir init-volumes && count=$$((count + 1)) || echo -e "  $(COLOR_RED)✗ Failed$(COLOR_RESET)"; \
				echo ""; \
			fi; \
		fi; \
	done; \
	echo -e "$(COLOR_GREEN)$(COLOR_BOLD)✓ Volume initialization complete for $$count node(s)$(COLOR_RESET)"

up:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║              Starting All Enabled Nodes                   ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@started=0; \
	skipped=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
				echo -e "  $(COLOR_GREEN)▶ Starting node...$(COLOR_RESET)"; \
				$(MAKE) -C $$dir up && { echo -e "  $(COLOR_GREEN)✓ Node started$(COLOR_RESET)"; started=$$((started + 1)); } || echo -e "  $(COLOR_RED)✗ Failed to start$(COLOR_RESET)"; \
				echo ""; \
			else \
				echo -e "$(COLOR_YELLOW)⊘ $$node: Skipped (disabled)$(COLOR_RESET)"; \
				skipped=$$((skipped + 1)); \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)⊘ $$node: Skipped (no .env file)$(COLOR_RESET)"; \
			skipped=$$((skipped + 1)); \
		fi; \
	done; \
	echo ""; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	echo -e "  $(COLOR_GREEN)Started:$(COLOR_RESET)  $$started"; \
	echo -e "  $(COLOR_YELLOW)Skipped:$(COLOR_RESET)  $$skipped"

down:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║                Stopping All Nodes                          ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@stopped=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
		echo -e "  $(COLOR_YELLOW)■ Stopping node...$(COLOR_RESET)"; \
		$(MAKE) -C $$dir down 2>/dev/null && { echo -e "  $(COLOR_YELLOW)✓ Node stopped$(COLOR_RESET)"; stopped=$$((stopped + 1)); } || echo -e "  $(COLOR_YELLOW)⚠ Not running or failed$(COLOR_RESET)"; \
		echo ""; \
	done; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	echo -e "  $(COLOR_YELLOW)Stopped:$(COLOR_RESET) $$stopped node(s)"

restart:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║            Restarting All Enabled Nodes                   ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@restarted=0; \
	skipped=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
				echo -e "  $(COLOR_YELLOW)⟳ Restarting node...$(COLOR_RESET)"; \
				$(MAKE) -C $$dir restart && { echo -e "  $(COLOR_GREEN)✓ Node restarted$(COLOR_RESET)"; restarted=$$((restarted + 1)); } || echo -e "  $(COLOR_RED)✗ Failed to restart$(COLOR_RESET)"; \
				echo ""; \
			else \
				echo -e "$(COLOR_YELLOW)⊘ $$node: Skipped (disabled)$(COLOR_RESET)"; \
				skipped=$$((skipped + 1)); \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)⊘ $$node: Skipped (no .env file)$(COLOR_RESET)"; \
			skipped=$$((skipped + 1)); \
		fi; \
	done; \
	echo ""; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	echo -e "  $(COLOR_GREEN)Restarted:$(COLOR_RESET) $$restarted"; \
	echo -e "  $(COLOR_YELLOW)Skipped:$(COLOR_RESET)   $$skipped"

logs:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║              Following Logs (Ctrl+C to exit)              ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
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
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║                 Node Status Overview                      ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
		if [ -f "$$dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			network_name=$$(grep '^X_LABELS_NETWORK_NAME=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			network_type=$$(grep '^X_LABELS_NETWORK_TYPE=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			node_role=$$(grep '^X_LABELS_NODE_ROLE=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			subsystem=$$(grep '^X_LABELS_SUB_SYSTEM_NAME=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			\
			if [ -n "$$network_name" ]; then \
				echo -e "  $(COLOR_MAGENTA)Network:$(COLOR_RESET)  $$network_name ($$network_type)"; \
			fi; \
			if [ -n "$$node_role" ]; then \
				role_display=$$(echo $$node_role | sed 's/_/ /g'); \
				echo -e "  $(COLOR_MAGENTA)Role:$(COLOR_RESET)     $$role_display"; \
			fi; \
			if [ -n "$$subsystem" ]; then \
				echo -e "  $(COLOR_MAGENTA)System:$(COLOR_RESET)   $$subsystem"; \
			fi; \
			\
			if [ "$$enabled" = "true" ]; then \
				echo -e "  $(COLOR_GREEN)Config:$(COLOR_RESET)   $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
			else \
				echo -e "  $(COLOR_RED)Config:$(COLOR_RESET)   $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
			fi; \
			if docker compose -f $$dir/compose.yaml ps 2>/dev/null | grep -q "Up"; then \
				echo -e "  $(COLOR_GREEN)Runtime:$(COLOR_RESET)  $(COLOR_GREEN)● Running$(COLOR_RESET)"; \
				if [ -n "$$http_port" ]; then \
					echo -e "  $(COLOR_CYAN)API:$(COLOR_RESET)      http://localhost:$$http_port"; \
				fi; \
			else \
				echo -e "  $(COLOR_YELLOW)Runtime:$(COLOR_RESET)  $(COLOR_YELLOW)○ Stopped$(COLOR_RESET)"; \
			fi; \
		else \
			echo -e "  $(COLOR_YELLOW)Config:$(COLOR_RESET)   $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
		fi; \
		echo ""; \
	done

health:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║               Node Health Check                           ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@checked=0; \
	healthy=0; \
	unhealthy=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if [ -f "$$dir/.env" ] && docker compose -f $$dir/compose.yaml ps 2>/dev/null | grep -q "Up"; then \
			http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
			echo -e "  $(COLOR_CYAN)Endpoint:$(COLOR_RESET) http://localhost:$$http_port/ext/health"; \
			response=$$(curl -s http://localhost:$$http_port/ext/health 2>/dev/null); \
			if echo "$$response" | jq -e '.healthy == true' > /dev/null 2>&1; then \
				echo -e "  $(COLOR_GREEN)Status:$(COLOR_RESET)   $(COLOR_GREEN)✓ HEALTHY$(COLOR_RESET)"; \
				healthy=$$((healthy + 1)); \
				echo "$$response" | jq -r '.checks | to_entries[] | "    \(.key): \(.value.message.engine.consensus.lastAcceptedHeight // "N/A") blocks"' 2>/dev/null || true; \
			else \
				echo -e "  $(COLOR_RED)Status:$(COLOR_RESET)   $(COLOR_RED)✗ UNHEALTHY or not responding$(COLOR_RESET)"; \
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
		echo -e "  $(COLOR_GREEN)Healthy:$(COLOR_RESET)   $$healthy"; \
		echo -e "  $(COLOR_RED)Unhealthy:$(COLOR_RESET) $$unhealthy"; \
		echo -e "  $(COLOR_CYAN)Total:$(COLOR_RESET)     $$checked"; \
	fi

ps:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║              Running Node Containers                      ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@found=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		if docker compose -f $$dir/compose.yaml ps 2>/dev/null | tail -n +2 | grep -q .; then \
			echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
			docker compose -f $$dir/compose.yaml ps; \
			echo ""; \
			found=$$((found + 1)); \
		fi; \
	done; \
	if [ $$found -eq 0 ]; then \
		echo -e "$(COLOR_YELLOW)⚠ No running containers found$(COLOR_RESET)"; \
	fi

check-all:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║         Configuration Check for All Nodes                 ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@total_issues=0; \
	for dir in $(NODE_DIRS); do \
		node=$$(basename $$dir); \
		node_issues=0; \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node:$(COLOR_RESET)"; \
		\
		if [ ! -f "$$dir/.env" ]; then \
			echo -e "  $(COLOR_RED)✗ Missing .env file$(COLOR_RESET)"; \
			node_issues=$$((node_issues + 1)); \
		else \
			echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) .env file exists"; \
			enabled=$$(grep '^ENABLED=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "    $(COLOR_CYAN)ENABLED:$(COLOR_RESET) $(COLOR_GREEN)true$(COLOR_RESET)"; \
			else \
				echo -e "    $(COLOR_CYAN)ENABLED:$(COLOR_RESET) $(COLOR_RED)$$enabled$(COLOR_RESET)"; \
			fi; \
		fi; \
		\
		if [ ! -f "$$dir/node/node.env" ]; then \
			echo -e "  $(COLOR_RED)✗ Missing node/node.env file$(COLOR_RESET)"; \
			node_issues=$$((node_issues + 1)); \
		else \
			echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) node.env file exists"; \
			node_id=$$(grep '^NODE_ID=' "$$dir/node/node.env" 2>/dev/null | cut -d'=' -f2); \
			if [ "$$node_id" = "<NodeID-ABC....>" ] || [ -z "$$node_id" ]; then \
				echo -e "    $(COLOR_YELLOW)⚠ NODE_ID not configured$(COLOR_RESET)"; \
				node_issues=$$((node_issues + 1)); \
			else \
				echo -e "    $(COLOR_CYAN)NODE_ID:$(COLOR_RESET) $(COLOR_GREEN)$$node_id$(COLOR_RESET)"; \
			fi; \
		fi; \
		\
		if [ ! -f "$$dir/node/certs/staking/staker.crt" ] || [ ! -f "$$dir/node/certs/staking/staker.key" ]; then \
			echo -e "  $(COLOR_YELLOW)⚠ Missing staking certificates$(COLOR_RESET)"; \
			node_issues=$$((node_issues + 1)); \
		else \
			echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) Staking certificates present"; \
		fi; \
		\
		if [ -f "$$dir/.env" ]; then \
			data_vol=$$(grep '^X_VOLUME_NODE_DATA_DEVICE=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			logs_vol=$$(grep '^X_VOLUME_NODE_LOGS_DEVICE=' "$$dir/.env" 2>/dev/null | cut -d'=' -f2); \
			if [ -d "$$data_vol" ] && [ -d "$$logs_vol" ]; then \
				echo -e "  $(COLOR_GREEN)✓$(COLOR_RESET) Volume directories exist"; \
				echo -e "    $(COLOR_CYAN)Data:$(COLOR_RESET) $$data_vol"; \
				echo -e "    $(COLOR_CYAN)Logs:$(COLOR_RESET) $$logs_vol"; \
			else \
				echo -e "  $(COLOR_YELLOW)⚠ Volume directories missing$(COLOR_RESET)"; \
				echo -e "    $(COLOR_CYAN)Hint:$(COLOR_RESET) Run $(COLOR_BOLD)make init-volumes$(COLOR_RESET)"; \
				node_issues=$$((node_issues + 1)); \
			fi; \
		fi; \
		\
		if [ $$node_issues -gt 0 ]; then \
			total_issues=$$((total_issues + node_issues)); \
			echo -e "  $(COLOR_YELLOW)Issues found:$(COLOR_RESET) $$node_issues"; \
		fi; \
		echo ""; \
	done; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	if [ $$total_issues -eq 0 ]; then \
		echo -e "  $(COLOR_GREEN)✓ All nodes configured correctly!$(COLOR_RESET)"; \
	else \
		echo -e "  $(COLOR_YELLOW)Total issues found:$(COLOR_RESET) $$total_issues"; \
		echo -e "  $(COLOR_CYAN)Tip:$(COLOR_RESET) Review warnings above and fix before starting nodes"; \
	fi
