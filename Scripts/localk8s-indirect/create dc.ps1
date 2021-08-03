# create an indirect data controller

# connect to correct cluster

# kubectl config use-context kubernetes-admin@kubernetes 

kubectl cluster-info
kubectl config current-context

$benscreds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$ENV:AZDATA_USERNAME="$($benscreds.UserName)"
$ENV:AZDATA_PASSWORD="$($benscreds.GetNetworkCredential().Password)"
$subscription_id = New-Object System.Management.Automation.PSCredential ('subscription-id', (Get-Secret -Name subscription-id))
$ENV:SUBSCRIPTION = "$($subscription_id.GetNetworkCredential().Password)"
$ENV:ACCEPT_EULA = "Y"
$env:namespace = 'arcaz'
$location = 'eastus' # location of resource group
$resourceGroup = 'beardarc' # name of the already created resource group

$datacontrollername = 'benindirect'

# create a config for the data controller
az arcdata dc config init --source azure-arc-kubeadm --path Scripts/localk8s-indirect

# replace storageclass names in config

az arcdata dc config replace --path Scripts/localk8s-indirect/control.json --json-values "spec.storage.data.className=bens-local-storage"
az arcdata dc config replace --path Scripts/localk8s-indirect/control.json --json-values "spec.storage.logs.className=bens-local-storage"

# create dc

az arcdata dc create --path Scripts/localk8s-indirect/ --k8s-namespace $env:namespace --use-k8s --name $datacontrollername --subscription $ENV:SUBSCRIPTION --resource-group $resourceGroup --location $location --connectivity-mode indirect --infrastructure onpremises

az arcdata dc endpoint list --k8s-namespace $env:namespace --use-k8s
az arcdata dc config show --k8s-namespace $env:namespace --use-k8s
