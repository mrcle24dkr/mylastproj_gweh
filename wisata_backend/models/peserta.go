package models

type Peserta struct {
	IDPeserta   string    `gorm:"primaryKey;type:varchar(20)"`
	NamaLengkap string    `gorm:"type:varchar(100);not null"`
	IDBus       *uint     `json:"id_bus"`
	Bus         ArmadaBus `gorm:"foreignKey:IDBus"`
	QRSecretKey string    `gorm:"type:varchar(255)"` 
	KataSandi   string `gorm:"column:kata_sandi" json:"-"`
	Role        string `gorm:"column:role" json:"role"`
}

// Tambahkan blok ini untuk memaksa nama tabel
func (Peserta) TableName() string {
	return "peserta"
}