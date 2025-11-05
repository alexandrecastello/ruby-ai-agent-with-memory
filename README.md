# Agente CRM com Memória e Embeddings

Agente inteligente de Follow-up Comercial (CRM) com memória de curto e longo prazo, usando embeddings para enriquecer o contexto.

## Como Executar

### Opção 1: Usando Docker (Recomendado)

```bash
# Build da imagem
docker-compose build

# Executar o agente
docker-compose run --rm agent

# Ou executar diretamente
docker-compose up
```

### Opção 2: Localmente (sem Docker)

```bash
# Instalar dependências
bundle install

# Executar o agente
ruby bin/agent

# Ou tornar executável e rodar diretamente
chmod +x bin/agent
./bin/agent
```

## Configuração

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```
OPENAI_API_KEY=sua_chave_openai
GOOGLE_GEMINI_KEY=sua_chave_gemini
EMBEDDING_PROVIDER=openai
DATABASE_PATH=db/agent.db
```

## Estrutura do Projeto

- `lib/agent.rb` - Classe principal do agente
- `lib/memory/` - Memória de curto e longo prazo
- `lib/knowledge/` - Banco vetorial e embeddings
- `lib/models/` - Modelos de dados
- `lib/cli.rb` - Interface CLI interativa
- `config/database.rb` - Configuração do banco SQLite
- `db/` - Banco de dados SQLite

## Funcionalidades

- Memória de curto prazo: contexto recente das interações
- Memória de longo prazo: histórico persistente em SQLite
- Banco vetorial: busca semântica usando embeddings
- Suporte a OpenAI e Google Gemini para embeddings
- CLI interativa para gerenciar contatos e interações

