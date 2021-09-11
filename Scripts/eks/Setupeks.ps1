# https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
# choco install -y eksctl 
eksctl version 

#https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html#
aws --version 
aws configure 
aws ec2 create-key-pair --region us-west-2 --key-name uswest2keypair --key-name uswest2keypair  --output text > uswest2keypair.pem
# make sure file is LF and not CRLF and starts -----BEGIN RSA PRIVATE KEY----- ends -----END RSA PRIVATE KEY----- and then new line
# to get punlic key - ssh-keygen -y -f uswest2keypair.pem

#add to yaml file as required
$clustername = 'ben-eks-cluster'
$region = 'us-west-2'
$publickey = 'uswest2keypair'

eksctl create cluster -f eks.yaml

$location = 'eastus' # location of resource group
$resourceGroup = 'beardarc' # name of the already created resource group

$eksConnectedClusterName = 'ben-eks-connected-cluster' # the name of the connected AKS Cluster
$customLocation  = 'ben-eks-cluster-location' # The name for the custom location

# I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
# You will need to change this for your own environment
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$subscription_id = New-Object System.Management.Automation.PSCredential ('subscription-id', (Get-Secret -Name subscription-id))
$ENV:SUBSCRIPTION = "$($subscription_id.GetNetworkCredential().Password)"
$subscription = $ENV:SUBSCRIPTION

<# 
# if you do not store them in secrets management use this
$admincredentials = New-Object System.Management.Automation.PSCredential ('username here ', (ConvertTo-SecureString -String 'password here' -AsPlainText))
$ENV:SUBSCRIPTION = ''
$subscription = $ENV:SUBSCRIPTION
#>
$ENV:ACCEPT_EULA = 'yes'
$ENV:AZDATA_USERNAME="$($admincredentials.UserName)"
$ENV:AZDATA_PASSWORD="$($admincredentials.GetNetworkCredential().Password)"


# set the context

# if it has gone screwy you can update it with aws eks update-kubeconfig --name  ben-eks-cluster
# eksctl utils write-kubeconfig --cluster=<name> [--kubeconfig=<path>][--set-kubeconfig-context=<bool>]

kubectl config use-context arn:aws:eks:us-west-2:933732381823:cluster/ben-eks-cluster

kubectl cluster-info
kubectl config current-context

# check the nodes are running
kubectl get nodes

# add and/or update the required az cli extensions
az extension add --name connectedk8s
az extension add --name k8s-extension
az extension add --name customlocation
az extension add --name arcdata
az extension update --name connectedk8s
az extension update --name k8s-extension
az extension update --name customlocation
az extension update --name arcdata

# onboard a connected kubernetes cluster to Azure
# https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-agent-architecture
# https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli
az connectedk8s connect --name $eksConnectedClusterName  --resource-group $resourceGroup --location $location

# check the onboarded clusters
az connectedk8s list --resource-group $resourceGroup --output table

# look at the kubernetes resources for the onboarded cluster
kubectl get deployments,pods -n azure-arc

# enable the required features
az connectedk8s enable-features -n $eksConnectedClusterName -g $resourceGroup --features cluster-connect custom-locations

# create the custom location extension
az k8s-extension create --name $customLocation --extension-type microsoft.arcdataservices --cluster-type connectedClusters `
    -c $eksConnectedClusterName -g $resourceGroup --scope cluster --release-namespace arc --config Microsoft.CustomLocation.ServiceAccount=sa-bootstrapper `
         --auto-upgrade false

# now we have to wait for it to be ready. Run this command until the custom location is installed
az k8s-extension show --name $customLocation --cluster-type connectedClusters -c $eksConnectedClusterName -g $resourceGroup  -o table

# check the arc namespace for the pods - now we will see the bootstrapper pod is available
kubectl get pods -n arc

# create the custom location
az customlocation create -n $customLocation -g $resourceGroup --namespace arc `
    --host-resource-id /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$eksConnectedClusterName `
    --cluster-extension-ids /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$eksConnectedClusterName/providers/Microsoft.KubernetesConfiguration/extensions/$customLocation `
    --location $location

# list the custom location
az customlocation list -o table

