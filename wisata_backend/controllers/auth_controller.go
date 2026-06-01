package controllers

import (
	"net/http"
	"wisata_backend/config" // Sesuaikan dengan nama module di go.mod milikmu
	"wisata_backend/models"

	"github.com/gin-gonic/gin"
)

type LoginRequest struct {
	IDPengguna string `json:"id_pengguna"`
	KataSandi  string `json:"kata_sandi"`
}

func Login(c *gin.Context) {
	var req LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format data salah"})
		return
	}

	var user models.Peserta
	// Cari pengguna berdasarkan ID
	if err := config.DB.Where("id_peserta = ?", req.IDPengguna).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "ID tidak ditemukan"})
		return
	}

	// Validasi Kata Sandi
	if user.KataSandi != req.KataSandi {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Kata sandi salah!"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Login berhasil",
		"data": gin.H{
			"id":   user.IDPeserta,
			"nama": user.NamaLengkap,
			"role": user.Role,
		},
	})
}