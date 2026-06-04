package controllers

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// Pastikan parameter db sesuai dengan yang didaftarkan di routes.go
func SyncKeysHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		query := `SELECT id_peserta, qr_secret_key FROM peserta`
		rows, err := db.Query(query)
		if err != nil {
			c.String(http.StatusInternalServerError, "Gagal mengambil data")
			return
		}
		defer rows.Close()

		var csvData string
		for rows.Next() {
			var idPeserta, secretKey string
			if err := rows.Scan(&idPeserta, &secretKey); err == nil {
				// Cegah data kosong masuk ke CSV
				if idPeserta != "" && secretKey != "" {
					csvData += idPeserta + "," + secretKey + "\n"
				}
			}
		}

		if len(csvData) == 0 {
			c.String(http.StatusNotFound, "Tidak ada data peserta")
			return
		}

		c.Header("Content-Length", strconv.Itoa(len(csvData)))

		c.Data(http.StatusOK, "text/csv", []byte(csvData))
	}
}