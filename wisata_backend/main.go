package main

import (
	"wisata_backend/config"
	"wisata_backend/models"
	"wisata_backend/controllers"
	"wisata_backend/routes"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

)

func main() {
	// 1. Panggil fungsi untuk menyambungkan ke database
	config.ConnectDatabase()

	// 2. JALANKAN AUTOMIGRATE GORM
	config.DB.AutoMigrate(&models.ProyekPerjalanan{}, &models.ArmadaBus{}, &models.Peserta{})

	// 3. Inisialisasi router Gin
	r := gin.Default()

	routes.SetupRoutes(r)

	r.Use(cors.Default())

	// 4. Buat rute uji coba (tes API)
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "sukses",
			"message": "Backend API Empirise berjalan lancar!",
		})
	})

	r.GET("/api/peserta/:id", controllers.GetPesertaByID)

	// 5. Jalankan server di port 8080
	r.Run(":8080")
}