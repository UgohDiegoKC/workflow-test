targetScope = 'resourceGroup'

@description('The location for all resources')
param location string

@description('The name of the Container App')
param containerAppName string

@description('The Container App Environment resource ID')
param containerAppEnvironmentId string

@description('The name of the Azure Container Registry')
param acrName string

@description('The name of the container image')
param imageName string

@description('The tag of the container image')
param imageTag string

@description('The port the container listens on')
param containerPort int

@description('The resource ID of the existing managed identity')
param managedIdentityId string

@description('The principal ID of the existing managed identity')
param managedIdentityPrincipalId string

// Reference to existing managed identity (using resource ID to get name)
var identityName = last(split(managedIdentityId, '/'))

resource containerAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
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
output containerAppName string = containerApp.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppIdentityId string = containerAppIdentity.id
output containerAppIdentityPrincipalId string = managedIdentityPrincipalId

