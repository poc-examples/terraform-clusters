# Makefile for rendering Jinja2 templates using a virtual environment

# Define the Python interpreter to use
PYTHON := python3

# Define the virtual environment directory
VENV_DIR := venv

# Define the script to run
SCRIPT := scripts/render_templates.py

# Define the requirements file (if you have one)
REQUIREMENTS := scripts/requirements.txt

# Target to check if virtualenv is installed
.PHONY: check_virtualenv
check_virtualenv:
	@echo "Checking if virtualenv is installed..."
	@command -v virtualenv >/dev/null 2>&1 || { echo >&2 "virtualenv not found. Installing..."; $(PYTHON) -m pip install --user virtualenv; }

# Target to create the virtual environment
.PHONY: create_venv
create_venv: check_virtualenv
	@echo "Creating virtual environment..."
	@virtualenv $(VENV_DIR)

# Target to activate the virtual environment and install dependencies
.PHONY: install_deps
install_deps: create_venv
	@echo "Activating virtual environment and installing dependencies..."
	@. $(VENV_DIR)/local/bin/activate && pip install -r $(REQUIREMENTS)

# Target to render the templates with the specified cluster type
.PHONY: render_templates
render_templates: install_deps
	@echo "Rendering Jinja2 templates for cluster type $(CLUSTER_TYPE)..."
	@. $(VENV_DIR)/local/bin/activate && $(PYTHON) $(SCRIPT) $(CLUSTER_TYPE)
	@echo "Templates rendered successfully for cluster type $(CLUSTER_TYPE)."

# Target to run Go tests
.PHONY: test
test:
	@echo "Running Go tests..."
	@cd tests && go test -v ${CLUSTER_TYPE}_cluster_test.go
	@echo "Go tests completed."

# Clean target to remove the virtual environment and generated files
.PHONY: clean
clean:
	@echo "Cleaning up virtual environment and generated files..."
	@rm -rf $(VENV_DIR)
	@find tests/use-cases/*/ -name "*.yaml" -type f -delete
	@echo "Cleanup complete."

# Help target to display usage information
.PHONY: help
help:
	@echo "Makefile for rendering Jinja2 templates"
	@echo
	@echo "Usage:"
	@echo "  make render_templates CLUSTER_TYPE=<type>  Run the Python script to render Jinja2 templates for a specific cluster type"
	@echo "  make clean                                Remove virtual environment and generated YAML files"
	@echo "  make help                                 Display this help message"
