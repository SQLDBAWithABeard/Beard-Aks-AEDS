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
param cpuRequest string
param memoryRequest string
param dataStorageSize string
param dataStorageClassName string
param logsStorageSize string
param logsStorageClassName string
param dataLogsStorageSize string
param dataLogsStorageClassName string
param backupsStorageSize string
param backupsStorageClassName string
param replicas int
param cpuLimit string 
param memoryLimit string = '64Gi'
@allowed([
  'GeneralPurpose'
  'BusinessCritical'
])
param tier string = 'GeneralPurpose'
param licenseType string = 'LicenseIncluded'
param isDev bool = false

resource sqlmi 'Microsoft.AzureArcData/sqlManagedInstances@2021-08-01' = {
  name: instancename
  location: resourceGroup().location
  extendedLocation: {
    type: 'CustomLocation'
    name: resourceId('microsoft.extendedlocation/customlocations', customLocation)
  }
  tags: tags
  sku: {
    name: 'vCore'
    tier: tier
  }
  properties: {
    admin: adminUserName
    basicLoginInformation: {
      username: adminUserName
      password: adminPassword
    }
    licenseType: licenseType
    k8sRaw: {
      spec: {
        dev: isDev
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
                cpu: cpuRequest
                memory: memoryRequest
              }
              limits: {
                cpu: cpuLimit
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
