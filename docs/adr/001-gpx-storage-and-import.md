# ADR 001: GPX storage and import

## Contexto

O sistema precisa usar o GPX oficial da prova para estimar progresso do atleta na rota. Reparsear XML a cada request publico deixaria a API mais lenta e misturaria I/O com calculo de tracking.

## Decisao

Manter o GPX original versionado no projeto em `data/routes/` e importar seus pontos uma vez para PostgreSQL em `RaceRoute` e `RoutePoint`.

## Alternativas consideradas

- Parsear o GPX em toda requisicao.
- Guardar apenas o arquivo GPX sem normalizar pontos.
- Buscar ou gerar coordenadas externamente.

## Consequencias

- Requests publicos consultam dados normalizados no banco.
- A importacao fica explicita por rake task.
- GPX real ainda precisa ser fornecido posteriormente.
- Nao ha coordenadas oficiais inventadas nesta etapa.
