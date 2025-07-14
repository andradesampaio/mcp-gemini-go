package mcp

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

type DBConfig struct {
	Host     string
	Port     string
	DBName   string
	User     string
	Password string
}

type Server struct {
	DB     *sql.DB
	config *DBConfig
	mcp    *server.MCPServer
}

func NewServer() *Server {
	config := &DBConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "5432"),
		DBName:   getEnv("DB_NAME", "sales_db"),
		User:     getEnv("DB_USER", "user"),
		Password: getEnv("DB_PASSWORD", "password"),
	}
	return &Server{config: config}
}

func (s *Server) Connect() error {
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		s.config.Host, s.config.Port, s.config.User, s.config.Password, s.config.DBName)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("erro ao conectar ao banco: %w", err)
	}

	if err := db.Ping(); err != nil {
		return fmt.Errorf("erro ao testar conexão: %w", err)
	}

	s.DB = db
	log.Println("✅ Conectado ao banco PostgreSQL")
	return nil
}

func (s *Server) Initialize() error {
	s.mcp = server.NewMCPServer(
		"SQL Server",
		"1.0.0",
	)

	s.mcp.AddTool(mcp.NewTool("get_schema",
		mcp.WithDescription("Retorna schema do banco com informações dos veículos e financiamentos"),
	), s.GetSchema)

	s.mcp.AddTool(mcp.NewTool("execute_sql",
		mcp.WithDescription("Executa uma consulta SQL no banco de dados da concessionária"),
		mcp.WithString("query",
			mcp.Required(),
			mcp.Description("Consulta SQL para executar"),
		),
	), s.ExecuteSQL)

	s.mcp.AddTool(mcp.NewTool("get_vehicles_available",
		mcp.WithDescription("Busca veículos disponíveis com filtros opcionais"),
		mcp.WithNumber("max_price",
			mcp.Description("Preço máximo"),
		),
		mcp.WithString("brand",
			mcp.Description("Marca do veículo"),
		),
		mcp.WithString("type",
			mcp.Description("Tipo do veículo (Novo, Usado, Seminovo)"),
		),
	), s.GetVehiclesAvailable)

	s.mcp.AddTool(mcp.NewTool("get_best_financing",
		mcp.WithDescription("Busca melhores opções de financiamento"),
		mcp.WithNumber("vehicle_price",
			mcp.Description("Preço do veículo"),
		),
		mcp.WithNumber("max_installments",
			mcp.Description("Número máximo de parcelas"),
		),
	), s.GetBestFinancing)

	s.mcp.AddTool(mcp.NewTool("calculate_financing",
		mcp.WithDescription("Calcula financiamento com simulação detalhada"),
		mcp.WithNumber("vehicle_price",
			mcp.Required(),
			mcp.Description("Preço do veículo"),
		),
		mcp.WithNumber("down_payment",
			mcp.Description("Valor da entrada"),
		),
		mcp.WithNumber("installments",
			mcp.Required(),
			mcp.Description("Número de parcelas"),
		),
		mcp.WithString("bank",
			mcp.Description("Banco para financiamento"),
		),
	), s.CalculateFinancing)

	log.Println("🚀 Servidor MCP SQL inicializado")
	return nil
}

func (s *Server) GetMCPServer() *server.MCPServer {
	return s.mcp
}

func (s *Server) GetSchema(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	query := `
		SELECT table_name, column_name, data_type
		FROM information_schema.columns
		WHERE table_schema = 'public'
		ORDER BY table_name, ordinal_position
	`

	rows, err := s.DB.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("erro ao consultar schema: %w", err)
	}
	defer rows.Close()

	schema := make(map[string][]string)
	for rows.Next() {
		var tableName, columnName, dataType string
		if err := rows.Scan(&tableName, &columnName, &dataType); err != nil {
			return nil, err
		}

		if _, exists := schema[tableName]; !exists {
			schema[tableName] = make([]string, 0)
		}
		schema[tableName] = append(schema[tableName], fmt.Sprintf("%s (%s)", columnName, dataType))
	}

	result := map[string]interface{}{
		"schema":      schema,
		"description": "Banco de dados da concessionária com veículos, financiamentos e vendas",
	}

	return mcp.NewToolResultText(fmt.Sprintf("%+v", result)), nil
}

