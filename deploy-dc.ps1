Set-Location D:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\
$bens_creds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$workspace_key_cred = New-Object System.Management.Automation.PSCredential ('workspacekey', (Get-Secret -Name workspace-shared-key))
$tenant_id_cred = New-Object System.Management.Automation.PSCredential ('tenant-id', (Get-Secret -Name tenant-id))
$client_id_cred = New-Object System.Management.Automation.PSCredential ('client-id', (Get-Secret -Name client-id))
$client_secret_cred = New-Object System.Management.Automation.PSCredential ('client-secret', (Get-Secret -Name client-secret))
$workspace_id_cred = New-Object System.Management.Automation.PSCredential ('workspace-id', (Get-Secret -Name workspace-id))
$uspClientId = "$($client_id_cred.GetNetworkCredential().Password)"
$uspTenantId = "$($tenant_id_cred.GetNetworkCredential().Password)"
$logAnalyticsWorkspaceId = 'cf3958a8-20e3-4422-8131-c762678d417d'# "$($workspace_id_cred.GetNetworkCredential().Password)"
$logAnalyticsResourceId = '/subscriptions/6d8f994c-9051-4cef-ba61-528bab27d213/resourceGroups/beardarc2/providers/Microsoft.OperationalInsights/workspaces/aks2loganalytics'
# $logAnalyticsPrimaryKey = "$($workspace_key_cred.GetNetworkCredential().Password)"
$resourceGroupName = 'beardarc2'

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_dc_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName       = $resourceGroupName  
    Name                    = $deploymentname
    TemplateFile            = 'data-controller-direct.bicep' 
    dcname                  = 'beard-aks-cluster2-dc'
    customLocationName      = 'beard-aks-cluster-location2'
    dcUsername              = $bens_creds.UserName
    dcPassword              = $bens_creds.Password
    uspClientId             = $uspClientId 
    uspTenantId             = $uspTenantId
    uspAuthority            = 'https://login.microsoftonline.com'
    uspClientSecret         = $client_secret_cred.Password
    logAnalyticsWorkspaceId = $logAnalyticsWorkspaceId
    logAnalyticsResourceId = $logAnalyticsResourceId 
    # logAnalyticsPrimaryKey  = $logAnalyticsPrimaryKey
    dockerImagePullPolicy   = 'Always'
    dockerImageTag          = 'public-preview-may-2021'
    dockerRegistry          = 'mcr.microsoft.com'
    dockerRepository        = 'arcdata'
    controllerPort          = 30080
    serviceType             = 'LoadBalancer'
    serviceProxyPort        = 30777
    connectionMode          = 'direct'
    logsRotationDays        = 7
    logsRotationSize        = 5000
    dataStorageClass        = 'default'
    dataStorageSize         = '15Gi'
    logsStorageClass        = 'default'
    logsStorageSize         = '15Gi'
    namespace               = 'arc'
    tags                    = @{
        Important    = 'This is controlled by Bicep'
        creator      = 'The Beard'
        project      = 'For Ben'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig -WhatIf -Verbose

