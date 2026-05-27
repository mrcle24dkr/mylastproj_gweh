package models

type Peserta struct {
	IDPeserta   string    `gorm:"primaryKey;type:varchar(20)"`
	NamaLengkap string    `gorm:"type:varchar(100);not null"`
	IDBus       uint      
	Bus         ArmadaBus `gorm:"foreignKey:IDBus"`
	QRSecretKey string    `gorm:"type:varchar(255)"` 
}

// Tambahkan blok ini untuk memaksa nama tabel
func (Peserta) TableName() string {
	return "peserta"
}