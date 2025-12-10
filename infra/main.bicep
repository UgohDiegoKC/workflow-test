targetScope = 'subscription'

@description('The name of the resource group where the VNet is located')
param vnetResourceGroupName string

@description('The name of the Virtual Network')
param vnetName string

@description('The name of the subnet for Container Apps')
param subnetName string

@description('The name of the resource group where the Log Analytics Workspace is located')
param logAnalyticsResourceGroupName string

@description('The name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('The name of the resource group for the Container App Environment and Container App')
param containerAppEnvironmentResourceGroupName string

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

// Reference to existing Container App Environment and Container App resource group
resource containerAppEnvironmentRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: containerAppEnvironmentResourceGroupName
}

// Reference existing Container App Environment resources using module
module containerAppEnvironmentModule 'modules/container-app-environment.bicep' = {
  name: 'containerAppEnvironmentDeployment'
  scope: containerAppEnvironmentRg
  params: {
    vnetResourceGroupName: vnetResourceGroupName
    vnetName: vnetName
    subnetName: subnetName
    logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    containerAppEnvironmentResourceGroupName: containerAppEnvironmentResourceGroupName
    containerAppEnvironmentName: containerAppEnvironmentName
  }
}

// Deploy Container App resources using module
module containerAppModule 'modules/container-app.bicep' = {
  name: 'containerAppDeployment'
  scope: containerAppEnvironmentRg
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

// Reference to existing ACR resource group
resource acrRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: acrResourceGroupName
}

// Role assignment: AcrPull role for the managed identity on ACR (deployed via module)
module acrRoleAssignmentModule 'modules/acr-role-assignment.bicep' = {
  name: 'acrRoleAssignmentDeployment'
  scope: acrRg
  params: {
    acrName: acrName
    principalId: containerAppModule.outputs.containerAppIdentityPrincipalId
    roleAssignmentNameSeed: '${containerAppEnvironmentRg.id}-${containerAppName}'
  }
}

// Outputs
output containerAppEnvironmentName string = containerAppEnvironmentModule.outputs.containerAppEnvironmentName
output containerAppName string = containerAppModule.outputs.containerAppName
output containerAppFqdn string = containerAppModule.outputs.containerAppFqdn
output containerAppUrl string = containerAppModule.outputs.containerAppFqdn != '' ? 'https://${containerAppModule.outputs.containerAppFqdn}' : 'Internal endpoint (VNet-only)'
output vnetName string = containerAppEnvironmentModule.outputs.vnetName
output containerAppIdentityId string = containerAppModule.outputs.containerAppIdentityId
