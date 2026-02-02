# Histórico de Desenvolvimento

Registro cronológico detalhado das etapas realizadas durante o desafio DevOps.

---

## Fase 1: Planejamento e Arquitetura

### 1. Roadmap Inicial
- Definição da ordem de execução das tarefas
- Decisão do desenho da arquitetura

### 2. Definição da Arquitetura
Componentes escolhidos:
- **Proxy**: Nginx
- **Frontend**: Nginx (servindo HTML estático)
- **Backend**: Node.js
- **Database**: PostgreSQL 15.8

### 3. Mapeamento de Portas
```
Frontend:   80 (interno)
Backend:    3000 (interno)
PostgreSQL: 5432 (interno)
Proxy:      8080:80 (exposto ao host)
```

### 4. Definição de Nomes dos Containers
- `proxy`
- `frontend`
- `backend`
- `postgres`

### 5. Identificação de Variáveis de Ambiente
- `user` - Usuário do banco de dados
- `pass` - Senha do banco de dados
- `host` - Host do banco de dados
- `db_name` - Nome do database
- `db_port` - Porta do PostgreSQL
- `back_port` - Porta do backend

---

## Fase 2: Implementação Docker Compose

### 6. Criação do Dockerfile do Backend
Dockerfile para aplicação Node.js

### 7. Criação do Dockerfile do Frontend
Dockerfile para servir HTML com Nginx

### 8. Criação do nginx.conf
Configuração do proxy reverso:
- Rota `/` → Frontend
- Rota `/api` → Backend

### 9. Criação do Diretório do Proxy
- Criado diretório `proxy/`
- Adicionado `nginx.conf` do proxy

### 10. Criação do Docker Compose
Arquivo `docker-compose.yml` inicial com todos os serviços

### 11. Criação das Variáveis de Ambiente
Arquivo `.env` com credenciais e configurações

### 12. Correção de Problemas no Backend
- **Problema**: Variáveis não estavam definidas corretamente
- **Solução**: Ajuste nas variáveis de ambiente

### 13. Atualização do README
Documentação da arquitetura implementada até o momento

---

## Fase 3: Primeiro Deploy e Debugging

### 14. Primeira Execução
```bash
docker compose up -d
```
Verificação de logs e testes iniciais

### 15. Problemas Identificados

#### Problema 1: Frontend Acessível Diretamente
- **Sintoma**: Frontend acessível tanto por `8080` (proxy) quanto `3001` (direto)
- **Esperado**: Apenas proxy deveria ser acessível

#### Problema 2: Erro no PostgreSQL
- **Sintoma**: `database "admin" does not exist`
- **Debug realizado**:
  1. `docker compose exec postgres bash` para investigar
  2. Adicionado nome do database na string de conexão (não resolveu)
  3. Alterado script SQL (não resolveu, retornado ao original)
  4. Verificado config do backend: `docker compose exec backend sh -c 'cat /app/index.js'`
  5. Backend ainda usava modelo inicial sem database explícito
  6. Removidas imagens Docker locais: `docker rmi ids`
  7. Recriado tudo novamente
- **Resultado**: Aplicação conectou, mas log ainda mostrava erro

#### Problema 3: Healthcheck Incorreto
- **Causa raiz**: Healthcheck do PostgreSQL sem database explicitado
- **Comportamento**: Tentava conectar ao database "admin" (default) que não existia
- **Solução**: Ajustado healthcheck com database correto
- **Ação**: Recriada imagem do Postgres

### 16. Aplicação Funcionando, Mas...
Backend e Frontend ainda parecem expostos diretamente

**Causa identificada**: Docker Compose inicial configurado com apenas uma rede (`app_network`), permitindo que todos os containers fossem acessíveis diretamente do host.

#### Testes Realizados

**Via Browser:**
- ✅ Proxy (8080): Página carrega e botão funciona
- ⚠️ Frontend (3001): Página carrega mas botão não funciona
- ✅ Backend (3000): Internal server error (esperado)

**Via curl:**
- ✅ Proxy (8080/api): `{"database":true,"userAdmin":true}`
- ⚠️ Frontend (3001): HTML da página retornado
- ⚠️ Backend (3000): `{"database":true,"userAdmin":true}`

**Conclusão**: Necessário implementar isolamento de rede para restringir acesso apenas via proxy.

---

## Fase 4: Isolamento de Rede

### 17. Ajuste na String de Conexão
Alterada variável para `db_name` apontando para `/desafio`
```bash
docker compose down -v && docker compose up -d --build
```

### 18. Reestruturação das Redes Docker
**Problema**: Com apenas `app_network`, todos os serviços ficavam acessíveis externamente.

**Solução**: Editado `docker-compose.yml` para implementar arquitetura de rede com isolamento:

**Configuração anterior:**
- ❌ `app_network` (bridge) - Única rede para todos os containers

**Nova configuração:**
- ✅ `external_net` - Rede externa (proxy ↔ host)
- ✅ `internal_net` - Rede interna isolada (proxy ↔ serviços)

