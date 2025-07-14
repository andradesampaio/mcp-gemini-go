package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"mcp-gemini-go/internal/mcp"
)

type ChatHandler struct {
	mcpClient *mcp.Client
	tools     []map[string]interface{}
}

type ChatRequest struct {
	Message string `json:"message"`
}

type ChatResponse struct {
	Response string `json:"response"`
	Error    string `json:"error,omitempty"`
}

func NewChatHandler(mcpClient *mcp.Client, tools []map[string]interface{}) *ChatHandler {
	return &ChatHandler{
		mcpClient: mcpClient,
		tools:     tools,
	}
}

func (h *ChatHandler) HandleHome(w http.ResponseWriter, r *http.Request) {
	templatePath := filepath.Join("internal", "web", "html", "templates", "chat.html")
	tmpl, err := template.ParseFiles(templatePath)
	if err != nil {
		http.Error(w, "Erro ao carregar template", http.StatusInternalServerError)
		return
	}
	tmpl.Execute(w, nil)
}

func (h *ChatHandler) HandleChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	var req ChatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response := ChatResponse{Error: "Formato de requisição inválido"}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
		return
	}

	ctx := context.Background()
	responseText := h.processQuestionWithDatabase(ctx, req.Message)

	response := ChatResponse{Response: responseText}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (h *ChatHandler) processQuestionWithDatabase(ctx context.Context, message string) string {
	if result := h.handleSpecificQuestions(ctx, message); result != "" {
		return result
	}
	return `💡 **Olá! Sou seu consultor automotivo com acesso à nossa base de dados exclusiva.**

🔍 **Posso te ajudar com:**
• "carro barato" - veículos até R$ 100.000
• "carro mais caro" - veículos premium  
• "simular [modelo] com entrada de R$ [valor] em [parcelas]x"
• "financiamento" - melhores taxas disponíveis

📊 **Todas as informações são baseadas em dados reais da nossa concessionária:**
✅ Preços atualizados dos veículos
✅ Taxas de financiamento dos bancos parceiros  
✅ Especificações técnicas completas
✅ Custos de IPVA e manutenção

❓ **Como posso te ajudar hoje?**`
}

func (h *ChatHandler) handleSpecificQuestions(ctx context.Context, message string) string {
	messageToLower := strings.ToLower(message)

	if strings.Contains(messageToLower, "carro barato") || strings.Contains(messageToLower, "carros baratos") ||
		strings.Contains(messageToLower, "veículo barato") || strings.Contains(messageToLower, "veículos baratos") {
		return h.executeGetVehiclesAvailable(ctx, map[string]interface{}{
			"max_price": 100000.0,
		})
	}

	if strings.Contains(messageToLower, "carro caro") || strings.Contains(messageToLower, "carros caros") ||
		strings.Contains(messageToLower, "carro mais caro") || strings.Contains(messageToLower, "veículo caro") ||
		strings.Contains(messageToLower, "veículos caros") {
		return h.executeGetVehiclesAvailable(ctx, map[string]interface{}{
			"sort": "expensive",
		})
	}

	if strings.Contains(messageToLower, "simular") {
		if strings.Contains(messageToLower, "fiat argo") && strings.Contains(messageToLower, "entrada") {
			var downPayment float64 = 0.0
			var installments float64 = 60.0

			downPayment = h.extractDownPayment(messageToLower)

			installments = h.extractInstallments(messageToLower)

			vehiclePrice := h.getVehiclePrice(ctx, "Fiat", "Argo")
			if vehiclePrice == 0 {
				return "❌ Veículo Fiat Argo não encontrado em nosso estoque. Consulte nossa base com 'carro barato' para ver opções disponíveis."
			}

			return h.executeCalculateFinancing(ctx, map[string]interface{}{
				"vehicle_price": vehiclePrice,
				"down_payment":  downPayment,
				"installments":  installments,
			})
		}

		if strings.Contains(messageToLower, "60") {
			avgPrice := h.getAverageVehiclePrice(ctx)
			if avgPrice == 0 {
				return "❌ Nenhum veículo encontrado na base. Consulte 'carro barato' ou 'carro mais caro' para ver opções disponíveis."
			}

			return h.executeCalculateFinancing(ctx, map[string]interface{}{
				"vehicle_price": avgPrice,
				"down_payment":  0.0,
				"installments":  60.0,
			})
		}
	}

	if strings.Contains(messageToLower, "financiamento") || strings.Contains(messageToLower, "melhor taxa") ||
		strings.Contains(messageToLower, "banco") {
		return h.executeGetBestFinancing(ctx, map[string]interface{}{})
	}

	if strings.Contains(messageToLower, "parcela") && (strings.Contains(messageToLower, "reais") || strings.Contains(messageToLower, "r$")) {
		return h.handleMonthlyPaymentQuestion(ctx, message)
	}

	return ""
}

