IMAGE ?= ffl-draft:production
CONTAINER ?= ffl-draft-production-test
VOLUME ?= ffl_draft_storage_test
PORT ?= 8080

SYSTEM_TEST_IMAGE ?= ffl-draft:system-test

.PHONY: production-build production-run production-health production-logs production-stop production-check system-test

system-test:
	docker build --file Dockerfile.system-test --tag $(SYSTEM_TEST_IMAGE) .
	docker run --rm $(SYSTEM_TEST_IMAGE)

production-build:
	docker build -t $(IMAGE) .

production-run:
	-docker rm -f $(CONTAINER) >/dev/null 2>&1
	docker volume create $(VOLUME) >/dev/null
	docker run -d \
		--name $(CONTAINER) \
		-p $(PORT):80 \
		-e SOLID_QUEUE_IN_PUMA=true \
		-e APP_HOST=localhost \
		-e RAILS_MASTER_KEY="$$(tr -d '\n' < config/master.key)" \
		-v $(VOLUME):/rails/storage \
		$(IMAGE)

production-health:
	curl -fsS http://localhost:$(PORT)/up

production-logs:
	docker logs --tail 100 $(CONTAINER)

production-stop:
	-docker rm -f $(CONTAINER)

production-check: production-build production-run
	@status=1; \
	for attempt in $$(seq 1 30); do \
		if curl -fs http://localhost:$(PORT)/up >/dev/null 2>&1; then \
			status=0; \
			break; \
		fi; \
		sleep 1; \
	done; \
	docker logs --tail 100 $(CONTAINER); \
	docker rm -f $(CONTAINER) >/dev/null 2>&1; \
	exit $$status
