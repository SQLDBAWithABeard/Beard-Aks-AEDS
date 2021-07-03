Set-Location D:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\
$resourceGroupName = 'beardarc'
$logAnalyticsResourceName = 'loggylytics'
$logAnalyticsResourceGroupName = 'beardarc'
$dataControllerName            = 'beard-aks-cluster-dc'
$customLocationName            = 'beard-aks-cluster-location'

$bens_creds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$tenant_id_cred = New-Object System.Management.Automation.PSCredential ('tenant-id', (Get-Secret -Name tenant-id))
$client_id_cred = New-Object System.Management.Automation.PSCredential ('client-id', (Get-Secret -Name client-id))
$client_secret_cred = New-Object System.Management.Automation.PSCredential ('client-secret', (Get-Secret -Name client-secret))
$uspClientId = "$($client_id_cred.GetNetworkCredential().Password)"
$uspTenantId = "$($tenant_id_cred.GetNetworkCredential().Password)"

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_dc_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName             = $resourceGroupName  
    Name                          = $deploymentname
    TemplateFile                  = 'data-controller-direct.bicep' 
    dataControllerName            = $dataControllerName 
    customLocationName            = $customLocationName
    dcUsername                    = $bens_creds.UserName
    dcPassword                    = $bens_creds.Password
    uspClientId                   = $uspClientId 
    uspTenantId                   = $uspTenantId
    uspAuthority                  = 'https://login.microsoftonline.com'
    uspClientSecret               = $client_secret_cred.Password
    logAnalyticsResourceName      = $logAnalyticsResourceName 
    logAnalyticsResourceGroupName = $logAnalyticsResourceGroupName 
    dockerImagePullPolicy         = 'Always'
    dockerImageTag                = 'public-preview-may-2021'
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

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf -Verbose # uncomment what if to see "what if" !!
