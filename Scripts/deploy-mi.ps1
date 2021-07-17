
Set-Location G:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\ # yes use your own path here !!


$resourceGroupName = 'beardarc'
$sqlMIName = 'ben-aks-las' # max 13 characters - name of the instance
$dataControllerName = 'beard-aks-cluster-dc' # the name of the data controller deployed with deploy-dc.ps1
$customLocationName = 'beard-aks-cluster-location'# the name of the custom location deployed with create-aks.ps1
# I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
# You will need to change this for your own environment
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))

<# 
# if you do not store them in secrets management use this
$admincredentials = New-Object System.Management.Automation.PSCredential ('username here ', (ConvertTo-SecureString -String 'password here' -AsPlainText))
#>

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_sqlmi_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName              = $resourceGroupName  
    Name                           = $deploymentname
    TemplateFile                   = 'sql-mi.bicep' 
    instancename                   = $sqlMIName
    dataControllerId               = $dataControllerName
    customLocation                 = $customLocationName
    adminUserName                  = $admincredentials.UserName
    adminPassword                  = $admincredentials.Password
    namespace                      = 'arc'
    serviceType                    = 'LoadBalancer'
    vCoresMax                      = 5  # vCores settings for instance
    memoryMax                      = 15 # Memory settings for instance
    dataStorageSize                = '15Gi'
    dataStorageClassName           = 'default' # dont change this for AKS deployments
    logsStorageSize                = '15Gi'
    logsStorageClassName           = 'default' # dont change this for AKS deployments
    dataLogsStorageSize            = '15Gi'
    dataLogsStorageClassName       = 'default' # dont change this for AKS deployments
    backupsStorageSize             = '15Gi'
    backupsStorageClassName        = 'default' # dont change this for AKS deployments
    replicas                       = 1 # 1 or 3 - number of replicas to create
    tags                            = @{
        Important = 'This is controlled by Bicep'
        creator = 'The Beard'
        project = 'For Ben'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf  # uncomment what if to see "what if" !!