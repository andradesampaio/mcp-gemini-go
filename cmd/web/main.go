package main

import (
	"log"
	"net/http"

	"mcp-gemini-go/internal/web/handlers"
	"mcp-gemini-go/internal/web/services"
)

func main() {
	webService, err := services.NewWebService()
	if err != nil {
		log.Fatalf("Erro ao inicializar serviços: %v", err)
	}
	defer webService.Close()

	chatHandler := handlers.NewChatHandler(webService.MCPClient, webService.Tools)
	staticHandler := handlers.NewStaticHandler("internal/web/html/static")

	http.HandleFunc("/", chatHandler.HandleHome)
	http.HandleFunc("/chat", chatHandler.HandleChat)
	http.HandleFunc("/static/", staticHandler.ServeFiles)

	port := "80"
	log.Printf("🚀 Servidor web iniciado em http://localhost:%s", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Erro ao iniciar servidor: %v", err)
	}
}
