param workspacename string 
param enableLogAccessUsingOnlyResourcePermissions bool
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccessForIngestion string
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccessForQuery string
param retentionInDays int
var dailyQuotaGb = -1
param tags object

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: workspacename
  tags: tags
  location: resourceGroup().location
  properties: {
    features: {
      enableLogAccessUsingOnlyResourcePermissions: enableLogAccessUsingOnlyResourcePermissions
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery:publicNetworkAccessForQuery
  }
}

output loganalyticsworkspaceid string = loganalytics.properties.customerId
output loganalyticsresourceid string = loganalytics.id
