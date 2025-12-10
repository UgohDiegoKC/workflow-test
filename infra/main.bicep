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

// Virtual Network (deployed to Container App Environment resource group)
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-${containerAppEnvironmentName}'
  location: location
  scope: containerAppEnvironmentRg
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet-containerapps'
        properties: {
          addressPrefix: containerAppsSubnetAddressPrefix
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

// Subnet reference for Container App Environment
resource containerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'subnet-containerapps'
  parent: vnet
}

// Log Analytics Workspace for Container App Environment (deployed to Container App Environment resource group)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${containerAppEnvironmentName}'
  location: location
  scope: containerAppEnvironmentRg
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container App Environment with VNet integration (deployed to Container App Environment resource group)
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvironmentName
  location: location
  scope: containerAppEnvironmentRg
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: containerAppsSubnet.id
      internal: true
    }
  }
}

// User-assigned managed identity for Container App (deployed to Container App resource group)
resource containerAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'identity-${containerAppName}'
  location: location
  scope: containerAppRg
}

// Role assignment: AcrPull role for the managed identity on ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerAppRg.id, containerAppIdentity.id, 'AcrPull')
  scope: resourceId(acrResourceGroupName, 'Microsoft.ContainerRegistry/registries', acrName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43b172e22efd') // AcrPull
    principalId: containerAppIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Container App (deployed to Container App resource group)
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  scope: containerAppRg
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: false
        targetPort: containerPort
        allowInsecure: false
        transport: 'auto'
      }
      registries: [
        {
          server: '${acrName}.azurecr.io'
          identity: containerAppIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrName}.azurecr.io/${imageName}:${imageTag}'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// Outputs
output containerAppEnvironmentName string = containerAppEnvironment.name
output containerAppName string = containerApp.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output vnetName string = vnet.name
output containerAppIdentityId string = containerAppIdentity.id
