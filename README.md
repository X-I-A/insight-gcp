[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) 
[![codecov](https://codecov.io/gh/X-I-A/insight-gcp/branch/master/graph/badge.svg)](https://codecov.io/gh/X-I-A/insight-gcp) 
[![master-check](https://github.com/x-i-a/insight-gcp/workflows/master-check/badge.svg)](https://github.com/X-I-A/insight-gcp/actions?query=workflow%3Amaster-check) 
# Insight Module For Google Cloud Platform

## Quick Start Guide
Download the source code:
```
git clone https://github.com/X-I-A/insight-gcp
cd insight-gcp
```
Please using Google Cloud Console or have Google Cloud SDK installed
1. `make config` Setting project id, cloud run region and cloud run platform
2. `make init` **Only Once per project** Activation of API, creation of service account with roles
3. `make build` Build and upload Cloud Run Images
4. `make deploy` Deploy Cloud Run Image by using the last built image
5. `make deploy-channel` Deploy different internal channels and link them to the deployed cloud run services

Now you can create topics by using the following command
* `make create-topic`