func (h *ChatHandler) executeGetVehiclesAvailable(ctx context.Context, params map[string]interface{}) string {
	if h.mcpClient == nil || h.mcpClient.Server == nil || h.mcpClient.Server.DB == nil {
		return "❌ Conexão com base de dados indisponível"
	}

	query := `
		SELECT 
			m.marca,
			mo.modelo,
			v.versao,
			v.preco_venda,
			v.consumo_urbano,
			v.consumo_rodoviario,
			v.potencia_cv,
			v.ipva_anual,
			v.ano_modelo,
			v.cor,
			v.tipo_combustivel
		FROM veiculos v
		JOIN modelos mo ON v.id_modelos = mo.id_modelos  
		JOIN marcas m ON mo.id_marcas = m.id_marcas
		WHERE v.status_veiculo = 'Disponivel'
	`

	var queryArgs []interface{}
	argIndex := 1

	if maxPrice, ok := params["max_price"]; ok {
		query += fmt.Sprintf(" AND v.preco_venda <= $%d", argIndex)
		queryArgs = append(queryArgs, maxPrice)
		argIndex++
	}

	if sort, ok := params["sort"]; ok && sort == "expensive" {
		query += " ORDER BY v.preco_venda DESC"
	} else {
		query += " ORDER BY v.preco_venda ASC"
	}

	query += " LIMIT 3"

	rows, err := h.mcpClient.Server.DB.QueryContext(ctx, query, queryArgs...)
	if err != nil {
		return fmt.Sprintf("❌ Erro ao buscar veículos: %v", err)
	}
	defer rows.Close()

	var response strings.Builder
	response.WriteString("💡 **Baseado em nossa base de dados:**\n\n")

	count := 0
	for rows.Next() && count < 3 {
		var marca, modelo, versao, cor, tipoCombustivel string
		var preco, consumoUrbano, consumoRodoviario, ipva float64
		var potencia, ano int

		err := rows.Scan(&marca, &modelo, &versao, &preco, &consumoUrbano, &consumoRodoviario, &potencia, &ipva, &ano, &cor, &tipoCombustivel)
		if err != nil {
			continue
		}

		response.WriteString(fmt.Sprintf("🚘 **%s %s %s (%s)**\n", marca, modelo, versao, cor))
		response.WriteString(fmt.Sprintf("💰 Preço: R$ %.2f\n", preco))
		response.WriteString(fmt.Sprintf("📅 Ano: %d\n", ano))
		response.WriteString(fmt.Sprintf("⚡ Potência: %d cv\n", potencia))
		response.WriteString(fmt.Sprintf("⛽ Consumo: %.1f (cidade) / %.1f (estrada) km/l\n", consumoUrbano, consumoRodoviario))
		response.WriteString(fmt.Sprintf("🏛️ IPVA anual: R$ %.2f\n", ipva))
		response.WriteString(fmt.Sprintf("⛽ Combustível: %s\n\n", tipoCombustivel))
		count++
	}

	if count == 0 {
		response.WriteString("❌ Nenhum veículo encontrado com os critérios especificados.\n")
	} else {
		response.WriteString("❓ Gostaria de simular o financiamento para algum desses veículos? Informe o prazo desejado!")
	}

	return response.String()
}

