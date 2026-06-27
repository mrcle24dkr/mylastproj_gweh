package controllers

import (
    "net/http"
    "wisata_backend/config"
    "wisata_backend/models"

    "github.com/gin-gonic/gin"
)

// ---> TAMBAHAN: Variabel Global penyimpan Sesi (Tersimpan di RAM Server) <---
var SesiPresensiAktif string = "Pemberangkatan Awal"

// ---> TAMBAHAN: Fungsi untuk API Get Sesi <---
func GetSesiAktif(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{"status": "success", "sesi": SesiPresensiAktif})
}

// ---> TAMBAHAN: Fungsi untuk API Set Sesi dari Flutter Panitia <---
func SetSesiAktif(c *gin.Context) {
    var input struct {
        Sesi string `json:"sesi"`
    }
    if err := c.ShouldBindJSON(&input); err == nil {
        SesiPresensiAktif = input.Sesi
        c.JSON(http.StatusOK, gin.H{"status": "success", "sesi": SesiPresensiAktif})
    } else {
        c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format salah"})
    }
}

// (Fungsi GetLogs mengambil semua riwayat presensi)
func GetLogs(c *gin.Context) {
    var logs []models.LogPresensi
    if err := config.DB.Order("waktu desc").Limit(50).Find(&logs).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil data log"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "success", "data": logs})
}

type InputLogRequest struct {
    IDPeserta string `json:"id_peserta"`
}

// 1. Fungsi CatatLog dengan Proteksi Ganda (ID Peserta + Nama Sesi)
func CatatLog(c *gin.Context) {
    var req InputLogRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"message": "Format salah"})
        return
    }

    // ---> REVISI: Cek Duplikat berdasarkan ID Peserta DAN Sesi Aktif <---
    var count int64
    config.DB.Model(&models.LogPresensi{}).Where("id_peserta = ? AND nama_sesi = ?", req.IDPeserta, SesiPresensiAktif).Count(&count)
    if count > 0 {
        c.JSON(http.StatusConflict, gin.H{"message": "Peserta sudah absen di sesi ini!"})
        return
    }

    var peserta models.Peserta
    namaPeserta := "Unknown"
    if err := config.DB.Where("id_peserta = ?", req.IDPeserta).First(&peserta).Error; err == nil {
        namaPeserta = peserta.NamaLengkap
    }

    logBaru := models.LogPresensi{
        IDPeserta: req.IDPeserta,
        Nama:      namaPeserta,
        NamaSesi:  SesiPresensiAktif, // ESP32 gak ngirim ini, Golang yang nyisipin otomatis
    }

    if err := config.DB.Create(&logBaru).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"message": "Gagal menyimpan log"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Log berhasil dicatat!"})
}

// 2. Fungsi Menghapus Log yang disesuaikan
func HapusLog(c *gin.Context) {
    idPeserta := c.Param("id") 

    // ---> REVISI: Hanya hapus log untuk SESI YANG SEDANG AKTIF. <---
    // Jadi kalau Panitia hapus absen di sesi "Makan Siang", absen waktu "Berangkat" tetap aman!
    if err := config.DB.Where("id_peserta = ? AND nama_sesi = ?", idPeserta, SesiPresensiAktif).Delete(&models.LogPresensi{}).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menghapus log"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Data absen di sesi ini berhasil dihapus!"})
}