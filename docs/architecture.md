# Architecture

## Fluxo

```text
iPhone
  |
  v
Tracking API
  |
  v
TrackingSession
  |
  v
LocationPoints
  |
  v
RouteProgress
  |
  v
RaceRoute / RoutePoints
  |
  v
Public Tracking API
  |
  v
futuro frontend/mapa
```

## Entidades

- `Race`: prova/percurso, com `name`, `slug`, `distance_km` e `status`.
- `RaceRoute`: rota principal processada de uma `Race`.
- `RoutePoint`: ponto normalizado do GPX, preservando `sequence` e `cumulative_distance_m`.
- `Athlete`: atleta rastreado, sem dados pessoais desnecessarios.
- `TrackingSession`: sessao de rastreamento do atleta em uma prova, com `public_token` e `ingest_token` separados.
- `LocationPoint`: coordenada real recebida do celular, com `recorded_at` original e `client_point_id` opcional para idempotencia.

## Services

- `Geo::Distance`: Haversine em metros.
- `RaceRoutes::ImportGpx`: parseia GPX uma vez, calcula distancia acumulada e persiste pontos.
- `Tracking::ReceiveLocation`: recebe uma localizacao individual, valida sessao ativa e aplica idempotencia.
- `Tracking::ReceiveLocationBatch`: sincroniza lote de pontos mantendo `recorded_at`.
- `Tracking::NearestRoutePoint`: encontra o ponto mais proximo da rota com varredura O(n).
- `Tracking::RouteProgress`: calcula distancia estimada, percentual e distancia restante.

## Persistencia de rota

O GPX original fica em `data/routes/`. A aplicacao nao parseia XML em requests publicos; usa `RaceRoute` e `RoutePoint` persistidos no PostgreSQL.

## Performance

O MVP usa busca linear pelo ponto mais proximo da rota. Isso e simples e correto para milhares de pontos. Caso o volume de rotas, pontos ou requests cresca, `Tracking::NearestRoutePoint` e o ponto isolado para substituir por estrategia espacial, incluindo PostGIS no futuro.

## Seguranca

- `public_token` e usado somente para leitura publica.
- `ingest_token` e usado para escrita.
- Tokens sao aleatorios, unicos e nao enumeraveis.
- IDs sequenciais nao sao usados como identificador publico.
- `ingest_token` nao aparece nos endpoints publicos.