func (h *ChatHandler) executeGetBestFinancing(ctx context.Context, params map[string]interface{}) string {
	if h.mcpClient == nil || h.mcpClient.Server == nil || h.mcpClient.Server.DB == nil {
		return "❌ Conexão com base de dados indisponível"
	}

	query := `
		SELECT 
			banco_financiadora,
			tipo_financiamento,
			taxa_juros_mes,
			taxa_juros_ano,
			numero_parcelas,
			valor_entrada,
			valor_parcela,
			valor_total,
			observacoes
		FROM financiamentos
		WHERE aprovado = true
		ORDER BY taxa_juros_mes ASC LIMIT 3
	`

	rows, err := h.mcpClient.Server.DB.QueryContext(ctx, query)
	if err != nil {
		return fmt.Sprintf("❌ Erro ao buscar financiamentos: %v", err)
	}
	defer rows.Close()

	var response strings.Builder
	response.WriteString("💡 **Melhores opções de financiamento:**\n\n")

	count := 0
	for rows.Next() && count < 3 {
		var banco, tipo, observacoes string
		var taxaMes, taxaAno, valorEntrada, valorParcela, valorTotal float64
		var numeroParcelas int

		err := rows.Scan(&banco, &tipo, &taxaMes, &taxaAno, &numeroParcelas, &valorEntrada, &valorParcela, &valorTotal, &observacoes)
		if err != nil {
			continue
		}

		response.WriteString(fmt.Sprintf("🏦 **%s - %s**\n", banco, tipo))
		response.WriteString(fmt.Sprintf("💸 Taxa: %.2f%% ao mês / %.2f%% ao ano\n", taxaMes, taxaAno))
		response.WriteString(fmt.Sprintf("📅 Parcelas: %d\n", numeroParcelas))
		response.WriteString(fmt.Sprintf("💰 Valor parcela: R$ %.2f\n", valorParcela))
		response.WriteString(fmt.Sprintf("💵 Valor total: R$ %.2f\n", valorTotal))
		if observacoes != "" {
			response.WriteString(fmt.Sprintf("📝 %s\n", observacoes))
		}
		response.WriteString("\n")
		count++
	}

	if count == 0 {
		response.WriteString("❌ Nenhuma opção de financiamento encontrada.\n")
	}

	return response.String()
}

