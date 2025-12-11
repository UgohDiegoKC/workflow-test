targetScope = 'resourceGroup'

@description('The name of the Container App (used to name the identity)')
param containerAppName string

@description('The location for the managed identity')
param location string

// User-assigned managed identity for Container App
resource containerAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'identity-${containerAppName}'
  location: location
}

// Outputs
output identityId string = containerAppIdentity.id
output identityPrincipalId string = containerAppIdentity.properties.principalId
output identityName string = containerAppIdentity.name

