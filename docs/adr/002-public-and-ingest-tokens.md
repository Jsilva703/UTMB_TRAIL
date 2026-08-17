# ADR 002: Public and ingest tokens

## Contexto

Familiares precisam consultar o tracking por link publico, enquanto o celular do atleta precisa escrever localizacoes. Leitura publica e escrita possuem riscos diferentes.

## Decisao

Cada `TrackingSession` possui dois tokens diferentes:

- `public_token`: consulta publica.
- `ingest_token`: envio de localizacoes e encerramento.

Ambos sao aleatorios, unicos e indexados.

## Alternativas consideradas

- Usar o ID sequencial da sessao.
- Usar um unico token para leitura e escrita.
- Criar autenticacao completa de usuarios nesta etapa.

## Consequencias

- O link publico nao permite escrita.
- O endpoint publico nao expoe `ingest_token`.
- O MVP evita autenticacao complexa sem abrir mao da separacao basica de acesso.