func (h *ChatHandler) executeCalculateFinancing(ctx context.Context, params map[string]interface{}) string {
	if h.mcpClient == nil || h.mcpClient.Server == nil || h.mcpClient.Server.DB == nil {
		return "❌ Conexão com base de dados indisponível"
	}

	vehiclePrice := 0.0
	if vp, ok := params["vehicle_price"]; ok {
		vehiclePrice = vp.(float64)
	}

	if vehiclePrice == 0 {
		vehiclePrice = h.getAverageVehiclePrice(ctx)
		if vehiclePrice == 0 {
			return "❌ Não foi possível obter informações de preço da base de dados"
		}
	}

	downPayment := 0.0
	if dp, ok := params["down_payment"]; ok {
		downPayment = dp.(float64)
	}

	installments := 60.0
	if inst, ok := params["installments"]; ok {
		installments = inst.(float64)
	}

	vehicleInfo := h.getVehicleByPrice(ctx, vehiclePrice)

	query := `
		SELECT taxa_juros_ano, banco_financiadora
		FROM financiamentos 
		WHERE aprovado = true 
		ORDER BY taxa_juros_ano ASC 
		LIMIT 1
	`

	row := h.mcpClient.Server.DB.QueryRowContext(ctx, query)
	var interestRate float64
	var bank string

	if err := row.Scan(&interestRate, &bank); err != nil {
		return "❌ Nenhuma opção de financiamento encontrada na base de dados"
	}

	interestRate = interestRate / 100

	financeAmount := vehiclePrice - downPayment
	monthlyRate := interestRate / 12

	var monthlyPayment float64
	if monthlyRate > 0 {
		power := 1.0
		for i := 0; i < int(installments); i++ {
			power *= (1 + monthlyRate)
		}
		monthlyPayment = financeAmount * (monthlyRate * power) / (power - 1)
	} else {
		monthlyPayment = financeAmount / installments
	}

	totalAmount := monthlyPayment * installments

	var response strings.Builder
	response.WriteString("💡 **Simulação de financiamento baseada em nossa base de dados:**\n\n")

	if vehicleInfo != nil {
		response.WriteString("🚘 **Veículo Selecionado:**\n")
		if marca, ok := vehicleInfo["marca"].(string); ok {
			response.WriteString(fmt.Sprintf("Marca: %s\n", marca))
		}
		if modelo, ok := vehicleInfo["modelo"].(string); ok {
			response.WriteString(fmt.Sprintf("Modelo: %s\n", modelo))
		}
		if versao, ok := vehicleInfo["versao"].(string); ok {
			response.WriteString(fmt.Sprintf("Versão: %s\n", versao))
		}
		if cor, ok := vehicleInfo["cor"].(string); ok {
			response.WriteString(fmt.Sprintf("Cor: %s\n", cor))
		}
		if consumoUrbano, ok := vehicleInfo["consumo_urbano"].(float64); ok {
			if consumoRodoviario, ok2 := vehicleInfo["consumo_rodoviario"].(float64); ok2 {
				response.WriteString(fmt.Sprintf("Consumo: %.1f (cidade) / %.1f (estrada) km/l\n", consumoUrbano, consumoRodoviario))
			}
		}
		if potencia, ok := vehicleInfo["potencia_cv"].(int); ok {
			response.WriteString(fmt.Sprintf("Potência: %d cv\n", potencia))
		}
		if ipva, ok := vehicleInfo["ipva_anual"].(float64); ok {
			response.WriteString(fmt.Sprintf("IPVA anual: R$ %.2f\n", ipva))
		}
		response.WriteString("\n")
	}

	response.WriteString("💰 **Detalhes do Financiamento:**\n")
	response.WriteString(fmt.Sprintf("🚘 Valor do veículo: R$ %.2f\n", vehiclePrice))
	response.WriteString(fmt.Sprintf("💰 Entrada: R$ %.2f\n", downPayment))
	response.WriteString(fmt.Sprintf("💵 Valor financiado: R$ %.2f\n", financeAmount))
	response.WriteString(fmt.Sprintf("🏦 **Banco com melhor taxa: %s**\n", bank))
	response.WriteString(fmt.Sprintf("📊 Taxa de juros: %.2f%% ao ano (%.2f%% ao mês)\n", interestRate*100, monthlyRate*100))
	response.WriteString(fmt.Sprintf("📅 Número de parcelas: %.0f\n", installments))
	response.WriteString(fmt.Sprintf("💸 Valor da parcela: R$ %.2f\n", monthlyPayment))
	response.WriteString(fmt.Sprintf("💵 Valor total a pagar: R$ %.2f\n", totalAmount))
	response.WriteString(fmt.Sprintf("💲 Total de juros: R$ %.2f\n", totalAmount-financeAmount))

	return response.String()
}

func (h *ChatHandler) getVehiclePrice(ctx context.Context, marca, modelo string) float64 {
	if h.mcpClient == nil || h.mcpClient.Server == nil || h.mcpClient.Server.DB == nil {
		return 0
	}

	query := `
		SELECT v.preco_venda
		FROM veiculos v
		JOIN modelos mo ON v.id_modelos = mo.id_modelos  
		JOIN marcas m ON mo.id_marcas = m.id_marcas
		WHERE LOWER(m.marca) = LOWER($1) AND LOWER(mo.modelo) = LOWER($2)
		AND v.status_veiculo = 'Disponivel'
		LIMIT 1
	`

	var price float64
	row := h.mcpClient.Server.DB.QueryRowContext(ctx, query, marca, modelo)
	if err := row.Scan(&price); err != nil {
		return 0
	}

	return price
}

func (h *ChatHandler) getAverageVehiclePrice(ctx context.Context) float64 {
	if h.mcpClient == nil || h.mcpClient.Server == nil || h.mcpClient.Server.DB == nil {
		return 0
	}

	query := `
		SELECT AVG(v.preco_venda)
		FROM veiculos v
		WHERE v.status_veiculo = 'Disponivel'
	`

	var avgPrice float64
	row := h.mcpClient.Server.DB.QueryRowContext(ctx, query)
	if err := row.Scan(&avgPrice); err != nil {
		return 0
	}

	return avgPrice
}

