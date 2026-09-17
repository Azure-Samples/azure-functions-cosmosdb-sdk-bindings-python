targetScope = 'resourceGroup'

param appKey string
param applicationInsightsName string
param cosmosAccountEndpoint string
param functionAppName string
param identityClientId string
param identityResourceId string
param location string
param logAnalyticsWorkspaceResourceId string
param packageContainerName string
param planName string
param storageAccountName string
param storageBlobEndpoint string
param tags object

module plan 'br/public:avm/res/web/serverfarm:0.5.0' = {
  name: 'plan-${appKey}'
  params: {
    name: planName
    location: location
    reserved: true
    skuName: 'FC1'
    zoneRedundant: false
    tags: tags
  }
}

module applicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'application-insights-${appKey}'
  params: {
    name: applicationInsightsName
    location: location
    workspaceResourceId: logAnalyticsWorkspaceResourceId
    tags: tags
  }
}

module functionApp 'br/public:avm/res/web/site:0.19.0' = {
  name: 'site-${appKey}'
  params: {
    name: functionAppName
    location: location
    kind: 'functionapp,linux'
    serverFarmResourceId: plan.outputs.resourceId
    managedIdentities: {
      userAssignedResourceIds: [
        identityResourceId
      ]
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageBlobEndpoint}${packageContainerName}'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: identityResourceId
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.14'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 100
      }
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.outputs.connectionString
          AzureWebJobsStorage__accountName: storageAccountName
          AzureWebJobsStorage__clientId: identityClientId
          AzureWebJobsStorage__credential: 'managedidentity'
          CosmosDBConnection__accountEndpoint: cosmosAccountEndpoint
          CosmosDBConnection__clientId: identityClientId
          CosmosDBConnection__credential: 'managedidentity'
          FUNCTIONS_EXTENSION_VERSION: '~4'
        }
      }
    ]
    basicPublishingCredentialsPolicies: [
      {
        name: 'ftp'
        allow: false
      }
      {
        name: 'scm'
        allow: false
      }
    ]
    httpsOnly: true
    siteConfig: {
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    tags: tags
  }
}

output name string = functionApp.outputs.name
output endpoint string = 'https://${functionApp.outputs.defaultHostname}'
