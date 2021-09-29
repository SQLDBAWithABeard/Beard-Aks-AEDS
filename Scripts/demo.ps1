# on aks - run deploy-mi first !

#region choose kubectl context
kubectl config use-context ben-aks-cluster
kubectl config use-context iam-root-account@ben-eks-cluster.us-west-2.eksctl.io
kubectl config use-context kubernetes-admin@kubernetes
kubectl cluster-info
kubectl config current-context
#endregion

#region get sql mi
$sqlmi = 'ben-nuc-mi' # make sure it is the same name Rob to avoid embarrassment!

# I use the SecretsManagement PowerShell module to store my secrets which can be installed with `Install-Module SecretManagement`. I add secrets with `Set-Secret -Name nameofsecret -Secret secretvalue`.
# You will need to change this for your own environment
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))

az sql mi-arc list -k arc --use-k8s
az sql mi-arc show -n $sqlmi --k8s-namespace arc --use-k8s
az sql mi-arc endpoint list -n $sqlmi --k8s-namespace arc --use-k8s

$MIJson = az sql mi-arc endpoint list -n $sqlmi --k8s-namespace arc --use-k8s | ConvertFrom-Json

$MIJson.instances.endpoints
$SqlInstance = $MIJson.instances.endpoints[0].endpoint
#endregion

#region Connect and explore
# lets connect to the instance
$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $admincredentials

# we do this to save key strokes 
# it means - for every command that has dba in it set the SqlInstance parameter to the $sql variable
$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaAvailabilityGroup
Get-DbaAgListener
Get-DbaAgReplica
Get-DbaAgDatabase
Get-DbaAgentServer
Get-DbaXESession
Get-DbaWaitStatistic
Get-DbaSpConfigure | Out-GridView
Get-DbaProcess
Get-DbaMaxMemory
Set-DbaMaxMemory -Max 22469
Get-DbaLogin | ft
Get-DbaLastBackup | Format-Table
Get-DbaLastGoodCheckDb | Format-Table
Get-DbaErrorLog | Out-GridView
Get-DbaBuild
#endregion

#region create a database

New-DbaDatabase -Name BensDatabaseOfWonder 
Get-DbaDatabase -Database BensDatabaseOfWonder 

Get-DbaAgDatabase

$query = @"
CREATE TABLE BenTime (
    WhatTimeIsIt varchar(50),
    NoWhatTimeIsIt datetime DEFAULT GetDate()
)
"@
Invoke-DbaQuery -Database BensDatabaseOfWonder -Query $query
Invoke-DbaQuery -Database BensDatabaseOfWonder -Query "INSERT INTO dbo.BenTime (WhatTimeIsIt) VALUES ('Its Ben Time')"
Invoke-DbaQuery -Database BensDatabaseOfWonder -Query "SELECT * FROM dbo.BenTime"

## in a different session
$sqlmi = 'ben-aks-mi'
$admincredentials = New-Object System.Management.Automation.PSCredential ((Get-Secret -Name beardmi-benadmin-user -AsPlainText), (Get-Secret -Name beardmi-benadmin-pwd))
$MIJson = az sql mi-arc endpoint list -n $sqlmi --k8s-namespace arc --use-k8s | ConvertFrom-Json
$SqlInstance = $MIJson.instances.endpoints[0].endpoint

$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $admincredentials
$x = 600
While ($x -gt 0){
Invoke-DbaQuery -SqlInstance $sql -Database BensDatabaseOfWonder -Query "INSERT INTO dbo.BenTime (WhatTimeIsIt) VALUES ('Its Ben Time')"
Start-Sleep -Seconds 10
$x --
}

# back to the original session
Invoke-DbaQuery -Database BensDatabaseOfWonder -Query "SELECT * FROM dbo.BenTime"

#endregion

#region restore a database to the instance

Get-DbaDatabase |Format-Table

