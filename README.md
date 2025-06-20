# Projeto de Portfólio: Consolidar tasks do planner com do spm do service now

Este projeto demonstra a construção de uma plataforma de dados completa, desde a ingestão até o consumo, utilizando práticas modernas de Engenharia de Dados, DataOps e Infraestrutura como Código.

## 🎯 Objetivo

O objetivo é integrar dados de gestão de projetos do **ServiceNow** e de gestão de tarefas do **MS Planner**. Os dados são processados e modelados para criar produtos de dados confiáveis, que podem ser consumidos por analistas e ferramentas de BI. A arquitetura segue os princípios do Data Mesh para promover autonomia e escalabilidade.

## 🏗️ Arquitetura da Solução

A arquitetura foi desenhada utilizando a abordagem "Diagrams as Code" com Mermaid, permitindo que a documentação seja versionada junto com o código-fonte.

```mermaid
graph TD;
    subgraph "Fontes de Dados"
        A["MS Planner"]
        B["ServiceNow"]
    end

    subgraph "Orquestração"
        C["Apache Airflow on Azure"]
    end

    subgraph "Plataforma de Dados (Azure)"
        D["Data Lake (Bronze)"]
        E["Azure Databricks"]
        F["Data Lake (Silver/Trusted)"]
        G["Azure Synapse SQL (Views)"]
    end

    subgraph "Consumo / Produtos de Dados"
        H["Power BI"]
        I["Usuários via SQL"]
    end

    %% Conexões
    A -- "Ingestão via PythonOperator" --> C;
    B -- "Ingestão via PythonOperator" --> C;
    C -- "Grava dados brutos em" --> D;
    C -- "Dispara Job de Transformação" --> E;
    E -- "Lê de" --> D;
    E -- "Grava dados limpos em" --> F;
    G -- "Expõe Views sobre" --> F;
    H -- "Acessa" --> G;
    I -- "Acessa" --> G;