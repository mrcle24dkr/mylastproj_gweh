package models

type ProyekPerjalanan struct {
	ID               uint   `gorm:"primaryKey"`
	NamaTujuan       string `gorm:"type:varchar(100);not null"`
	TanggalBerangkat string `gorm:"type:date"`
}

// Tambahkan blok ini untuk memaksa nama tabel
func (ProyekPerjalanan) TableName() string {
	return "proyek_perjalanan"
}