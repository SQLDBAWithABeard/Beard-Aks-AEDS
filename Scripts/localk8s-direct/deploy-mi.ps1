
Set-Location G:\OneDrive\Documents\GitHub\Beard-Aks-AEDS\bicep\ # yes use your own path here !!


$resourceGroupName = 'beardarc'
$sqlMIName = 'louis-nuc' # max 13 characters - name of the instance
$dataControllerName = 'beard-nuc-cluster-dc' # the name of the data controller deployed with deploy-dc.ps1
$customLocationName = 'beard-nuc-cluster-location' # the name of the custom location deployed with create-aks.ps1
# I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
# You will need to change this for your own environment
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))

<# 
# if you do not store them in secrets management use this
$admincredentials = New-Object System.Management.Automation.PSCredential ('username here ', (ConvertTo-SecureString -String 'password here' -AsPlainText))
#>

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_sqlmi_{0}_{1}' -f $sqlMIName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName        = $resourceGroupName  
    Name                     = $deploymentname
    TemplateFile             = 'sql-mi.bicep' 
    instancename             = $sqlMIName
    dataControllerId         = $dataControllerName
    customLocation           = $customLocationName
    adminUserName            = $admincredentials.UserName
    adminPassword            = $admincredentials.Password
    namespace                = 'arc'
    serviceType              = 'NodePort' # Node port for NUC
    cpuRequest               = '2'  # Yes its a string dont hate me vCores settings for instance
    cpuLimit                 = '4'  # Yes its a string dont hate me vCores settings for instance
    memoryRequest            = '8Gi' # Yes its a string dont hate me Memory settings for instance
    memoryLimit              = '16Gi' # Yes its a string dont hate me Memory settings for instance
    dataStorageSize          = '50Gi'
    dataStorageClassName     = 'bens-local-storage' # dont change this for AKS deployments
    logsStorageSize          = '25Gi'
    logsStorageClassName     = 'bens-local-storage' # dont change this for AKS deployments
    dataLogsStorageSize      = '15Gi'
    dataLogsStorageClassName = 'bens-local-storage' # dont change this for AKS deployments
    backupsStorageSize       = '50Gi'
    backupsStorageClassName  = 'bens-local-storage' # dont change this for AKS deployments
    replicas                 = 2 # 1, 2 or 3 - number of replicas to create - BusinessCritical MUST be 2 or 3
    tier                     = 'BusinessCritical' # BusinessCritical or GeneralPurpose
    licenseType              = 'LicenseIncluded' # LicenseIncluded or
    isDev                    = $true # is this a dev instance true or false
    tags                     = @{
        Important    = 'This is controlled by Bicep'
        creator      = 'The Beard'
        project      = 'For Ben'
        location     = 'On Robs NUC in his office'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf  # uncomment what if to see "what if" !!

az sql mi-arc list -k arc --use-k8s
az sql mi-arc show -k arc --use-k8s -n $sqlMIName
az sql mi-arc endpoint list -k arc --use-k8s -n $sqlMIName

$sqlinstance = '192.168.2.63,30693'
$sqlinstance = '192.168.2.63,32177'

$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $admincredentials

$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaAvailabilityGroup
Get-DbaAgListener