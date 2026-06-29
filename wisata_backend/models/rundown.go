package models

type Rundown struct {
    ID       uint   `gorm:"primaryKey;autoIncrement" json:"id"`
    Waktu    string `gorm:"type:varchar(50)" json:"waktu"`
    Kegiatan string `gorm:"type:varchar(255)" json:"kegiatan"`
    Lokasi   string `gorm:"type:varchar(255)" json:"lokasi"`

    PerluPresensi bool   `gorm:"default:false" json:"perlu_presensi"`
}

func (Rundown) TableName() string {
    return "rundown"
}