Set-Location D:\OneDrive\Documents\GitHub\BeardLInux\bicep
$benscreds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$resourceGroupName = 'beardarc'

$date = Get-Date -Format yyyyMMddHHmmsss
$deploymentname = 'deploy_sqlmi_{0}_{1}' -f $ResourceGroupName, $date # name of the deployment seen in the activity log
$deploymentConfig = @{
    resourceGroupName  = $resourceGroupName  
    Name               = $deploymentname
    TemplateFile       = 'vm.bicep' 
    virtualMachineName = 'jump'
    osDiskType         = 'Premium_LRS'
    virtualMachineSize = 'Standard_D8s_v3'
    adminUsername      = $benscreds.UserName
    adminPassword      = $benscreds.Password
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

New-AzResourceGroupDeployment @deploymentConfig -WhatIf