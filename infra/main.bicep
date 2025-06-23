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
var databricksWorkspaceName = 'dbw-${projectName}-${uniqueString(resourceGroup().id)}'
var databricksManagedResourceGroupName = 'mrg-${projectName}-${uniqueString(resourceGroup().id)}'

// Variável para o nome do nosso novo recurso Access Connector
var accessConnectorName = 'ac-${projectName}-${uniqueString(resourceGroup().id)}'
// ID da Role "Storage Blob Data Contributor". Este ID é fixo.
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'


// =================================================================   
// RECURSOS
// =================================================================   

// Recursos existentes (Key Vault, Storage Account, Databricks, etc.)
// ... (O código anterior para estes recursos permanece o mesmo) ...
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
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
  name: '${storageAccount.name}/default/bronze'
  properties: {
    publicAccess: 'None'
  }
}
resource silverContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/silver'
  properties: {
    publicAccess: 'None'
  }
}
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: databricksWorkspaceName
  location: location
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', databricksManagedResourceGroupName)
  }
}

// NOVO RECURSO: O "Embaixador" Access Connector for Azure Databricks
resource accessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: accessConnectorName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

// NOVO RECURSO: A Permissão
// Dando ao "Embaixador" a permissão de "Storage Blob Data Contributor" no nosso Data Lake
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(accessConnector.id, storageAccount.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: accessConnector.identity.principalId // ID do nosso "Embaixador"
    principalType: 'ServicePrincipal'
  }
}


// =================================================================   
// SAÍDAS (OUTPUTS)
// =================================================================   

@description('O nome da conta de armazenamento (Data Lake) criada.')
output dataLakeName string = storageAccount.name

@description('O nome do workspace do Databricks criado.')
output databricksWorkspaceName string = databricksWorkspace.name

// NOVA SAÍDA: O ID do nosso "Embaixador" para usarmos no Databricks
@description('O Resource ID do Access Connector para ser usado na criação da Storage Credential.')
output accessConnectorId string = accessConnector.id
