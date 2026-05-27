package models

type ArmadaBus struct {
	ID             uint    `gorm:"primaryKey"`
	IDProyek       uint    
	NamaBus        string  `gorm:"type:varchar(50);not null"`
	LatTitikKumpul float64 `gorm:"type:numeric(10,5)"` 
	LonTitikKumpul float64 `gorm:"type:numeric(10,5)"`
}

// Tambahkan blok ini untuk memaksa nama tabel
func (ArmadaBus) TableName() string {
	return "armada_bus"
}