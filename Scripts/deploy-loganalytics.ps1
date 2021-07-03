Set-Location D:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\

$resourceGroupName = 'beardarc2'
$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_loganalytics_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName                           = $resourceGroupName  
    Name                                        = $deploymentname
    TemplateFile                                = 'loganalytics.bicep' 
    workspacename                               = 'aks2loganalytics' 
    enableLogAccessUsingOnlyResourcePermissions = $true
    publicNetworkAccessForIngestion             = 'Enabled' # Enabled Disabled
    publicNetworkAccessForQuery                 = 'Enabled' # Enabled Disabled
    retentionInDays                             = 30
    tags                                        = @{
        Important    = 'This is controlled by Bicep'
        creator      = 'The Beard'
        project      = 'For Ben'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig -WhatIf -Verbose

