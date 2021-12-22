#
# After the remote EKS cluster creation is completed using Crossplane, do the following.
# 'kubeconfig-admin' file contains the KubeConfig data created by Crossplane when the remote cluster is provisioned.
# This can be obtained from the Secret 'crossplane-workload-cluster-connection' created in the 'flux-system' namespace by Crossplane.
# These credentials pertain to that of the cluster creator and has system:masters permissions in the EKS cluster and are rorated on a continual basis.
# Using this KubeConfig data, create a service account in the workload cluster
#
kubectl apply -f service-account-rbac.yaml --kubeconfig ./kubeconfig-admin

#
# After applying the above change, a service account named 'apprunner' is created in the 'applications' namespace of the remote cluster.
# The service account is configured to have 'cluster-admin' permissions in the EKS cluster.
# Next, create a file 'kubeconfig-sa' with the KubeConfig data to connect to the workload cluster using this service account's credentials.
# These credentials are not rotataed and are permanent.
#
cp kubeconfig-admin kubeconfig-sa
SERVICE_ACCOUNT_NAME=apprunner
SERVICE_ACCOUNT_NAMESPACE=applications
SERVICE_ACCOUNT_SECRET_NAME=$(kubectl -n $SERVICE_ACCOUNT_NAMESPACE get sa $SERVICE_ACCOUNT_NAME -o jsonpath='{.secrets[0].name}' --kubeconfig ./kubeconfig-admin)
SERVICE_ACCOUNT_TOKEN=$(kubectl -n $SERVICE_ACCOUNT_NAMESPACE get secret $SERVICE_ACCOUNT_SECRET_NAME -o jsonpath={.data.token} --kubeconfig ./kubeconfig-admin | base64 -d) 
kubectl config set-credentials $SERVICE_ACCOUNT_NAME --token=$SERVICE_ACCOUNT_TOKEN  --kubeconfig=./kubeconfig-sa
kubectl config set-context --current --user=$SERVICE_ACCOUNT_NAME --kubeconfig=./kubeconfig-sa

#
# Create a Secret named 'crossplane-workload-cluster-sa-connection' in the 'flux-system' namespace
# Reference this Secret in Kustomization/HelmRelease that are targeting deployments to the workload cluster
#
kubectl -n flux-system create secret generic crossplane-workload-cluster-sa-connection --from-file=value=./kubeconfig-sa
