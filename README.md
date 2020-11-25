[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) 
[![codecov](https://codecov.io/gh/X-I-A/insight-gcp/branch/master/graph/badge.svg)](https://codecov.io/gh/X-I-A/insight-gcp) 
[![master-check](https://github.com/x-i-a/insight-gcp/workflows/master-check/badge.svg)](https://github.com/X-I-A/insight-gcp/actions?query=workflow%3Amaster-check) 
# Insight Receiver For Google Cloud Platform

## Quick Start Guide
### Preparation

### Service Account Preparation
1. Enable Pub/Sub to create token
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
     --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com \
     --role=roles/iam.serviceAccountTokenCreator
```
2. Create a service account for pubsub
```
gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"
```
3. Create a service account for Insight Receiver
```
gcloud iam service-accounts create cloud-run-insight-receiver \
     --display-name "Cloud Run Insight Receiver"
```
4. Add Roles to the created service account
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:cloud-run-insight-receiver@${PROJECT_ID}.iam.gserviceaccount.com \
	--role=roles/pubsub.publisher
```
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:cloud-run-insight-receiver@${PROJECT_ID}.iam.gserviceaccount.com \
	--role=roles/datastore.user
```
### Deployment of Cloud Run
1. Clone the repo 
```
git clone https://github.com/X-I-A/Insight_receiver_gcp
```
2. Go to the downloaded directory 
```
cd Insight_receiver_gcp
```
3. Build the solution
```
gcloud builds submit --tag gcr.io/${PROJECT_ID}/insight-receiver
```
4. Deploy the solution with created service account and provide user / password
```
gcloud run deploy insight-receiver --image gcr.io/${PROJECT_ID}/insight-receiver \
    --service-account cloud-run-insight-receiver@${PROJECT_ID}.iam.gserviceaccount.com \
	--region ${REGION_NAME} --platform managed --no-allow-unauthenticated
```
### Pub/Sub Integration
1. Bind the role to the receiver service  
```
gcloud run services add-iam-policy-binding insight-receiver \
   --member=serviceAccount:cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
   --role=roles/run.invoker --region ${REGION_NAME} --platform managed
```
2. Create a subscription with the end point
```
gcloud pubsub subscriptions create ${TOPIC_ID}-receiver --topic ${TOPIC_ID} \
   --push-endpoint=https://insight-receiver-${CLOUD_RUN_DOMAIN}/topics/${TOPIC_ID} --min-retry-delay=10 \
   --push-auth-service-account=cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com
```