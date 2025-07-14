package mcp

import (
	"context"
)

type Client struct {
	Server *Server
}

type Tool struct {
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Parameters  map[string]interface{} `json:"parameters"`
}

func NewClientWithServer(server *Server) *Client {
	return &Client{
		Server: server,
	}
}

func (c *Client) ListTools(ctx context.Context) ([]Tool, error) {
	return []Tool{
		{
			Name:        "get_schema",
			Description: "Retorna schema do banco com informações dos veículos e financiamentos",
			Parameters: map[string]interface{}{
				"type":       "object",
				"properties": map[string]interface{}{},
			},
		},
		{
			Name:        "execute_sql",
			Description: "Executa uma consulta SQL no banco de dados da concessionária",
			Parameters: map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"query": map[string]interface{}{
						"type":        "string",
						"description": "Consulta SQL para executar",
					},
				},
				"required": []string{"query"},
			},
		},
		{
			Name:        "get_vehicles_available",
			Description: "Busca veículos disponíveis com filtros opcionais",
			Parameters: map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"max_price": map[string]interface{}{
						"type":        "number",
						"description": "Preço máximo",
					},
					"brand": map[string]interface{}{
						"type":        "string",
						"description": "Marca do veículo",
					},
					"type": map[string]interface{}{
						"type":        "string",
						"description": "Tipo do veículo (Novo, Usado, Seminovo)",
					},
				},
			},
		},
		{
			Name:        "get_best_financing",
			Description: "Busca melhores opções de financiamento",
			Parameters: map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"vehicle_price": map[string]interface{}{
						"type":        "number",
						"description": "Preço do veículo",
					},
					"max_installments": map[string]interface{}{
						"type":        "number",
						"description": "Número máximo de parcelas",
					},
				},
			},
		},
		{
			Name:        "calculate_financing",
			Description: "Calcula financiamento com simulação detalhada",
			Parameters: map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"vehicle_price": map[string]interface{}{
						"type":        "number",
						"description": "Preço do veículo",
					},
					"down_payment": map[string]interface{}{
						"type":        "number",
						"description": "Valor da entrada",
					},
					"installments": map[string]interface{}{
						"type":        "number",
						"description": "Número de parcelas",
					},
				},
				"required": []string{"vehicle_price", "down_payment", "installments"},
			},
		},
	}, nil
}

func (c *Client) FormatToolsForLLM(tools []Tool) []map[string]interface{} {
	formatted := make([]map[string]interface{}, len(tools))
	for i, tool := range tools {
		formatted[i] = map[string]interface{}{
			"type": "function",
			"function": map[string]interface{}{
				"name":        tool.Name,
				"description": tool.Description,
				"parameters":  tool.Parameters,
			},
		}
	}
	return formatted
}
