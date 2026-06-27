package models

import "time"

type LogPresensi struct {
    ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
    IDPeserta string    `gorm:"column:id_peserta" json:"id_peserta"`
    Nama      string    `gorm:"column:nama" json:"nama"`
    Waktu     time.Time `gorm:"column:waktu;autoCreateTime" json:"waktu"`
    
    // ---> TAMBAHAN: Kolom Nama Sesi <---
    NamaSesi  string    `gorm:"column:nama_sesi;type:varchar(100);default:'Pemberangkatan Awal'" json:"nama_sesi"`
}

func (LogPresensi) TableName() string {
    return "log_presensi" 
}