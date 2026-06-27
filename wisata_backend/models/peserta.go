package models

type Peserta struct {
    IDPeserta   string    `gorm:"primaryKey;type:varchar(20)" json:"IDPeserta"`
    NamaLengkap string    `gorm:"type:varchar(100);not null" json:"NamaLengkap"`
    IDBus       *uint     `json:"IDBus"` 
    Bus         ArmadaBus `gorm:"foreignKey:IDBus" json:"Bus"`
    QRSecretKey string    `gorm:"type:varchar(255)" json:"QRSecretKey"` 
    
    // Dua kolom keamanan akun
    KataSandi   string    `gorm:"column:kata_sandi" json:"-"` 
    Role        string    `gorm:"column:role" json:"Role"`

    // ---> TAMBAHKAN 4 BARIS BARU HASIL REVISI DI SINI <---
    Seat           string    `gorm:"column:seat;type:varchar(20)" json:"Seat"`
    PenyakitBawaan string    `gorm:"column:penyakit_bawaan;type:varchar(100)" json:"PenyakitBawaan"`
    Alergi         string    `gorm:"column:alergi;type:varchar(100)" json:"Alergi"`
    KontakDarurat  string    `gorm:"column:kontak_darurat;type:varchar(20)" json:"KontakDarurat"`
}

// Tambahkan blok ini untuk memaksa nama tabel
func (Peserta) TableName() string {
    return "peserta"
}