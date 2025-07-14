package services

import (
	"context"
	"log"

	"mcp-gemini-go/internal/mcp"

	"github.com/joho/godotenv"
)

type WebService struct {
	MCPClient *mcp.Client
	MCPServer *mcp.Server
	Tools     []map[string]interface{}
}

func NewWebService() (*WebService, error) {
	ctx := context.Background()

	if err := godotenv.Load(".env"); err != nil {
		if err2 := godotenv.Load("../../.env"); err2 != nil {
			log.Printf("Aviso: arquivo .env não encontrado: %v", err2)
		}
	}

	mcpServer := mcp.NewServer()
	if err := mcpServer.Connect(); err != nil {
		return nil, err
	}
	log.Printf("✅ Conectado ao banco PostgreSQL")

	if err := mcpServer.Initialize(); err != nil {
		return nil, err
	}

	mcpClient := mcp.NewClientWithServer(mcpServer)
	log.Printf("✅ Servidor MCP integrado inicializado")

	tools, err := mcpClient.ListTools(ctx)
	if err != nil {
		return nil, err
	}

	formattedTools := mcpClient.FormatToolsForLLM(tools)

	return &WebService{
		MCPClient: mcpClient,
		MCPServer: mcpServer,
		Tools:     formattedTools,
	}, nil
}
func (ws *WebService) Close() error {
	if ws.MCPServer != nil {
		return ws.MCPServer.Close()
	}
	return nil
}
