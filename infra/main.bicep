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

// Variável para o nome da nossa conta de armazenamento (Data Lake).
// Nomes de storage account precisam ser únicos globalmente, com letras minúsculas e números.
// st (2) + tpsnow (6) + uniqueString (13) = 21 caracteres. Perfeito.
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

// NOVO RECURSO: Definição da nossa Conta de Armazenamento (Data Lake Gen2)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // LRS (Locally-redundant storage) é o mais barato e suficiente.
  }
  kind: 'StorageV2'
  properties: {
    // A linha abaixo é o que transforma uma conta de armazenamento comum
    // em um Data Lake Gen2 com sistema de arquivos hierárquico.
    isHnsEnabled: true
  }
}


// =================================================================   
// SAÍDAS (OUTPUTS) - Valores que queremos que o deploy nos retorne
// =================================================================   

@description('O nome da conta de armazenamento (Data Lake) criada.')
output dataLakeName string = storageAccount.name
