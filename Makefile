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

.PHONY: test
test:
	docker run -e PLATFORMAPI_SERVICE_HOST=test --network=host -v `pwd`/testing:/testing:ro -w /testing -t $(IMAGE_NAME) $(TEST_COMMAND)
	@echo ok
