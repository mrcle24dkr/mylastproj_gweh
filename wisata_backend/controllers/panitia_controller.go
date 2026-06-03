package controllers

import (
	"net/http"
	"wisata_backend/config"
	"wisata_backend/models"

	"github.com/gin-gonic/gin"
)

// Mengambil seluruh data peserta (Master Data)
func GetAllPeserta(c *gin.Context) {
	var peserta []models.Peserta
	
	// Preload "Bus" agar data relasinya ikut terambil
	if err := config.DB.Preload("Bus").Find(&peserta).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menarik master data"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   peserta,
	})
}

// Penampung data edit dari Flutter
type EditPesertaRequest struct {
	NamaLengkap string `json:"nama_lengkap"`
	IDBus       *uint  `json:"id_bus"`
}

// Mengedit data diri peserta spesifik
func EditPesertaManual(c *gin.Context) {
	idTarget := c.Param("id")
	var req EditPesertaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	var user models.Peserta
	if err := config.DB.Where("id_peserta = ?", idTarget).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Peserta tidak ditemukan"})
		return
	}

	// Update spesifik ke kolom yang diizinkan
	config.DB.Model(&user).Updates(models.Peserta{
		NamaLengkap: req.NamaLengkap,
		IDBus:       req.IDBus,
	})

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Data peserta berhasil dikoreksi!",
	})
}