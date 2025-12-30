.PHONY: help docs nodes status clean pull-images

# Color definitions
COLOR_RESET   := \033[0m
COLOR_BOLD    := \033[1m
COLOR_RED     := \033[31m
COLOR_GREEN   := \033[32m
COLOR_YELLOW  := \033[33m
COLOR_BLUE    := \033[34m
COLOR_MAGENTA := \033[35m
COLOR_CYAN    := \033[36m

# Auto-discover all networks and node directories
NETWORKS := $(sort $(notdir $(wildcard network/*)))
FLARE_OBS_NODES := $(sort $(wildcard network/flare/observation-nodes/node-*))
FLARE_VAL_NODES := $(sort $(wildcard network/flare/validation-nodes/node-*))
SONGBIRD_OBS_NODES := $(sort $(wildcard network/songbird/observation-nodes/node-*))
COSTON_OBS_NODES := $(sort $(wildcard network/coston/observation-nodes/node-*))
COSTWO_OBS_NODES := $(sort $(wildcard network/costwo/observation-nodes/node-*))
# Combined list of all nodes (for compatibility with existing targets)
NODE_DIRS := $(FLARE_OBS_NODES) $(FLARE_VAL_NODES) $(SONGBIRD_OBS_NODES) $(COSTON_OBS_NODES) $(COSTWO_OBS_NODES)

# Default target
.DEFAULT_GOAL := help

help:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║         Flare Node Deployment - Top Level Makefile         ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Orchestration (Recommended):$(COLOR_RESET)"
	@echo -e "  $(COLOR_CYAN)cd network/flare/observation-nodes && make help$(COLOR_RESET)"
	@echo -e "  Use the orchestration Makefile for better node management"
	@echo ""
	@echo -e "$(COLOR_BOLD)Documentation:$(COLOR_RESET)"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make docs-help$(COLOR_RESET)      - Show documentation build commands"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make docs-pdf$(COLOR_RESET)       - Generate PDF documentation"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make docs-html$(COLOR_RESET)      - Generate HTML documentation"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make docs-all$(COLOR_RESET)       - Generate all documentation formats"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make docs-clean$(COLOR_RESET)     - Clean documentation output"
	@echo ""
	@echo -e "$(COLOR_BOLD)Node Management:$(COLOR_RESET)"
	@echo -e "  $(COLOR_BOLD)$(COLOR_MAGENTA)make nodes-status$(COLOR_RESET)   - Show status of all nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_GREEN)make nodes-start$(COLOR_RESET)    - Start all enabled nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_YELLOW)make nodes-stop$(COLOR_RESET)     - Stop all nodes"
	@echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)make nodes-logs$(COLOR_RESET)     - Show logs from all running nodes"
	@echo ""
	@echo -e "$(COLOR_BOLD)Node-Specific (replace XXX with node number):$(COLOR_RESET)"
	@echo -e "  $(COLOR_CYAN)make node-XXX-help$(COLOR_RESET)   - Show help for specific node"
	@echo -e "  $(COLOR_CYAN)make node-XXX-up$(COLOR_RESET)     - Start specific node"
	@echo -e "  $(COLOR_CYAN)make node-XXX-down$(COLOR_RESET)   - Stop specific node"
	@echo -e "  $(COLOR_CYAN)make node-XXX-logs$(COLOR_RESET)   - View logs for specific node"
	@echo -e "  $(COLOR_CYAN)make node-XXX-status$(COLOR_RESET) - Show status for specific node"
	@echo ""
	@echo -e "$(COLOR_BOLD)Maintenance:$(COLOR_RESET)"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make pull-images$(COLOR_RESET)    - Pull latest Docker images"
	@echo -e "  $(COLOR_BOLD)$(COLOR_BLUE)make clean$(COLOR_RESET)          - Clean all generated files"
	@echo ""
	@echo -e "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo -e "  $(COLOR_CYAN)make node-001-up$(COLOR_RESET)     - Start node-001"
	@echo -e "  $(COLOR_CYAN)make node-004-status$(COLOR_RESET) - Check node-004 status"
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

# Documentation targets
docs-help:
	@$(MAKE) -C docs help

docs-pdf:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Generating PDF documentation...$(COLOR_RESET)"
	@$(MAKE) -C docs pdf && echo -e "$(COLOR_GREEN)✓ PDF documentation generated$(COLOR_RESET)" || echo -e "$(COLOR_RED)✗ Failed to generate PDF$(COLOR_RESET)"

docs-html:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Generating HTML documentation...$(COLOR_RESET)"
	@$(MAKE) -C docs html && echo -e "$(COLOR_GREEN)✓ HTML documentation generated$(COLOR_RESET)" || echo -e "$(COLOR_RED)✗ Failed to generate HTML$(COLOR_RESET)"

docs-all:
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Generating all documentation...$(COLOR_RESET)"
	@$(MAKE) -C docs all && echo -e "$(COLOR_GREEN)✓ All documentation generated$(COLOR_RESET)" || echo -e "$(COLOR_RED)✗ Failed to generate documentation$(COLOR_RESET)"

docs-clean:
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)Cleaning documentation output...$(COLOR_RESET)"
	@$(MAKE) -C docs clean && echo -e "$(COLOR_YELLOW)✓ Documentation cleaned$(COLOR_RESET)"

# Node status - show all nodes grouped by network
nodes-status:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║            Multi-Network Node Status Overview              ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@total_nodes=0; \
	total_running=0; \
	total_enabled=0; \
	flare_running=0; \
	flare_total=0; \
	songbird_running=0; \
	songbird_total=0; \
	coston_running=0; \
	coston_total=0; \
	costwo_running=0; \
	costwo_total=0; \
	\
	if [ -n "$(FLARE_OBS_NODES)$(FLARE_VAL_NODES)" ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)━━━ FLARE MAINNET ━━━$(COLOR_RESET)"; \
		echo ""; \
		for node_dir in $(FLARE_OBS_NODES) $(FLARE_VAL_NODES); do \
			node_name=$$(basename $$node_dir); \
			node_type=$$(echo $$node_dir | grep -q "validation-nodes" && echo "validation" || echo "observation"); \
			flare_total=$$((flare_total + 1)); \
			total_nodes=$$((total_nodes + 1)); \
			echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)$$node_name$(COLOR_RESET) $(COLOR_YELLOW)[$$node_type]$(COLOR_RESET)"; \
			if [ -f "$$node_dir/.env" ]; then \
				enabled=$$(grep '^ENABLED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				if [ "$$enabled" = "true" ]; then \
					total_enabled=$$((total_enabled + 1)); \
					echo -e "    $(COLOR_GREEN)Config:$(COLOR_RESET)   $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
				else \
					echo -e "    $(COLOR_RED)Config:$(COLOR_RESET)   $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
				fi; \
				if cd $$node_dir && docker compose ps 2>/dev/null | grep -q "Up"; then \
					echo -e "    $(COLOR_GREEN)Runtime:$(COLOR_RESET)  $(COLOR_GREEN)● Running$(COLOR_RESET)"; \
					flare_running=$$((flare_running + 1)); \
					total_running=$$((total_running + 1)); \
					if [ -n "$$http_port" ]; then \
						echo -e "    $(COLOR_CYAN)API:$(COLOR_RESET)      http://localhost:$$http_port"; \
					fi; \
				else \
					echo -e "    $(COLOR_YELLOW)Runtime:$(COLOR_RESET)  $(COLOR_YELLOW)○ Stopped$(COLOR_RESET)"; \
				fi; \
				cd - > /dev/null 2>&1; \
			else \
				echo -e "    $(COLOR_YELLOW)Config:$(COLOR_RESET)   $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
			fi; \
			echo ""; \
		done; \
	fi; \
	\
	if [ -n "$(SONGBIRD_OBS_NODES)" ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)━━━ SONGBIRD CANARY NETWORK ━━━$(COLOR_RESET)"; \
		echo ""; \
		for node_dir in $(SONGBIRD_OBS_NODES); do \
			node_name=$$(basename $$node_dir); \
			songbird_total=$$((songbird_total + 1)); \
			total_nodes=$$((total_nodes + 1)); \
			echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)$$node_name$(COLOR_RESET) $(COLOR_YELLOW)[observation]$(COLOR_RESET)"; \
			if [ -f "$$node_dir/.env" ]; then \
				enabled=$$(grep '^ENABLED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				if [ "$$enabled" = "true" ]; then \
					total_enabled=$$((total_enabled + 1)); \
					echo -e "    $(COLOR_GREEN)Config:$(COLOR_RESET)   $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
				else \
					echo -e "    $(COLOR_RED)Config:$(COLOR_RESET)   $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
				fi; \
				if cd $$node_dir && docker compose ps 2>/dev/null | grep -q "Up"; then \
					echo -e "    $(COLOR_GREEN)Runtime:$(COLOR_RESET)  $(COLOR_GREEN)● Running$(COLOR_RESET)"; \
					songbird_running=$$((songbird_running + 1)); \
					total_running=$$((total_running + 1)); \
					if [ -n "$$http_port" ]; then \
						echo -e "    $(COLOR_CYAN)API:$(COLOR_RESET)      http://localhost:$$http_port"; \
					fi; \
				else \
					echo -e "    $(COLOR_YELLOW)Runtime:$(COLOR_RESET)  $(COLOR_YELLOW)○ Stopped$(COLOR_RESET)"; \
				fi; \
				cd - > /dev/null 2>&1; \
			else \
				echo -e "    $(COLOR_YELLOW)Config:$(COLOR_RESET)   $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
			fi; \
			echo ""; \
		done; \
	fi; \
	\
	if [ -n "$(COSTON_OBS_NODES)" ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)━━━ COSTON TESTNET ━━━$(COLOR_RESET)"; \
		echo ""; \
		for node_dir in $(COSTON_OBS_NODES); do \
			node_name=$$(basename $$node_dir); \
			coston_total=$$((coston_total + 1)); \
			total_nodes=$$((total_nodes + 1)); \
			echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)$$node_name$(COLOR_RESET) $(COLOR_YELLOW)[observation]$(COLOR_RESET)"; \
			if [ -f "$$node_dir/.env" ]; then \
				enabled=$$(grep '^ENABLED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				if [ "$$enabled" = "true" ]; then \
					total_enabled=$$((total_enabled + 1)); \
					echo -e "    $(COLOR_GREEN)Config:$(COLOR_RESET)   $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
				else \
					echo -e "    $(COLOR_RED)Config:$(COLOR_RESET)   $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
				fi; \
				if cd $$node_dir && docker compose ps 2>/dev/null | grep -q "Up"; then \
					echo -e "    $(COLOR_GREEN)Runtime:$(COLOR_RESET)  $(COLOR_GREEN)● Running$(COLOR_RESET)"; \
					coston_running=$$((coston_running + 1)); \
					total_running=$$((total_running + 1)); \
					if [ -n "$$http_port" ]; then \
						echo -e "    $(COLOR_CYAN)API:$(COLOR_RESET)      http://localhost:$$http_port"; \
					fi; \
				else \
					echo -e "    $(COLOR_YELLOW)Runtime:$(COLOR_RESET)  $(COLOR_YELLOW)○ Stopped$(COLOR_RESET)"; \
				fi; \
				cd - > /dev/null 2>&1; \
			else \
				echo -e "    $(COLOR_YELLOW)Config:$(COLOR_RESET)   $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
			fi; \
			echo ""; \
		done; \
	fi; \
	\
	if [ -n "$(COSTWO_OBS_NODES)" ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)━━━ COSTWO TESTNET ━━━$(COLOR_RESET)"; \
		echo ""; \
		for node_dir in $(COSTWO_OBS_NODES); do \
			node_name=$$(basename $$node_dir); \
			costwo_total=$$((costwo_total + 1)); \
			total_nodes=$$((total_nodes + 1)); \
			echo -e "  $(COLOR_BOLD)$(COLOR_CYAN)$$node_name$(COLOR_RESET) $(COLOR_YELLOW)[observation]$(COLOR_RESET)"; \
			if [ -f "$$node_dir/.env" ]; then \
				enabled=$$(grep '^ENABLED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				http_port=$$(grep '^X_PORT_HTTP_PUBLISHED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
				if [ "$$enabled" = "true" ]; then \
					total_enabled=$$((total_enabled + 1)); \
					echo -e "    $(COLOR_GREEN)Config:$(COLOR_RESET)   $(COLOR_GREEN)✓ Enabled$(COLOR_RESET)"; \
				else \
					echo -e "    $(COLOR_RED)Config:$(COLOR_RESET)   $(COLOR_RED)✗ Disabled$(COLOR_RESET)"; \
				fi; \
				if cd $$node_dir && docker compose ps 2>/dev/null | grep -q "Up"; then \
					echo -e "    $(COLOR_GREEN)Runtime:$(COLOR_RESET)  $(COLOR_GREEN)● Running$(COLOR_RESET)"; \
					costwo_running=$$((costwo_running + 1)); \
					total_running=$$((total_running + 1)); \
					if [ -n "$$http_port" ]; then \
						echo -e "    $(COLOR_CYAN)API:$(COLOR_RESET)      http://localhost:$$http_port"; \
					fi; \
				else \
					echo -e "    $(COLOR_YELLOW)Runtime:$(COLOR_RESET)  $(COLOR_YELLOW)○ Stopped$(COLOR_RESET)"; \
				fi; \
				cd - > /dev/null 2>&1; \
			else \
				echo -e "    $(COLOR_YELLOW)Config:$(COLOR_RESET)   $(COLOR_YELLOW)⚠ No .env file$(COLOR_RESET)"; \
			fi; \
			echo ""; \
		done; \
	fi; \
	\
	echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"; \
	echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║                      Summary                               ║$(COLOR_RESET)"; \
	echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"; \
	echo ""; \
	if [ $$flare_total -gt 0 ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)Flare Mainnet:$(COLOR_RESET)"; \
		echo -e "  Running:  $(COLOR_GREEN)$$flare_running$(COLOR_RESET) / $$flare_total nodes"; \
	fi; \
	if [ $$songbird_total -gt 0 ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)Songbird Canary:$(COLOR_RESET)"; \
		echo -e "  Running:  $(COLOR_GREEN)$$songbird_running$(COLOR_RESET) / $$songbird_total nodes"; \
	fi; \
	if [ $$coston_total -gt 0 ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)Coston Testnet:$(COLOR_RESET)"; \
		echo -e "  Running:  $(COLOR_GREEN)$$coston_running$(COLOR_RESET) / $$coston_total nodes"; \
	fi; \
	if [ $$costwo_total -gt 0 ]; then \
		echo -e "$(COLOR_BOLD)$(COLOR_MAGENTA)Costwo Testnet:$(COLOR_RESET)"; \
		echo -e "  Running:  $(COLOR_GREEN)$$costwo_running$(COLOR_RESET) / $$costwo_total nodes"; \
	fi; \
	echo ""; \
	echo -e "$(COLOR_BOLD)Overall:$(COLOR_RESET)"; \
	echo -e "  Total nodes:     $$total_nodes"; \
	echo -e "  Enabled nodes:   $(COLOR_GREEN)$$total_enabled$(COLOR_RESET)"; \
	echo -e "  Running nodes:   $(COLOR_GREEN)$$total_running$(COLOR_RESET)"; \
	stopped=$$((total_nodes - total_running)); \
	echo -e "  Stopped nodes:   $(COLOR_YELLOW)$$stopped$(COLOR_RESET)"

# Start all enabled nodes
nodes-start:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║              Starting All Enabled Nodes                    ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@started=0; \
	skipped=0; \
	for node_dir in $(NODE_DIRS); do \
		node_name=$$(basename $$node_dir); \
		if [ -f "$$node_dir/.env" ]; then \
			enabled=$$(grep '^ENABLED=' $$node_dir/.env 2>/dev/null | cut -d'=' -f2); \
			if [ "$$enabled" = "true" ]; then \
				echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node_name:$(COLOR_RESET)"; \
				echo -e "  $(COLOR_GREEN)▶ Starting node...$(COLOR_RESET)"; \
				$(MAKE) -C $$node_dir up && { echo -e "  $(COLOR_GREEN)✓ Node started$(COLOR_RESET)"; started=$$((started + 1)); } || echo -e "  $(COLOR_RED)✗ Failed to start$(COLOR_RESET)"; \
				echo ""; \
			else \
				echo -e "$(COLOR_YELLOW)⊘ $$node_name: Skipped (disabled)$(COLOR_RESET)"; \
				skipped=$$((skipped + 1)); \
			fi; \
		else \
			echo -e "$(COLOR_YELLOW)⊘ $$node_name: Skipped (no .env file)$(COLOR_RESET)"; \
			skipped=$$((skipped + 1)); \
		fi; \
	done; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	echo -e "  $(COLOR_GREEN)Started:$(COLOR_RESET)  $$started"; \
	echo -e "  $(COLOR_YELLOW)Skipped:$(COLOR_RESET)  $$skipped"; \
	echo ""; \
	echo -e "$(COLOR_CYAN)Tip: Run$(COLOR_RESET) $(COLOR_BOLD)make nodes-status$(COLOR_RESET) $(COLOR_CYAN)to check status$(COLOR_RESET)"

# Stop all nodes
nodes-stop:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║                Stopping All Nodes                          ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@stopped=0; \
	for node_dir in $(NODE_DIRS); do \
		node_name=$$(basename $$node_dir); \
		echo -e "$(COLOR_BOLD)$(COLOR_CYAN)$$node_name:$(COLOR_RESET)"; \
		echo -e "  $(COLOR_YELLOW)■ Stopping node...$(COLOR_RESET)"; \
		$(MAKE) -C $$node_dir down 2>/dev/null && { echo -e "  $(COLOR_YELLOW)✓ Node stopped$(COLOR_RESET)"; stopped=$$((stopped + 1)); } || echo -e "  $(COLOR_YELLOW)⚠ Not running or failed$(COLOR_RESET)"; \
		echo ""; \
	done; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	echo -e "  $(COLOR_YELLOW)Stopped:$(COLOR_RESET) $$stopped node(s)"

# Show logs from all running nodes
nodes-logs:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║              Node Logs (Ctrl+C to stop)                    ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@found=0; \
	for node_dir in $(NODE_DIRS); do \
		if [ -f "$$node_dir/.env" ]; then \
			if cd $$node_dir && docker compose ps -q 2>/dev/null | grep -q .; then \
				echo -e "$(COLOR_BOLD)$(COLOR_CYAN)=== $$(basename $$node_dir) ===$(COLOR_RESET)"; \
				docker compose logs --tail=20; \
				echo ""; \
				found=$$((found + 1)); \
			fi; \
			cd - > /dev/null 2>&1; \
		fi; \
	done; \
	if [ $$found -eq 0 ]; then \
		echo -e "$(COLOR_YELLOW)⚠ No running nodes found$(COLOR_RESET)"; \
	fi

# Individual node targets - node-001
node-001-help:
	@$(MAKE) -C network/flare/observation-nodes/node-001 help

node-001-up:
	@$(MAKE) -C network/flare/observation-nodes/node-001 up

node-001-down:
	@$(MAKE) -C network/flare/observation-nodes/node-001 down

node-001-restart:
	@$(MAKE) -C network/flare/observation-nodes/node-001 restart

node-001-logs:
	@$(MAKE) -C network/flare/observation-nodes/node-001 logs

node-001-status:
	@$(MAKE) -C network/flare/observation-nodes/node-001 status

# Individual node targets - node-002
node-002-help:
	@$(MAKE) -C network/flare/observation-nodes/node-002 help

node-002-up:
	@$(MAKE) -C network/flare/observation-nodes/node-002 up

node-002-down:
	@$(MAKE) -C network/flare/observation-nodes/node-002 down

node-002-restart:
	@$(MAKE) -C network/flare/observation-nodes/node-002 restart

node-002-logs:
	@$(MAKE) -C network/flare/observation-nodes/node-002 logs

node-002-status:
	@$(MAKE) -C network/flare/observation-nodes/node-002 status

# Individual node targets - node-003
node-003-help:
	@$(MAKE) -C network/flare/observation-nodes/node-003 help

node-003-up:
	@$(MAKE) -C network/flare/observation-nodes/node-003 up

node-003-down:
	@$(MAKE) -C network/flare/observation-nodes/node-003 down

node-003-restart:
	@$(MAKE) -C network/flare/observation-nodes/node-003 restart

node-003-logs:
	@$(MAKE) -C network/flare/observation-nodes/node-003 logs

node-003-status:
	@$(MAKE) -C network/flare/observation-nodes/node-003 status

# Individual node targets - node-004
node-004-help:
	@$(MAKE) -C network/flare/observation-nodes/node-004 help

node-004-up:
	@$(MAKE) -C network/flare/observation-nodes/node-004 up

node-004-down:
	@$(MAKE) -C network/flare/observation-nodes/node-004 down

node-004-restart:
	@$(MAKE) -C network/flare/observation-nodes/node-004 restart

node-004-logs:
	@$(MAKE) -C network/flare/observation-nodes/node-004 logs

node-004-status:
	@$(MAKE) -C network/flare/observation-nodes/node-004 status

# Pull all Docker images
pull-images:
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)║              Pulling Docker Images                         ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Pulling AsciiDoctor image...$(COLOR_RESET)"
	@$(MAKE) -C docs pull && echo -e "$(COLOR_GREEN)✓ AsciiDoctor image pulled$(COLOR_RESET)" || echo -e "$(COLOR_YELLOW)⚠ Failed to pull AsciiDoctor image$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_BOLD)$(COLOR_BLUE)Pulling node images...$(COLOR_RESET)"
	@pulled=0; \
	for node_dir in $(NODE_DIRS); do \
		if [ -f "$$node_dir/.env" ]; then \
			node_name=$$(basename $$node_dir); \
			echo -e "$(COLOR_CYAN)$$node_name:$(COLOR_RESET) Pulling image..."; \
			cd $$node_dir && docker compose pull 2>/dev/null && { echo -e "  $(COLOR_GREEN)✓ Image pulled$(COLOR_RESET)"; pulled=$$((pulled + 1)); } || echo -e "  $(COLOR_YELLOW)⚠ Failed$(COLOR_RESET)"; \
			cd - > /dev/null 2>&1; \
		fi; \
	done; \
	echo ""; \
	echo -e "$(COLOR_BOLD)Summary:$(COLOR_RESET)"; \
	echo -e "  $(COLOR_GREEN)Images pulled:$(COLOR_RESET) $$pulled"

# Clean all generated files
clean: docs-clean
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)╔════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)║              Cleaning Generated Files                      ║$(COLOR_RESET)"
	@echo -e "$(COLOR_BOLD)$(COLOR_YELLOW)╚════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo -e "$(COLOR_GREEN)✓ All generated files cleaned$(COLOR_RESET)"
