// Main orchestrator for Azure OpenAI deployment
// Run with: azd up
targetScope = 'subscription'

@description('Azure region for all resources')
param location string

@description('Environment name (used to generate unique resource names)')
param environmentName string

@allowed(['dev', 'test', 'prod'])
@description('Environment type — controls capacity and SKU defaults')
param environmentType string = 'dev'

@description('Name of the resource group')
param resourceGroupName string = 'rg-${environmentName}'

@description('Name of the Azure OpenAI service')
param openAiServiceName string = 'openai-${environmentName}'

@description('SKU for the Azure OpenAI service')
param openAiSkuName string = 'S0'

@description('Name for the model deployment')
param deploymentName string = 'gpt-5-mini'

@description('SKU name for the model deployment')
param deploymentSkuName string = 'GlobalStandard'

@description('Capacity in thousands of tokens per minute (0 = use environment default)')
param deploymentCapacity int = 0

@description('Model version')
param modelVersion string = '2025-08-07'

// Environment-based capacity defaults
var environmentCapacityDefaults = {
  dev: 10
  test: 20
  prod: 60
}
var effectiveCapacity = deploymentCapacity > 0 ? deploymentCapacity : environmentCapacityDefaults[environmentType]

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    project: 'agent-skills-demo'
    environment: environmentName
    'environment-type': environmentType
    'managed-by': 'azd'
  }
}

// Azure OpenAI (Cognitive Services) account
module openAi 'modules/cognitive-services.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    name: openAiServiceName
    location: location
    skuName: openAiSkuName
  }
}

// Model deployment (parameterized)
module modelDeployment 'modules/model-deployment.bicep' = {
  name: 'modelDeployment'
  scope: rg
  params: {
    openAiServiceName: openAi.outputs.name
    location: location
    deploymentName: deploymentName
    deploymentSkuName: deploymentSkuName
    deploymentCapacity: effectiveCapacity
    modelVersion: modelVersion
  }
}

// Outputs for azd and downstream use
output AZURE_OPENAI_ENDPOINT string = openAi.outputs.endpoint
output AZURE_OPENAI_DEPLOYMENT_NAME string = modelDeployment.outputs.deploymentName
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_OPENAI_ACCOUNT_ID string = openAi.outputs.id
