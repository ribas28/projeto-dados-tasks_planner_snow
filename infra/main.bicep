// =================================================================   
// PARÂMETROS - Valores que passamos na hora do deploy
// =================================================================   

@description('Prefixo CURTO (máx 10 caracteres) para todos os recursos a serem criados.')
param projectName string = 'tpsnow' 

@description('Localização geográfica onde os recursos serão criados.')
param location string = resourceGroup().location

@description('O Object ID do usuário ou principal que receberá todas as permissões no Key Vault.')
param keyVaultAdminObjectId string


// =================================================================   
// VARIÁVEIS - Nomes e configurações que montamos dentro do arquivo
// =================================================================   

var keyVaultName = 'kv-${projectName}-${uniqueString(resourceGroup().id)}'
var storageAccountName = 'st${projectName}${uniqueString(resourceGroup().id)}'


// =================================================================   
// RECURSOS - A infraestrutura que será criada no Azure
// =================================================================   

// Definição do nosso Key Vault
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

// Definição da nossa Conta de Armazenamento (Data Lake Gen2)
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

// NOVOS RECURSOS: Contêineres dentro do Data Lake
// Este é um recurso "filho" do storageAccount. Note o tipo e o nome.

// Contêiner para a camada BRONZE (dados brutos)
resource bronzeContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  // O nome é composto pelo nome da conta de armazenamento, /default/ e o nome do contêiner
  name: '${storageAccount.name}/default/bronze'
  properties: {
    // Acesso público desabilitado por segurança.
    publicAccess: 'None'
  }
}

// Contêiner para a camada SILVER (dados limpos e transformados)
resource silverContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/silver'
  properties: {
    publicAccess: 'None'
  }
}


// =================================================================   
// SAÍDAS (OUTPUTS) - Valores que queremos que o deploy nos retorne
// =================================================================   

@description('O nome da conta de armazenamento (Data Lake) criada.')
output dataLakeName string = storageAccount.name
