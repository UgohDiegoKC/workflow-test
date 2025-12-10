targetScope = 'resourceGroup'

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

@description('The name of the resource group where the Container App Environment is located')
param containerAppEnvironmentResourceGroupName string

@description('The name of the Container App Environment')
param containerAppEnvironmentName string

// Reference to existing VNet resource group
resource vnetRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: vnetResourceGroupName
}

// Reference to existing Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: vnetRg
}

// Reference to existing Subnet
resource containerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: subnetName
  parent: vnet
}

// Reference to existing Log Analytics Workspace resource group
resource lawRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: logAnalyticsResourceGroupName
}

// Reference to existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: lawRg
}

// Reference to existing Container App Environment resource group
resource caeRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: containerAppEnvironmentResourceGroupName
}

// Reference to existing Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnvironmentName
  scope: caeRg
}

// Outputs
output containerAppEnvironmentId string = containerAppEnvironment.id
output containerAppEnvironmentName string = containerAppEnvironment.name
output vnetName string = vnet.name
output subnetId string = containerAppsSubnet.id

