package routes

import (
	"wisata_backend/config"
	"wisata_backend/controllers"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	// Mempertahankan kode aslimu untuk mengambil sql.DB dari GORM
	sqlDB, err := config.DB.DB()
	if err != nil {
		panic("Gagal mengambil instance sql.DB dari GORM: " + err.Error())
	}

	// Grouping API
	api := r.Group("/api")
	{
		// 1. Rute lamamu untuk alat ESP32 (Tetap biarkan seperti aslinya)
		api.GET("/sync-keys", controllers.SyncKeysHandler(sqlDB))

		// 2. Rute BARU untuk Aplikasi Flutter (Login & Dashboard)
		api.POST("/login", controllers.Login)
		api.GET("/logs", controllers.GetLogs)

		api.PUT("/user/password", controllers.GantiPassword)

		// ---> RUTE BARU UNTUK HAK AKSES PANITIA <---
		api.GET("/panitia/peserta", controllers.GetAllPeserta)
		api.PUT("/panitia/peserta/:id", controllers.EditPesertaManual)
		api.POST("/panitia/peserta", controllers.TambahPeserta)
		api.DELETE("/panitia/peserta/:id", controllers.HapusPeserta)    // Hapus data (DELETE)

        api.POST("/logs", controllers.CatatLog)
		api.DELETE("/logs/:id", controllers.HapusLog)
	}
}