# MCP Gemini Go

Sistema de chat inteligente refatorado usando Go, MCP (Model Context Protocol) e Google Gemini para consultas de banco de dados de veículos.

## Arquitetura Refatorada (Clean Code)

```text
mcp-gemini-go/
├── cmd/web/main.go           # 🚀 Ponto de entrada único
├── internal/                 # 🏛️ Lógica privada organizada
│   ├── llm/client.go        # 🤖 Cliente Gemini simplificado
│   ├── mcp/                 # 🔧 MCP unificado
│   │   ├── server.go        # 📊 Ferramentas de banco
│   │   └── client.go        # 🔌 Cliente local otimizado
│   └── web/                 # 🌐 Aplicação web
│       ├── handlers/        # 📡 HTTP handlers SOLID
│       ├── services/        # ⚙️ Business logic
│       └── html/            # 🎨 Interface separada
│           ├── templates/   # 📄 HTML templates
│           └── static/      # 🎭 CSS/JS assets
├── docker-compose.yml       # 🐳 PostgreSQL
└── .env                     # 🔐 Configurações
```

## Como executar

### 1. Subir o banco de dados

```bash
docker-compose up -d
```

### 2. Executar a aplicação completa

```bash
go run cmd/web/main.go
```

### 3. Acessar a aplicação

- Interface web: <http://localhost:80>
- pgAdmin: <http://localhost:8085> (usuário: admin@admin.com / senha: admin)

## Funcionalidades

- 🤖 Chat inteligente com IA
- 🚗 Consultas sobre veículos disponíveis
- 💰 Cálculos de financiamento
- 📊 Análise de dados do banco
- 🔍 Busca inteligente com SQL