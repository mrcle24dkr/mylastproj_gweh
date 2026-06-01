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