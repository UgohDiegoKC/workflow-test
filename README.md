# Workflow Test App

This is a minimal test application for testing the GitHub Actions workflow that builds and pushes Docker images to Azure Container Registry, and deploys them to Azure Container Apps.

## Structure

- `src/index.ts` - Simple Express.js server with health check endpoint
- `Dockerfile` - Multi-stage Docker build
- `.github/workflows/build-push-acr.yml` - GitHub Actions workflow for building and pushing to ACR
- `.github/workflows/deploy-container-app.yml` - GitHub Actions workflow for deploying to Container App
- `infra/main.bicep` - Main Bicep template orchestrating infrastructure deployment
- `infra/main.parameters.json` - Bicep parameters file
- `infra/modules/container-app-environment.bicep` - Module for Container App Environment
- `infra/modules/container-app.bicep` - Module for Container App deployment
- `package.json` - Node.js dependencies

## Infrastructure Deployment

### Prerequisites

1. Ensure you have the `AZURE_CREDENTIALS` secret configured in your GitHub repository with the following JSON format:
   ```json
   {
     "clientSecret": "...",
     "subscriptionId": "...",
     "tenantId": "...",
     "clientId": "..."
   }
   ```
2. Make sure the service principal has the following permissions:
   - `Contributor` role at **subscription level** (for creating resource groups and deploying resources)
   - `AcrPull` role on the ACR (for pulling images - already configured)
   - `AcrPush` role on the ACR (for building and pushing images)
3. The Azure Container Registry (`workflowtest`) must already exist in the `workflowtest-rg` resource group

### Deploy Infrastructure

The infrastructure is deployed at **subscription level** and creates the following resources:

#### Resource Groups Used:
- Uses existing resource group `workflowtest-rg` (same as ACR) for all Container App resources

#### Resources Created:
- **Container App Environment** (`cae-test`) with **internal VNet integration** (VNet-only access)
- **Container App** (`capp-test-new`) configured to use the image from ACR with Service Principal authentication
- **Log Analytics Workspace** for monitoring (created as part of Container App Environment)

#### Authentication

The Container App authenticates to Azure Container Registry using the Service Principal from `AZURE_CREDENTIALS`. The SPN's client ID and secret are extracted from the GitHub secret and securely passed to the Bicep template. The SPN must already have the `AcrPull` role assigned on the ACR at the subscription level.

#### Deployment Order

The infrastructure deployment follows a specific order:

1. **Container App Environment** - Creates the managed environment
2. **Container App** - Creates the Container App using Service Principal credentials for ACR authentication

No managed identity creation or role assignment is needed since the existing SPN from `AZURE_CREDENTIALS` is used directly.

#### Deployment Command

The infrastructure can be deployed using Azure CLI. Note that `spnClientId` and `spnClientSecret` are required parameters (extracted from `AZURE_CREDENTIALS` in the GitHub workflow):

```bash
az deployment sub create \
  --name "container-app-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')" \
  --location eastus2 \
  --template-file ./infra/main.bicep \
  --parameters @./infra/main.parameters.json \
    vnetResourceGroupName=Vnet-RG \
    vnetName=vnet-cae-test \
    subnetName=subnet-containerapps \
    containerAppEnvironmentName=cae-test \
    acrName=workflowtest \
    acrResourceGroupName=workflowtest-rg \
    imageName=workflow-test-app \
    imageTag=latest \
    containerAppName=capp-test-new \
    spnClientId=<SPN_CLIENT_ID> \
    spnClientSecret=<SPN_CLIENT_SECRET>
```

**Note:** When deploying via GitHub Actions, the SPN credentials are automatically extracted from the `AZURE_CREDENTIALS` secret and passed to the deployment.

**Note:** The Container App is configured for **internal VNet access only**. It is not publicly accessible and can only be reached from resources within the VNet or connected via VPN/ExpressRoute.

**Prerequisites:**
- The Virtual Network (`vnet-cae-test`) must exist in resource group `Vnet-RG`
- The subnet (`subnet-containerapps`) must exist in the VNet
- The Azure Container Registry (`workflowtest`) must exist in resource group `workflowtest-rg`
- The container image must exist in ACR before deployment (e.g., `workflowtest.azurecr.io/workflow-test-app:latest`)

## Testing the Workflow

### Prerequisites

1. Ensure you have the `AZURE_CREDENTIALS` secret configured in your GitHub repository
2. Make sure the service principal has `AcrPush` role on the ACR
3. Infrastructure must be deployed first (see above)

### Testing Options

1. **Manual Trigger (Recommended for testing):**
   - Go to Actions tab in GitHub
   - Select "Build and Push to ACR" workflow
   - Click "Run workflow"
   - Optionally provide a custom tag
   - Click "Run workflow"

2. **Push to main/develop branch:**
   ```bash
   git add .
   git commit -m "Test workflow"
   git push origin main
   ```

3. **Test locally (without pushing):**
   ```bash
   docker build -t workflow-test-app:local .
   docker run -p 3000:3000 workflow-test-app:local
   ```

## Application Endpoints

- `GET /` - Returns app info
- `GET /health` - Health check endpoint (used by Docker healthcheck)

## Workflows

### Build and Push to ACR

- Automatically triggers on pushes to `main` or `develop` branches
- Builds Docker image and pushes to Azure Container Registry
- Tags images based on branch and commit SHA
- Images are pushed to: `workflowtest.azurecr.io/workflow-test-app:<tag>`
- Uses Docker Buildx for advanced caching

### Deploy Container App

- Automatically triggers after successful "Build and Push to ACR" workflow
- Can also be manually triggered with optional image tag parameter
- Extracts Service Principal credentials from `AZURE_CREDENTIALS` secret
- Creates Container App Environment and Container App
- Deploys/updates the Container App using the specified image from ACR
- Uses Service Principal authentication for ACR image pulling (no managed identity required)
- Uses subscription-level Bicep templates with modular architecture for infrastructure deployment
- Container App is configured for **internal VNet access only** (not publicly accessible)

## Notes

- The build workflow will tag images based on branch and commit SHA
- Images are pushed to: `workflowtest.azurecr.io/workflow-test-app:<tag>`
- The build workflow uses Docker Buildx for advanced caching
- The deployment workflow uses the Service Principal from `AZURE_CREDENTIALS` for ACR authentication
- The SPN's client ID and secret are securely extracted from the GitHub secret and passed to the Bicep template
- The Service Principal must have the `AcrPull` role on the ACR (configured at subscription level)
- Container App is configured for **internal VNet access only** - it cannot be accessed from the public internet
- To access the Container App, you need to be connected to the VNet via:
  - A VM in the same VNet
  - VPN connection to the VNet
  - ExpressRoute connection
  - Azure Bastion or jump host in the VNet
- The Container App's internal FQDN will be displayed in the deployment workflow summary
- No managed identity is created - the existing Service Principal from `AZURE_CREDENTIALS` is used directly for ACR authentication

