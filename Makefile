IMAGE_NAME?=neuromation/base
DOCKERFILE?=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab

# Shortcuts:
DOCKER_RUN?=docker run --tty --rm
ASSERT_COMMAND_FAILS=&& { echo 'Failure!'; exit 1; } || { echo 'Success!'; }
ASSERT_COMMAND_SUCCEEDS=&& echo 'Success!'

# Testing settings:
IMAGE_TEST_DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing

# SSH test variables:
SSH=ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes"
SSH_CONT_NAME=ssh-test
SSH_OPTION?=-e EXPOSE_SSH=yes
SSH_TEST_SUCCEEDS?=yes
SSH_TEST_ASSERTION:=
ifeq ($(SSH_TEST_SUCCEEDS),yes)
	SSH_TEST_ASSERTION=$(ASSERT_COMMAND_SUCCEEDS)
else
	SSH_TEST_ASSERTION=$(ASSERT_COMMAND_FAILS)
endif


.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .


.PHONY: generate_recipes
generate_recipes:
	python3 testing/generate_recipes.py $(DOCKERFILE)


.PHONY: test_dependencies_pip
test_dependencies_pip:
	# Note: `--network=host` is used for the Internet access (to use `pip install ...`)
	# however this prevents SSH to start (port 22 is already bind).
	# see https://github.com/neuromation/template-base-image/issues/21
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) --network=host --workdir=/testing $(IMAGE_NAME) python ./run_tests.py


.PHONY: test_timeout
test_timeout:
	# job exits within the timeout 3 sec (ok):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 $(IMAGE_NAME) sleep 1  $(ASSERT_COMMAND_SUCCEEDS)
	# job exits within the timeout sec (exit code 124):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 $(IMAGE_NAME) sleep 10  $(ASSERT_COMMAND_FAILS)


.PHONY: cleanup_test_ssh
cleanup_test_ssh:
	docker kill $(SSH_CONT_NAME) | true

.PHONY: test_ssh
test_ssh: cleanup_test_ssh
	# run with ssh
	{ $(DOCKER_RUN) --detach --publish-all --name=$(SSH_CONT_NAME) $(SSH_OPTION) $(IMAGE_NAME) sleep 1h ;} && \
	{ $(DOCKER_RUN) --network=container:$(SSH_CONT_NAME) --name=$(SSH_CONT_NAME)-client  kroniak/ssh-client \
		$(SSH) root@localhost -p 22 whoami ;}  \
	$(SSH_TEST_ASSERTION)
