SHELL:=/bin/bash

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Activation of API, creation of service account with roles
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-xeed-http@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher

build: ## Build and upload Cloud Run Image
	@TMP_PROJECT=$(shell gcloud config list --format 'value(core.project)'); \
	read -e -p "Enter Your Project Name: " -i $${TMP_PROJECT} PROJECT_ID; \
	gcloud config set project $${PROJECT_ID}; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/xeed-http-gcr;

deploy: ## Deploy Cloud Run Image by using the last built image
	@TMP_PROJECT=$(shell gcloud config list --format 'value(core.project)'); \
	read -e -p "Enter Your Project Name: " -i $${TMP_PROJECT} PROJECT_ID; \
	gcloud config set project $${PROJECT_ID}; \
	read -e -p "Enter Desired Cloud Run Region: " -i "europe-west1" CLOUD_RUN_REGION; \
	read -e -p "Enter Desired Username: " -i "user" XEED_USER; \
	read -e -p "Enter Desired Password: " -i "La_vie_est_belle" XEED_PASSWORD; \
	gcloud run deploy xeed-http \
		--image gcr.io/$${PROJECT_ID}/xeed-http-gcr \
    	--service-account cloud-run-xeed-http@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform managed \
		--allow-unauthenticated \
		--update-env-vars XEED_USER=$${XEED_USER},XEED_PASSWORD=$${XEED_PASSWORD};

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
	gcloud iam service-accounts create cloud-run-insight-merger \
		--display-name "Cloud Run Insight Merger"; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-merger@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/pubsub.publisher; \
	gcloud projects add-iam-policy-binding $${PROJECT_ID} \
		--member=serviceAccount:cloud-run-insight-merger@$${PROJECT_ID}.iam.gserviceaccount.com \
		--role=roles/datastore.user; \
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
		--member=serviceAccount:service-$${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com \
		--role=roles/iam.serviceAccountTokenCreator

init-topics: ## Create internal channel topics
	gcloud pubsub topics create insight-cleaner;
	gcloud pubsub subscriptions create insight-cleaner-debug --topic=insight-cleaner;
	gcloud pubsub topics create insight-merger;
	gcloud pubsub subscriptions create insight-merger-debug --topic=insight-merger;
	gcloud pubsub topics create insight-packager;
	gcloud pubsub subscriptions create insight-packager-debug --topic=insight-packager;
	gcloud pubsub topics create insight-loader;
	gcloud pubsub subscriptions create insight-loader-debug --topic=insight-loader;
	gcloud pubsub topics create insight-backlog;
	gcloud pubsub subscriptions create insight-backlog-debug --topic=insight-backlog;
	gcloud pubsub topics create insight-cockpit;
	gcloud pubsub subscriptions create insight-cockpit-debug --topic=insight-cockpit;

build-receiver: ## Build receiver and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd receiver; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-receiver;

build-cleaner: ## Build cleaner and upload Cloud Run Image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	cd cleaner; \
	gcloud builds submit --tag gcr.io/$${PROJECT_ID}/insight-cleaner;

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

build-receiver: ## Deploy Cloud Run Insight Receiver by using the last built image
	@PROJECT_ID=$(shell gcloud config list --format 'value(core.project)'); \
	read -e -p "Enter Desired Cloud Run Region: " -i "europe-west1" CLOUD_RUN_REGION; \
	gcloud run deploy xeed-http \
		--image gcr.io/$${PROJECT_ID}/insight-receiver \
    	--service-account cloud-run-insight-receiver@$${PROJECT_ID}.iam.gserviceaccount.com \
		--region $${CLOUD_RUN_REGION} \
		--platform managed \
		--no-allow-unauthenticated  \
		--update-env-vars XEED_USER=$${XEED_USER},XEED_PASSWORD=$${XEED_PASSWORD};

deploy-receiver:
