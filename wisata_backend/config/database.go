package config

import (
	"fmt"
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Variabel global agar database bisa dipanggil dari file lain (seperti controller)
var DB *gorm.DB

func ConnectDatabase() {
	// Konfigurasi koneksi ke PostgreSQL di Docker
	// Sesuaikan host dengan localhost, dan sslmode=disable karena kita berjalan di lokal
	dsn := "host=127.0.0.1 user=admin_wisata password=empirise dbname=db_data_peserta port=5432 sslmode=disable TimeZone=Asia/Jakarta"
	
	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Gagal terhubung ke database PostgreSQL!\n", err)
	}

	fmt.Println("🚀 Berhasil terhubung ke database PostgreSQL (Docker)!")
	DB = database
}