.DEFAULT_GOAL := help
.PHONY: help check git-init env infra jenkins up status password down

help: ## Show available commands
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

check: ## Confirm required tools are installed and Docker is running
	@for tool in git docker kind kubectl terraform; do \
		command -v $$tool >/dev/null || { echo "Missing: $$tool"; exit 1; }; \
	done
	@docker info >/dev/null 2>&1 || { echo "Docker is not running"; exit 1; }
	@echo "All tools found."

git-init: ## Create the Git repo with a first commit on main
	@if [ -d .git ]; then echo "Git repo already exists."; else \
		git init -b main && git add . && git commit -m "Initial commit"; fi

env: ## Generate .env with a random Jenkins password
	@if [ -f .env ]; then echo ".env already exists."; else \
		echo "JENKINS_ADMIN_PASSWORD=$$(openssl rand -hex 16)" > .env; chmod 600 .env; echo "Created .env"; fi

infra: ## Create the cluster, registry and platform with Terraform
	terraform -chdir=terraform init
	terraform -chdir=terraform apply -auto-approve

jenkins: env ## Build and start Jenkins
	docker compose up -d --build

up: check git-init infra jenkins ## Create everything
	@echo "Jenkins: http://localhost:8080  (user: admin, password: make password)"

status: ## Show cluster and app status
	kubectl --context kind-devops-lab get nodes
	kubectl --context kind-devops-lab get deploy,pods,ingress,hpa -n demo-dev
	kubectl --context kind-devops-lab get deploy,pods,ingress,hpa -n demo-prod

password: ## Print the Jenkins admin password
	@grep JENKINS_ADMIN_PASSWORD .env | cut -d= -f2

down: ## Delete Jenkins, the cluster and the registry
	-docker compose down -v
	terraform -chdir=terraform destroy -auto-approve
