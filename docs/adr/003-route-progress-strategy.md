# ADR 003: Route progress strategy

## Contexto

Para estimar progresso, a API precisa projetar a posicao GPS real do atleta sobre a rota oficial processada.

## Decisao

Usar inicialmente uma busca linear O(n) sobre `RoutePoint` para encontrar o ponto mais proximo e derivar:

- distancia estimada percorrida;
- percentual estimado;
- distancia restante estimada.
- distancia em metros entre o GPS recebido e o ponto de rota escolhido.

## Alternativas consideradas

- PostGIS com indices espaciais.
- Estruturas em memoria.
- Pre-processamento por tiles ou bounding boxes.

## Consequencias

- Implementacao simples, correta e testavel para o MVP.
- O algoritmo fica isolado em `Tracking::NearestRoutePoint`.
- `distance_from_route_m` ajuda consumidores da API a avaliar se a projecao parece confiavel quando o atleta esta distante do percurso.
- Se escala exigir, a estrategia pode ser substituida por PostGIS sem mudar os controllers.
