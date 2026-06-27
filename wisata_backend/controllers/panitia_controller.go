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

// Struct khusus untuk menangkap data dari Flutter (POST & PUT)
// ---> REVISI: Menambahkan tag JSON baru agar pas dengan Map dari Flutter <---
type InputDataPeserta struct {
    IDPeserta      string `json:"id_peserta"`
    NamaLengkap    string `json:"nama_lengkap"`
    Password       string `json:"password"`
    Role           string `json:"role"`
    Seat           string `json:"seat"`
    PenyakitBawaan string `json:"penyakit_bawaan"`
    Alergi         string `json:"alergi"`
    KontakDarurat  string `json:"kontak_darurat"`
}

// 1. FUNGSI TAMBAH PESERTA (POST)
func TambahPeserta(c *gin.Context) {
    var input InputDataPeserta

    // Tangkap data JSON dari Flutter
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "status":  "gagal",
            "message": "Format data tidak sesuai",
        })
        return
    }

    // Cek apakah ID Peserta sudah ada di database agar tidak bentrok
    var existing models.Peserta
    if err := config.DB.Where("id_peserta = ?", input.IDPeserta).First(&existing).Error; err == nil {
        c.JSON(http.StatusConflict, gin.H{
            "status":  "gagal",
            "message": "ID Peserta sudah terdaftar!",
        })
        return
    }

    // Bentuk objek peserta baru dengan field lengkap hasil revisi
    pesertaBaru := models.Peserta{
        IDPeserta:      input.IDPeserta,
        NamaLengkap:    input.NamaLengkap,
        KataSandi:      input.Password, // Menyimpan password (termasuk default '123456' dari Flutter)
        Role:           input.Role,
        Seat:           input.Seat,
        PenyakitBawaan: input.PenyakitBawaan,
        Alergi:         input.Alergi,
        KontakDarurat:  input.KontakDarurat,
    }

    // Simpan ke Database
    if err := config.DB.Create(&pesertaBaru).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "status":  "gagal",
            "message": "Gagal menyimpan data ke database",
        })
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "status":  "sukses",
        "message": "Data peserta berhasil ditambahkan!",
        "data":    pesertaBaru,
    })
}

// 2. FUNGSI EDIT PESERTA (PUT)
func EditPesertaManual(c *gin.Context) {
    idPeserta := c.Param("id")
    var input InputDataPeserta

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "status":  "gagal",
            "message": "Format data tidak sesuai",
        })
        return
    }

    var peserta models.Peserta

    // Cari peserta berdasarkan ID
    if err := config.DB.First(&peserta, "id_peserta = ?", idPeserta).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "status":  "gagal",
            "message": "Data peserta tidak ditemukan!",
        })
        return
    }

    // ---> REVISI: Update seluruh data pelengkap sesuai form edit Flutter <---
    peserta.NamaLengkap = input.NamaLengkap
    peserta.Seat = input.Seat
    peserta.PenyakitBawaan = input.PenyakitBawaan
    peserta.Alergi = input.Alergi
    peserta.KontakDarurat = input.KontakDarurat

    // Simpan perubahan ke Database
    if err := config.DB.Save(&peserta).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "status":  "gagal",
            "message": "Gagal memperbarui data peserta",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "status":  "sukses",
        "message": "Data peserta berhasil diupdate!",
        "data":    peserta,
    })
}

// 3. FUNGSI HAPUS PESERTA (DELETE)
func HapusPeserta(c *gin.Context) {
    idPeserta := c.Param("id")
    var peserta models.Peserta

    // Cari dulu apakah datanya ada
    if err := config.DB.First(&peserta, "id_peserta = ?", idPeserta).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "status":  "gagal",
            "message": "Data peserta tidak ditemukan!",
        })
        return
    }

    // Hapus datanya
    if err := config.DB.Delete(&peserta).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "status":  "gagal",
            "message": "Gagal menghapus data peserta",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "status":  "sukses",
        "message": "Peserta berhasil dihapus!",
    })
}