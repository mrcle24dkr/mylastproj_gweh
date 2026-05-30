package routes

import (
	"wisata_backend/config"
	"wisata_backend/controllers"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	sqlDB, err := config.DB.DB()
	if err != nil {
		panic("Gagal mengambil instance sql.DB dari GORM: " + err.Error())
	}

	api := r.Group("/api")
	{
		api.GET("/sync-keys", controllers.SyncKeysHandler(sqlDB))
	}
}