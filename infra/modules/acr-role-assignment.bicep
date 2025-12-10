targetScope = 'resourceGroup'

@description('The name of the Azure Container Registry')
param acrName string

@description('The principal ID for the role assignment')
param principalId string

@description('A unique identifier for the role assignment name')
param roleAssignmentNameSeed string

// Reference to existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// Role assignment: AcrPull role for the managed identity on ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleAssignmentNameSeed, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43b172e22efd') // AcrPull
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

