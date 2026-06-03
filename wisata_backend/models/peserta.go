package models

type Peserta struct {
	IDPeserta   string    `gorm:"primaryKey;type:varchar(20)" json:"IDPeserta"`
	NamaLengkap string    `gorm:"type:varchar(100);not null" json:"NamaLengkap"`
	IDBus       *uint     `json:"IDBus"` 
	Bus         ArmadaBus `gorm:"foreignKey:IDBus" json:"Bus"`
	QRSecretKey string    `gorm:"type:varchar(255)" json:"QRSecretKey"` 
	
	// Dua kolom baru kita biarkan aman
	KataSandi   string    `gorm:"column:kata_sandi" json:"-"` 
	Role        string    `gorm:"column:role" json:"Role"`
}

// Tambahkan blok ini untuk memaksa nama tabel
func (Peserta) TableName() string {
	return "peserta"
}