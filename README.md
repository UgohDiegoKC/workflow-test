# Workflow Test App

This is a minimal test application for testing the GitHub Actions workflow that builds and pushes Docker images to Azure Container Registry, and deploys them to Azure Container Apps.

## Structure

- `src/index.ts` - Simple Express.js server with health check endpoint
- `Dockerfile` - Multi-stage Docker build
- `.github/workflows/build-push-acr.yml` - GitHub Actions workflow for building and pushing to ACR
- `.github/workflows/deploy-container-app.yml` - GitHub Actions workflow for deploying to Container App
- `infra/main.bicep` - Bicep template for infrastructure (VNet, Container App Environment, Container App)
- `infra/main.parameters.bicep` - Bicep parameters file
- `package.json` - Node.js dependencies

## Infrastructure Deployment

### Prerequisites

1. Ensure you have the `AZURE_CREDENTIALS` secret configured in your GitHub repository
2. Make sure the service principal has the following permissions:
   - `Contributor` role at **subscription level** (for creating resource groups and deploying resources)
   - `User Access Administrator` role at **subscription level** (for role assignments)
   - `AcrPush` role on the ACR (for building and pushing images)
3. The Azure Container Registry (`workflowtest`) must already exist in the `workflowtest-rg` resource group

### Deploy Infrastructure

The infrastructure is deployed at **subscription level** and creates the following resources:

#### Resource Groups Created:
- `rg-cae-test` - Container App Environment resources
- `rg-capp-test` - Container App resources

#### Resources Created:
- **Virtual Network** (`vnet-cae-test`) with a `/23` subnet (`10.0.0.0/23`) for Container Apps
- **Container App Environment** (`cae-test`) with **internal VNet integration** (VNet-only access)
- **Container App** (`capp-test`) configured to use the image from ACR
- **Log Analytics Workspace** for monitoring
- **User-assigned Managed Identity** with AcrPull permissions on ACR

#### Deployment Command

The infrastructure can be deployed using Azure CLI:

```bash
az deployment sub create \
  --location eastus \
  --template-file ./infra/main.bicep \
  --parameters @./infra/main.parameters.bicep \
    acrName=workflowtest \
    acrResourceGroupName=workflowtest-rg \
    imageName=workflow-test-app \
    imageTag=latest \
    containerAppEnvironmentResourceGroupName=rg-cae-test \
    containerAppResourceGroupName=rg-capp-test \
    containerAppEnvironmentName=cae-test \
    containerAppName=capp-test
```

**Note:** The Container App is configured for **internal VNet access only**. It is not publicly accessible and can only be reached from resources within the VNet or connected via VPN/ExpressRoute.

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
- Creates resource groups, VNet, subnet, Container App Environment, and Container App
- Deploys/updates the Container App using the specified image from ACR
- Uses subscription-level Bicep templates for infrastructure deployment
- Container App is configured for **internal VNet access only** (not publicly accessible)

## Notes

- The build workflow will tag images based on branch and commit SHA
- Images are pushed to: `workflowtest.azurecr.io/workflow-test-app:<tag>`
- The build workflow uses Docker Buildx for advanced caching
- The deployment workflow creates all infrastructure resources (resource groups, VNet, Container App Environment, Container App)
- Container App is configured for **internal VNet access only** - it cannot be accessed from the public internet
- To access the Container App, you need to be connected to the VNet via:
  - A VM in the same VNet
  - VPN connection to the VNet
  - ExpressRoute connection
  - Azure Bastion or jump host in the VNet
- The Container App's internal FQDN will be displayed in the deployment workflow summary