**Configuração de networks:**
- **Proxy**: Conectado a `external_net` + `internal_net` (ponte entre redes)
- **Frontend, Backend, Postgres**: Apenas `internal_net` (isolados do host)

**Portas internas (expose):**
- Frontend: `80`
- Backend: `3000`
- Postgres: `5432`

**Portas externas (ports):**
- Proxy: `8080:80` (única porta exposta ao host)

```bash
docker compose down -v && docker compose up -d --build
```

### 19. ✅ Isolamento Funcionando
- **Browser**: Aplicação carrega apenas via proxy `localhost:8080`
- **curl**: Funciona apenas para endereço do proxy
- **Acesso direto**: Frontend, backend e postgres inacessíveis externamente

---

## Fase 5: Correções e Melhorias

### 20. Correção de Erro no Backend
**Problema**: Erro ao tentar reconexão no banco
```
Database not connected - Error: Client has already been connected. 
You cannot reuse a client
```
**Solução**: Cliente conecta apenas no início e mantém a sessão

### 21. Implementação de Auto-Restart
Adicionado política de restart nos containers:
```yaml
restart: unless-stopped
```

**Teste realizado**: Kill manual nos containers para validar reinício
```bash
docker compose exec "container" kill -9 1
```

---

## Fase 6: Migração para Terraform

### 22. Início da Adaptação
- Projeto até aqui foi feito usando Docker Compose (para testes)
- Iniciando conversão para Terraform

### 23. Criação dos Arquivos Terraform
Arquivos criados:
- `main.tf` - Provider Docker
- `volumes.tf` - Volumes persistentes
- `network.tf` - Redes Docker
- `images.tf` - Build de imagens customizadas
- `container.tf` - Definição de containers
- `variables.tf` - Variáveis de entrada
- `outputs.tf` - Outputs informativos
- `terraform.tfvars` - Valores das variáveis

### 24. Primeiro Deploy Terraform
```bash
terraform init
terraform plan
```

**Erro encontrado**: Absolute path required
```
Error: must be an absolute path
```

**Solução**: Adicionada função `abspath()` ao `${path.module}` nos volumes

```bash
terraform plan
terraform apply -auto-approve
```

### 25. Ambiente Subiu, Mas...
- ✅ Containers rodando
- ✅ Página web carrega pelo proxy
- ❌ Backend não conecta ao database

### 26. Ajustes nos Containers
Adicionado aos containers:
```hcl
destroy_grace_seconds = 10
```

### 27. Ajustes nas Imagens
Adicionado às imagens:
```hcl
force_remove = true
```

### 28. Correção de Variáveis
**Problemas identificados**:
- Variável `pass` estava como `password` no Terraform
- Variável `db_name` estava como `dbname` no Terraform
- Variável `db_port` estava como `dbport` no Terraform

**Solução**: Padronizadas todas as variáveis

```bash
terraform plan
terraform apply -auto-approve
```

### 29. ✅ Terraform Funcionando
Ambiente provisionado com sucesso via Terraform!

---

## Fase 7: Otimizações e Refatoração

### 30. Análise de Melhorias
Avaliação de:
- Uso de módulos Terraform
- Possíveis pontos de melhoria/correção

### 31. Implementação de Healthcheck
Adicionado healthcheck ao PostgreSQL:
```hcl
healthcheck {
  test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
  interval = "10s"
  timeout  = "5s"
  retries  = 5
}
```
**Comportamento**: 
- Container fica em `waiting` até healthcheck ficar `healthy`
- Apenas após isso as aplicações dependentes são criadas

### 32. Migração de Credenciais para Migrations
- **Problema**: Credenciais do usuário presentes no script SQL
- **Solução**: Adicionada etapa de migration no `index.js`
    - Inserção de dados via código usando variáveis de ambiente
    - Maior segurança (sem hardcoded credentials)

### 33. Refatoração do Código
- **Decisão**: Não foi necessário criar módulos Terraform
- **Ação**: Refatoração aplicada separando cada aplicação por arquivo:
    - `postgres.tf` - PostgreSQL + volume
    - `backend.tf` - Backend + imagem
    - `frontend.tf` - Frontend + imagem
    - `proxy.tf` - Proxy Nginx
    - `network.tf` - Redes
    - `variables.tf` - Variáveis
    - `outputs.tf` - Outputs
    - `main.tf` - Provider

### 34. Documentação Completa
Criação de documentação abrangente:
- `README.md` - Instruções completas de uso
- `DEVELOPMENT.md` - Este histórico de desenvolvimento
- `terraform.tfvars.example` - Template de configuração

---

## Conclusão

✅ Ambiente containerizado funcional com isolamento de rede  
✅ Infraestrutura como código com Terraform  
✅ Proxy reverso configurado corretamente  
✅ Persistência de dados implementada  
✅ Credenciais gerenciadas via variáveis de ambiente  
✅ Auto-restart configurado  
✅ Healthchecks implementados  
✅ Documentação completa  