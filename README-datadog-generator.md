# Gerador de Entity Datadog

Este script bash gera automaticamente o arquivo `entity.datadog.yaml` baseado nas informações do workflow de CI/CD do projeto.

## 🚀 Como Usar

### Pré-requisitos

- Bash shell (Linux/macOS/WSL)
- Projeto com arquivo de workflow em `.github/workflows/`
- Git (opcional, para extrair URL do repositório)

### Uso Básico
```bash
# Torne o script executável
chmod +x generate-datadog-entity.sh

# Execute o script (pula se o arquivo já existir)
./generate-datadog-entity.sh
```

### Opções Disponíveis
```bash
# Mostrar ajuda
./generate-datadog-entity.sh --help

# Forçar sobrescrita do arquivo existente
./generate-datadog-entity.sh --force

# Versão curta da opção force
./generate-datadog-entity.sh -f
```

### 🛡️ Proteção Contra Sobrescrita
O script **automaticamente verifica** se o arquivo `entity.datadog.yaml` já existe:
- ✅ **Arquivo não existe**: Gera normalmente
- ⚠️ **Arquivo existe**: Pula a geração e mostra aviso
- 🔄 **Com --force**: Sobrescreve o arquivo existente

## 📋 O que o Script Faz

1. **Busca workflows**: Procura arquivos `.yml` e `.yaml` em `.github/workflows/`
2. **Analisa package.json**: Se disponível, extrai informações adicionais como:
   - Nome do projeto
   - Versão da aplicação
   - Framework detectado (Angular, NestJS, React, Vue)
   - Versão do Angular (se aplicável)
3. **Extrai informações**: Coleta dados como:
   - `app_name` (workflow ou package.json)
   - `namespace`
   - `bu` (business unit)
   - `team`
   - `nodeVersion`/`dotnetVersion`
   - `name` (nome do workflow)
4. **Gera entity.datadog.yaml**: Cria o arquivo na raiz do projeto com informações combinadas

## 🔍 Tipos de Projeto Suportados

O script detecta automaticamente o tipo de projeto baseado no template usado no workflow:

### 🅰️ Angular (Frontend)
```yaml
jobs:
  Pipeline:
    uses: mottu-ops/pipeline-core/.github/workflows/angular-deploy.yaml@v2
    with:
      approvers: Phillipe42,oluizcarvalho
      output_path: 'dist/binoculars-front'
      minimum_approvals: 1
      node_version: 18
      datadog_service_name: 'bino'
      subdomain: 'bino'
      bu: 'rental'
      namespace: 'operations'
      team: 'operations'
```

### 🟢 NestJS (API)
```yaml
jobs:
  Pipeline:
    uses: mottu-ops/pipeline-core/.github/workflows/container-nodejs-kubernetes.yaml@v2
    with:
      namespace: platform
      app_name: platform-webhook-api
      bu: cross-bu
      team: platform
      nodeVersion: "22"
```

### 🔵 .NET (Backend)
```yaml
jobs:
  Pipeline:
    uses: mottu-ops/pipeline-core/.github/workflows/container-dotnet-kubernetes.yaml@v2
    with:
      dotnetSln: "mottu.sln"
      dotnetSources: '-s "https://nuget.pkg.github.com/Mottu-ops/index.json"'
      dotnetVersion: '8.0.x'
      app_name: payments-backend
      namespace: payments
      bu: rental-bu
      team: payments
```

### 🐍 Python (Backend)
```yaml
jobs:
  Pipeline:
    uses: mottu-ops/pipeline-core/.github/workflows/container-python-kubernetes.yaml@python-module-catalog
    with:
      namespace: "platform"
      app_name: "python-full121-auto"
      bu: "cross-bu"
      stack: "python"
```

## 📦 Integração com package.json

O script automaticamente detecta e utiliza informações do `package.json` quando disponível:

### 🔍 Detecção Automática de Framework
```json
{
  "name": "my-angular-app",
  "version": "1.2.3",
  "dependencies": {
    "@angular/core": "^17.0.0",
    "@angular/common": "^17.0.0"
  }
}
```

### 📊 Informações Extraídas
- **Nome do App**: Usado como fallback se não especificado no workflow
- **Versão**: Adicionada como tag `app-version`
- **Framework**: Detectado automaticamente (Angular, NestJS, React, Vue)
- **Versão do Angular**: Extraída das dependências e adicionada como tag

### 🔄 Prioridade de Informações
1. **Workflow** (prioridade alta)
2. **package.json** (fallback)
3. **Valores padrão** (último recurso)

## 📄 Exemplos de Saída

### Para Projeto NestJS
```yaml
apiVersion: v3
kind: service
metadata:
  name: platform-webhook-api
  displayName: Platform-webhook-api API
  description: NestJS API service platform-webhook-api managed by team platform
  owner: platform
  tags:
    - namespace:platform
    - bu:cross-bu
    - team:platform
    - project-type:nestjs
    - node-version:22
  links:
    - name: Repository
      type: repository
      url: https://github.com/mottu-ops/platform-webhook-api
    - name: CI/CD Pipeline
      type: other
      url: https://github.com/mottu-ops/platform-webhook-api/actions
    - name: Documentation
      type: documentation
      url: https://github.com/mottu-ops/platform-webhook-api#readme
spec:
  type: web
  lifecycle: production
  tier: 2
  language: javascript
  dependencies: []
```

