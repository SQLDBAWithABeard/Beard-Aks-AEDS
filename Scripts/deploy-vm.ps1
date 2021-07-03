Set-Location D:\OneDrive\Documents\GitHub\BeardLInux\bicep # yes use your own path here !!

$resourceGroupName = 'beardarc'

# I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretsManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
# You will need to change this for your own environment
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))

<# 
# if you do not store them in secrets management use this
$admincredentials = New-Object System.Management.Automation.PSCredential ('username here ', (ConvertTo-SecureString -String 'password here' -AsPlainText))
#>



$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_sqlmi_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName  = $resourceGroupName  
    Name               = $deploymentname
    TemplateFile       = 'vm.bicep' 
    virtualMachineName = 'jump'
    osDiskType         = 'Premium_LRS'
    virtualMachineSize = 'Standard_D8s_v3'
    adminUsername      = $admincredentials.UserName
    adminPassword      = $admincredentials.Password
    publisher          = 'MicrosoftWindowsDesktop'
    offer              = 'Windows-10'
    sku                = '21h1-ent-g2'
    version            = 'latest'
    tags               = @{
        Important    = 'This is controlled by Bicep'
        creator      = 'The Beard'
        project      = 'For Ben'
        BenIsAwesome = $true
    }
}

New-AzResourceGroupDeployment @deploymentConfig # -WhatIf  # uncomment what if to see "what if" !!