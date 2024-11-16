Apolo Platform Base Image
====================

Base docker image used in [Apolo Platform Template](https://github.com/neuro-inc/flow-template), deployed on GitHub as [`ghcr.io/neuro-inc/base`](https://github.com/orgs/neuro-inc/packages/container/package/base).

Versions
---
- `python`: the list of python modules and their versions could be found in the [requirements](./requirements) folder.
- `system`: the list of APK packages might be found in the [Dockerfile](./Dockerfile).

Notes
-----
1. This image is designed for [Apolo Platform](https://apolo.us) only. Running it on public machine might be insecure.
2. Setting environment variable `EXPOSE_SSH` enables SSH server with root account without password. This is safe to do within [Apolo Platform](https://apolo.us), but very dangerous otherwise.

License
-------
This project is licensed under the terms of the [Apache License](/LICENSE)

Additional info
---------------
For more details, see [Apolo Platform documentation](https://docs.apolo.us/index).
