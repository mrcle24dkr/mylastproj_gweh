package controllers

import (
	"net/http"
	"wisata_backend/config"
	"wisata_backend/models"

	"github.com/gin-gonic/gin"
)

func GetPesertaByID(c *gin.Context) {
	// Ambil ID dari URL (misal: /api/peserta/P-001)
	idPeserta := c.Param("id")

	var peserta models.Peserta

	// Cari data peserta di database, dan JANGAN LUPA tarik juga data Bus-nya (Preload)
	// agar kita bisa mendapatkan LatTitikKumpul dan LonTitikKumpul
	if err := config.DB.First(&peserta, "id_peserta = ?", idPeserta).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "gagal",
			"message": "Data peserta tidak ditemukan!",
		})
		return
	}

	// Jika ketemu, kirim datanya ke Flutter dalam format JSON
	c.JSON(http.StatusOK, gin.H{
		"status": "sukses",
		"data":   peserta,
	})
}