func (h *ChatHandler) getVehicleByPrice(ctx context.Context, targetPrice float64) map[string]interface{} {
	if h.mcpClient == nil || h.mcpClient.Server == nil || h.mcpClient.Server.DB == nil {
		return nil
	}

	query := `
		SELECT 
			m.marca,
			mo.modelo,
			v.versao,
			v.preco_venda,
			v.consumo_urbano,
			v.consumo_rodoviario,
			v.potencia_cv,
			v.ipva_anual,
			v.ano_modelo,
			v.cor,
			v.tipo_combustivel
		FROM veiculos v
		JOIN modelos mo ON v.id_modelos = mo.id_modelos  
		JOIN marcas m ON mo.id_marcas = m.id_marcas
		WHERE v.status_veiculo = 'Disponivel'
		AND ABS(v.preco_venda - $1) <= 5000
		ORDER BY ABS(v.preco_venda - $1) ASC
		LIMIT 1
	`

	row := h.mcpClient.Server.DB.QueryRowContext(ctx, query, targetPrice)

	var marca, modelo, versao, cor, tipoCombustivel string
	var preco, consumoUrbano, consumoRodoviario, ipva float64
	var potencia, ano int

	if err := row.Scan(&marca, &modelo, &versao, &preco, &consumoUrbano, &consumoRodoviario, &potencia, &ipva, &ano, &cor, &tipoCombustivel); err != nil {
		return nil
	}

	return map[string]interface{}{
		"marca":              marca,
		"modelo":             modelo,
		"versao":             versao,
		"preco_venda":        preco,
		"consumo_urbano":     consumoUrbano,
		"consumo_rodoviario": consumoRodoviario,
		"potencia_cv":        potencia,
		"ipva_anual":         ipva,
		"ano_modelo":         ano,
		"cor":                cor,
		"tipo_combustivel":   tipoCombustivel,
	}
}

func (h *ChatHandler) extractDownPayment(message string) float64 {
	patterns := []string{
		`entrada\s+(?:de\s+)?r?\$?\s*([0-9]+(?:\.[0-9]{3})*(?:,[0-9]{2})?)`,
		`entrada\s+(?:de\s+)?([0-9]+\.?[0-9]*)`,
		`r?\$\s*([0-9]+(?:\.[0-9]{3})*(?:,[0-9]{2})?)\s+(?:de\s+)?entrada`,
	}

	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindStringSubmatch(message)
		if len(matches) > 1 {
			valueStr := strings.ReplaceAll(matches[1], ".", "")
			valueStr = strings.ReplaceAll(valueStr, ",", ".")

			if value, err := strconv.ParseFloat(valueStr, 64); err == nil {
				if value >= 1000 && value <= 1000000 {
					return value
				}
			}
		}
	}

	return 0.0
}

func (h *ChatHandler) extractInstallments(message string) float64 {
	patterns := []string{
		`(\d+)x`,
		`em\s+(\d+)x`,
		`(\d+)\s+parcelas?`,
		`(\d+)\s+vezes?`,
	}

	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindStringSubmatch(message)
		if len(matches) > 1 {
			if value, err := strconv.ParseFloat(matches[1], 64); err == nil {
				if value >= 12 && value <= 84 {
					return value
				}
			}
		}
	}

	return 60.0
}

