# UTMB Trail Tracking API

Backend Rails API para um MVP de rastreamento de atletas em provas de trail running. O primeiro caso de uso e a UTMB Paraty, mas o dominio foi modelado para permitir novas provas e novos percursos.

## Stack

- Ruby on Rails API
- PostgreSQL
- RSpec
- Docker
- Docker Compose

Nao usa Redis, Sidekiq, Kafka, microservices, Elasticsearch, PostGIS, Google Maps ou frontend nesta etapa.

## Arquitetura inicial

O Rails concentra a regra de negocio em models e services. Controllers recebem parametros, autenticam tokens e delegam operacoes como ingestao de localizacoes, importacao de GPX e calculo de progresso.

```text
iPhone -> Tracking API -> TrackingSession -> LocationPoints
                           |
                           v
                         RouteProgress -> RaceRoute / RoutePoints
                           |
                           v
                         Public Tracking API
```

## Subir com Docker

```bash
docker compose up
```

A API sobe em `http://localhost:3000`.

Health check:

```bash
curl http://localhost:3000/health
```

## Rodar testes

```bash
docker compose run --rm -e RAILS_ENV=test api bundle exec rails db:prepare
docker compose run --rm -e RAILS_ENV=test api bundle exec rspec
```

## Seeds

```bash
docker compose run --rm api bundle exec rails db:seed
```

Cria `Athlete: Test Athlete` e `Race: UTMB Paraty Test`.

## Cadastrar Race manualmente

```bash
docker compose run --rm api bundle exec rails runner 'Race.create!(name: "UTMB Paraty 55K", slug: "utmb-paraty-55k", distance_km: 55, status: "active")'
```

## GPX oficial

Arquivos GPX reais devem ficar em `data/routes/`, por exemplo:

```text
data/routes/utmb_paraty_55k.gpx
data/routes/utmb_paraty_108k.gpx
```

Nenhuma coordenada oficial foi inventada. A pasta esta preparada para receber os GPX reais.

Importar GPX:

```bash
docker compose run --rm api bundle exec rails race_routes:import RACE_ID=1 FILE=data/routes/utmb_paraty_55k.gpx
```

A importacao parseia o XML uma vez, calcula distancia acumulada por Haversine e persiste `RoutePoint` normalizado no PostgreSQL.

## Criar TrackingSession

```bash
curl -X POST http://localhost:3000/api/v1/tracking_sessions \
  -H "Content-Type: application/json" \
  -d '{"athlete_id":1,"race_id":1}'
```

Resposta inclui `public_token` e `ingest_token`. O `ingest_token` deve ser usado apenas para escrita.

## Enviar localizacao

```bash
curl -X POST http://localhost:3000/api/v1/tracking_sessions/1/locations \
  -H "Authorization: Bearer INGEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": -23.123456,
    "longitude": -44.123456,
    "accuracy": 8.2,
    "altitude": 540.0,
    "recorded_at": "2026-08-17T10:30:00-03:00",
    "client_point_id": "uuid-opcional"
  }'
```

Se `client_point_id` ja existir na mesma sessao, a API retorna a localizacao existente sem duplicar.

## Enviar batch

```bash
curl -X POST http://localhost:3000/api/v1/tracking_sessions/1/locations/batch \
  -H "Authorization: Bearer INGEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"locations":[{"latitude":-23.1,"longitude":-44.1,"accuracy":10,"recorded_at":"2026-08-17T10:30:00-03:00","client_point_id":"p1"}]}'
```

O batch preserva `recorded_at` original e aplica idempotencia por `tracking_session_id + client_point_id` quando o id do cliente esta presente.

O comportamento atual do batch e all-or-nothing: se qualquer item for invalido, a transacao e revertida e nenhum ponto do lote e persistido.

## Consultar link publico

```bash
curl http://localhost:3000/api/v1/public/tracking/PUBLIC_TOKEN
```

Esse endpoint nao retorna `ingest_token` nem dados administrativos.

Historico publico paginado:

```bash
curl "http://localhost:3000/api/v1/public/tracking/PUBLIC_TOKEN/locations?page=1&per_page=50"
```

## Finalizar sessao

```bash
curl -X POST http://localhost:3000/api/v1/tracking_sessions/1/finish \
  -H "Authorization: Bearer INGEST_TOKEN"
```

Depois de finalizada, a sessao nao aceita novas localizacoes.

## Endpoints

- `GET /health`
- `POST /api/v1/tracking_sessions`
- `POST /api/v1/tracking_sessions/:id/locations`
- `POST /api/v1/tracking_sessions/:id/locations/batch`
- `POST /api/v1/tracking_sessions/:id/finish`
- `GET /api/v1/public/tracking/:public_token`
- `GET /api/v1/public/tracking/:public_token/locations`

## Limitacoes atuais

- Busca do ponto mais proximo e O(n) sobre os pontos da rota importada.
- Nao ha PostGIS nesta etapa.
- Nao ha autenticacao completa de usuarios.
- Nao ha frontend/mapa.
- Nao ha GPX oficial versionado ainda.
- Valores de progresso sao estimativas, nao medicao oficial da prova.

## Deploy no Render com Docker

Use o painel do Render manualmente, sem `render.yaml`.

Crie um Render PostgreSQL separado e configure a Web Service como Docker. O Render nao usa `docker-compose.yml`; ele builda somente o `Dockerfile`.

Build:

```text
Dockerfile
```

Start:

```bash
bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
```

Migration:

```bash
bundle exec rails db:migrate
```

Health check:

```text
GET /health
```

Variaveis de ambiente:

```text
DATABASE_URL=<Render PostgreSQL internal database URL>
RAILS_ENV=production
SECRET_KEY_BASE=<generated secret>
RAILS_LOG_TO_STDOUT=true
```

`PORT` e fornecida pelo Render para web services. Use `RAILS_MASTER_KEY` somente se a aplicacao passar a depender de Rails credentials em production; nao versione `config/master.key`.