func (s *Server) ExecuteSQL(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	query, err := request.RequireString("query")
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("parâmetro 'query' é obrigatório: %v", err)), nil
	}

	rows, err := s.DB.QueryContext(ctx, query)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("erro ao executar query: %v", err)), nil
	}
	defer rows.Close()

	columns, err := rows.Columns()
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("erro ao obter colunas: %v", err)), nil
	}

	var results []map[string]interface{}
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("erro ao escanear linha: %v", err)), nil
		}

		row := make(map[string]interface{})
		for i, col := range columns {
			val := values[i]
			if b, ok := val.([]byte); ok {
				row[col] = string(b)
			} else {
				row[col] = val
			}
		}
		results = append(results, row)
	}

	resultJSON, _ := json.Marshal(results)
	return mcp.NewToolResultText(string(resultJSON)), nil
}

func (s *Server) GetVehiclesAvailable(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	query := `
		SELECT 
			m.marca,
			mo.modelo,
			v.versao,
			v.preco_venda,
			v.tipo_veiculo,
			v.status_veiculo,
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

	maxPrice := request.GetFloat("max_price", 0)
	if maxPrice > 0 {
		query += fmt.Sprintf(" AND v.preco_venda <= $%d", argIndex)
		queryArgs = append(queryArgs, maxPrice)
		argIndex++
	}

	minPrice := request.GetFloat("min_price", 0)
	if minPrice > 0 {
		query += fmt.Sprintf(" AND v.preco_venda >= $%d", argIndex)
		queryArgs = append(queryArgs, minPrice)
		argIndex++
	}

	brand := request.GetString("brand", "")
	if brand != "" {
		query += fmt.Sprintf(" AND LOWER(m.marca) = LOWER($%d)", argIndex)
		queryArgs = append(queryArgs, brand)
		argIndex++
	}

	vehicleType := request.GetString("type", "")
	if vehicleType != "" {
		query += fmt.Sprintf(" AND v.tipo_veiculo = $%d", argIndex)
		queryArgs = append(queryArgs, vehicleType)
		argIndex++
	}

	orderBy := " ORDER BY v.preco_venda ASC"
	if request.GetString("sort", "") == "expensive" || maxPrice == 0 {
		orderBy = " ORDER BY v.preco_venda DESC"
	}

	query += orderBy + " LIMIT 3"

	rows, err := s.DB.QueryContext(ctx, query, queryArgs...)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("erro ao buscar veículos: %v", err)), nil
	}
	defer rows.Close()

	var vehicles []map[string]interface{}
	for rows.Next() {
		var marca, modelo, versao, tipoVeiculo, statusVeiculo, cor, tipoCombustivel string
		var precoVenda, consumoUrbano, consumoRodoviario, ipvaAnual float64
		var potenciaCv, anoModelo int

		err := rows.Scan(&marca, &modelo, &versao, &precoVenda, &tipoVeiculo, &statusVeiculo,
			&consumoUrbano, &consumoRodoviario, &potenciaCv, &ipvaAnual, &anoModelo, &cor, &tipoCombustivel)
		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("erro ao escanear linha: %v", err)), nil
		}

		vehicles = append(vehicles, map[string]interface{}{
			"marca":              marca,
			"modelo":             modelo,
			"versao":             versao,
			"preco_venda":        precoVenda,
			"tipo_veiculo":       tipoVeiculo,
			"status_veiculo":     statusVeiculo,
			"consumo_urbano":     consumoUrbano,
			"consumo_rodoviario": consumoRodoviario,
			"potencia_cv":        potenciaCv,
			"ipva_anual":         ipvaAnual,
			"ano_modelo":         anoModelo,
			"cor":                cor,
			"tipo_combustivel":   tipoCombustivel,
		})
	}

	resultJSON, _ := json.Marshal(vehicles)
	return mcp.NewToolResultText(string(resultJSON)), nil
}

func (s *Server) GetBestFinancing(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
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
	`

	var queryArgs []interface{}
	argIndex := 1

	maxInstallments := request.GetInt("max_installments", 0)
	if maxInstallments > 0 {
		query += fmt.Sprintf(" AND numero_parcelas <= $%d", argIndex)
		queryArgs = append(queryArgs, maxInstallments)
		argIndex++
	}

	financingType := request.GetString("type", "")
	if financingType != "" {
		query += fmt.Sprintf(" AND tipo_financiamento = $%d", argIndex)
		queryArgs = append(queryArgs, financingType)
	}

	query += " ORDER BY taxa_juros_mes ASC LIMIT 3"

	rows, err := s.DB.QueryContext(ctx, query, queryArgs...)
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("erro ao buscar financiamentos: %v", err)), nil
	}
	defer rows.Close()

	var financings []map[string]interface{}
	for rows.Next() {
		var banco, tipo, observacoes string
		var taxaMes, taxaAno, valorEntrada, valorParcela, valorTotal float64
		var numeroParcelas int

		err := rows.Scan(&banco, &tipo, &taxaMes, &taxaAno, &numeroParcelas,
			&valorEntrada, &valorParcela, &valorTotal, &observacoes)
		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("erro ao escanear financiamento: %v", err)), nil
		}

		financings = append(financings, map[string]interface{}{
			"banco":         banco,
			"tipo":          tipo,
			"taxa_mes":      taxaMes,
			"taxa_ano":      taxaAno,
			"parcelas":      numeroParcelas,
			"valor_entrada": valorEntrada,
			"valor_parcela": valorParcela,
			"valor_total":   valorTotal,
			"observacoes":   observacoes,
		})
	}

	resultJSON, _ := json.Marshal(financings)
	return mcp.NewToolResultText(string(resultJSON)), nil
}

func (s *Server) CalculateFinancing(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	vehiclePrice, err := request.RequireFloat("vehicle_price")
	if err != nil {
		return mcp.NewToolResultError("parâmetro 'vehicle_price' é obrigatório"), nil
	}

	installments, err := request.RequireFloat("installments")
	if err != nil {
		return mcp.NewToolResultError("parâmetro 'installments' é obrigatório"), nil
	}

	downPayment := request.GetFloat("down_payment", 0.0)
	bank := request.GetString("bank", "Itaú Unibanco")

	var interestRate float64 = 0.0427
	query := `
		SELECT taxa_juros_ano 
		FROM financiamentos 
		WHERE banco_financiadora = $1 AND aprovado = true 
		ORDER BY taxa_juros_ano ASC 
		LIMIT 1
	`

	row := s.DB.QueryRowContext(ctx, query, bank)
	var rate float64
	if err := row.Scan(&rate); err == nil {
		interestRate = rate / 100
	}

	financeAmount := vehiclePrice - downPayment
	monthlyRate := interestRate / 12

	var monthlyPayment float64
	if monthlyRate > 0 {
		monthlyPayment = financeAmount * (monthlyRate * mathPow(1+monthlyRate, installments)) / (mathPow(1+monthlyRate, installments) - 1)
	} else {
		monthlyPayment = financeAmount / installments
	}

	totalAmount := monthlyPayment * installments

	result := map[string]interface{}{
		"valor_veiculo":      vehiclePrice,
		"valor_entrada":      downPayment,
		"valor_financiado":   financeAmount,
		"numero_parcelas":    int(installments),
		"valor_parcela":      monthlyPayment,
		"valor_total":        totalAmount,
		"taxa_juros_ano":     interestRate * 100,
		"banco_financiadora": bank,
	}

	resultJSON, _ := json.Marshal(result)
	return mcp.NewToolResultText(string(resultJSON)), nil
}

func (s *Server) Close() error {
	if s.DB != nil {
		return s.DB.Close()
	}
	return nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func mathPow(base, exp float64) float64 {
	if exp == 0 {
		return 1
	}
	result := 1.0
	for i := 0; i < int(exp); i++ {
		result *= base
	}
	return result
}
