.PHONY: help init validate fmt plan apply destroy clean test

# Default target
help:
	@echo "Reusable Terraform - GCP Development Environments"
	@echo ""
	@echo "Development Commands:"
	@echo "  make init              - Initialize Terraform"
	@echo "  make validate          - Validate all modules"
	@echo "  make fmt               - Format Terraform files"
	@echo "  make fmt-check         - Check formatting"
	@echo ""
	@echo "Example Commands:"
	@echo "  make example-init      - Initialize example"
	@echo "  make example-plan      - Plan example deployment"
	@echo "  make example-apply     - Apply example deployment"
	@echo "  make example-destroy   - Destroy example deployment"
	@echo ""
	@echo "Testing:"
	@echo "  make test              - Run all tests"
	@echo "  make test-security     - Run security scan (tfsec)"

# Development
init:
	@echo "Initializing root module..."
	terraform init -backend=false

validate:
	@echo "Validating all modules..."
	@for dir in modules/*/; do \
		echo "Validating $$dir"; \
		terraform -chdir="$$dir" init -backend=false > /dev/null 2>&1 || true; \
		terraform -chdir="$$dir" validate || exit 1; \
	done
	@echo "All modules validated successfully!"

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive

# Example deployment
example-init:
	cd examples/destaquesgovbr && terraform init

example-plan:
	cd examples/destaquesgovbr && terraform plan

example-apply:
	cd examples/destaquesgovbr && terraform apply

example-destroy:
	cd examples/destaquesgovbr && terraform destroy

# Testing
test: fmt-check validate
	@echo "All tests passed!"

test-security:
	@echo "Running tfsec..."
	tfsec .

# Cleanup
clean:
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -type f -name "*.tfstate*" -delete 2>/dev/null || true
