targetScope = 'subscription'

@description('The name of the resource group where the VNet is located')
param vnetResourceGroupName string

@description('The name of the Virtual Network')
param vnetName string

@description('The name of the subnet for Container Apps')
param subnetName string

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
// Uses the same resource group as ACR
resource containerAppEnvironmentRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: acrResourceGroupName
}

// Reference existing Container App Environment resources using module
module containerAppEnvironmentModule 'modules/container-app-environment.bicep' = {
  name: 'containerAppEnvironmentDeployment'
  scope: containerAppEnvironmentRg
  params: {
    vnetResourceGroupName: vnetResourceGroupName
    vnetName: vnetName
    subnetName: subnetName
    containerAppEnvironmentName: containerAppEnvironmentName
  }
}

// Reference to existing ACR resource group
resource acrRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: acrResourceGroupName
}

// Step 1: Create managed identity first
module managedIdentityModule 'modules/managed-identity.bicep' = {
  name: 'managedIdentityDeployment'
  scope: containerAppEnvironmentRg
  params: {
    containerAppName: containerAppName
    location: location
  }
}

// Step 2: Assign AcrPull role to the managed identity (depends on identity creation)
module acrRoleAssignmentModule 'modules/acr-role-assignment.bicep' = {
  name: 'acrRoleAssignmentDeployment'
  scope: acrRg
  dependsOn: [
    managedIdentityModule  // Ensure identity exists before role assignment
  ]
  params: {
    acrName: acrName
    principalId: managedIdentityModule.outputs.identityPrincipalId
    roleAssignmentNameSeed: '${containerAppEnvironmentRg.id}-${containerAppName}'
  }
}

// Step 3: Deploy Container App using existing identity (depends on role assignment)
// This ensures the role assignment has been created before the Container App tries to pull the image
module containerAppModule 'modules/container-app.bicep' = {
  name: 'containerAppDeployment'
  scope: containerAppEnvironmentRg
  dependsOn: [
    containerAppEnvironmentModule
    acrRoleAssignmentModule  // Ensure role assignment exists before Container App creation
  ]
  params: {
    location: location
    containerAppName: containerAppName
    containerAppEnvironmentId: containerAppEnvironmentModule.outputs.containerAppEnvironmentId
    acrName: acrName
    imageName: imageName
    imageTag: imageTag
    containerPort: containerPort
    managedIdentityId: managedIdentityModule.outputs.identityId
    managedIdentityPrincipalId: managedIdentityModule.outputs.identityPrincipalId
  }
}

// Outputs
output containerAppEnvironmentName string = containerAppEnvironmentModule.outputs.containerAppEnvironmentName
output containerAppName string = containerAppModule.outputs.containerAppName
output containerAppFqdn string = containerAppModule.outputs.containerAppFqdn
output containerAppUrl string = containerAppModule.outputs.containerAppFqdn != '' ? 'https://${containerAppModule.outputs.containerAppFqdn}' : 'Internal endpoint (VNet-only)'
output vnetName string = containerAppEnvironmentModule.outputs.vnetName
output containerAppIdentityId string = managedIdentityModule.outputs.identityId
output containerAppIdentityPrincipalId string = managedIdentityModule.outputs.identityPrincipalId
