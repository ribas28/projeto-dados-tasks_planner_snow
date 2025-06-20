// =================================================================   
// PARÂMETROS - Valores que passamos na hora do deploy
// =================================================================   

// Parâmetro para o nome do projeto, usado para nomear os recursos.
// RECURSOS DO AZURE TÊM REGRAS DE NOME, ESPECIALMENTE DE TAMANHO.
// Usaremos um nome curto e sem caracteres especiais.
@description('Prefixo CURTO (máx 10 caracteres) para todos os recursos a serem criados.')
param projectName string = 'tpsnow' // Abreviação de Tasks Planner Snow

// Parâmetro para a localização. O padrão será a do grupo de recursos.
@description('Localização geográfica onde os recursos serão criados.')
param location string = resourceGroup().location

// Parâmetro para o ID do usuário que terá acesso total ao Key Vault.
// Vamos passar o seu próprio ID de usuário aqui.
@description('O Object ID do usuário ou principal que receberá todas as permissões no Key Vault.')
param keyVaultAdminObjectId string


// =================================================================   
// VARIÁVEIS - Nomes e configurações que montamos dentro do arquivo
// =================================================================   

// O nome do nosso Key Vault. Nomes de Key Vault precisam ser únicos globalmente.
// Vamos usar o nome do projeto + um sufixo único para garantir.
// Com o projectName 'tpsnow' (6) + 'kv-' (3) + '-' (1) + uniqueString (13) = 23 caracteres. PERFEITO!
var keyVaultName = 'kv-${projectName}-${uniqueString(resourceGroup().id)}'


// =================================================================   
// RECURSOS - A infraestrutura que será criada no Azure
// =================================================================   

// Definição do nosso Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    // ID do Tenant do seu Azure AD. O Bicep pega isso automaticamente.
    tenantId: subscription().tenantId
    sku: {
      name: 'standard' // O SKU gratuito é suficiente para nosso projeto.
      family: 'A'
    }
    // Política de acesso: QUEM pode fazer O QUÊ neste cofre.
    accessPolicies: [
      {
        // O ID do usuário que passamos como parâmetro.
        objectId: keyVaultAdminObjectId
        tenantId: subscription().tenantId
        // Permissões completas para chaves, segredos e certificados.
        permissions: {
          keys: ['all']
          secrets: ['all']
          certificates: ['all']
        }
      }
    ]
  }
}
