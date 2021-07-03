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

I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretsManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
#>
$location = 'eastus'
$resourceGroup = 'beardarc'
$subscription_id = New-Object System.Management.Automation.PSCredential ('subscription-id', (Get-Secret -Name subscription-id))
$ENV:SUBSCRIPTION = "$($subscription_id.GetNetworkCredential().Password)"
$subscription = $ENV:SUBSCRIPTION
$aksClusterName = 'beard-aks-cluster'
$clusterNodePoolSize = "Standard_DS4_v2"
$benscreds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$ENV:AZDATA_USERNAME="$($benscreds.UserName)"
$ENV:AZDATA_PASSWORD="$($benscreds.GetNetworkCredential().Password)"
$ENV:ACCEPT_EULA = 'yes'
$customLocation  = 'beard-aks-cluster-location'
$dataController= "ben-aks-direct"

az login

az account set -s $ENV:SUBSCRIPTION 
az aks create -g $resourceGroup -n $aksClusterName --node-vm-size $clusterNodePoolSize # --generate-ssh-keys 
az aks get-credentials -g $resourceGroup -n $aksClusterName --overwrite-existing

kubectl get nodes

az extension add --name connectedk8s
az extension add --name k8s-extension
az extension add --name customlocation
az extension add --name arcdata
az extension update --name connectedk8s
az extension update --name k8s-extension
az extension update --name customlocation
az extension update --name arcdata

az connectedk8s connect --name $aksClusterName  --resource-group $resourceGroup --location $location
az connectedk8s list --resource-group $resourceGroup --output table

kubectl get deployments,pods -n azure-arc

az connectedk8s enable-features -n $aksClusterName -g $resourceGroup --features cluster-connect custom-locations
az k8s-extension create --name $customLocation --extension-type microsoft.arcdataservices --cluster-type connectedClusters `
    -c $aksClusterName -g $resourceGroup --scope cluster --release-namespace arc --config Microsoft.CustomLocation.ServiceAccount=sa-bootstrapper `
         --auto-upgrade false

# now we have to wait for it to be ready. Run a couple of times until it says installed
az k8s-extension show --name $customLocation --cluster-type connectedClusters -c $aksClusterName -g $resourceGroup  -o table

# now we will see the bootstrapper pod is available
kubectl get pods -n arc


az customlocation create -n $customLocation -g $resourceGroup --namespace arc `
    --host-resource-id /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$aksClusterName `
    --cluster-extension-ids /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$aksClusterName/providers/Microsoft.KubernetesConfiguration/extensions/$customLocation `
    --location $location

    az customlocation list -o table

