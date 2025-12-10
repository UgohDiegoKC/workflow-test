@description('The name of the resource group for the Container App Environment')
param containerAppEnvironmentResourceGroupName string = 'rg-cae-test'

@description('The name of the resource group for the Container App')
param containerAppResourceGroupName string = 'rg-capp-test'

@description('The location for all resources')
param location string = 'eastus'

@description('The name of the Container App Environment')
param containerAppEnvironmentName string = 'cae-test'

@description('The name of the Container App')
param containerAppName string = 'capp-test'

@description('The name of the Azure Container Registry')
param acrName string = 'workflowtest'

@description('The resource group name where the Azure Container Registry is located')
param acrResourceGroupName string = 'workflowtest-rg'

@description('The name of the container image')
param imageName string = 'workflow-test-app'

@description('The tag of the container image (defaults to latest)')
param imageTag string = 'latest'

@description('The port the container listens on')
param containerPort int = 3000

@description('The VNet address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('The subnet address prefix for Container Apps')
param containerAppsSubnetAddressPrefix string = '10.0.0.0/23'
