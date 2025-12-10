targetScope = 'subscription'

@description('The name of the resource group for the Container App Environment')
param containerAppEnvironmentResourceGroupName string

@description('The name of the resource group for the Container App')
param containerAppResourceGroupName string

@description('The location for all resources')
param location string

@description('The name of the Container App Environment')
param containerAppEnvironmentName string

@description('The name of the Container App')
param containerAppName string

@description('The name of the Azure Container Registry')
param acrName string

@description('The resource group name where the Azure Container Registry is located')
param acrResourceGroupName string

@description('The name of the container image')
param imageName string

@description('The tag of the container image (defaults to latest)')
param imageTag string

@description('The port the container listens on')
param containerPort int

@description('The VNet address prefix')
param vnetAddressPrefix string

@description('The subnet address prefix for Container Apps')
param containerAppsSubnetAddressPrefix string

// Resource Group for Container App Environment
resource containerAppEnvironmentRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: containerAppEnvironmentResourceGroupName
  location: location
}

// Resource Group for Container App
resource containerAppRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: containerAppResourceGroupName
  location: location
}

// Deploy Container App Environment resources using module
module containerAppEnvironmentModule 'modules/container-app-environment.bicep' = {
  name: 'containerAppEnvironmentDeployment'
  scope: containerAppEnvironmentRg
  params: {
    location: location
    containerAppEnvironmentName: containerAppEnvironmentName
    vnetAddressPrefix: vnetAddressPrefix
    containerAppsSubnetAddressPrefix: containerAppsSubnetAddressPrefix
  }
}

// Deploy Container App resources using module
module containerAppModule 'modules/container-app.bicep' = {
  name: 'containerAppDeployment'
  scope: containerAppRg
  params: {
    location: location
    containerAppName: containerAppName
    containerAppEnvironmentId: containerAppEnvironmentModule.outputs.containerAppEnvironmentId
    acrName: acrName
    imageName: imageName
    imageTag: imageTag
    containerPort: containerPort
  }
}

// Role assignment: AcrPull role for the managed identity on ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerAppRg.id, containerAppModule.outputs.containerAppIdentityId, 'AcrPull')
  scope: resourceId(acrResourceGroupName, 'Microsoft.ContainerRegistry/registries', acrName)
  dependsOn: [
    containerAppModule
  ]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43b172e22efd') // AcrPull
    principalId: containerAppModule.outputs.containerAppIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output containerAppEnvironmentName string = containerAppEnvironmentModule.outputs.containerAppEnvironmentName
output containerAppName string = containerAppModule.outputs.containerAppName
output containerAppFqdn string = containerAppModule.outputs.containerAppFqdn
output containerAppUrl string = 'https://${containerAppModule.outputs.containerAppFqdn}'
output vnetName string = containerAppEnvironmentModule.outputs.vnetName
output containerAppIdentityId string = containerAppModule.outputs.containerAppIdentityId
