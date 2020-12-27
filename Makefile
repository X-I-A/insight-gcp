SHELL:=/bin/bash

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

config: ## Setting deploy configuration
	@TMP_PROJECT=$(shell gcloud config list --format 'value(core.project)'); \
	read -e -p "Enter Your Project Name: " -i $${TMP_PROJECT} PROJECT_ID; \
	gcloud config set project $${PROJECT_ID}; \
	read -e -p "Enter Desired Cloud Run Region: " -i 'europe-west1' CLOUD_RUN_REGION; \
	gcloud config set run/region $${CLOUD_RUN_REGION}; \
	read -e -p "Enter Desired Cloud Run Platform: " -i 'managed' CLOUD_RUN_PLATFORM; \
	gcloud config set run/platform $${CLOUD_RUN_PLATFORM};

init: init-users ## Activation of API, creation of service account with roles

build: build-receiver build-cleaner build-linker build-merger build-packager build-loader ## Build all Cloud Run Image

deploy: deploy-receiver deploy-cleaner deploy-linker deploy-merger deploy-packager deploy-loader ## Deploy Cloud Run Image by using the last built image

init-users: ## Create Cloud Run needed users
	@TMP_PROJECT=$(shell gcloud config list --format 'value(core.project)'); \
	read -e -p "Enter Your Project Name: " -i $${TMP_PROJECT} PROJECT_ID; \
	gcloud config set project $${PROJECT_ID}; \
	PROJECT_NUMBER=$(shell gcloud projects list --filter=$(shell gcloud config list --format 'value(core.project)') --format="value(PROJECT_NUMBER)"); \
	gcloud iam service-accounts create cloud-run-pubsub-invoker \
 		--display-name "Cloud Run Pub/Sub Invoker"; \
	gcloud iam service-accounts create cloud-run-insight-receiver \
		--display-name "Cloud Run Insight Receiver"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-receiver@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-receiver@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/datastore.user; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-receiver@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/logging.logWriter;
	gcloud iam service-accounts create cloud-run-insight-cleaner \
		--display-name "Cloud Run Insight Cleaner"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-cleaner@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-cleaner@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/datastore.user; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-cleaner@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/storage.objectAdmin; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-cleaner@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/logging.logWriter;
	gcloud iam service-accounts create cloud-run-insight-linker \
		--display-name "Cloud Run Insight Linker"; \
	gcloud iam service-accounts create cloud-run-insight-merger \
		--display-name "Cloud Run Insight Merger"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-merger@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-merger@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/datastore.user; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-merger@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/logging.logWriter;
	gcloud iam service-accounts create cloud-run-insight-packager \
		--display-name "Cloud Run Insight Packager"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-packager@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-packager@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/datastore.user; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-packager@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/storage.objectAdmin; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-packager@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/logging.logWriter;
	gcloud iam service-accounts create cloud-run-insight-loader \
		--display-name "Cloud Run Insight Loader"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-loader@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-loader@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/datastore.user; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-loader@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/storage.objectAdmin; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-loader@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/logging.logWriter;
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:service-$${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com \
		--role=roles/iam.serviceAccountTokenCreator

build-receiver: ## Build receiver and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd receiver; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-receiver;

build-cleaner: ## Build cleaner and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd cleaner; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-cleaner;

build-linker: ## Build linker and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd linker; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-linker;

build-merger: ## Build merger and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd merger; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-merger;

build-packager: ## Build packager and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd packager; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-packager;

build-loader: ## Build loader and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd loader; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-loader;

deploy-receiver: ## Deploy a receiver from last built image
	@RECEIVER_ID="000"; \
	PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy insight-receiver-$${RECEIVER_ID} \
		--image gcr.io/$${PROJECT_ID}/insight-receiver \
    	--service-account cloud-run-insight-receiver@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM} \
		--no-allow-unauthenticated; \
	gcloud run services add-iam-policy-binding insight-receiver-$${RECEIVER_ID} \
		--member=serviceAccount:cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM};

deploy-cleaner: ## Deploy a cleaner from last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy insight-cleaner \
		--image gcr.io/$${PROJECT_ID}/insight-cleaner \
    	--service-account cloud-run-insight-cleaner@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM} \
		--no-allow-unauthenticated; \
	gcloud run services add-iam-policy-binding insight-cleaner \
		--member=serviceAccount:cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM};

deploy-linker: ## Deploy a linker from last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy insight-linker \
		--image gcr.io/$${PROJECT_ID}/insight-linker \
    	--service-account cloud-run-insight-linker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM} \
		--no-allow-unauthenticated; \
	gcloud run services add-iam-policy-binding insight-linker \
		--member=serviceAccount:cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM};

deploy-merger: ## Deploy a merger from last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy insight-merger \
		--image gcr.io/$${PROJECT_ID}/insight-merger \
    	--service-account cloud-run-insight-merger@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM} \
		--no-allow-unauthenticated; \
	gcloud run services add-iam-policy-binding insight-merger \
		--member=serviceAccount:cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM};

