targetScope = 'subscription'

@minLength(1)
@maxLength(64)
param environmentName string

param location string

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var resourceGroupName = 'rg-${environmentName}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

module resources './resources.bicep' = {
  name: 'resources'
  scope: resourceGroup
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
  }
}

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output COSMOSCLIENT_FUNCTION_APP_NAME string = resources.outputs.cosmosClientFunctionAppName
output DATABASEPROXY_FUNCTION_APP_NAME string = resources.outputs.databaseProxyFunctionAppName
output CONTAINERPROXY_FUNCTION_APP_NAME string = resources.outputs.containerProxyFunctionAppName
