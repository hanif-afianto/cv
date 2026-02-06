# ==============================
# CONFIG
# ==============================

MAIN_BRANCH := master
DEPLOY_BRANCH := gh-pages
BUILD_DIR := .output/public
DEPLOY_TAG := deploy-$(shell date +%Y%m%d-%H%M%S)

# ==============================
# PHONY
# ==============================

.PHONY: build deploy ensure-clean ensure-branch clean

# ==============================
# BUILD
# ==============================

build:
	@echo "▶ Generating Nuxt static build"
	npx nuxi generate


# ==============================
# SAFETY: block dirty repo
# ==============================

ensure-clean:
	@echo "▶ Checking working tree"
	@if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "❌ Repo has uncommitted changes. Commit or stash first."; \
		exit 1; \
	fi


# ==============================
# FIRST-TIME BRANCH CREATION
# ==============================

ensure-branch:
	@echo "▶ Ensuring $(DEPLOY_BRANCH) exists"
	@if git show-ref --quiet refs/heads/$(DEPLOY_BRANCH); then \
		echo "✔ Local branch exists"; \
	elif git ls-remote --exit-code --heads origin $(DEPLOY_BRANCH) > /dev/null 2>&1; then \
		echo "✔ Remote branch exists → fetch and checkout"; \
		git fetch origin $(DEPLOY_BRANCH):$(DEPLOY_BRANCH); \
		git checkout $(DEPLOY_BRANCH); \
	else \
		echo "➕ Creating orphan $(DEPLOY_BRANCH)"; \
		git checkout --orphan $(DEPLOY_BRANCH); \
		git rm -rf . >/dev/null 2>&1 || true; \
		touch .nojekyll; \
		git add .nojekyll; \
		git commit -m "init: gh-pages"; \
		git push origin $(DEPLOY_BRANCH); \
	fi


# ==============================
# DEPLOY
# ==============================

deploy: ensure-clean
	@echo "▶ Switching to $(MAIN_BRANCH)"
	git checkout $(MAIN_BRANCH)

	$(MAKE) build
	$(MAKE) ensure-branch

	@echo "▶ Switching to $(DEPLOY_BRANCH)"
	git checkout $(DEPLOY_BRANCH)

	@echo "▶ Cleaning old build"
	git rm -rf . >/dev/null 2>&1 || true
	git clean -fxd

	@echo "▶ Copying new build"
	cp -r $(BUILD_DIR)/* .

	@echo "▶ Commit + tag + push"
	git add .
	git commit -m "deploy: update gh-pages"
	git tag $(DEPLOY_TAG)
	git push origin $(DEPLOY_BRANCH)
	git push origin $(DEPLOY_TAG)

	@echo "▶ Back to $(MAIN_BRANCH)"
	git checkout $(MAIN_BRANCH)

	@echo "✅ Deploy finished"


# ==============================
# CLEAN
# ==============================

clean:
	rm -rf .output
