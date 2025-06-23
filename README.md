# Projeto de Portfólio: Plataforma de Engenharia de Dados

Este projeto demonstra a construção de uma plataforma de dados de ponta a ponta, desde a ingestão da fonte de dados (ServiceNow) até a camada de consumo governada, utilizando práticas modernas de Engenharia de Dados, DataOps e arquitetura Multi-Tenant.

## 🎯 Objetivo

O objetivo é ingerir dados de gestão de projetos do **ServiceNow**, processá-los e transformá-los em uma camada confiável (Silver), e então expor "Produtos de Dados" seguros para diferentes grupos de usuários (PMO e Performance Financeira). O acesso a esses produtos é solicitado e automatizado através de um fluxo de chamados no próprio ServiceNow, implementando um ciclo completo de governança de dados.

## 🏗️ Arquitetura Detalhada do Projeto

A arquitetura do projeto é dividida em três visões complementares: o fluxo de dados, a estrutura de segurança e o processo de negócio para solicitação de acesso.

### 1. Arquitetura de Dados (Fluxo de Dados)

Este diagrama mostra o caminho que os dados percorrem, desde a origem até se tornarem informação útil para o consumidor final.

```mermaid
graph TD;
    subgraph Fonte_SNOW["Fonte de Dados"]
        A["ServiceNow API"]
    end
    subgraph Orquestracao["Orquestração"]
        B("Apache Airflow")
    end
    subgraph Processamento["Processamento"]
        C("Azure Databricks")
    end
    subgraph Armazenamento["Armazenamento - Data Lake (Tenant Pessoal)"]
        D["Bronze Layer<br/>(Parquet)"]
        E["Silver Layer<br/>(Parquet / Delta)"]
    end
    subgraph CamadaAcesso["Camada de Acesso - SQL Layer"]
        F["Views de Dados<br/>(Data Products)"]
    end
    subgraph Consumidores["Consumidores"]
        G["Grupo PMO"]
        H["Grupo Perf. Financeira"]
        I["Ferramentas de BI"]
    end

    A -- "Ingestão Agendada" --> B;
    B -- "Dispara Job de Processamento" --> C;
    C -- "Grava Dados Brutos" --> D;
    C -- "Lê Dados Brutos" --> D;
    C -- "Grava Dados Limpos" --> E;
    F -- "Lê Dados da Camada Silver" --> E;
    G -- "Acessa View Específica" --> F;
    H -- "Acessa View Específica" --> F;
    I -- "Conecta nas Views" --> F;
```

### 2. Arquitetura de Segurança
```mermaid
graph TD;
    subgraph Tenant_Pessoal [Tenant Pessoal / Data Center]
        direction LR
        subgraph Assinatura_Azure [Assinatura Azure com Créditos]
            DataLake[Data Lake / Views];
            Databricks(Databricks Workspace);
            KeyVault(Azure Key Vault);
            Connector["Access Connector for<br/>Azure Databricks"];
        end
    end

    subgraph Tenant_M365 [Tenant M365 / Escritório]
        direction LR
        subgraph Azure_AD [Azure AD / Entra ID]
            Users[Usuários Finais];
            Groups[Grupos de Segurança<br/>grp-data-pmo<br/>grp-data-finance];
            SP["Service Principal<br/>(Para jobs específicos<br/>e autenticação legada)"];
        end
    end
    
    subgraph UnityCatalog [Dentro do Databricks]
        direction LR
        Credencial["Storage Credential<br/>(Usa o Access Connector)"];
        Localizacao["External Location<br/>(Usa a Credencial)"];
    end

    %% Fluxo de Permissões do Unity Catalog (O Novo Modelo)
    Connector -- "1. Permissão de Acesso ao Storage<br/>(Storage Blob Data Contributor)" --> DataLake;
    Credencial -- "2. Aponta Para" --> Connector;
    Localizacao -- "3. Registra o Caminho e Usa" --> Credencial;
    
    %% Fluxo de Permissões de Usuários
    Groups -- "4. Permissão aos Dados<br/>(GRANT SELECT nas Tabelas/Views)" --> Databricks;
    Users -- "5. São Membros" --> Groups;

    %% Fluxo de Segredos para outras automações
    KeyVault -- "6. Armazena Segredos<br/>(API SNOW, etc.)" --> SP;
    Databricks -- "7. Lê Segredos<br/>(Para notebooks específicos)" --> KeyVault;
```

### 3. Processo de Negócio para Solicitação de Acesso
```mermaid
sequenceDiagram
    actor Usuário
    participant ServiceNow
    actor Gerente
    participant LogicApp as "Azure Logic App"
    participant AAD as "Azure AD (Tenant M365)"

    Usuário->>ServiceNow: Abre chamado "Solicitar Acesso<br/>ao Produto de Dados PMO"
    ServiceNow->>Gerente: Notifica sobre pendência de aprovação
    Gerente->>ServiceNow: Aprova o chamado
    ServiceNow-->>LogicApp: Dispara gatilho "Chamado Aprovado" via Webhook
    LogicApp->>AAD: Faz chamada à API para<br/>adicionar Usuário ao grupo "grp-data-pmo"
    
    Note right of AAD: Permissão concedida instantaneamente!
```
