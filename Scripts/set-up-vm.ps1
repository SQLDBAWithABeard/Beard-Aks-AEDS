Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install azure-data-studio -y
choco install pwsh
choco install vscode -y 
choco install vscode-powershell
choco install azure-cli -y 
choco install kubernetes-cli -y
choco install kubernetes-helm -y
choco install git -y

$File = "$ENV:temp\azdata.msi"
Invoke-WebRequest -Uri https://aka.ms/azdata-msi -OutFile $file
msiexec  /i $file

