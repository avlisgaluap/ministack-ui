# MiniStack UI

UI web para inspecionar serviços AWS locais rodando no [MiniStack](https://github.com/ministackorg/ministack).

## Serviços suportados
- 🗃️ DynamoDB — tabelas, itens, GSIs
- 🪣 S3 — buckets, objetos, download
- 📨 SQS — filas, mensagens, enviar, purgar
- 📢 SNS — tópicos, assinaturas, publicar
- 🐘 RDS — instâncias, clusters, start/stop
- ⚡ Lambda — funções, invocar, logs, event sources

---

## Contribuição e workflow

Como o CI funciona

- Arquivo: `.github/workflows/publish.yml`
- Quando: o workflow roda em push para `main`.
- O que faz: builda as imagens e publica automaticamente no GitHub Container Registry; se os secrets do Docker Hub estiverem configurados pelos maintainers, também publicará no Docker Hub.
- Resumo prático: após merge para `main`, as imagens são publicadas automaticamente.

Como testar localmente sem publicar

1) Usar imagens públicas já publicadas (mais rápido):

```bash
docker-compose pull
docker-compose up -d
```

2) Buildar as imagens localmente e subir com o `docker-compose` local:

```bash
docker build -t local/ministack-ui-backend:dev ./backend
docker build -t local/ministack-ui-frontend:dev ./frontend
DOCKER_USER=local docker-compose up --build
```

3) Rodar só os serviços que precisa durante desenvolvimento (faster feedback):

```bash
docker-compose build ministack-ui-backend
docker-compose up ministack-ui-backend
```

4) Alternativa: executar serviços localmente sem Docker

- Você pode rodar o `backend` com `npm run dev` (entre na pasta `backend`) e o `frontend` com `npm run dev` (pasta `frontend`) se preferir debugging tradicional.


## Como usar em qualquer projeto

### Pré-requisito
Seu projeto precisa ter o MiniStack rodando em uma rede Docker.

### 1. Descubra o nome da rede Docker do seu projeto

```bash
docker network ls
# Ex: meu-projeto_default, dockerfiles_core-network
```

### 2. Adicione ao `docker-compose.yml` do seu projeto

```yaml
services:
  ministack-ui-backend:
    image: ghcr.io/open-platforms-org/ministack-ui-backend:latest
    environment:
      - MINISTACK_ENDPOINT=http://ministack:4566  # nome do container do MiniStack
      - AWS_REGION=us-east-1
    ports:
      - "3001:3001"
    networks:
      - sua-rede  # mesma rede do MiniStack

  ministack-ui-frontend:
    image: ghcr.io/open-platforms-org/ministack-ui-frontend:latest
    ports:
      - "3030:3000"
    depends_on:
      - ministack-ui-backend
    networks:
      - sua-rede
```

### 3. Suba

```bash
docker-compose up -d
# Acesse: http://localhost:3030
```

---

## Desenvolvimento (rodar localmente)

```bash
git clone https://github.com/open-platforms-org/ministack-ui.git
cd ministack-ui

# Copiar e ajustar variáveis
cp .env.example .env

# Subir
docker-compose up --build
```
-------------------------------------------
