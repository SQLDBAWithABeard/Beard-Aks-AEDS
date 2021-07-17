<#
# Azure Arc Enabled SQL Managed Instance in AKS

This notebook and repo will create a
- AKS Cluster
- Custom Location
- Azure Arc Enabled Direct Connected Data Controller
- 3 replica Azure Arc Enabled SQL Managed Instance

It requires

- Azure Cli [install from here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 
- kubectl - I install with chocolatey `choco install kubernetes-cli -y` or [install instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

## First set some variables for the session

I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
#>
$location = 'eastus' # location of resource group
$resourceGroup = 'beardarc' # name of the already created resource group
$aksClusterName = 'beard-aks-cluster' # the name of the AKS Cluster
$aksConnectedClusterName = 'beard-aks-connected-cluster' # the name of the connected AKS Cluster
$clusterNodePoolSize = "Standard_DS4_v2" # The VM size for the AKS cluster node pool
$customLocation  = 'beard-aks-cluster-location' # The name for the custom location

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

# log into Azure and set subscription
az login
az account set -s $ENV:SUBSCRIPTION 

# Create an AKS cluster
az aks create -g $resourceGroup -n $aksClusterName --node-vm-size $clusterNodePoolSize # --generate-ssh-keys 
# Get the credentials and set kubeconfig
az aks get-credentials -g $resourceGroup -n $aksClusterName --overwrite-existing

# check the nodes are running
kubectl get nodes

# add and update the required az cli extensions
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
az connectedk8s connect --name $aksConnectedClusterName  --resource-group $resourceGroup --location $location

# check the onboarded clusters
az connectedk8s list --resource-group $resourceGroup --output table

# look at the kubernetes resources for the onboarded cluster
kubectl get deployments,pods -n azure-arc

# enable the required features
az connectedk8s enable-features -n $aksConnectedClusterName -g $resourceGroup --features cluster-connect custom-locations

# create the custom location extension
az k8s-extension create --name $customLocation --extension-type microsoft.arcdataservices --cluster-type connectedClusters `
    -c $aksConnectedClusterName -g $resourceGroup --scope cluster --release-namespace arc --config Microsoft.CustomLocation.ServiceAccount=sa-bootstrapper `
         --auto-upgrade false

# now we have to wait for it to be ready. Run this command until the custom location is installed
az k8s-extension show --name $customLocation --cluster-type connectedClusters -c $aksConnectedClusterName -g $resourceGroup  -o table

# check the arc namespace for the pods - now we will see the bootstrapper pod is available
kubectl get pods -n arc

# create the custom location
az customlocation create -n $customLocation -g $resourceGroup --namespace arc `
    --host-resource-id /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$aksConnectedClusterName `
    --cluster-extension-ids /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$aksConnectedClusterName/providers/Microsoft.KubernetesConfiguration/extensions/$customLocation `
    --location $location

# list the custom location
az customlocation list -o table

