package controllers

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

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
				// Susun CSV dengan rapi
				csvData += idPeserta + "," + secretKey + "\n"
			}
		}

		if len(csvData) == 0 {
			c.String(http.StatusNotFound, "Tidak ada data peserta")
			return
		}

		// ---------------------------------------------------------
		// 3 HEADER PENYELAMAT ESP32 (MEMAKSA PENULISAN SD CARD)
		// ---------------------------------------------------------
		// 1. Beritahu ukuran pastinya
		c.Header("Content-Length", strconv.Itoa(len(csvData)))

		c.Header("Connection", "close")
		
		// 2. MATIKAN Keep-Alive! Ini yang membuat writeToStream ESP32 error
		c.Header("Connection", "close") 
		
		// 3. Gunakan c.Data agar Golang mengirim raw byte langsung (tanpa chunking)
		c.Data(http.StatusOK, "text/plain", []byte(csvData))
	}
}