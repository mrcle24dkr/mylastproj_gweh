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

    err := config.DB.AutoMigrate(
        &models.ProyekPerjalanan{}, 
        &models.ArmadaBus{}, 
        &models.Peserta{},
        &models.LogPresensi{},
        &models.Rundown{}, 
    )
    if err != nil {
        panic("Gagal melakukan migrasi database: " + err.Error())
    }

    // 3. Inisialisasi router Gin
    r := gin.Default()

    // PASANG CORS DI SINI (Sebelum rute didefinisikan)
    r.Use(cors.Default())

    // Daftarkan rute API (Termasuk /api/login dan /api/logs yang baru kita buat)
    routes.SetupRoutes(r)

    // 4. Buat rute uji coba (tes API)
    r.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "status":  "sukses",
            "message": "Backend API Empirise berjalan lancar!",
        })
    })

    // Rute get peserta lama (Tetap aman)
    r.GET("/api/peserta/:id", controllers.GetPesertaByID)

    // 5. Jalankan server di port 8080
    r.Run(":8080")
}