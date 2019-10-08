IMAGE_NAME?=neuromation/base
DOCKERFILE?=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab
TEST_COMMAND?=python ./run_tests.py

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
# 	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .
	@echo ok

.PHONY: generate-recipes
generate-recipes:
	python3 testing/generate_recipes.py $(DOCKERFILE)
	git status

.PHONY: setup-docker-locally
setup-docker-locally:
	sudo pkill docker
	sudo iptables -t nat -F
	sudo ifconfig docker0 down
	sudo brctl delbr docker0
	sudo docker -d


.PHONY: test
test:
	docker run -e PLATFORMAPI_SERVICE_HOST=test --volume=testing:/testing -w /testing -t $(IMAGE_NAME) pwd
	docker run -e PLATFORMAPI_SERVICE_HOST=test --volume=testing:/testing -w /testing -t $(IMAGE_NAME) ls -la
	docker run -e PLATFORMAPI_SERVICE_HOST=test --volume=testing:/testing -w /testing -t $(IMAGE_NAME) ls -la /testing
# 	docker run -e PLATFORMAPI_SERVICE_HOST=test --volume=testing:/testing -w /testing -t $(IMAGE_NAME) $(TEST_COMMAND)
	@echo ok
