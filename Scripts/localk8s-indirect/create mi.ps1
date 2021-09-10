# connect to correct cluster

# kubectl config use-context kubernetes-admin@kubernetes 

kubectl cluster-info
kubectl config current-context

$benscreds = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$ENV:AZDATA_USERNAME="$($benscreds.UserName)"
$ENV:AZDATA_PASSWORD="$($benscreds.GetNetworkCredential().Password)"
$subscription_id = New-Object System.Management.Automation.PSCredential ('subscription-id', (Get-Secret -Name subscription-id))
$ENV:SUBSCRIPTION = "$($subscription_id.GetNetworkCredential().Password)"
$ENV:ACCEPT_EULA = "Y"
$env:namespace = 'arc'
$MIName = 'louis-nuc'

azdata arc sql mi create -n $MIName  -scd bens-local-storage -scl bens-local-storage -cr "2" -cl "4" -mr "6Gi" -ml "8Gi"

azdata arc sql endpoint list -n $MIName

$SqlInstance = '192.168.2.61,32015' # Audience please help Rob - He WILL forget to change this

$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $benscreds


$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaDatabase |Format-Table

Push-Location D:\SQLBackups
kubectl cp AdventureWorks2017.bak  $MIName-0:/var/opt/mssql/backups -c arc-sqlmi -n $env:namespace
Pop-Location

Get-DbaFile -Path /var/opt/mssql/backups

Restore-DbaDatabase -DatabaseName AdventureWorks2017 -Path /var/opt/mssql/backups/AdventureWorks2017.bak -replace

$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $benscreds

$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaDatabase |Format-Table

azdata arc sql mi delete -n $MIName  

# or with az

$3nodebustierdevname = 'ben3tier'
az sql mi-arc create `
    --name $3nodebustierdevname `
    --k8s-namespace $env:namespace `
    --use-k8s  --agent-enabled true  --dev --replicas 3 --tier BusinessCritical  `
    --cores-limit 4  --cores-request 2   `
    --memory-limit "8Gi" --memory-request "6Gi" `
    --storage-class-backups bens-local-storage  `
    --storage-class-data bens-local-storage `
    --storage-class-datalogs bens-local-storage  `
    --storage-class-logs bens-local-storage `
    --volume-size-backups "50Gi"   `
    --volume-size-data "20Gi" `
    --volume-size-datalogs "20Gi"  `
    --volume-size-logs "5Gi"

az sql mi-arc endpoint list -n $3nodebustierdevname --k8s-namespace $env:namespace --use-k8s

$SqlInstance = '192.168.2.63,32443' # Audience please help Rob - He WILL forget to change this
 
$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $benscreds

$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaDatabase |Format-Table

Invoke-DbaQuery -Query "Select @@ServerName as 'Which pod am I?'"

Get-DbaAvailabilityGroup
Get-DbaAgListener

Get-DbaAgDatabase 

Get-DbaAgReplica

az sql mi-arc show -n $3nodebustierdevname --k8s-namespace $env:namespace --use-k8s

Push-Location D:\SQLBackups
kubectl cp AdventureWorks2017.bak  $3nodebustierdevname-0:/var/opt/mssql/backups -c arc-sqlmi -n $env:namespace
Pop-Location

Get-DbaFile -Path /var/opt/mssql/backups

Restore-DbaDatabase  -DatabaseName AdventureWorks2017 -Path /var/opt/mssql/backups/AdventureWorks2017.bak

$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $benscreds
$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaDatabase |Format-Table

Get-DbaAgDatabase |Format-Table

az sql mi-arc delete -n $3nodebustierdevname --k8s-namespace $env:namespace --use-k8s