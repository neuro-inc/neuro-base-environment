IMAGE_NAME?=neuromation/base
DOCKERFILE?=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab

# Shortcuts:
DOCKER_RUN?=docker run --tty --rm --publish-all=true
ASSERT_COMMAND_FAILS=&& { echo 'Failure!'; exit 1; } || { echo 'Success!'; }
ASSERT_COMMAND_SUCCEEDS=&& echo 'Success!'

# Testing settings:
IMAGE_TEST_DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing

# SSH test variables:
SSH=ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes"
SSH_OPTION?="-e EXPOSE_SSH=yes"
SSH_TEST_SUCCEEDS?="yes"
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


.PHONY: test_image
test_image:
	# Note: `--network=host` is used for the Internet access (to use `pip install ...`)
	# however this prevents SSH to start (port 22 is already bind).
	# see https://github.com/neuromation/template-base-image/issues/21
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) --network=host --workdir=/testing $(IMAGE_NAME) python ./run_tests.py


.PHONY: test_timeout
test_timeout:
	# job exits within the timeout 3 sec (ok):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 -t $(IMAGE_NAME) sleep 1  $(ASSERT_COMMAND_SUCCEEDS)
	# job exits within the timeout sec (exit code 124):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 -t $(IMAGE_NAME) sleep 10  $(ASSERT_COMMAND_FAILS)


.PHONY: cleanup_ssh_test
cleanup_ssh_test:
	docker kill container_test_ssh | true

.PHONY: test_ssh
test_ssh: cleanup_ssh_test
	# run with ssh
	{ $(DOCKER_RUN) --detach --name=container_test_ssh $(SSH_OPTION) $(IMAGE_NAME) sleep 1h ;} && { $(SSH) root@localhost -p $$(docker port container_test_ssh 22 | grep -oP ':\K.+') echo 'SSH by $$(whoami)'  | grep "SSH by root" ;}  $(SSH_TEST_ASSERTION)

