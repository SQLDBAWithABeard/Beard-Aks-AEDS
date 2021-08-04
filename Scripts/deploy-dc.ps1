Set-Location G:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\ # yes use your own path here !!
$resourceGroupName = 'beardarc'
$logAnalyticsResourceName = 'loggyben' # name of the log analytics workspace
$logAnalyticsResourceGroupName = 'beardarc' # resource group name that has the log analytics workspace in it in case it is a centralised one
$dataControllerName            = 'beard-aks-cluster-dc' # the name you want for the data controller
$customLocationName            = 'beard-aks-cluster-location' # the name for the custom location that you created in the Create AKS script

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
    customLocationName            = $customLocationName
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
    serviceType                   = 'LoadBalancer'
    serviceProxyPort              = 30777
    connectionMode                = 'direct'
    logsRotationDays              = 7
    logsRotationSize              = 5000
    dataStorageClass              = 'default'
    dataStorageSize               = '15Gi'
    logsStorageClass              = 'default'
    logsStorageSize               = '15Gi'
    namespace                     = 'arc'
    tags                          = @{
        Important    = 'This is controlled by Bicep'
        creator      = 'The Beard'
        project      = 'For Ben'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf  # uncomment what if to see "what if" !!

