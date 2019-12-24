IMAGE_NAME?=neuromation/base
DOCKERFILE_NAME?=python36-jupyter-pytorch-tensorflow-jupyterlab

# Shortcuts:
DOCKER_RUN?=docker run --tty --rm
ASSERT_COMMAND_FAILS=&& { echo -e 'Failure!\n'; exit 1; } || { echo -e 'Success!\n'; }
ASSERT_COMMAND_SUCCEEDS=&& echo -e 'Success!\n'

# Testing settings:
IMAGE_TEST_DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing --volume=/tmp/neuro-base-environment:/tmp
# Create required temp directory:
$(shell mkdir -p /tmp/neuro-base-environment)

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
	$(DOCKER_RUN) -e JOB_TIMEOUT=1 $(IMAGE_NAME) sleep 0.1  $(ASSERT_COMMAND_SUCCEEDS)
	# job exits within the timeout sec (exit code 124):
	$(DOCKER_RUN) -e JOB_TIMEOUT=1 $(IMAGE_NAME) sleep 10  $(ASSERT_COMMAND_FAILS)


.PHONY: cleanup_test_ssh
cleanup_test_ssh:
	docker kill $(SSH_CONTAINER) | true

.PHONY: test_ssh
test_ssh: cleanup_test_ssh
	{ $(DOCKER_RUN) --detach --publish-all --name=$(SSH_CONTAINER) $(SSH_OPTION) $(IMAGE_NAME) sleep 1h ;} && \
	{ $(DOCKER_RUN) --network=container:$(SSH_CONTAINER) --name=$(SSH_CONTAINER)-client  kroniak/ssh-client \
		$(SSH) root@localhost -p 22 whoami ;}  \
	$(SSH_TEST_ASSERTION)


GCP_SUCCESS_PATTERN=Activated service account credentials for

.PHONY: test_gcloud
test_gcloud:
	make _test_gcloud_false
	make _generate_gcloud_key
	make _test_gcloud_true

.PHONY: _test_gcloud_false
_test_gcloud_false:
	# no env var was set => no auth (note: 'grep -v' reverses the pattern)
	$(DOCKER_RUN) $(IMAGE_NAME) echo OK | grep -v "${GCP_SUCCESS_PATTERN}" ${ASSERT_COMMAND_SUCCEEDS}
	$(DOCKER_RUN) -e GCP_SERVICE_ACCOUNT_KEY_PATH= $(IMAGE_NAME) echo OK | grep -v "${GCP_SUCCESS_PATTERN}" ${ASSERT_COMMAND_SUCCEEDS}
	# wrong env var was set => file not found error
	$(DOCKER_RUN) -e GCP_SERVICE_ACCOUNT_KEY_PATH=non-existing.json $(IMAGE_NAME) echo OK | grep -Pz "(?s)Unable to read file .*No such file or directory: .+OK" ${ASSERT_COMMAND_SUCCEEDS}

.PHONY: _generate_gcloud_key
_generate_gcloud_key:
	python3 testing/gcloud/decrypter.py testing/gcloud/gcp-key.json.enc testing/gcloud/gcp-key.json

.PHONY: _test_gcloud_true
_test_gcloud_true:
	# correct env var was set => auth successful
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) -e GCP_SERVICE_ACCOUNT_KEY_PATH=/testing/gcloud/gcp-key.json $(IMAGE_NAME) echo OK | grep -Pz "(?s)${GCP_SUCCESS_PATTERN}.+OK" ${ASSERT_COMMAND_SUCCEEDS}
	make --quiet _delete_gcloud_key

.PHONY: _delete_gcloud_key
_delete_gcloud_key:
	rm testing/gcloud/gcp-key.json


WANDB_SUCCESS_PATTERN=Successfully logged in to Weights & Biases

.PHONY: test_wandb
test_wandb:
	# no env var was set => no auth (note: 'grep -v' reverses the pattern)
	$(DOCKER_RUN) $(IMAGE_NAME) echo OK | grep -v "${WANDB_SUCCESS_PATTERN}" ${ASSERT_COMMAND_SUCCEEDS}
	$(DOCKER_RUN) -e NM_WANDB_TOKEN_PATH= $(IMAGE_NAME) echo OK | grep -v "${WANDB_SUCCESS_PATTERN}" ${ASSERT_COMMAND_SUCCEEDS}
	# wrong env var was set => no action
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) -e NM_WANDB_TOKEN_PATH=non-existing.txt $(IMAGE_NAME) echo OK ${ASSERT_COMMAND_SUCCEEDS}
	# wrong token length in file => ValueError
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) -e NM_WANDB_TOKEN_PATH=testing/wandb-keys/wrong-length-token.txt $(IMAGE_NAME) echo OK | grep "ValueError: API key must be 40 characters long, yours was 10" ${ASSERT_COMMAND_SUCCEEDS}
	# correct env var was set => auth successful
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) -e NM_WANDB_TOKEN_PATH=/testing/wandb-keys/fake-token.txt $(IMAGE_NAME) echo OK | grep -Pz "(?s)${WANDB_SUCCESS_PATTERN}.+OK" ${ASSERT_COMMAND_SUCCEEDS}


.PHONY: test_output
test_output:
	# test that stdout is redirected to /tmp/output
	$(DOCKER_RUN) $(IMAGE_NAME) bash -c 'echo "stdout" && grep -q "stdout" /tmp/output' ${ASSERT_COMMAND_SUCCEEDS}
	# test that stderr is redirected to /tmp/output
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) $(IMAGE_NAME) bash -c 'echo "stderr" >&2 && grep -q "stderr" /tmp/output' ${ASSERT_COMMAND_SUCCEEDS}
	# test tqdm
	docker kill test-output | true
	$(DOCKER_RUN) --detach --name test-output ${IMAGE_NAME} python -u -c 'import time, tqdm; [(time.sleep(0.1), print(i)) for i in tqdm.tqdm(range(1000))]' \
		&& docker exec -it test-output bash -c 'tail -f /tmp/output | sed -n "/5%.*50/ {;p;q;}"' ${ASSERT_COMMAND_SUCCEEDS}
	docker kill test-output
