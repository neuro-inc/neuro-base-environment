Neuro Platform Base Image
====================

Base docker image used in [Neuro Platform Template](https://github.com/neuromation/cookiecutter-neuro-project/), deployed on GitHub as [`ghcr.io/neuro-inc/base`](https://github.com/orgs/neuro-inc/packages/container/package/base).

Versions
---
- `python`: the list of python modules and their versions could be found in the [requirements](./requirements) folder.
- `system`: the list of APK packages might be found in the [Dockerfile](./Dockerfile).

Notes
-----
1. This image is designed for [Neuro Platform](https://neu.ro/platform) only. Running it on public machine might be insecure.
2. Setting environment variable `EXPOSE_SSH` enables SSH server with root account without password. This is safe to do within [Neuro Platform](https://neu.ro/platform), but very dangerous otherwise.

License
-------
This project is licensed under the terms of the [Apache License](/LICENSE)

Additional info
---------------
For more details, see [Neuro Platform documentation](https://docs.neu.ro).
