@maxLength(13)
param instancename string
param tags object
param dataControllerId string
param customLocation string
param adminUserName string

@secure()
param adminPassword string
param namespace string
@allowed([
  'LoadBalancer'
  'NodePort'
])
param serviceType string
param vCoresMax int
param memoryMax string
param dataStorageSize string
param dataStorageClassName string
param logsStorageSize string
param logsStorageClassName string
param dataLogsStorageSize string
param dataLogsStorageClassName string
param backupsStorageSize string
param backupsStorageClassName string
param replicas int
var vCoresLimit = vCoresMax * 2
param memoryLimit string = '64Gi'

resource sqlmi 'Microsoft.AzureArcData/sqlManagedInstances@2021-07-01-preview' = {
  name: instancename
  location: resourceGroup().location
  extendedLocation: {
    type: 'CustomLocation'
    name: resourceId('microsoft.extendedlocation/customlocations', customLocation) 
  }
  tags: tags
  sku: {
    name: 'vCore'
    tier: 'GeneralPurpose'
  }
  properties: {
    admin: adminUserName
    basicLoginInformation: {
      username: adminUserName
      password: adminPassword
    }
    licenseType: 'LicenseIncluded'
    k8sRaw: {
      spec: {
        dev: false
        services: {
          primary: {
            type: serviceType
          }
        }
        replicas: replicas
        scheduling: {
          default: {
            resources: {
              requests: {
                vcores: vCoresMax
                memory: memoryMax
              }
              limits: {
                vcores: vCoresLimit
                memory: memoryLimit
              }
            }
          }
        }
        storage: {
          data: {
            volumes: [
              {
                className: dataStorageClassName
                size: dataStorageSize
              }
            ]
          }
          logs: {
            volumes: [
              {
                className: logsStorageClassName
                size: logsStorageSize
              }
            ]
          }
          datalogs: {
            volumes: [
              {
                className: dataLogsStorageClassName
                size: dataLogsStorageSize
              }
            ]
          }
          backups: {
            volumes: [
              {
                className: backupsStorageClassName
                size: backupsStorageSize
              }
            ]
          }
        }
        settings: {
          azure: {
            subscription: subscription().subscriptionId
            resourceGroup: resourceGroup().name
            location: resourceGroup().location
          }
        }
      }
      metadata: {
        namespace: namespace
      }
      status: {}
    }
    dataControllerId: dataControllerId
  }
}
