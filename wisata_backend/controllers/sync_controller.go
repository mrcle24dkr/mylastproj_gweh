package controllers

import (
	"database/sql"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

// Pastikan fungsi ini menerima parameter sql.DB sesuai dengan routes.go milikmu
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
			// Tarik data dengan aman
			if err := rows.Scan(&idPeserta, &secretKey); err == nil {
				if idPeserta != "" && secretKey != "" {
					csvData += idPeserta + "," + secretKey + "\n"
				}
			}
		}

		if len(csvData) == 0 {
			c.String(http.StatusNotFound, "Tidak ada data peserta")
			return
		}

		fileName := "database_peserta.csv"
		err = os.WriteFile(fileName, []byte(csvData), 0644)
		if err != nil {
			c.String(http.StatusInternalServerError, "Gagal membuat file fisik di server")
			return
		}

		c.Header("Connection", "close")

		c.File(fileName)
	}
}