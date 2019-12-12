IMAGE_NAME?=neuromation/base
DOCKERFILE_NAME?=python36-jupyter-pytorch-tensorflow-jupyterlab

# Shortcuts:
DOCKER_RUN?=docker run --tty --rm
ASSERT_COMMAND_FAILS=&& { echo -e 'Failure!\n'; exit 1; } || { echo -e 'Success!\n'; }
ASSERT_COMMAND_SUCCEEDS=&& echo -e 'Success!\n'

# Testing settings:
IMAGE_TEST_DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing

# SSH test variables:
SSH=ssh -o "StrictHostKeyChecking=no" -o "BatchMode=yes"
SSH_CONTAINER=ssh-test
SSH_OPTION?=-e EXPOSE_SSH=yes
SSH_ENABLED?=yes
SSH_TEST_ASSERTION:=
ifeq ($(SSH_ENABLED),yes)
	SSH_TEST_ASSERTION=$(ASSERT_COMMAND_SUCCEEDS)
else
	SSH_TEST_ASSERTION=$(ASSERT_COMMAND_FAILS)
endif



.PHONY: image_build
image_build:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py --cuda-ver=10.0 --cudnn-ver=cudnn7-devel --ubuntu-ver=ubuntu18.04 targets/$(DOCKERFILE_NAME)/Dockerfile-deepo tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f targets/$(DOCKERFILE_NAME)/Dockerfile .


.PHONY: image_diff
image_diff:
	diff --color=always --side-by-side  targets/$(DOCKERFILE_NAME)/Dockerfile.deepo targets/$(DOCKERFILE_NAME)/Dockerfile


.PHONY: generate_recipes
generate_recipes:
	python3 testing/generate_recipes.py targets/$(DOCKERFILE_NAME)/Dockerfile


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
	docker kill $(SSH_CONTAINER) | true

.PHONY: test_ssh
test_ssh: cleanup_test_ssh
	{ $(DOCKER_RUN) --detach --publish-all --name=$(SSH_CONTAINER) $(SSH_OPTION) $(IMAGE_NAME) sleep 1h ;} && \
	{ $(DOCKER_RUN) --network=container:$(SSH_CONTAINER) --name=$(SSH_CONTAINER)-client  kroniak/ssh-client \
		$(SSH) root@localhost -p 22 whoami ;}  \
	$(SSH_TEST_ASSERTION)

.PHONY: test_gcloud_auth
test_gcloud_auth:
	# no env var was set => no auth
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) $(IMAGE_NAME) echo ok | grep -v "Activated service account credentials for"
	# wrong env var was set => file not found error
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) -e GCP_SERVICE_ACCOUNT_KEY_PATH=non-existing.json $(IMAGE_NAME) echo ok | grep -Pz "(?s)Unable to read file .*No such file or directory: .+ok"
	# correct env var was set => auth successful
	python3 testing/gcloud/decrypter.py testing/gcloud/gcp-key.json.enc testing/gcloud/gcp-key.json
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) -v $${PWD}/testing/gcloud/:/mnt/ -e GCP_SERVICE_ACCOUNT_KEY_PATH=/mnt/gcp-key.json $(IMAGE_NAME) echo ok | grep -Pz "(?s)Activated service account credentials for: .+ok"
	make --quiet cleanup_test_gcloud_auth

.PHONY: cleanup_test_gcloud_auth
cleanup_test_gcloud_auth:
	rm testing/gcloud/gcp-key.json | true
