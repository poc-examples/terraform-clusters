SHELL := /bin/bash

REQUIRED_ENV_VARS 	:= 	AWS_ACCESS_KEY_ID \
						AWS_SECRET_ACCESS_KEY \
						CLUSTER_USERNAME \
						CLUSTER_PASSWORD \
						ROSA_TOKEN

PYTHON := python3
VENV_DIR := venv
SCRIPT := scripts/render.py
REQUIREMENTS := scripts/requirements.txt

.PHONY: 
	check_shell 
	check_virtualenv 
	create_venv 
	install_deps 
	render
	test
	clean
	help

check_shell:
	@for var in $(REQUIRED_ENV_VARS); do \
		if [ -z "$${!var}" ]; then \
			echo "Error: $$var is not set"; \
			exit 1; \
		else \
			echo "$$var is set"; \
		fi \
	done
	@echo "All required environment variables are set."

check_virtualenv:
	@echo "Checking if virtualenv is installed..."
	@command -v virtualenv >/dev/null 2>&1 || \
		{ echo >&2 "virtualenv not found. Installing..."; $(PYTHON) -m pip install --user virtualenv; }

create_venv: check_virtualenv
	@echo "Creating virtual environment..."
	@virtualenv $(VENV_DIR)

install_deps: create_venv
	@echo "Activating virtual environment and installing dependencies..."
	@. $(VENV_DIR)/local/bin/activate && pip install -r $(REQUIREMENTS)

render: check_shell install_deps
	@echo "Rendering Jinja2 templates for cluster type $(CLUSTER_TYPE)..."
	@. $(VENV_DIR)/local/bin/activate && $(PYTHON) $(SCRIPT) $(CLUSTER_TYPE)
	@echo "Templates rendered successfully for cluster type $(CLUSTER_TYPE)."

test: check_shell
	@echo "Running Go tests..."
	@cd tests && go test -v ${CLUSTER_TYPE}_cluster_test.go -timeout 2h
	@echo "Go tests completed."

clean:
	@echo "Cleaning up virtual environment and generated files..."
	@rm -rf $(VENV_DIR)
	@find tests/use-cases/*/ -name "*.yaml" -type f -delete
	@echo "Cleanup complete."

help:
	@echo "Makefile for rendering Jinja2 templates and running tests"
	@echo
	@echo "Usage:"
	@echo "  make check_shell                         Verify that all required environment variables are set"
	@echo "  make check_virtualenv                    Check if virtualenv is installed, and install it if missing"
	@echo "  make create_venv                         Create a Python virtual environment"
	@echo "  make install_deps                        Install Python dependencies into the virtual environment"
	@echo "  make render_templates CLUSTER_TYPE=<type>  Render Jinja2 templates for a specific cluster type"
	@echo "  make test                                Run Go tests for the specified cluster type"
	@echo "  make clean                               Remove the virtual environment and generated YAML files"
	@echo "  make help                                Display this help message"
