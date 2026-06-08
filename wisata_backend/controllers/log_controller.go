package controllers

import (
	"net/http"
	"wisata_backend/config"
	"wisata_backend/models"

	"github.com/gin-gonic/gin"
)

func GetLogs(c *gin.Context) {
	var logs []models.LogPresensi

	// Ambil 50 log terbaru
	if err := config.DB.Order("waktu desc").Limit(50).Find(&logs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil data log"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   logs,
	})
}

type InputLogRequest struct {
	IDPeserta string `json:"id_peserta"`
}

// Fungsi penerima lemparan log
func CatatLog(c *gin.Context) {
	var req InputLogRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Format salah"})
		return
	}

	// Cari nama peserta di tabel master data berdasarkan ID-nya
	var peserta models.Peserta
	namaPeserta := "Unknown"
	if err := config.DB.Where("id_peserta = ?", req.IDPeserta).First(&peserta).Error; err == nil {
		namaPeserta = peserta.NamaLengkap
	}

	// Rangkai data log baru
	logBaru := models.LogPresensi{
		IDPeserta: req.IDPeserta,
		Nama:      namaPeserta,
	}

	// Simpan permanen ke PostgreSQL
	if err := config.DB.Create(&logBaru).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Gagal menyimpan log"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Log berhasil dicatat!"})
}