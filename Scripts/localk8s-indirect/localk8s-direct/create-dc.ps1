<#
# Azure Arc Enabled SQL Managed Instance in AKS

This notebook and repo will connect an existing K8s cluster to Azure Arc and set up the data controller
- Custom Location
- Azure Arc Enabled Direct Connected Data Controller


It requires

- Azure Cli [install from here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 
- kubectl - I install with chocolatey `choco install kubernetes-cli -y` or [install instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

## First set some variables for the session

I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
#>
$location = 'eastus' # location of resource group
$resourceGroup = 'beardarc' # name of the already created resource group
$aksConnectedClusterName = 'beard-nuc-connected-cluster' # the name of the connected AKS Cluster
$customLocation  = 'beard-nuc-cluster-location' # The name for the custom location

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

# Deploy a Data controller with Bicep

Set-Location G:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\ # yes use your own path here !!
$resourceGroupName = 'beardarc'
$logAnalyticsResourceName = 'loggyben' # name of the log analytics workspace
$logAnalyticsResourceGroupName = 'beardarc' # resource group name that has the log analytics workspace in it in case it is a centralised one
$dataControllerName            = 'beard-nuc-cluster-dc' # the name you want for the data controller

# I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
# You will need to change this for your own environment
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))

<# 
# if you do not store them in secrets management use this
$admincredentials = New-Object System.Management.Automation.PSCredential ('username here ', (ConvertTo-SecureString -String 'password here' -AsPlainText))
#>

# if you store tenantid and clientid in secrets management module
# You need to have created a service principal using az ad sp create-for-rbac --name <ServicePrincipalName> --role Contributor --scopes /subscriptions/{SubscriptionId}/resourceGroups/{resourcegroup}
# and add the details to the secrets management module with Set-Secret
$tenant_id_cred = New-Object System.Management.Automation.PSCredential ('tenant-id', (Get-Secret -Name tenant-id))
$client_id_cred = New-Object System.Management.Automation.PSCredential ('client-id', (Get-Secret -Name client-id))
$client_secret_cred = New-Object System.Management.Automation.PSCredential ('client-secret', (Get-Secret -Name client-secret))
$uspClientId = "$($client_id_cred.GetNetworkCredential().Password)"
$uspTenantId = "$($tenant_id_cred.GetNetworkCredential().Password)"

<# 
if doing demos in portal
$workspace_id = New-Object System.Management.Automation.PSCredential ('workspace-id', (Get-Secret -Name workspace-id))
$workspace_shared_key = New-Object System.Management.Automation.PSCredential ('workspace-shared-key', (Get-Secret -Name workspace-shared-key))
$uspClientId | Set-Clipboard
$uspTenantId | Set-Clipboard
$workspace_id.GetNetworkCredential().Password  | Set-Clipboard
$workspace_shared_key.GetNetworkCredential().Password  | Set-Clipboard
#>
<# 
# # if you dont store tenantid and clientid in secrets management module you can just put the string here 
# You still need to have created a service principal using az ad sp create-for-rbac --name <ServicePrincipalName> --role Contributor --scopes /subscriptions/{SubscriptionId}/resourceGroups/{resourcegroup}

$uspClientId = "$($client_id_cred.GetNetworkCredential().Password)" 
$uspTenantId = "$($tenant_id_cred.GetNetworkCredential().Password)" 
$client_secret_cred1 = New-Object System.Management.Automation.PSCredential ('client-secret', (ConvertTo-SecureString -String 'sp password here' -AsPlainText))

#>

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_dc_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName             = $resourceGroupName  
    Name                          = $deploymentname
    TemplateFile                  = 'data-controller-direct.bicep' 
    dataControllerName            = $dataControllerName 
    customLocationName            = $customLocation
    dcUsername                    = $admincredentials.UserName
    dcPassword                    = $admincredentials.Password
    uspClientId                   = $uspClientId 
    uspTenantId                   = $uspTenantId
    uspAuthority                  = 'https://login.microsoftonline.com'
    uspClientSecret               = $client_secret_cred.Password
    logAnalyticsResourceName      = $logAnalyticsResourceName 
    logAnalyticsResourceGroupName = $logAnalyticsResourceGroupName 
    dockerImagePullPolicy         = 'Always'
    dockerImageTag                = 'v1.0.0_2021-07-30'
    dockerRegistry                = 'mcr.microsoft.com'
    dockerRepository              = 'arcdata'
    controllerPort                = 30080
    serviceType                   = 'NodePort' # Node port for NUC
    serviceProxyPort              = 30777
    connectionMode                = 'direct'
    logsRotationDays              = 28
    logsRotationSize              = 5000
    dataStorageClass              = 'bens-local-storage'
    dataStorageSize               = '15Gi'
    logsStorageClass              = 'bens-local-storage'
    logsStorageSize               = '15Gi'
    namespace                     = 'arc'
    tags                          = @{
        Important    = 'This is controlled by Bicep'
        creator      = 'The Beard'
        project      = 'For Ben'
        location     = 'On Robs NUC in his office'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf  # uncomment what if to see "what if" !!

az arcdata dc endpoint list --k8s-namespace arc --use-k8s
az arcdata dc config show --k8s-namespace arc --use-k8s
az arcdata dc status show --k8s-namespace arc --use-k8s