          mountPath: /var/lib/cassandra
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: regional-pd-legacy # <-- THE FIX: Point to the new SC
      resources:
        requests:
          storage: 200Gi
EOF

kubectl describe pvc data-cassandra-0
# Delete the statefulset
kubectl delete statefulset cassandra
# Delete the stuck PVC
kubectl delete pvc data-cassandra-0
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
spec:
  serviceName: "cassandra"
  replicas: 2
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: app
        image: registry.k8s.io/google-samples/cassandra:v14
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /var/lib/cassandra
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: regional-pd-legacy # <-- Use the SC we created
      resources:
        requests:
          storage: 200Gi # <-- THE FIX: Changed from 10Gi
EOF

kubectl get pods -w
# Delete the stuck PVC
kubectl delete statefulset cassandra
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
spec:
  serviceName: "cassandra"
  replicas: 2
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: app
        image: gcr.io/google-samples/cassandra:v14 # <-- THE FIX
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /var/lib/cassandra
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: regional-pd-legacy
      resources:
        requests:
          storage: 200Gi
EOF

kubectl get pods -w
# 1. Get the current cluster version
VERSION=$(gcloud container clusters describe "case-5-cluster" \
    --region "us-central1" \
    --format="value(currentMasterVersion)")
# 2. Trigger the rolling upgrade
gcloud container clusters upgrade "case-5-cluster"     --node-pool "default-pool"     --region "us-central1"     --cluster-version "$VERSION"
echo $VERSION
VERSION=1.34.1-gke.1829001
echo $VERSION
gcloud container clusters upgrade "case-5-cluster"     --node-pool "default-pool"     --region "us-central1"     --cluster-version "$VERSION"
VERSION=1.32.9-gke.1072000
gcloud container clusters upgrade "case-5-cluster"     --node-pool "default-pool"     --region "us-central1"     --cluster-version "$VERSION"
gcloud auth login
kubectl get pods -w
gcloud container clusters upgrade "case-5-cluster"     --node-pool "default-pool"     --region "us-central1"     --cluster-version "$VERSION"
kubectl get nodes -w
kubectl describe pod cassandra-1
kubectl delete statefulset cassandra
gcloud auth login
kubectl delete statefulset cassandra
kubectl delete pvc data-cassandra-0 data-cassandra-1
kubectl delete sc regional-pd-legacy
gcloud container clusters delete "case-5-cluster" --region "us-central1"
gcloud container clusters create "network-policy-demo"     --enable-network-policy     --num-nodes=1
gcloud auth login
gcloud container clusters create "network-policy-demo"     --enable-network-policy     --num-nodes=1
gcloud container clusters create "network-policy-demo" --zone us-central1-a    --enable-network-policy     --num-nodes=1
kubectl create namespace frontend
kubectl create namespace backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
spec:
kubectl
gcloud auth login
kubectl create namespace backend-services
export PROJECT_ID="alpine-anvil-473102-c4"
export CLUSTER_ZONE="us-central1-c"
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $CLUSTER_ZONE
gcloud container clusters create "asm-demo-cluster"     --machine-type "e2-standard-4"     --num-nodes=2     --workload-pool="${PROJECT_ID}.svc.id.goog"
# This can take 5-10 minutes
gcloud container clusters get-credentials asm-demo-cluster
curl https://storage.googleapis.com/csm-artifacts/asm/asmcli -o asmcli
chmod +x asmcli
./asmcli install   --project_id $PROJECT_ID   --cluster_name asm-demo-cluster   --cluster_location $CLUSTER_ZONE   --platform gcp   --enable_all
# This installation will take several minutes.
kubectl create namespace backend-services
kubectl label namespace backend-services istio-injection=enabled
kubectl get namespace backend-services --show-labels
# NAME               STATUS   AGE   LABELS
# backend-services   Active   10s   istio-injection=enabled
kubectl apply -f backend-deploy.yaml
# Wait for the deployment to finish
kubectl rollout status deployment/critical-backend -n backend-services
kubectl get pods -n backend-services
# NAME                                READY   STATUS    RESTARTS   AGE
# critical-backend-7f8b5f...-abcde   2/2     Running   0          60s
# critical-backend-7f8b5f...-fghij   2/2     Running   0          60s
# critical-backend-7f8b5f...-klmno   2/2     Running   0          60s
# Get the name of one pod
POD_NAME=$(kubectl get pods -n backend-services -o jsonpath='{.items[0].metadata.name}')
# Describe it
kubectl describe pod $POD_NAME -n backend-services
# ...scroll down to "Containers:"...
# You will see two containers:
# 1. "app" (your nginx container)
# 2. "istio-proxy" (the injected, resource-heavy sidecar)
kubectl top pods -n backend-services
# NAME                                CPU(cores)   MEMORY(bytes)
# critical-backend-7f8b5f...-abcde   115m         142Mi
# critical-backend-7f8b5f...-fghij   109m         139Mi
# critical-backend-7f8b5f...-klmno   112m         141Mi
kubectl label namespace backend-services istio-injection-
kubectl rollout restart deployment/critical-backend -n backend-services
# Pods are now 1/1
kubectl get pods -n backend-services
# NAME                                READY   STATUS    RESTARTS   AGE
# critical-backend-8c9d6g...-vwxyz   1/1     Running   0          25s
# ...
# Resource usage is back to normal
kubectl top pods -n backend-services
# NAME                                CPU(cores)   MEMORY(bytes)
# critical-backend-8c9d6g...-vwxyz   1m           10Mi
# ...
gcloud container clusters delete "network-policy-demo"     --zone "us-central1-c"     --quiet
gcloud container clusters delete "asm-demo-cluster"     --zone "us-central1-c"     --quiet
ls
gcloud auth login
4/0Ab32j91moiMBHhb0f3SKm_O3HTUgolWHT6WX6fEJH_3nmJhA68J3qKGq0_7BWi2vBUIVlggc
gcloud list services
gcloud services list
gcloud services enable compute.googleapis.com, container.googleapis.com, sqladmin.googleapis.com, redis.googleapis.com, secretmanager.googleapis.com, artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com container.googleapis.com sqladmin.googleapis.com redis.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com
teraform
terraform
terraform init
terraform -version
terraform update
terraform state
gcloud auth application-default login
git clone https://github.com/terraform-google-modules/terraform-docs-samples.git --single-branch
cd terraform-docs-samples/storage/remote_terraform_backend_template
ls
terraform init
terraform apply
terraform init -migrate-state
ls
cd ~
vim provider.tf
dig +short myip.opendns.com @resolver1.opendns.com
vim variables.tf
vim vpc.tf
vim networking.tf
vim gke.tf
vim gke-nodepools.tf
terraform init
terraform plan
vim gke.tf
terraform plan
terraform init -upgrade
terraform plan
terraform init -upgrade
terraform plan
terraform init
terraform plan
terraform init
terraform plan
terraform init
terraform plan
terraform init
terraform plan
terraform apply 
terraform plan
gcloud auth application-default login
terraform plan
gcloud auth login
terraform init
terraform plan
gcloud auth application-default login
terraform init
terraform plan
# This is the main one from your error
gcloud services enable cloudresourcemanager.googleapis.com --project=alpine-anvil-473102-c4
# This one is for the service usage API
gcloud services enable serviceusage.googleapis.com --project=alpine-anvil-473102-c4
# This one is for the VPC Peering
gcloud services enable servicenetworking.googleapis.com --project=alpine-anvil-473102-c4
terraform plan
terraform apply
terraform plan
terraform init
terraform plan
terraform init
terraform plan
terraform apply
gcloud auth application-default login
terraform apply
terraform init
terraform apply
gcloud auth application-default login
terraform apply
terraform init
terraform apply
terraform init
terraform apply
terraform init
terraform apply
terraform init
terraform apply
terraform init
terraform apply
terraform init
terraform apply
ls
la
ls
ls -a
cd .github
ls
cd workflows
ls
cat gke-deploy.yaml
cd ~
mv git-hub-workflow.yaml .github/workflows
cd .github/workflows
ls
rm gke-deply.yaml
rm gke-deploy.yaml
ls
cd ~
cd .git
ls
cd ~
git commit -m "Admin: Remove old, unused CI/CD workflow"
# 1. Stage the new .gitignore file
git add .gitignore
# 2. Stage the DELETION of the old workflow.
# (This tells git to track the deletion you performed with 'rm')
git rm .github/workflows/gke-deploy.yaml
# 3. Stage the ADDITION of your new workflow
# (I'm using the name from your 'mv' command)
git add .github/workflows/git-hub-workflow.yaml
# 4. (Optional but recommended) Check your work.
# This should now show a clean list of 3 files:
# new file:    .gitignore
# deleted:     .github/workflows/gke-deploy.yaml
# new file:    .github/workflows/git-hub-workflow.yaml
git status
# 5. Now, commit your staged changes
git commit -m "Admin: Add .gitignore, remove old workflow, add new workflow"
# 6. Finally, push to GitHub
git push origin main
ls
ls -a
vim .gitignore
git commit -m "Update GitHub workflow files"
# This command forces Git to stop tracking all the cache/log folders
git rm -r --cached .cache .codeoss .docker .npm .kube .ssh
# This command removes the individual log/history files
git rm --cached .bash_history .gke.tf.swp .viminfo .gitconfig .terraform.lock.hcl *.tfstate *.tfstate.backup
git add .gitignore
git commit -m "Admin: Add .gitignore and remove local tracked files"
git push origin master
git remote -v
# Make sure this is the correct repository name from your cicd.tf file
git remote set-url origin git@github.com:gandinehru35-spec/secure-bank.git
git push origin master
vim .github/workflows/git-hub-workflow.yaml
# 1. Stage the corrected workflow file
git add .github/workflows/git-hub-workflow.yaml
# 2. Commit the fix
git commit -m "Fix: Correct the GitHub Actions workflow file"
# 3. Push to your repository
git push origin master
This will trigger the workflow again, and this time it should run correctly.
# 1. Stage the corrected workflow file
git add .github/workflows/git-hub-workflow.yaml
# 2. Commit the fix
git commit -m "Fix: Correct paths in GitHub Actions workflow"
# 3. Push to your repository (this will trigger the Action)
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
terraform apply
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Fix: Correct paths in GitHub Actions workflow"
git push origin master
ls
cd helm
cd ~
# 1. Add the 'helm' directory to Git's tracking
git add helm/
# 2. Commit this new directory
git commit -m "Add helm chart directory for auth-service"
# 3. Push the new commit to GitHub
git push origin master
tree
ls tree
ls --tree
ls --help
ls -d
ls
apt-get tree
apt get tree
apt install tree
sudo apt install tree
tree
cd tree
ls
tree --help
tree -d
tree
# 1. Rename your Chart.yaml file
mv ~/helm/Helm-chart.yaml ~/helm/Chart.yaml
# 2. Rename your Kubernetes Service Account (KSA) file
mv ~/helm/templates/Helm-KSA.yaml ~/helm/templates/serviceaccount.yaml
# 3. Rename your SecretProviderClass file
mv ~/helm/templates/Helm-Secretprovider.yaml ~/helm/templates/secretproviderclass.yaml
# 4. Rename your Service file
mv ~/helm/templates/Helm-Service.yaml ~/helm/templates/service.yaml
# 5. Rename your Deployment file (and add the .yaml extension)
mv ~/helm/templates/Helm-deployment ~/helm/templates/deployment.yaml
# 6. (Optional but good practice) Helm expects a values.yaml file, 
#    but yours is Helm-values.yaml. Let's fix that too.
mv ~/helm/Helm-values.yaml ~/helm/values.yaml
# 1. Add all the file changes (renames) to Git
git add .
# 2. Commit the renames
git commit -m "Fix: Rename Helm chart files to match standard conventions"
# 3. Push to your repository
git push origin master
git add .
git commit -m "Fix: Rename Helm chart files to match standard conventions"
git push origin master
# 1. Stage the corrected requirements file
git add auth-service/requirements.txt
# 2. Commit the fix
git commit -m "Fix: Correct formatting in requirements.txt"
# 3. Push to your repository
git push origin master
This will trigger the workflow again, and the `pip install` command will now succeed.
git add auth-service/requirements.txt
git commit -m "Fix: Correct formatting in requirements.txt"
git add .
git commit -m "Fix: Correct formatting in requirements.txt"
git push origin master
# 1. Stage the corrected requirements file
git add auth-service/requirements.txt
# 2. Commit the fix
git commit -m "Fix: Correct formatting in requirements.txt (for real)"
# 3. Push to your repository
git push origin master
terraform apply
gcloud auth application-default login
terraform apply
kubectl get pods
gcloud container clusters get-credentials gke-securebank-prod --region us-central1 --project alpine-anvil-473102-c4
kubectl get pods --namespace default
gcloud auth application-default login --remote-bootstrap="https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com&scope=openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fsqlservice.login&state=qi0A0gucf5IrqzQsHEsGb1EzV3IpaI&access_type=offline&code_challenge=PTJ9ofVN9EfwhauNVdOnGVOysmu2vZql-wwLnZOZAA4&code_challenge_method=S256&token_usage=remote"
gcloud container clusters get-credentials gke-securebank-prod --region us-central1 --project alpine-anvil-473102-c4
kubectl get pods
gcloud auth application-default login
terraform apply
gcloud auth application-default login
terraform apply
gcloud auth login
terraform apply
gcloud auth application-default login
terraform apply
gcloud auth application-default login
terraform apply
gcloud auth list
gcloud auth login 
gcloud auth list
gcloud auth application-default login
gcloud auth list
terraform apply
gcloud auth list
terraform apply
gcloud auth list
terraform apply
# 1. Add all the file changes in the helm directory
git add helm/
# 2. Commit the fix
git commit -m "Fix: Update Helm chart to use new secrets.gke.io driver"
# 3. Push to your repository
git push origin master
This will trigger your GitHub Actions workflow, and this time the deployment will succeed.
git add helm/
git commit -m "Fix: Update Helm chart to use new secrets.gke.io driver"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Final Fix: Manual CRD deploy and corrected network management"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Final Fix: Corrected Secret Manager CRD Links"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Final Fix: Corrected Secret Manager CRD Links"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Definitive Fix: Install CSI Driver via Helm Repo (Stable)"
git push origin master
terraform apply
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Definitive Fix: Install CSI Driver via Helm Repo (Stable)"
git push origin master
git add .github/workflows/git-hub-workflow.yaml
git commit -m "Definitive Fix: Use stable K8s CSI CRDs via kubectl apply"
git push origin master
git add helm/
git commit -m "Final Fix: Aligned Deployment and SecretProviderClass with GKE native driver"
git push origin master
git add helm/
git commit -m "Final FIX: Align deployment with GKE native driver after CRD installation"
git push origin master
git add helm/
git commit -m "Final FIX: Align deployment with GKE native driver after CRD installation"
git push origin master
curl -sL https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/deploy/rbac-crds/secrets-store.csi.x-k8s.io_secretproviderclasses.yaml > ./helm/templates/secrets-crds.yaml
# 1. Add all the file changes in the helm directory
git add helm/
# 2. Commit the fix
git commit -m "Final FIX: Verified and pushed GKE-native driver names"
# 3. Push to your repository
git push origin master
curl -sL https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/main/deployment/cluster-role-binding.yaml > ./helm/templates/secrets-rbac.yaml
git add helm/
git commit -m "Final FIX: Verified and pushed GKE-native driver names"
git push origin master
git add /helm
ls
git add .
git commit -m "Final FIX: Verified and pushed GKE-native driver names"
git push origin master
# Delete the old, incomplete file
rm ./helm/templates/secrets-crds.yaml
# Download the complete, self-contained CRD manifest
curl -sL https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/charts/secrets-store-csi-driver/crds/secrets-store.csi.x-k8s.io_secretproviderclasses.yaml > ./helm/templates/secrets-crds.yaml
git add .
git commit -m "Final FIX: Using correct local CRD manifest file for installation"
git push origin master
# 1. DELETE the bad RBAC file
rm ./helm/templates/secrets-rbac.yaml
# 2. RUN this command to install the missing RBAC elements directly 
#    This command is guaranteed to be stable and complete.
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/main/deployment/provider-gcp-cluster-role.yaml
# Delete the old, bad RBAC file first
rm ./helm/templates/secrets-rbac.yaml
# Download the content of the correct ClusterRoleBinding file locally
curl -sL https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/main/deployment/cluster-role-binding.yaml > ./helm/templates/secrets-rbac.yaml
# 1. Add both the CRD file (if changed) and the new RBAC file
git add ./helm/templates/secrets-rbac.yaml
git add ./helm/templates/secrets-crds.yaml
# 2. Commit the fix
git commit -m "Final Fix: Using local RBAC files to guarantee installation"
# 3. Push to your repository
git push origin master
