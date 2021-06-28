param managedClusters_beard_aks_cluster2_name string = 'beard-aks-cluster2'
param publicIPAddresses_02236609_940a_48a2_999b_80267270a620_externalid string = '/subscriptions/6d8f994c-9051-4cef-ba61-528bab27d213/resourceGroups/MC_beardarc2_beard-aks-cluster2_westeurope/providers/Microsoft.Network/publicIPAddresses/02236609-940a-48a2-999b-80267270a620'
param userAssignedIdentities_beard_aks_cluster2_agentpool_externalid string = '/subscriptions/6d8f994c-9051-4cef-ba61-528bab27d213/resourceGroups/MC_beardarc2_beard-aks-cluster2_westeurope/providers/Microsoft.ManagedIdentity/userAssignedIdentities/beard-aks-cluster2-agentpool'

resource managedClusters_beard_aks_cluster2_name_resource 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: managedClusters_beard_aks_cluster2_name
  location: 'westeurope'
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    principalId: '84d85e5e-84b1-40a7-ad94-5f5e8204c845'
    tenantId: 'add02cc8-7eaf-4746-902a-53d0ceeff326'
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.19.11'
    dnsPrefix: 'beard-aks--beardarc2-6d8f99'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: 3
        vmSize: 'Standard_DS4_v2'
        osDiskSizeGB: 128
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: '1.19.11'
        enableNodePublicIP: false
        nodeLabels: {}
        mode: 'System'
        enableEncryptionAtHost: false
        osType: 'Linux'
        osSKU: 'Ubuntu'
        enableFIPS: false
      }
    ]
    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAu5Qi3xTmAuAQSPi2rUjrK6NDYE672y6q4pignuCzKk/zLx9t194vlc9Ry2ZKXqDQvAKT6ynv6nl7r/v+BgJkTSiObBqX+6i+U42hcu+AdXzWwYczqzK6GuCRjBqMuN8j1yPvRUi4U9lUqF6VNq86jMP1VJ95yDpHfKMm7ooFv/I2pNCZ2A9X9QBW1Akp3EJz0ZO/mhcEk61T9qwjyK0WUkgEhyLNvK5zcm9X1yr7IMfAYS1gPbu0MZ4R6v7SxK7zi24TdeVBWlFtW0DS7hpUujlS6Uu5JjyS5bL2IjwCBGICCmszTfFft6TlAYnww9YnLfYtF7vAL8hHbZ+i2q7l rob@sewells-consulting.co.uk\n'
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    nodeResourceGroup: 'MC_beardarc2_${managedClusters_beard_aks_cluster2_name}_westeurope'
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'Standard'
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
        effectiveOutboundIPs: [
          {
            id: publicIPAddresses_02236609_940a_48a2_999b_80267270a620_externalid
          }
        ]
      }
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'loadBalancer'
    }
    identityProfile: {
      kubeletidentity: {
        resourceId: userAssignedIdentities_beard_aks_cluster2_agentpool_externalid
        clientId: 'd34e0e39-ab3d-46d0-8359-382d3e8d7291'
        objectId: '19908cb6-0c06-49f4-828b-596ea8f6608a'
      }
    }
  }
}

resource managedClusters_beard_aks_cluster2_name_nodepool1 'Microsoft.ContainerService/managedClusters/agentPools@2021-05-01' = {
  parent: managedClusters_beard_aks_cluster2_name_resource
  name: 'nodepool1'
  properties: {
    count: 3
    vmSize: 'Standard_DS4_v2'
    osDiskSizeGB: 128
    osDiskType: 'Ephemeral'
    kubeletDiskType: 'OS'
    maxPods: 110
    type: 'VirtualMachineScaleSets'
    orchestratorVersion: '1.19.11'
    enableNodePublicIP: false
    nodeLabels: {}
    mode: 'System'
    enableEncryptionAtHost: false
    osType: 'Linux'
    osSKU: 'Ubuntu'
    enableFIPS: false
  }
}
