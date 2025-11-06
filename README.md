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

- ✅ **Memória de curto prazo**: contexto recente das interações (últimas 10)
- ✅ **Memória de longo prazo**: histórico persistente em SQLite
- ✅ **Banco vetorial**: busca semântica usando embeddings
- ✅ **Suporte a OpenAI e Google Gemini** para embeddings
- ✅ **CLI interativa** para gerenciar contatos e interações
- ✅ **Arquivamento automático**: quando um contato tem mais de 20 interações, as antigas são sumarizadas e arquivadas (mantendo as 10 mais recentes)
- ✅ **Sumarização inteligente**: usa OpenAI para criar resumos concisos das interações arquivadas
- ✅ **Personalização**: respostas adaptadas ao histórico do contato
- ✅ **Evita repetições**: detecta e evita repetir informações já discutidas

## Funcionalidades de Arquivamento

Quando um contato atinge **mais de 20 interações**, o sistema:

1. **Sumariza todas as interações antigas** juntas usando OpenAI
2. **Salva o resumo** na tabela `context_summaries`
3. **Mantém apenas as 10 interações mais recentes**
4. **Deleta as interações antigas** apenas após confirmar que o resumo foi salvo com sucesso

Isso garante que:
- O histórico importante seja preservado em formato resumido
- O banco de dados não cresça indefinidamente
- O contexto relevante seja mantido para futuras interações

## Scripts Úteis

### Popular o banco com dados de exemplo

```bash
# Via Docker
docker-compose run --rm agent ruby db/seeds.rb

# Localmente
ruby db/seeds.rb
```

### Visualizar dados do banco

```bash
# Via Docker
docker-compose run --rm agent ruby db/view_db.rb

# Localmente
ruby db/view_db.rb
```

### Rodar testes

```bash
# Via Docker
docker-compose run --rm agent ruby test/test_runner.rb

# Localmente
ruby test/test_runner.rb
```

### Verificar sistema

```bash
# Via Docker
docker-compose run --rm agent ruby verify_system.rb

# Localmente
ruby verify_system.rb
```

## Estrutura do Banco de Dados

- `contacts`: Contatos do CRM
- `interactions`: Histórico de interações (mantém apenas as 10 mais recentes por contato)
- `context_summaries`: Resumos das interações arquivadas
- `knowledge_embeddings`: Base de conhecimento vetorial

## Tecnologias

- **Ruby 3.2+**
- **SQLite3**: Banco de dados
- **OpenAI API**: Geração de respostas e sumarização
- **OpenAI/Gemini**: Embeddings para busca vetorial
- **Docker**: Containerização

