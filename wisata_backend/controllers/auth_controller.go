package controllers

import (
    "net/http"
    "wisata_backend/config" // Sesuaikan dengan nama module di go.mod milikmu
    "wisata_backend/models"

    "github.com/gin-gonic/gin"
)

// 1. UBAH STRUCT REQUEST-NYA
type LoginRequest struct {
    NamaPengguna string `json:"nama_pengguna"` // Menangkap data nama dari Flutter
    KataSandi    string `json:"kata_sandi"`
}

func Login(c *gin.Context) {
    var req LoginRequest

    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format data salah"})
        return
    }

    var user models.Peserta
    
    // 2. UBAH LOGIKA PENCARIAN DATABASE-NYA
    // Sekarang mencari berdasarkan nama_lengkap (Peka terhadap huruf besar/kecil)
    if err := config.DB.Where("nama_lengkap = ?", req.NamaPengguna).First(&user).Error; err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Nama tidak ditemukan / Salah ketik"})
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
            "id":   user.IDPeserta, // Tetap harus melempar ID agar sistem QR Flutter bisa jalan
            "nama": user.NamaLengkap,
            "role": user.Role,
        },
    })
}