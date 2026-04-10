// Model deployment for an Azure OpenAI model on an existing account

@description('Name of the parent Azure OpenAI service')
param openAiServiceName string

@description('Azure region (unused but kept for consistency)')
param location string

@description('Name for the model deployment')
param deploymentName string = 'gpt-5-mini'

@description('SKU name for the deployment')
param deploymentSkuName string = 'GlobalStandard'

@description('Capacity in thousands of tokens per minute')
param deploymentCapacity int = 10

@description('Model version')
param modelVersion string = '2025-08-07'

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: openAiServiceName
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAi
  name: deploymentName
  sku: {
    name: deploymentSkuName
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5-mini'
      version: modelVersion
    }
  }
}

output deploymentName string = deployment.name
