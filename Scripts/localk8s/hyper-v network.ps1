New-VMSwitch -SwitchName 'k8s' -SwitchType internal
Get-NetAdapter       // (note down ifIndex of the newly created switch as INDEX)
New-NetIPAddress -IPAddress 172.172.0.1 -PrefixLength 24 -InterfaceIndex 59
New-NetNat -Name MyNATnetwork -InternalIPInterfaceAddressPrefix 172.172.0.0/24