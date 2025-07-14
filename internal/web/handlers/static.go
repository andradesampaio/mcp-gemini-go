package handlers

import (
	"net/http"
	"path/filepath"
)

type StaticHandler struct {
	staticDir string
}

func NewStaticHandler(staticDir string) *StaticHandler {
	return &StaticHandler{staticDir: staticDir}
}

func (h *StaticHandler) ServeFiles(w http.ResponseWriter, r *http.Request) {
	filename := r.URL.Path[len("/static/"):]
	fullPath := filepath.Join(h.staticDir, filename)
	http.ServeFile(w, r, fullPath)
}
