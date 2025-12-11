targetScope = 'resourceGroup'

@description('The name of the resource group where the VNet is located')
param vnetResourceGroupName string

@description('The name of the Virtual Network')
param vnetName string

@description('The name of the subnet for Container Apps')
param subnetName string

@description('The name of the Container App Environment')
param containerAppEnvironmentName string

// Construct resource ID for cross-resource-group reference
var subnetId = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

// Reference to existing Container App Environment (in the same resource group as module scope)
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnvironmentName
}

// Outputs
output containerAppEnvironmentId string = containerAppEnvironment.id
output containerAppEnvironmentName string = containerAppEnvironment.name
output vnetName string = vnetName
output subnetId string = subnetId