deploy-packager: ## Deploy a packager from last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy insight-packager \
		--image gcr.io/$${PROJECT_ID}/insight-packager \
    	--service-account cloud-run-insight-packager@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM} \
		--no-allow-unauthenticated \
		--memory=1Gi; \
	gcloud run services add-iam-policy-binding insight-packager \
		--member=serviceAccount:cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM};

deploy-loader: ## Deploy a loader from last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLOUD_RUN_REGION=$(shell gcloud config list --format 'value(run.region)'); \
	CLOUD_RUN_PLATFORM=$(shell gcloud config list --format 'value(run.platform)'); \
	gcloud run deploy insight-loader \
		--image gcr.io/$${PROJECT_ID}/insight-loader \
    	--service-account cloud-run-insight-loader@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM} \
		--no-allow-unauthenticated \
		--max-instances=1 \
		--concurrency=1 \
		--memory=512Mi; \
	gcloud run services add-iam-policy-binding insight-loader \
		--member=serviceAccount:cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/run.invoker \
		--region $${CLOUD_RUN_REGION} \
		--platform $${CLOUD_RUN_PLATFORM};

deploy-channel: ## Deployer internal channel topics and attach them to related services
	gcloud pubsub topics create insight-cleaner;
	gcloud pubsub subscriptions create insight-cleaner-debug --topic=insight-cleaner;
	PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	CLEANER_URL=$(shell gcloud run services list --platform managed --filter="insight-cleaner" --format="value(URL)"); \
	gcloud pubsub subscriptions create insight-cleaner-agent --topic insight-cleaner \
		--push-endpoint=$${CLEANER_URL} \
		--ack-deadline=600 \
		--min-retry-delay=10 \
		--push-auth-service-account=cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com;
	gcloud pubsub topics create insight-merger;
	gcloud pubsub subscriptions create insight-merger-debug --topic=insight-merger;
	PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	MERGER_URL=$(shell gcloud run services list --platform managed --filter="insight-merger" --format="value(URL)"); \
	gcloud pubsub subscriptions create insight-merger-agent --topic insight-merger \
		--push-endpoint=$${MERGER_URL} \
		--ack-deadline=600 \
		--min-retry-delay=10 \
		--push-auth-service-account=cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com;
	gcloud pubsub topics create insight-packager;
	gcloud pubsub subscriptions create insight-packager-debug --topic=insight-packager;
	PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	PACKAGER_URL=$(shell gcloud run services list --platform managed --filter="insight-packager" --format="value(URL)"); \
	gcloud pubsub subscriptions create insight-packager-agent --topic insight-packager \
		--push-endpoint=$${PACKAGER_URL} \
		--ack-deadline=600 \
		--min-retry-delay=10 \
		--push-auth-service-account=cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com;
	gcloud pubsub topics create insight-loader;
	gcloud pubsub subscriptions create insight-loader-debug --topic=insight-loader;
	PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	LOADER_URL=$(shell gcloud run services list --platform managed --filter="insight-loader" --format="value(URL)"); \
	gcloud pubsub subscriptions create insight-loader-agent --topic insight-loader \
		--push-endpoint=$${LOADER_URL} \
		--ack-deadline=600 \
		--min-retry-delay=10 \
		--push-auth-service-account=cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com;
	gcloud pubsub topics create insight-backlog;
	gcloud pubsub subscriptions create insight-backlog-debug --topic=insight-backlog;
	gcloud pubsub topics create insight-cockpit;
	gcloud pubsub subscriptions create insight-cockpit-debug --topic=insight-cockpit;

create-topic: ## Create a topic
	@read -e -p "Enter desired topic name: " -i "dummy" TOPIC_ID; \
	read -e -p "Enter Desired Bucket Location: " -i "europe-west1" BUCKET_REGION; \
	PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	RECEIVER_URL=$(shell gcloud run services list --platform managed --filter="insight-receiver-000" --format="value(URL)");\
	gcloud firestore indexes composite create \
		--collection-group=slt-npl-01 \
		--field-config=field-path=table_id,order=ascending \
		--field-config=field-path=filter_key,order=ascending \
		--field-config=field-path=sort_key,order=ascending \
		--asyn; \
	gcloud firestore indexes composite create \
		--collection-group=slt-npl-01 \
		--field-config=field-path=table_id,order=ascending \
		--field-config=field-path=filter_key,order=ascending \
		--field-config=field-path=sort_key,order=descending \
		--asyn; \
	gcloud firestore indexes fields update data \
		--collection-group=slt-npl-01 \
		--disable-indexes \
		--asyn; \
	gsutil mb gs://$${PROJECT_ID}-$${TOPIC_ID}/ -l $${BUCKET_REGION}
	gcloud pubsub topics create $${TOPIC_ID}; \
	gcloud pubsub subscriptions create $${TOPIC_ID}-receiver --topic $${TOPIC_ID} \
		--push-endpoint=$${RECEIVER_URL} \
		--ack-deadline=600 \
		--min-retry-delay=10 \
		--push-auth-service-account=cloud-run-pubsub-invoker@$${PROJECT_ID}.iam.gserviceaccount.com; \

