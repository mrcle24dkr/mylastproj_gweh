package controllers

import (
	"database/sql"
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// SyncKeysHandler meracik data dari PostgreSQL menjadi format CSV untuk ESP32
func SyncKeysHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// SESUAIKAN NAMA TABEL DAN KOLOM DENGAN DATABASE POSTGRESQL KAMU
		// Ambil data peserta yang aktif (misal: belum checkout)
		query := `SELECT id_peserta, secret_key FROM peserta WHERE status_aktif = true`
		
		rows, err := db.Query(query)
		if err != nil {
			c.String(http.StatusInternalServerError, "Gagal mengambil data dari database")
			return
		}
		defer rows.Close()

		// Gunakan strings.Builder untuk merakit teks CSV dengan sangat cepat dan hemat RAM
		var csvBuilder strings.Builder

		// Loop semua data dan susun dengan format: ID,SECRET_KEY\n
		for rows.Next() {
			var idPeserta, secretKey string
			if err := rows.Scan(&idPeserta, &secretKey); err != nil {
				continue // Abaikan baris yang error, lanjut ke peserta berikutnya
			}
			
			// Tulis ke dalam builder
			csvBuilder.WriteString(fmt.Sprintf("%s,%s\n", idPeserta, secretKey))
		}

		// Jika data kosong
		if csvBuilder.Len() == 0 {
			c.String(http.StatusNotFound, "Tidak ada data peserta")
			return
		}

		// Set header agar dikenali sebagai teks mentah oleh HTTPClient ESP32
		c.Header("Content-Type", "text/plain")
		
		// Tembakkan output CSV-nya (Code 200 OK)
		c.String(http.StatusOK, csvBuilder.String())
	}
}