### Para Projeto Angular
```yaml
apiVersion: v3
kind: service
metadata:
  name: bino
  displayName: Bino Frontend
  description: Frontend application bino built with Angular, managed by team operations
  owner: operations
  tags:
    - namespace:operations
    - bu:rental
    - team:operations
    - project-type:angular
    - node-version:18
    - angular-version:17
    - app-version:1.2.3
    - subdomain:bino
  links:
    - name: Repository
      type: repository
      url: https://github.com/mottu-ops/binoculars-front
    - name: CI/CD Pipeline
      type: other
      url: https://github.com/mottu-ops/binoculars-front/actions
    - name: Documentation
      type: documentation
      url: https://github.com/mottu-ops/binoculars-front#readme
spec:
  type: web
  lifecycle: production
  tier: 2
  language: typescript
  dependencies: []
```

### Para Projeto .NET
```yaml
apiVersion: v3
kind: service
metadata:
  name: payments-backend
  displayName: Payments-backend Service
  description: .NET service payments-backend managed by team payments
  owner: payments
  tags:
    - namespace:payments
    - bu:rental-bu
    - team:payments
    - project-type:dotnet
    - dotnet-version:8.0.x
  links:
    - name: Repository
      type: repository
      url: https://github.com/mottu-ops/payments-backend
    - name: CI/CD Pipeline
      type: other
      url: https://github.com/mottu-ops/payments-backend/actions
    - name: Documentation
      type: documentation
      url: https://github.com/mottu-ops/payments-backend#readme
spec:
  type: web
  lifecycle: production
  tier: 2
  language: csharp
  dependencies: []
```

### Para Projeto Python
```yaml
apiVersion: v3
kind: service
metadata:
  name: python-backend
  displayName: Python-backend Service
  description: Python service python-backend managed by team python
  owner: python
  tags:
    - namespace:python
    - bu:cross-bu
    - team:python
    - project-type:python
    - stack:python-3.9
  links:
    - name: Repository
      type: repository
      url: https://github.com/mottu-ops/python-backend
    - name: CI/CD Pipeline
      type: other
      url: https://github.com/mottu-ops/python-backend/actions
    - name: Documentation
      type: documentation
      url: https://github.com/mottu-ops/python-backend#readme
spec:
  type: web
  lifecycle: production
  tier: 2
  language: python
  dependencies: []
```

## ⚙️ Lógica de Mapeamento

### Detecção de Tipo de Projeto
- **Angular**: Detectado pelo template `angular-deploy.yaml`
- **NestJS**: Detectado pelo template `container-nodejs-kubernetes.yaml`
- **.NET**: Detectado pelo template `container-dotnet-kubernetes.yaml`
- **Python**: Detectado pelo template `container-python-kubernetes.yaml`

### Campos Específicos por Tipo

#### Angular
- **app_name**: Extraído de `datadog_service_name`
- **language**: `typescript`
- **Tags extras**: `subdomain`, `node-version`
- **Display Name**: `{nome} Frontend`

#### NestJS
- **app_name**: Extraído de `app_name`
- **language**: `javascript`
- **Tags extras**: `node-version`
- **Display Name**: `{nome} API`

#### .NET
- **app_name**: Extraído de `app_name`
- **language**: `csharp`
- **Tags extras**: `dotnet-version`
- **Display Name**: `{nome} Service`

#### Python
- **app_name**: Extraído de `app_name` (workflow) ou `name` (pyproject.toml)
- **language**: `python`
- **Tags extras**: `python-version`, `python-framework`, `app-version`
- **Display Name**: `{nome} Service`
- **Detecção de Framework**: Django, FastAPI, Flask ou Python genérico

### Tipo de Serviço (`spec.type`)
- **worker**: Se o nome contém `worker`, `job`, ou `cron`
- **queue**: Se o nome contém `queue`, `kafka`, ou `redis`
- **web**: Padrão para todos os tipos de projeto

### Tier (`spec.tier`)
- **1**: Para BUs críticas (`core`, `platform`, `critical`)
- **2**: Padrão para outras BUs

### Tags Automáticas
- **namespace**: Namespace do Kubernetes
- **bu**: Business Unit
- **team**: Equipe responsável
- **project-type**: Tipo do projeto (angular/nestjs/dotnet/python)
- **node-version**: Versão do Node.js (Angular/NestJS)
- **dotnet-version**: Versão do .NET (.NET)
- **python-version**: Versão do Python (extraída de pyproject.toml/requirements.txt)
- **python-framework**: Framework Python (django/fastapi/flask)
- **angular-version**: Versão do Angular (extraída do package.json)
- **app-version**: Versão da aplicação (extraída do package.json/pyproject.toml)
- **subdomain**: Subdomínio (Angular)

### Links Automáticos
- **Repository**: URL do repositório Git
- **CI/CD Pipeline**: Link para GitHub Actions
- **Documentation**: Link para README do repositório

## 🔧 Personalização

Para adaptar o script para outros padrões de workflow:

1. **Modificar campos de busca**: Altere as variáveis extraídas na função `find_workflow_info()`
2. **Ajustar mapeamentos**: Modifique a lógica de `service_type` e `tier`
3. **Adicionar validações**: Inclua novas verificações conforme necessário

## 🐛 Troubleshooting

### Erro: "No workflow files found"
- Verifique se existe a pasta `.github/workflows/`
- Confirme que há arquivos `.yml` ou `.yaml` na pasta

### Erro: "Could not extract 'app_name'"
- Verifique se o workflow contém o campo `app_name:`
- Confirme que o workflow segue o padrão esperado

### Erro: "Could not extract 'bu'"
- O script procura especificamente por workflows com campo `bu:`
- Verifique se o workflow usa o template da Mottu

## 📝 Notas

- O script é **reutilizável** para qualquer projeto que siga o padrão de workflow da Mottu
- Campos opcionais recebem valores padrão se não encontrados
- O arquivo `entity.datadog.yaml` é sobrescrito a cada execução
- Funciona tanto em repositórios Git quanto em projetos locais (com funcionalidades limitadas)
