package controllers

import (
    "net/http"
    "wisata_backend/config"
    "wisata_backend/models"

    "github.com/gin-gonic/gin"
)

// Ambil Semua Jadwal (Untuk Peserta & Panitia)
func GetRundown(c *gin.Context) {
    var rundowns []models.Rundown
    // Diurutkan berdasarkan ID atau Waktu (disini kita urutkan by ID agar sesuai urutan input)
    if err := config.DB.Order("id asc").Find(&rundowns).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil jadwal"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "success", "data": rundowns})
}

// Tambah Jadwal (Panitia)
func TambahRundown(c *gin.Context) {
    var input models.Rundown
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format data salah"})
        return
    }

    if err := config.DB.Create(&input).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menyimpan jadwal"})
        return
    }
    c.JSON(http.StatusCreated, gin.H{"status": "sukses", "message": "Jadwal ditambahkan!"})
}

// Edit Jadwal (Panitia)
func EditRundown(c *gin.Context) {
    id := c.Param("id")
    var input models.Rundown

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format data salah"})
        return
    }

    var rundown models.Rundown
    if err := config.DB.First(&rundown, id).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Jadwal tidak ditemukan"})
        return
    }

    rundown.Waktu = input.Waktu
    rundown.Kegiatan = input.Kegiatan
    rundown.Lokasi = input.Lokasi

    config.DB.Save(&rundown)
    c.JSON(http.StatusOK, gin.H{"status": "sukses", "message": "Jadwal diperbarui!"})
}

// Hapus Jadwal (Panitia)
func HapusRundown(c *gin.Context) {
    id := c.Param("id")
    if err := config.DB.Delete(&models.Rundown{}, id).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menghapus jadwal"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "sukses", "message": "Jadwal dihapus!"})
}