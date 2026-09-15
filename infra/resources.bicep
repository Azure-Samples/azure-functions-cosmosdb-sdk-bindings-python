targetScope = 'resourceGroup'

param environmentName string
param location string
param resourceToken string

var tags = {
  'azd-env-name': environmentName
}
var databaseName = 'db_name'
var containerName = 'container_name'
var cosmosAccountName = 'cosmos-${resourceToken}'
var storageAccountName = 'st${resourceToken}'
var logAnalyticsName = take('log-${environmentName}-${resourceToken}', 63)
var apps = [
  {
    key: 'cosmosclient'
    packageContainerName: 'cosmosclient-packages'
  }
  {
    key: 'databaseproxy'
    packageContainerName: 'databaseproxy-packages'
  }
  {
    key: 'containerproxy'
    packageContainerName: 'containerproxy-packages'
  }
]

module identities 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = [for app in apps: {
  name: 'identity-${app.key}'
  params: {
    name: take('id-${app.key}-${resourceToken}', 128)
    location: location
    tags: tags
  }
}]

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'log-analytics'
  params: {
    name: logAnalyticsName
    location: location
    dataRetention: 30
    tags: tags
  }
}

module storage 'br/public:avm/res/storage/storage-account:0.26.0' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    skuName: 'Standard_LRS'
    blobServices: {
      containers: [for app in apps: {
        name: app.packageContainerName
        publicAccess: 'None'
      }]
    }
    roleAssignments: [
      {
        principalId: identities[0].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Account Contributor'
      }
      {
        principalId: identities[0].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Owner'
      }
      {
        principalId: identities[0].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Queue Data Contributor'
      }
      {
        principalId: identities[0].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }
      {
        principalId: identities[1].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Account Contributor'
      }
      {
        principalId: identities[1].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Owner'
      }
      {
        principalId: identities[1].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Queue Data Contributor'
      }
      {
        principalId: identities[1].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }
      {
        principalId: identities[2].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Account Contributor'
      }
      {
        principalId: identities[2].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Owner'
      }
      {
        principalId: identities[2].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Queue Data Contributor'
      }
      {
        principalId: identities[2].outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }
    ]
    tags: tags
  }
}

module cosmos 'br/public:avm/res/document-db/database-account:0.15.0' = {
  name: 'cosmos'
  params: {
    name: cosmosAccountName
    location: location
    capabilitiesToAdd: [
      'EnableServerless'
    ]
    disableKeyBasedMetadataWriteAccess: true
    disableLocalAuthentication: true
    networkRestrictions: {
      ipRules: []
      publicNetworkAccess: 'Enabled'
      virtualNetworkRules: []
    }
    sqlDatabases: [
      {
        name: databaseName
        containers: [
          {
            name: containerName
            paths: [
              '/id'
            ]
          }
        ]
      }
    ]
    dataPlaneRoleAssignments: [for (app, index) in apps: {
      name: guid(cosmosAccountName, identities[index].outputs.principalId, 'data-contributor')
      principalId: identities[index].outputs.principalId
      roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosAccountName, '00000000-0000-0000-0000-000000000002')
    }]
    tags: tags
    zoneRedundant: false
  }
}

module functionApps './function-app.bicep' = [for (app, index) in apps: {
  name: 'function-app-${app.key}'
  params: {
    appKey: app.key
    applicationInsightsName: take('appi-${app.key}-${resourceToken}', 260)
    cosmosAccountEndpoint: cosmos.outputs.endpoint
    functionAppName: take('func-${app.key}-${resourceToken}', 60)
    identityClientId: identities[index].outputs.clientId
    identityResourceId: identities[index].outputs.resourceId
    location: location
    logAnalyticsWorkspaceResourceId: logAnalytics.outputs.resourceId
    packageContainerName: app.packageContainerName
    planName: take('plan-${app.key}-${resourceToken}', 40)
    storageAccountName: storage.outputs.name
    storageBlobEndpoint: storage.outputs.primaryBlobEndpoint
    tags: tags
  }
}]

output cosmosClientFunctionAppName string = functionApps[0].outputs.name
output databaseProxyFunctionAppName string = functionApps[1].outputs.name
output containerProxyFunctionAppName string = functionApps[2].outputs.name