# I am going to use kubectl to copy a backup file straight into the sqlmi container
Push-Location D:\SQLBackups
kubectl cp AdventureWorks2017.bak  $sqlmi-0:/var/opt/mssql/backups -c arc-sqlmi -n arc
Pop-Location

# here is the file
Get-DbaFile -Path /var/opt/mssql/backups

# now we can restore it
Restore-DbaDatabase -DatabaseName AdventureWorks2017 -Path /var/opt/mssql/backups/AdventureWorks2017.bak -replace

# refresh our connection
$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $admincredentials

$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}

Get-DbaDatabase |Format-Table
# notice the last backup time
Get-DbaDatabase -Database AdventureWorks2017

# check the Availability Group Databases
Get-DbaAgDatabase

#endregion

#region restore a database

kubectl edit sqlmi $sqlmi  -n arc -o yaml
Get-DbaDbBackupHistory -Database BensDatabaseOfWonder

backup:
  recoveryPointObjectiveInSeconds: 300

# check the full name and paste it Rob
Get-DbaDbBackupHistory -Database BensDatabaseOfWonder -Last -Raw
/var/opt/mssql/backups/current/33b9afa0-dc5c-4c2e-bffc-be18b3c9bee8/Log-20210910083743-c0ed7711-cccd-4d4a-b185-a8c377f477cd.bak
# check the backups

Get-DbaFile -Path '/var/opt/mssql/backups/'
Get-DbaFile -Path '/var/opt/mssql/backups/current/'
Get-DbaFile -Path '/var/opt/mssql/backups/archived/33b9afa0-dc5c-4c2e-bffc-be18b3c9bee8/20210910085721'
Get-DbaFile -Path '/var/opt/mssql/backups/current/33b9afa0-dc5c-4c2e-bffc-be18b3c9bee8'

# in a seperate session
$sqlmi = 'ben-aks-mi'
kubectl exec --stdin --tty --namespace arc "$sqlmi-0" --container arc-sqlmi -- /bin/bash

ls /var/opt/mssql/backups/current/

# stop the load
# back to this one
$sql = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $admincredentials

$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $sql 
}
Invoke-DbaQuery -Database BensDatabaseOfWonder -Query "SELECT * FROM dbo.BenTime"

# open the restore-db.yaml and alter the time value

kubectl delete -f .\yaml\restore-db.yaml
kubectl apply -f .\yaml\restore-db.yaml
kubectl get sqlmirestoretask -n arc -o yaml

Get-DbaDatabase

kubectl -n arc expose pod "$sqlmi-0" --port=1533  --name="$sqlmi-0-external-admin-svc" --type=LoadBalancer
kubectl get services -n arc

$externaladmin = '20.185.12.54,1533'
$adminsql = Connect-DbaInstance -SqlInstance $externaladmin -SqlCredential $admincredentials

Get-DbaDbBackupHistory -Database BensDatabaseOfWonder -Raw 
$files = Get-DbaFile -Path '/var/opt/mssql/backups/archived/33b9afa0-dc5c-4c2e-bffc-be18b3c9bee8/20210910085721/' | Where Filename -NotLike *json
$files.Filename |  Restore-DbaDatabase -SqlInstance $adminsql -DatabaseName BenWonderRestore  -RestoreTime (Get-Date).ToUniversalTime().AddMinutes(-100) -WithReplace -DestinationFilePrefix Restore 
# Invoke-DbaQuery -Query "RESTORE DATABASE BenWonderRestore"

$adminsql = Connect-DbaInstance -SqlInstance $externaladmin -SqlCredential $admincredentials

$PSDefaultParameterValues = @{
    "*dba*:SqlInstance" = $adminsql
}
Invoke-DbaQuery -Database BenWonderRestore -Query "SELECT * FROM dbo.BenTime"
Invoke-DbaQuery -Database BensDatabaseOfWonder -Query "SELECT * FROM dbo.BenTime"

Get-DbaDatabase | ft

#endregion