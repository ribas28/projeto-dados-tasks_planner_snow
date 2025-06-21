// =================================================================   
// PARÂMETROS
// =================================================================   

@description('Prefixo CURTO (máx 10 caracteres) para todos os recursos a serem criados.')
param projectName string = 'tpsnow' 

@description('Localização geográfica onde os recursos serão criados.')
param location string = resourceGroup().location

@description('O Object ID do usuário ou principal que receberá todas as permissões no Key Vault.')
param keyVaultAdminObjectId string


// =================================================================   
// VARIÁVEIS
// =================================================================   

var keyVaultName = 'kv-${projectName}-${uniqueString(resourceGroup().id)}'
var storageAccountName = 'st${projectName}${uniqueString(resourceGroup().id)}'

// Nome do Workspace do Databricks. Precisa ser único globalmente.
var databricksWorkspaceName = 'dbw-${projectName}-${uniqueString(resourceGroup().id)}'
// Nome do Grupo de Recursos que o Databricks irá criar e gerenciar.
var databricksManagedResourceGroupName = 'mrg-${projectName}-${uniqueString(resourceGroup().id)}'


// =================================================================   
// RECURSOS
// =================================================================   

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  // ... (código do Key Vault continua o mesmo, sem alterações)
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        objectId: keyVaultAdminObjectId
        tenantId: subscription().tenantId
        permissions: {
          keys: ['all']
          secrets: ['all']
          certificates: ['all']
        }
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  // ... (código do Storage Account continua o mesmo, sem alterações)
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
  }
}

resource bronzeContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  // ... (código do contêiner bronze continua o mesmo, sem alterações)
  name: '${storageAccount.name}/default/bronze'
  properties: {
    publicAccess: 'None'
  }
}

resource silverContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  // ... (código do contêiner silver continua o mesmo, sem alterações)
  name: '${storageAccount.name}/default/silver'
  properties: {
    publicAccess: 'None'
  }
}

// NOVO RECURSO: Workspace do Azure Databricks
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: databricksWorkspaceName
  location: location
  // O SKU 'premium' permite controle de acesso por usuário em notebooks, etc.
  // Essencial para um ambiente colaborativo e seguro.
  sku: {
    name: 'premium'
  }
  properties: {
    // Definimos aqui o nome do Resource Group que o Databricks vai criar e gerenciar.
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', databricksManagedResourceGroupName)
  }
}


// =================================================================   
// SAÍDAS (OUTPUTS)
// =================================================================   

@description('O nome da conta de armazenamento (Data Lake) criada.')
output dataLakeName string = storageAccount.name

@description('O nome do workspace do Databricks criado.')
output databricksWorkspaceName string = databricksWorkspace.name
