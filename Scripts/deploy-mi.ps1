
Set-Location D:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\
$benscreds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$resourceGroupName = 'beardarc'

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_sqlmi_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName              = $resourceGroupName  
    Name                           = $deploymentname
    TemplateFile                   = 'sql-mi.bicep' 
    instancename                   = 'ben-aks-eins' # max 13 characters
    dataControllerId               = 'beard-aks-cluster-dc'
    customLocation                 = 'beard-aks-cluster-location'
    adminUserName                  = $benscreds.UserName
    adminPassword                  = $benscreds.Password
    namespace                      = 'arc'
    serviceType                    = 'LoadBalancer'
    vCoresMax                      = 5
    memoryMax                      = 15
    dataStorageSize                = '15Gi'
    dataStorageClassName           = 'default'
    logsStorageSize                = '15Gi'
    logsStorageClassName           = 'default'
    dataLogsStorageSize            = '15Gi'
    dataLogsStorageClassName       = 'default'
    backupsStorageSize             = '15Gi'
    backupsStorageClassName        = 'default'
    replicas                       = 1
    tags                            = @{
        Important = 'This is controlled by Bicep'
        creator = 'The Beard'
        project = 'For Ben'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf