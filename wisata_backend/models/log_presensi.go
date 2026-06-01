package models

import "time"

type LogPresensi struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	IDPeserta string    `gorm:"column:id_peserta" json:"id_peserta"`
	Nama      string    `gorm:"column:nama" json:"nama"`
	Waktu     time.Time `gorm:"column:waktu;autoCreateTime" json:"waktu"`
}

func (LogPresensi) TableName() string {
	return "log_presensi" // Sesuaikan nama tabel log aslimu dari ESP32
}