func (h *ChatHandler) handleMonthlyPaymentQuestion(ctx context.Context, message string) string {
	messageToLower := strings.ToLower(message)

	targetPayment := h.extractTargetPayment(messageToLower)
	if targetPayment <= 0 {
		return "❌ Não consegui identificar o valor da parcela desejada. Por favor, especifique como 'parcela de R$ 1.000'"
	}

	var vehiclePrice float64
	var vehicleName string

	if strings.Contains(messageToLower, "chevrolet onix") {
		vehiclePrice = h.getVehiclePrice(ctx, "Chevrolet", "Onix")
		vehicleName = "Chevrolet Onix LT 1.0 Turbo"
	} else if strings.Contains(messageToLower, "fiat argo") {
		vehiclePrice = h.getVehiclePrice(ctx, "Fiat", "Argo")
		vehicleName = "Fiat Argo Drive 1.3"
	} else if strings.Contains(messageToLower, "honda civic") {
		vehiclePrice = h.getVehiclePrice(ctx, "Honda", "Civic")
		vehicleName = "Honda Civic LX 2.0 CVT"
	} else if strings.Contains(messageToLower, "toyota corolla") {
		vehiclePrice = h.getVehiclePrice(ctx, "Toyota", "Corolla")
		vehicleName = "Toyota Corolla GLI 1.8 CVT"
	} else {
		vehiclePrice = h.getAverageVehiclePrice(ctx)
		vehicleName = "Veículo da nossa base"
	}

	if vehiclePrice <= 0 {
		return "❌ Veículo não encontrado em nossa base de dados. Consulte 'carro barato' para ver opções disponíveis."
	}

	query := `
		SELECT taxa_juros_ano, banco_financiadora
		FROM financiamentos 
		WHERE aprovado = true 
		ORDER BY taxa_juros_ano ASC 
		LIMIT 1
	`

	row := h.mcpClient.Server.DB.QueryRowContext(ctx, query)
	var interestRate float64
	var bank string

	if err := row.Scan(&interestRate, &bank); err != nil {
		return "❌ Nenhuma opção de financiamento encontrada na base de dados"
	}

	interestRate = interestRate / 100
	monthlyRate := interestRate / 12
	installments := 60.0

	var requiredDownPayment float64

	if monthlyRate > 0 {
		power := 1.0
		for i := 0; i < int(installments); i++ {
			power *= (1 + monthlyRate)
		}
		financeAmount := targetPayment * (power - 1) / (monthlyRate * power)
		requiredDownPayment = vehiclePrice - financeAmount
	} else {
		financeAmount := targetPayment * installments
		requiredDownPayment = vehiclePrice - financeAmount
	}

	if requiredDownPayment < 0 {
		requiredDownPayment = 0
	}

	financeAmount := vehiclePrice - requiredDownPayment
	totalAmount := targetPayment * installments

	var response strings.Builder
	response.WriteString("💡 **Cálculo baseado em nossa base de dados:**\n\n")
	response.WriteString(fmt.Sprintf("🚘 **Veículo: %s**\n", vehicleName))
	response.WriteString(fmt.Sprintf("💰 Valor do veículo: R$ %.2f\n", vehiclePrice))
	response.WriteString(fmt.Sprintf("💸 Parcela desejada: R$ %.2f\n", targetPayment))
	response.WriteString(fmt.Sprintf("📅 Prazo: %.0f parcelas\n\n", installments))

	response.WriteString("💰 **Resultado do Cálculo:**\n")
	response.WriteString(fmt.Sprintf("💵 **Entrada necessária: R$ %.2f**\n", requiredDownPayment))
	response.WriteString(fmt.Sprintf("💳 Valor financiado: R$ %.2f\n", financeAmount))
	response.WriteString(fmt.Sprintf("🏦 **Banco com melhor taxa: %s**\n", bank))
	response.WriteString(fmt.Sprintf("📊 Taxa: %.2f%% ao ano (%.2f%% ao mês)\n", interestRate*100, monthlyRate*100))
	response.WriteString(fmt.Sprintf("💵 Total a pagar: R$ %.2f\n", totalAmount))
	response.WriteString(fmt.Sprintf("💸 Total de juros: R$ %.2f\n", totalAmount-financeAmount))

	return response.String()
}

func (h *ChatHandler) extractTargetPayment(message string) float64 {
	patterns := []string{
		`parcela\s+(?:de\s+)?r?\$?\s*([0-9]+(?:\.[0-9]{3})*(?:,[0-9]{2})?)`,
		`([0-9]+(?:\.[0-9]{3})*(?:,[0-9]{2})?)\s+reais?\s+(?:de\s+)?parcela`,
		`r?\$\s*([0-9]+(?:\.[0-9]{3})*(?:,[0-9]{2})?)\s+(?:de\s+)?parcela`,
	}

	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindStringSubmatch(message)
		if len(matches) > 1 {
			valueStr := strings.ReplaceAll(matches[1], ".", "")
			valueStr = strings.ReplaceAll(valueStr, ",", ".")

			if value, err := strconv.ParseFloat(valueStr, 64); err == nil {
				if value >= 200 && value <= 5000 {
					return value
				}
			}
		}
	}

	return 0.0
}
