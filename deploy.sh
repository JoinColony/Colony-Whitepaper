echo $GCLOUD_SERVICE_KEY | base64 --decode > ${HOME}/gcloud-service-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json
gcloud config set project $PROJECT_NAME
gcloud --quiet config set container/cluster $CLUSTER_NAME
gcloud config set compute/zone ${CLOUDSDK_COMPUTE_ZONE}
gcloud --quiet container clusters get-credentials $CLUSTER_NAME

chown -R root:root /root/.kube
export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/gcloud-service-key.json

kubectl create secret generic whitepaper --from-file /tmp/workspace/main.pdf --dry-run -o yaml | kubectl replace -f -

