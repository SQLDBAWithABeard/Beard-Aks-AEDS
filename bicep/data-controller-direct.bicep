param tags object = {
  important: 'Controlled by Bicep'
}
param dataControllerName string = 'beard-aks-direct'
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
param logAnalyticsResourceName string
param logAnalyticsResourceGroupName string

var logAnalyticsResourceId = resourceId(logAnalyticsResourceGroupName,'Microsoft.OperationalInsights/workspaces',logAnalyticsResourceName)
var logAnalyticsPrimaryKey = listKeys(logAnalyticsResourceId, '2020-10-01').primarySharedKey
var logAnalyticsWorkspaceId = reference(logAnalyticsResourceId,'2020-10-01').customerId

param dockerImagePullPolicy string = 'Always'
param dockerImageTag string = 'v1.0.0_2021-07-30'
param dockerRegistry string = 'mcr.microsoft.com'
param dockerRepository string = 'arcdata'
param controllerPort int = 30080
param serviceType string = 'LoadBalancer'
param serviceProxyPort int = 30777
param connectionMode string = 'direct'
param logsRotationDays int = 7
var logsRotationDaysString = string(logsRotationDays)
param logsRotationSize int = 5000
var logsRotationSizeString = string(logsRotationSize)
param dataStorageClass string = 'default'
param dataStorageSize string = '15Gi'
param logsStorageClass string = 'default'
param logsStorageSize string = '15Gi'
param namespace string = 'arc'
param infrastructure string = 'azure' // Allowed values are alibaba, aws, azure, gpc, onpremises, other.

resource datacontroller 'Microsoft.AzureArcData/dataControllers@2021-07-01-preview' = {
  name: dataControllerName
  location: resourceGroup().location
  extendedLocation: {
    name: customlocation
    type: 'CustomLocation'
  }
  tags: tags
  properties: {
    infrastructure: infrastructure
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
            displayName: dataControllerName
            enableBilling: 'True'
            'logs.rotation.days': logsRotationDaysString //'${logsRotationDays}'
            'logs.rotation.size': logsRotationSizeString //'${logsRotationSize}'
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
output customlocationvar1 string = logsRotationDaysString
output customlocationvar2 string = logsRotationSizeString
