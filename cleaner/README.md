# Insight Cleaner For Google Cloud Platform

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
3. Create a service account for Insight Cleaner
```
gcloud iam service-accounts create cloud-run-insight-cleaner \
     --display-name "Cloud Run Insight Cleaner"
```
4. Add Roles to the created service account
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:cloud-run-insight-cleaner@${PROJECT_ID}.iam.gserviceaccount.com \
	--role=roles/pubsub.publisher
```
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:cloud-run-insight-cleaner@${PROJECT_ID}.iam.gserviceaccount.com \
	--role=roles/datastore.user
```
```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:cloud-run-insight-cleaner@${PROJECT_ID}.iam.gserviceaccount.com \
	--role=roles/storage.objectAdmin
```
### Deployment of Cloud Run
1. Clone the repo 
```
git clone https://github.com/X-I-A/Insight_cleaner_gcp
```
2. Go to the downloaded directory 
```
cd Insight_cleaner_gcp
```
3. Build the solution
```
gcloud builds submit --tag gcr.io/${PROJECT_ID}/insight-cleaner
```
4. Deploy the solution with created service account and provide user / password
```
gcloud run deploy insight-cleaner --image gcr.io/${PROJECT_ID}/insight-cleaner \
    --service-account cloud-run-insight-cleaner@${PROJECT_ID}.iam.gserviceaccount.com \
	--region ${REGION_NAME} --platform managed --no-allow-unauthenticated
```
### Pub/Sub Integration
1. Bind the role to the cleaner service  
```
gcloud run services add-iam-policy-binding insight-cleaner \
   --member=serviceAccount:cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com \
   --role=roles/run.invoker --region ${REGION_NAME} --platform managed
```
2. Create a subscription with the end point
```
gcloud pubsub subscriptions create insight-cleaner-agent --topic insight-cleaner \
   --push-endpoint=https://insight-cleaner-${CLOUD_RUN_DOMAIN} --min-retry-delay=10 \
   --push-auth-service-account=cloud-run-pubsub-invoker@${PROJECT_ID}.iam.gserviceaccount.com
```