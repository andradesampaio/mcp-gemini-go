package llm

import (
	"context"
	"fmt"
	"os"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type ChatResponse struct {
	Content string `json:"content"`
}

type Client struct {
	model  *genai.GenerativeModel
	client *genai.Client
}

func NewClient(ctx context.Context, modelName string) (*Client, error) {
	apiKey := os.Getenv("GOOGLE_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GOOGLE_API_KEY não encontrada")
	}

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, fmt.Errorf("erro ao criar cliente: %v", err)
	}

	model := client.GenerativeModel(modelName)

	return &Client{
		model:  model,
		client: client,
	}, nil
}

func (c *Client) GenerateText(ctx context.Context, prompt string) (string, error) {
	response, err := c.model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return "", fmt.Errorf("erro ao gerar conteúdo: %v", err)
	}

	if len(response.Candidates) == 0 {
		return "", fmt.Errorf("nenhuma resposta gerada")
	}

	candidate := response.Candidates[0]
	if len(candidate.Content.Parts) == 0 {
		return "", fmt.Errorf("resposta vazia")
	}

	if textPart, ok := candidate.Content.Parts[0].(genai.Text); ok {
		return string(textPart), nil
	}

	return "", fmt.Errorf("tipo de resposta não suportado")
}

func (c *Client) CompleteChat(ctx context.Context, message string, tools []map[string]interface{}) (*ChatResponse, error) {
	systemPrompt := `🚗 CONSULTOR DE VENDAS AUTOMOTIVAS INTELIGENTE

Você é um consultor especializado em vendas de veículos com acesso a uma base de dados completa da concessionária.

REGRAS IMPORTANTES:
1. ✅ SEMPRE use as ferramentas disponíveis para consultar dados reais
2. ✅ Para perguntas sobre carros baratos/caros, use get_vehicles_available com filtros de preço
3. ✅ Para simulações de financiamento, use calculate_financing
4. ✅ Para melhores taxas, use get_best_financing
5. ❌ NUNCA invente dados - sempre consulte a base

FERRAMENTAS DISPONÍVEIS:
- get_vehicles_available: busca veículos (filtros: max_price, brand, type)
- get_best_financing: busca melhores opções de financiamento
- calculate_financing: calcula parcelas específicas

COMO RESPONDER A PERGUNTAS COMUNS:

🔍 "carro barato" → Use get_vehicles_available com max_price baixo
🔍 "carro mais caro" → Use get_vehicles_available sem filtro de preço e ordene por valor
🔍 "simular parcelas de 60" → Use calculate_financing com installments=60
🔍 "melhor financiamento" → Use get_best_financing

FORMATO DE RESPOSTA:
💡 Baseado em nossa base de dados:
[DADOS REAIS OBTIDOS DAS FERRAMENTAS]

✨ Sempre inclua:
- Preços dos veículos
- Especificações importantes (consumo, potência, etc.)
- Detalhes do financiamento (valor da parcela, taxa, banco)
- Informações de IPVA e custos

❓ Seja proativo oferecendo simulações e mais informações.

LEMBRE-SE: Use as ferramentas para obter dados reais e atualizados!`

	if len(tools) > 0 {
		systemPrompt += "\n\nFERRAMENTAS ATIVAS:"
		for _, tool := range tools {
			if name, ok := tool["name"].(string); ok {
				systemPrompt += "\n- " + name
			}
		}
	}

	fullPrompt := fmt.Sprintf("%s\n\nUsuário: %s", systemPrompt, message)

	text, err := c.GenerateText(ctx, fullPrompt)
	if err != nil {
		return nil, err
	}

	return &ChatResponse{
		Content: text,
	}, nil
}

func (c *Client) Close() error {
	return c.client.Close()
}
