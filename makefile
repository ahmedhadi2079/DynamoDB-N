SHELL := /bin/bash

# Define the virtual environment directory
VENV_DIR = .venv

# Define directories
LAMBDAS_DIR := src/lambdas
GLUE_DIR := glues
TESTS_DIR := tests
COMMON_DIR := common
SRC_COMMON_DIR := src/common

# Define common tests directory
COMMON_TESTS_DIR = tests

.PHONY: help test-all-combined-cov create-venv install-test-deps clean clean-coverage clean-venv

help:
	@echo "Available targets:"
	@echo "  test-all-combined-cov  Combined coverage across lambdas, glues, common, and src/common (xml + html)"
	@echo "  create-venv            Create virtual environment"
	@echo "  install-test-deps      Install pytest and test dependencies in virtual environment"
	@echo "  test-lambdas           Run tests for all lambdas"
	@echo "  clean                  Remove coverage artifacts and virtual environment"
	@echo "  clean-coverage         Remove coverage artifacts only"
	@echo "  clean-venv             Remove virtual environment"

# Create a virtual environment
.PHONY: create-venv
create-venv:
	@echo "Creating virtual environment and installing dependencies"
	rm -rf $(VENV_DIR)
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install --upgrade pip; \
	pip install pip-tools

# Install pytest and test dependencies
.PHONY: install-test-deps
install-test-deps: create-venv
	source $(VENV_DIR)/bin/activate; \
	pip install pytest pytest-cov coverage boto3; \
	if [ -f $(TESTS_DIR)/requirements.txt ]; then \
		pip install -r $(TESTS_DIR)/requirements.txt; \
	fi; \
	for dir in $(LAMBDAS_DIR)/*; do \
		if [ -d "$$dir" ] && [ -f "$$dir/requirements.txt" ]; then \
			echo 'Installing dependencies for' $$dir; \
			pip install -r $$dir/requirements.txt; \
		fi; \
		if [ -d "$$dir" ] && [ -f "$$dir/tests/requirements.txt" ]; then \
			echo 'Installing test dependencies for' $$dir; \
			pip install -r $$dir/tests/requirements.txt; \
		fi; \
	done

# Install pytest and dependencies for each lambda and its tests
.PHONY: install-deps
install-deps: create-venv
	source $(VENV_DIR)/bin/activate; \
	pip install pytest pytest-cov; \
	for lambda in $(LAMBDAS_DIR)/*; do \
		if [ -d "$$lambda" ]; then \
			echo 'Found lambda directory:' $$lambda; \
			if [ -f $$lambda/requirements.txt ]; then \
				echo 'Installing dependencies for' $$lambda; \
				pip install -r $$lambda/requirements.txt; \
			fi; \
			if [ -f $$lambda/tests/requirements.txt ]; then \
				echo 'Installing test dependencies for' $$lambda; \
				pip install -r $$lambda/tests/requirements.txt; \
			fi; \
		fi; \
	done

# Run pytest for each lambda
.PHONY: test-lambdas
test-lambdas: install-deps
	source $(VENV_DIR)/bin/activate; \
	for dir in $(LAMBDAS_DIR)/*; do \
		if [ -d $$dir/tests ]; then \
			pytest $$dir/tests; \
			pytest --cov=$$dir --cov-report=html --cov-report=term $$dir/tests; \
			coverage report; \
		fi; \
	done

# Debug target to just list directories
.PHONY: list-lambdas
list-lambdas:
	@ls -1 $(LAMBDAS_DIR)/

# Clean the virtual environment
.PHONY: clean-venv
clean-venv:
	rm -rf $(VENV_DIR)

# Clean up previous coverage data
.PHONY: clean-coverage
clean-coverage:
	rm -rf htmlcov coverage.xml .coverage .coverage.*

# Combined coverage across lambdas, glues, common, and src/common (xml + html)
.PHONY: test-all-combined-cov
test-all-combined-cov: install-test-deps clean-coverage
	@echo "Setting PYTHONPATH to project root and running tests with coverage"
	source $(VENV_DIR)/bin/activate; \
	export PYTHONPATH=$(PWD); \
	coverage erase; \
	echo "Running lambda tests with coverage..."; \
	for dir in $(LAMBDAS_DIR)/*; do \
		if [ -d $$dir ] && [ -d $$dir/tests ]; then \
			echo 'Running tests with coverage for' $$dir; \
			pytest -q -r a --disable-warnings --maxfail=1 --cov=$$dir --cov-append --cov-report= $$dir/tests; \
		fi; \
	done; \
	echo "Running glue tests with coverage..."; \
	for glue in $(GLUE_DIR)/*; do \
		if [ -d $$glue ] && [ -d $$glue/tests ]; then \
			echo 'Running tests with coverage for' $$glue; \
			pytest -q -r a --disable-warnings --maxfail=1 --cov=$$glue --cov-append --cov-report= $$glue/tests; \
		fi; \
	done; \
	if [ -d $(COMMON_DIR)/tests ]; then \
		echo "Running common tests with coverage..."; \
		pytest -q -r a --disable-warnings --maxfail=1 --cov=$(COMMON_DIR) --cov-append --cov-report= $(COMMON_DIR)/tests; \
	fi; \
	if [ -d $(SRC_COMMON_DIR)/tests ]; then \
		echo "Running src/common tests with coverage..."; \
		pytest -q -r a --disable-warnings --maxfail=1 --cov=$(SRC_COMMON_DIR) --cov-append --cov-report= $(SRC_COMMON_DIR)/tests; \
	fi; \
	echo "Including full src coverage from top-level tests..."; \
	pytest -q -r a --disable-warnings --maxfail=1 --cov=src --cov-append --cov-report= $(TESTS_DIR); \
	echo "Including full common coverage from top-level tests..."; \
	pytest -q -r a --disable-warnings --maxfail=1 --cov=common --cov-append --cov-report= $(TESTS_DIR); \
	echo "Generating combined coverage report..."; \
	coverage report; \
	coverage html; \
	coverage xml

# Clean all artifacts
.PHONY: clean
clean:
	rm -rf .pytest_cache htmlcov .coverage .coverage.* coverage.xml $(VENV_DIR)