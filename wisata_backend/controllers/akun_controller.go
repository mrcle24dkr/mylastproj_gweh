package controllers

import (
	"net/http"
	"wisata_backend/config"
	"wisata_backend/models"

	"github.com/gin-gonic/gin"
)

// Penampung data dari Flutter
type PasswordRequest struct {
	IDPeserta    string `json:"id_peserta"`
	PasswordLama string `json:"password_lama"`
	PasswordBaru string `json:"password_baru"`
}

func GantiPassword(c *gin.Context) {
	var req PasswordRequest

	// Tangkap JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format data tidak valid"})
		return
	}

	var user models.Peserta
	// Cari user di database
	if err := config.DB.Where("id_peserta = ?", req.IDPeserta).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Pengguna tidak ditemukan"})
		return
	}

	// Validasi password lama
	if user.KataSandi != req.PasswordLama {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Kata sandi saat ini salah!"})
		return
	}

	// Timpa dengan password baru
	if err := config.DB.Model(&user).Update("kata_sandi", req.PasswordBaru).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal memperbarui kata sandi"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Kata sandi berhasil diperbarui!",
	})
}