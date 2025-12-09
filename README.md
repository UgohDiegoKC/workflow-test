# Workflow Test App

This is a minimal test application for testing the GitHub Actions workflow that builds and pushes Docker images to Azure Container Registry.

## Structure

- `src/index.ts` - Simple Express.js server with health check endpoint
- `Dockerfile` - Multi-stage Docker build
- `.github/workflows/build-push-acr.yml` - GitHub Actions workflow
- `package.json` - Node.js dependencies

## Testing the Workflow

### Prerequisites

1. Ensure you have the `AZURE_CREDENTIALS` secret configured in your GitHub repository
2. Make sure the service principal has `AcrPush` role on the ACR

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

## Notes

- The workflow will tag images based on branch and commit SHA
- Images are pushed to: `workflowtest.azurecr.io/workflow-test-app:<tag>`
- The workflow uses Docker Buildx for advanced caching

