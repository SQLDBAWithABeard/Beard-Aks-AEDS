param tags object = {
  important: 'Controlled by Bicep'
}
param dcname string = 'beard-aks-direct'
param customLocationName string = 'beard-aks-cluster-location'
var customlocation =  resourceId('microsoft.extendedlocation/customlocations', customLocationName)
param dcUsername string
@secure()
param dcPassword string
param uspClientId string
param uspTenantId string
param uspAuthority string
@secure()
param uspClientSecret string
param logAnalyticsWorkspaceId string
param logAnalyticsResourceId string
var logAnalyticsPrimaryKey = listKeys(logAnalyticsResourceId, '2020-10-01').primarySharedKey
param dockerImagePullPolicy string = 'Always'
param dockerImageTag string = 'public-preview-april-2021'
param dockerRegistry string = 'mcr.microsoft.com'
param dockerRepository string = 'arcdata'
param controllerPort int = 30080
param serviceType string = 'LoadBalancer'
param serviceProxyPort int = 30777
param connectionMode string = 'direct'
param logsRotationDays int = 7
param logsRotationSize int = 5000
param dataStorageClass string = 'default'
param dataStorageSize string = '15Gi'
param logsStorageClass string = 'default'
param logsStorageSize string = '15Gi'
param namespace string = 'arc'

resource datacontroller 'Microsoft.AzureArcData/dataControllers@2021-06-01-preview' = {
  name: dcname
  location: resourceGroup().location
  extendedLocation: {
    name: customlocation
    type: 'CustomLocation'
  }
  tags: tags
  properties: {
    basicLoginInformation: {
      username: dcUsername
      password: dcPassword
    }
    uploadServicePrincipal: {
      clientId: uspClientId
      tenantId: uspTenantId
      authority: uspAuthority
      clientSecret: uspClientSecret
    }
    logAnalyticsWorkspaceConfig: {
      workspaceId: logAnalyticsWorkspaceId
      primaryKey: logAnalyticsPrimaryKey
    }
    k8sRaw: {
      apiVersion: 'arcdata.microsoft.com/v1alpha1'
      kind: 'datacontroller'
      spec: {
        credentials: {
          controllerAdmin: 'controller-login-secret'
          dockerRegistry: 'arc-private-registry'
          domainServiceAccount: 'domain-service-account-secret'
          serviceAccount: 'sa-mssql-controller'
        }
        docker: {
          imagePullPolicy: dockerImagePullPolicy
          imageTag: dockerImageTag
          registry: dockerRegistry
          repository: dockerRepository
        }
        security: {
          allowDumps: true
          allowNodeMetricsCollection: true
          allowPodMetricsCollection: true
          allowRunAsRoot: false
        }
        services: [
          {
            name: 'controller'
            port: controllerPort
            serviceType: serviceType
          }
          {
            name: 'serviceProxy'
            port: serviceProxyPort
            serviceType: serviceType
          }
        ]
        settings: {
          ElasticSearch: {
            'vm.max_map_count': '-1'
          }
          azure: {
            connectionMode: connectionMode
            location: resourceGroup().location
            resourceGroup: resourceGroup().name
            subscription: subscription().subscriptionId
          }
          controller: {
            displayName: dcname
            enableBilling: 'True'
            'logs.rotation.days': '7'
            'logs.rotation.size': '5000'
          }
        }
        storage: {
          data: {
            accessMode: 'ReadWriteOnce'
            className: dataStorageClass
            size: dataStorageSize
          }
          logs: {
            accessMode: 'ReadWriteOnce'
            className: logsStorageClass
            size: logsStorageSize
          }
        }
      }
      metadata: {
        namespace: namespace
        name: 'datacontroller'
      }
    }
  }
}

output customlocationvar string = customlocation
