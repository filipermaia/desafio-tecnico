# Desafio Técnico DevOps - Terraform + Docker

Infraestrutura como código para ambiente containerizado seguro com redes isoladas, proxy reverso e persistência de dados.

## 📋 Índice

- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração](#-configuração)
- [Como Executar](#-como-executar)
- [Testes](#-testes)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Limpeza](#-limpeza)
- [Referência Técnica](#-referência-técnica)

## 🏗 Arquitetura

```
Usuário (localhost:8080)
    ↓
┌────────────────────────────────────┐
│  Rede Externa (external_net)       │
│  ┌──────────────────────────────┐  │
│  │  Proxy (Nginx)               │  │
│  │  Porta 8080 → 80             │  │
│  └──────────────────────────────┘  │
└────────────┬───────────────────────┘
             │
┌────────────┴───────────────────────┐
│  Rede Interna (internal_net)       │
│  Isolada do host                   │
│                                    │
│  ┌──────────┐    ┌──────────┐      │
│  │ Frontend │    │ Backend  │      │
│  │ (Nginx)  │    │ (Node.js)│      │
│  └──────────┘    └─────┬────┘      │
│                        │           │
│                  ┌─────▼──────┐    │
│                  │ PostgreSQL │    │
│                  │   15.8     │    │
│                  │  + Volume  │    │
│                  └────────────┘    │
└────────────────────────────────────┘
```

### Conceitos Implementados

- **Proxy Reverso**: Nginx roteia `/` → frontend e `/api` → backend
- **Isolamento de Rede**: Apenas o proxy é exposto ao host
- **Persistência**: Volume Docker para dados do PostgreSQL
- **Segurança**: Credenciais via variáveis de ambiente
- **Alta Disponibilidade**: Restart automático de containers

## 🔧 Pré-requisitos

Antes de executar, certifique-se de ter instalado:

- **Docker** (v20.10+): `docker --version`
- **Terraform** (v1.0+): `terraform version`

### Instalação das Dependências

#### Docker

Siga a documentação oficial para seu sistema operacional:

👉 **[Instalar Docker Engine](https://docs.docker.com/engine/install/)**

Após a instalação, verifique:
```bash
docker --version
```

#### Terraform

Siga o guia oficial de instalação:

👉 **[Instalar Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)**

Após a instalação, verifique:
```bash
terraform version
```

## ⚙️ Configuração

### 1. Criar arquivo de variáveis

Crie um arquivo `terraform.tfvars` na raiz do projeto terraform com as seguintes configurações:

```hcl
# terraform.tfvars - NUNCA commitar este arquivo!

# Credenciais do banco de dados
db_user = "admin"
db_pass = "sua_senha_segura_aqui"
db_name = "desafio"

# Senha do usuário admin da aplicação
admin_password = "sua_senha_segura_aqui"

# Configurações de rede
db_host = "postgres"
db_port = 5432
back_port = 3000
```

> ⚠️ **IMPORTANTE**: O arquivo `terraform.tfvars` contém credenciais sensíveis e **NÃO** deve ser versionado no Git. Certifique-se de mantê-lo no `.gitignore`.

### 2. Estrutura de arquivos necessária

Verifique se você tem a seguinte estrutura:

```
terraform/
├── main.tf              # Provider Docker
├── variables.tf         # Definição de variáveis
├── terraform.tfvars     # ⚠️ Valores das variáveis (criar)
├── postgres.tf          # Container PostgreSQL + Volume persistente
├── backend.tf           # Container Backend + Imagem
├── frontend.tf          # Container Frontend + Imagem
├── proxy.tf             # Container Proxy (Nginx)
├── network.tf           # Redes Docker
├── outputs.tf           # Outputs informativos
├── backend/             # Código fonte backend
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── frontend/            # Código fonte frontend
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── proxy/               # Configuração proxy
│   └── nginx.conf
└── sql/                 # Scripts SQL
    └── script.sql
```

## 🚀 Como Executar

### Passo 1: Inicializar o Terraform

```bash
cd terraform
terraform init
```

Este comando irá:
- Baixar o provider Docker (kreuzwerker/docker v3.6.2)
- Preparar o backend local
- Validar a configuração

### Passo 2: Validar a configuração

```bash
terraform validate
```

Deve retornar: `Success! The configuration is valid.`

### Passo 3: Planejar a infraestrutura

```bash
terraform plan
```

Revise os recursos que serão criados:
- 2 redes Docker (external_net, internal_net)
- 1 volume Docker (postgres_data)
- 2 imagens Docker (backend, frontend)
- 4 containers Docker (postgres, backend, frontend, proxy)

### Passo 4: Aplicar a infraestrutura

```bash
terraform apply -auto-approve
```

O Terraform irá:
1. Criar as redes isoladas
2. Criar o volume persistente
3. Construir as imagens Docker customizadas
4. Iniciar os containers na ordem correta
5. Executar healthchecks e aguardar disponibilidade

> ⏱️ **Tempo estimado**: 1-2 minutos na primeira execução (build das imagens)

### Passo 5: Verificar os outputs

Após a aplicação bem-sucedida, você verá:

```
Outputs:

backend_internal = "http://backend:3000"
postgres_container = "postgres"
proxy_url = "http://localhost:8080"
```

## 🧪 Testes

### Teste 1: Verificar containers ativos

```bash
docker ps
```

Deve mostrar 4 containers rodando:
- `proxy` (nginx:alpine)
- `frontend` (imageID)
- `backend` (imageID)
- `postgres` (postgres:15.8-alpine)

### Teste 2: Acessar a aplicação

```bash
# Página frontend
curl http://localhost:8080

# API backend (via proxy)
curl http://localhost:8080/api

# Resposta esperada:
# {"database":true,"userAdmin":true}
```

### Teste 3: Abrir no navegador

Acesse: http://localhost:8080

Você deve ver a página HTML com:
- Botão "Verificar Backend e Banco"
- Ao clicar, deve mostrar:
  ```
  Database is up
  Migration runned
  ```

> 💡 **Nota**: Via `curl` a resposta é em JSON: `{"database":true,"userAdmin":true}`

### Teste 4: Verificar logs

```bash
# Ver logs de um container
docker logs backend

# Seguir logs em tempo real
docker logs -f backend
```

> 💡 Para verificar outros serviços, substitua `backend` por `postgres`, `frontend` ou `proxy`

### Teste 5: Validar isolamento de rede

```bash
# Tentar acessar backend diretamente (deve falhar)
curl http://localhost:3000
# curl: (7) Failed to connect to localhost port 3000

# Tentar acessar frontend diretamente (deve falhar)
curl http://localhost:80
# curl: (7) Failed to connect to localhost port 80

# Apenas o proxy está exposto!
```

## 📁 Estrutura do Projeto

```
.
├── main.tf              # Configuração do provider
├── variables.tf         # Definição de variáveis
├── terraform.tfvars     # Valores das variáveis (não versionar!)
├── outputs.tf           # Outputs informativos
├── network.tf           # Redes Docker (external + internal)
├── postgres.tf          # Container PostgreSQL + volume persistente
├── backend.tf           # Container Backend Node.js + build da imagem
├── frontend.tf          # Container Frontend Nginx  + build da imagem
└── proxy.tf             # Container Nginx (proxy reverso)
```

## 🧹 Limpeza

### Remover toda a infraestrutura

```bash
terraform destroy
```

Digite `yes` quando solicitado. Isso irá:
- Parar e remover todos os containers
- Remover as imagens customizadas
- Remover as redes Docker
- ⚠️ **Remover o volume com dados do PostgreSQL**

### Limpeza adicional (se necessário)

```bash
# Remover cache do Terraform
rm -rf .terraform .terraform.lock.hcl

# Remover state files (cuidado!)
rm -f terraform.tfstate terraform.tfstate.backup

# Limpar imagens Docker não utilizadas
docker system prune -a --volumes
```

## 🔒 Segurança

### Boas práticas implementadas:

1. **Isolamento de rede**: Backend e banco inacessíveis externamente
2. **Variáveis sensíveis**: Marcadas como `sensitive = true`
3. **Sem credenciais hardcoded**: Tudo via variáveis de ambiente
4. **Healthchecks**: PostgreSQL valida disponibilidade antes do backend
5. **Restart policies**: Containers reiniciam automaticamente

### Arquivos sensíveis (adicionar ao `.gitignore`):

```gitignore
# Terraform
terraform.tfvars
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Variáveis locais
.env
*.env
```

## 📚 Referência Técnica

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | 3.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_docker"></a> [docker](#provider\_docker) | 3.6.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [docker_container.backend](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/container) | resource |
| [docker_container.frontend](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/container) | resource |
| [docker_container.postgres](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/container) | resource |
| [docker_container.proxy](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/container) | resource |
| [docker_image.backend](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/image) | resource |
| [docker_image.frontend](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/image) | resource |
| [docker_network.external_net](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/network) | resource |
| [docker_network.internal_net](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/network) | resource |
| [docker_volume.postgres_data](https://registry.terraform.io/providers/kreuzwerker/docker/3.6.2/docs/resources/volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Admin user password | `string` | `""` | no |
| <a name="input_back_port"></a> [back\_port](#input\_back\_port) | Backend application port | `number` | `0` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | Database host | `string` | `""` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | `""` | no |
| <a name="input_db_pass"></a> [db\_pass](#input\_db\_pass) | Database password | `string` | `""` | no |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Database port | `number` | `0` | no |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | Database user | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_internal"></a> [backend\_internal](#output\_backend\_internal) | n/a |
| <a name="output_postgres_container"></a> [postgres\_container](#output\_postgres\_container) | n/a |
| <a name="output_proxy_url"></a> [proxy\_url](#output\_proxy\_url) | n/a |
<!-- END_TF_DOCS -->