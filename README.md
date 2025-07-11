# 🏷️ Generate Datadog Entity

> Gerador automático de arquivos `entity.datadog.yaml` baseado em informações de workflows CI/CD

[![GitHub](https://img.shields.io/badge/GitHub-Mottu--ops-blue?logo=github)](https://github.com/Mottu-ops)
[![Action](https://img.shields.io/badge/Action-Ready-green?logo=github-actions)](https://github.com/features/actions)
[![Shell](https://img.shields.io/badge/Shell-Bash-orange?logo=gnu-bash)](https://www.gnu.org/software/bash/)

## 🚀 Duas Formas de Usar

### 📱 1. GitHub Action (Recomendado)

Use como uma GitHub Action reutilizável em seus workflows:

```yaml
# .github/workflows/generate-datadog-entity.yml
name: Generate Datadog Entity

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  generate-entity:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Generate Datadog Entity
        uses: mottu-ops/generate-entity-dd@v1
        with:
          force: false
          commit-and-push: true
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### 💻 2. Execução Local

Execute diretamente na sua máquina:

```bash
# Clonar o repositório
git clone https://github.com/mottu-ops/generate-entity-dd.git
cd generate-entity-dd

# Tornar executável
chmod +x generate-datadog-entity.sh

# Executar no seu projeto
cp generate-datadog-entity.sh /caminho/para/seu/projeto/
cd /caminho/para/seu/projeto/
./generate-datadog-entity.sh
```

## 📋 GitHub Action - Inputs & Outputs

### Inputs

| Input | Descrição | Obrigatório | Padrão |
|-------|-----------|-------------|--------|
| `force` | Forçar sobrescrita do arquivo existente | Não | `false` |
| `working-directory` | Diretório de trabalho | Não | `.` |
| `commit-and-push` | Fazer commit e push automático do arquivo gerado | Não | `false` |
| `commit-message` | Mensagem personalizada para o commit | Não | `chore: generate/update entity.datadog.yaml` |
| `github-token` | Token GitHub para push (use secrets.GITHUB_TOKEN ou secrets.PAT) | Não | `''` |

### Outputs

| Output | Descrição |
|--------|-----------|
| `file-generated` | Se o arquivo foi gerado (`true`/`false`) |
| `file-path` | Caminho para o arquivo gerado |
| `project-type` | Tipo de projeto detectado |

## 🔧 Script Local - Opções

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

## 🔍 Tipos de Projeto Suportados

### 🅰️ Angular Frontend
- **Template**: `angular-deploy.yaml`
- **Campos**: `app_name`, `namespace`, `bu`, `team`, `nodeVersion`, `subdomain`
- **Detecção**: Busca por `angular-deploy` no workflow

### 🟢 NestJS Backend
- **Template**: `container-nodejs-kubernetes.yaml`
- **Campos**: `app_name`, `namespace`, `bu`, `team`, `nodeVersion`
- **Detecção**: Busca por `container-nodejs-kubernetes` no workflow

### 🔵 .NET Backend
- **Template**: `container-dotnet-kubernetes.yaml`
- **Campos**: `app_name`, `namespace`, `bu`, `team`, `dotnetVersion`, `dotnetSln`
- **Detecção**: Busca por `container-dotnet-kubernetes` no workflow

### 🐍 Python Backend
- **Template**: `container-python-kubernetes.yaml`
- **Campos**: `app_name`, `namespace`, `bu`, `team`, `stack`
- **Detecção**: Busca por `container-python-kubernetes` no workflow
- **Arquivos Python**: Analisa `pyproject.toml` e `requirements.txt` para detectar framework e versão

## 💡 Exemplos de Uso - GitHub Action

### Uso Básico
```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
```

### Com Sobrescrita Forçada
```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
  with:
    force: true
```

### Em Subdiretório
```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
  with:
    working-directory: './backend'
```

### Com Commit Automático
```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
  with:
    commit-and-push: true
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Com PAT (Personal Access Token)
```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
  with:
    commit-and-push: true
    github-token: ${{ secrets.PAT }}
    commit-message: "feat: add datadog entity configuration"
```

### Com Outputs
```yaml
- name: Generate Datadog Entity
  id: generate
  uses: mottu-ops/generate-entity-dd@v1

- name: Check Result
  run: |
    echo "File generated: ${{ steps.generate.outputs.file-generated }}"
    echo "Project type: ${{ steps.generate.outputs.project-type }}"
    echo "File path: ${{ steps.generate.outputs.file-path }}"
```

## 🔐 Configuração de Tokens

### 🎯 GITHUB_TOKEN (Recomendado)
Para a maioria dos casos, use o token automático do GitHub:

```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
  with:
    commit-and-push: true
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### 🔑 Personal Access Token (PAT)
Para repositórios com proteções especiais ou workflows mais complexos:

1. **Criar PAT**: Acesse GitHub → Settings → Developer settings → Personal access tokens
2. **Permissões necessárias**: `repo` (acesso completo ao repositório)
3. **Adicionar Secret**: No repositório, vá em Settings → Secrets and variables → Actions
4. **Nome do Secret**: `PAT`

```yaml
- name: Generate Datadog Entity
  uses: mottu-ops/generate-entity-dd@v1
  with:
    commit-and-push: true
    github-token: ${{ secrets.PAT }}
```

### ⚙️ Configuração Git
A action usa automaticamente as credenciais da Mottu:
- **Email**: `tech@mottu.com.br`
- **Nome**: `tech-mottu`

## 📦 Integração Automática

### Package.json (Angular/NestJS)
O script automaticamente detecta e utiliza informações do `package.json` quando disponível:

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

**Informações Extraídas:**
- **Nome do App**: Usado como fallback se não especificado no workflow
- **Versão**: Adicionada como tag `app-version`
- **Framework**: Detectado automaticamente (Angular, NestJS)
- **Versão do Angular**: Extraída das dependências

### Pyproject.toml (Python)
Para projetos Python, analisa `pyproject.toml` e `requirements.txt`:

```toml
[tool.poetry]
name = "python-backend"
version = "1.0.0"

[tool.poetry.dependencies]
python = "^3.9"
fastapi = "^0.104.0"
```

**Informações Extraídas:**
- **Nome do Projeto**: Extraído do pyproject.toml
- **Versão**: Versão da aplicação
- **Framework**: Django, FastAPI, Flask ou Python genérico
- **Versão do Python**: Extraída dos requisitos

## 🏗️ Workflow Completo - GitHub Action

```yaml
name: Generate and Deploy Datadog Entity

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  generate-entity:
    runs-on: ubuntu-latest
    outputs:
      file-generated: ${{ steps.generate.outputs.file-generated }}
      project-type: ${{ steps.generate.outputs.project-type }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Generate Datadog Entity
        id: generate
        uses: mottu-ops/generate-entity-dd@v1
        with:
          force: ${{ github.event_name == 'workflow_dispatch' }}
          commit-and-push: ${{ github.event_name == 'push' }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: "chore: update entity.datadog.yaml for ${{ github.repository }}"
      
      - name: Validate Generated File
        if: steps.generate.outputs.file-generated == 'true'
        run: |
          echo "✅ Generated entity.datadog.yaml for ${{ steps.generate.outputs.project-type }} project"
          cat entity.datadog.yaml
```

## 📄 Exemplos de Saída

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
    - subdomain:bino
  links:
    - name: Repository
      type: repository
      url: https://github.com/mottu-ops/bino-frontend
spec:
  type: web
  lifecycle: production
  tier: 2
  language: javascript
  dependencies: []
```

### Para Projeto Python
```yaml
apiVersion: v3
kind: service
metadata:
  name: python-backend
  displayName: Python-backend Service
  description: Python service python-backend managed by team platform
  owner: platform
  tags:
    - namespace:platform
    - bu:cross-bu
    - team:platform
    - project-type:python
    - python-version:3.9
    - python-framework:fastapi
  links:
    - name: Repository
      type: repository
      url: https://github.com/mottu-ops/python-backend
spec:
  type: web
  lifecycle: production
  tier: 2
  language: python
  dependencies: []
```

## 🔧 Desenvolvimento e Contribuição

### Pré-requisitos
- Bash shell (Linux/macOS/WSL)
- Git
- Projeto com workflow em `.github/workflows/`

### Estrutura do Projeto
```
generate-entity-dd/
├── action.yml                    # Definição da GitHub Action
├── generate-datadog-entity.sh    # Script principal
├── README.md                     # Esta documentação
└── examples/                     # Exemplos de uso
```

### Testando Localmente
```bash
# Clonar o repositório
git clone https://github.com/mottu-ops/generate-entity-dd.git
cd generate-entity-dd

# Tornar executável
chmod +x generate-datadog-entity.sh

# Testar em um projeto
cd /caminho/para/projeto/com/workflows
/caminho/para/generate-entity-dd/generate-datadog-entity.sh --help
/caminho/para/generate-entity-dd/generate-datadog-entity.sh
```

## 🐛 Troubleshooting

### Erro: "No workflow files found"
- Verifique se existe pasta `.github/workflows/`
- Confirme se há arquivos `.yml` ou `.yaml` na pasta
- Verifique se os workflows usam os templates suportados

### Erro: "Permission denied"
```bash
chmod +x generate-datadog-entity.sh
```

### Arquivo não é gerado
- Verifique se já existe `entity.datadog.yaml`
- Use `--force` para sobrescrever
- Verifique se o workflow contém os campos necessários

## 📄 Licença

Este projeto é licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

**Desenvolvido com ❤️ pela equipe Mottu-ops**
