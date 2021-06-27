# Create AKS

$location = 'eastus'
$resourceGroup = 'beardarc2'
$subscription_id = New-Object System.Management.Automation.PSCredential ('subscription-id', (Get-Secret -Name subscription-id))
$ENV:SUBSCRIPTION = "$($subscription_id.GetNetworkCredential().Password)"
$subscription = $ENV:SUBSCRIPTION
$aksClusterName = 'beard-aks-cluster2'
$clusterNodePoolSize = "Standard_DS4_v2"
$benscreds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$ENV:AZDATA_USERNAME="$($benscreds.UserName)"
$ENV:AZDATA_PASSWORD="$($benscreds.GetNetworkCredential().Password)"
$ENV:ACCEPT_EULA = 'yes'
$customLocation  = 'beard-aks-cluster-location2'
$dataController= "ben-aks-direct2"

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

az k8s-extension show --name $customLocation --cluster-type connectedClusters -c $aksClusterName -g $resourceGroup  -o table
az connectedk8s show -n $aksClusterName -g $resourceGroup   --query id -o tsv
az k8s-extension show --name $customLocation --cluster-type connectedClusters -c $aksClusterName -g $resourceGroup  --query id -o tsv
kubectl get pods -n arc

az customlocation create -n $customLocation -g $resourceGroup --namespace arc `
    --host-resource-id /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$aksClusterName `
    --cluster-extension-ids /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Kubernetes/connectedClusters/$aksClusterName/providers/Microsoft.KubernetesConfiguration/extensions/$customLocation `
    --location $location

    az customlocation list -o table

