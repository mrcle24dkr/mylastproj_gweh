// Lokasi: controllers/log_controller.go
package controllers

import (
	"net/http"
	"wisata_backend/config"
	"wisata_backend/models"

	"github.com/gin-gonic/gin"
)

// (Fungsi GetLogs biarkan tetap ada seperti sebelumnya)
func GetLogs(c *gin.Context) {
	var logs []models.LogPresensi
	if err := config.DB.Order("waktu desc").Limit(50).Find(&logs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil data log"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": logs})
}

type InputLogRequest struct {
	IDPeserta string `json:"id_peserta"`
}

// 1. Fungsi CatatLog dengan Proteksi Ganda
func CatatLog(c *gin.Context) {
	var req InputLogRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Format salah"})
		return
	}

	// CEK DUPLIKAT: Apakah ID ini sudah ada di tabel log?
	var count int64
	config.DB.Model(&models.LogPresensi{}).Where("id_peserta = ?", req.IDPeserta).Count(&count)
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"message": "Peserta sudah absen sebelumnya!"})
		return
	}

	var peserta models.Peserta
	namaPeserta := "Unknown"
	if err := config.DB.Where("id_peserta = ?", req.IDPeserta).First(&peserta).Error; err == nil {
		namaPeserta = peserta.NamaLengkap
	}

	logBaru := models.LogPresensi{
		IDPeserta: req.IDPeserta,
		Nama:      namaPeserta,
	}

	if err := config.DB.Create(&logBaru).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Gagal menyimpan log"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Log berhasil dicatat!"})
}

// 2. Fungsi BARU untuk Menghapus Log
func HapusLog(c *gin.Context) {
    idPeserta := c.Param("id") // Menangkap id_peserta dari Flutter (misal: EMP-001)

    // Perintah GORM diubah untuk memfilter berdasarkan kolom id_peserta
    if err := config.DB.Where("id_peserta = ?", idPeserta).Delete(&models.LogPresensi{}).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menghapus log"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Data absen berhasil dihapus!"})
}