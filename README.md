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
    subgraph TenantUnificado [Tenant Pessoal Unificado]
        direction LR

        subgraph AssinaturaAzure [Assinatura Azure e Recursos]
            DataLake["Data Lake e Views"];
            Databricks("Databricks Workspace");
            KeyVault("Azure Key Vault");
            Connector["Access Connector"];
        end

        subgraph AzureAD [Azure AD - Entra ID]
            Users["Usuarios Finais"];
            Groups["Grupos de Seguranca<br/>grp-data-pmo<br/>grp-data-finance"];
            SP["Service Principal<br/>(Para automacoes)"];
        end
    end
    
    %% Fluxo de Permissoes
    Groups -- "Permissao aos Dados (GRANT SELECT)" --> Databricks;
    Users -- "Sao Membros de" --> Groups;
    Connector -- "Permissao ao Storage" --> DataLake;
    Databricks -- "Usa Credencial de" --> Connector;
    Databricks -- "Le Segredos para Jobs" --> KeyVault;
    KeyVault -- "Armazena Segredos de" --> SP;
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
