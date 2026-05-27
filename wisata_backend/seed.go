//go:build ignore

package main

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/csv"
	"fmt"
	"log"
	"strings"
	"wisata_backend/config"
	"wisata_backend/models"
)

// Fungsi untuk generate Secret Key TOTP (Base32, 16 karakter)
func generateTOTPSecret() string {
	bytes := make([]byte, 10)
	rand.Read(bytes)
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(bytes)
}

func main() {
	// 1. Hubungkan ke Database
	config.ConnectDatabase()

	// 2. Buat Data Proyek (Kunjungan Industri)
	fmt.Println("⏳ Menyiapkan data Proyek...")
	proyek := models.ProyekPerjalanan{
		NamaTujuan:       "Surabaya - Bali (Collaboration Engineering In Action)",
		TanggalBerangkat: "2025-07-07",
	}
	config.DB.FirstOrCreate(&proyek, models.ProyekPerjalanan{NamaTujuan: proyek.NamaTujuan})

	// 3. Buat Data 2 Armada Bus (Titik kumpul 0, akan diupdate dinamis via aplikasi)
	fmt.Println("⏳ Menyiapkan data Armada Bus...")
	bus1 := models.ArmadaBus{
		IDProyek: proyek.ID, NamaBus: "Vella Autotrans (HIMTEK)", LatTitikKumpul: 0, LonTitikKumpul: 0,
	}
	bus2 := models.ArmadaBus{
		IDProyek: proyek.ID, NamaBus: "Surya Agung (HMTI)", LatTitikKumpul: 0, LonTitikKumpul: 0,
	}
	config.DB.FirstOrCreate(&bus1, models.ArmadaBus{NamaBus: bus1.NamaBus})
	config.DB.FirstOrCreate(&bus2, models.ArmadaBus{NamaBus: bus2.NamaBus})

	// 4. Data Mentah Mahasiswa (Dosen sudah difilter keluar)
	rawCSV := `Jovensy Devianto,5220611206
Benediktus Adryano Vito,5230611169
Anisa Nur Salsabila,5230611177
Adlya Adhwa Prabowo,5240611050
Nadin Neva Mulyani,5240611023
Rezki Mepta Kurniawan,5230611141
Rajif Anwar Miftahul Falah,5230611164
Aishafa Dwita Radiasari,5240611131
Maulidia Sintia Bella,5240611081
Muhammad Afrian Pratama,5230611146
Firda Muthmainnah,5230611130
Haikal Firza Zaidu Dzaka,5220611159
Rahman Fahid,5230611091
Rachel Wanda Chirstiani,5230611188
Selvia Hanif Ardian Putri,5230611158
Dirly Aldy Tombeng,5240611121
Riyan Ardian Syah,5221011058
Dwiyan Agung Wicaksono,5221011038
Dian Ramadanti,5231011046
Lidia Fitriana,5231011009
Aprian Adi Setyawan,5221011068
Alifia Sindi Ananda,5231011035
Sri Zulfa,5231011023
Yodha Ardiansyah,5221011054
Ahmad Nur Fauzan,5231011028
Achmad Agim Machfud,5221011053
Cindy Aurelia,5221011003
Laora Margareth Gogali,5221011022
Ivan Bagus Zulpani,5221011041
Agung Hanif Izzatulhaq,5221011067
Rizqi Akbar Hernawan,5231011016
Raditya Ramadhan,5231011001`
    // (Saya memasukkan 32 data pertama sebagai sampel, Anda bisa copy-paste sisa datanya ke dalam string rawCSV ini dengan format yang sama)

	// 5. Eksekusi Otomatisasi
	fmt.Println("⏳ Memproses injeksi data Peserta...")
	reader := csv.NewReader(strings.NewReader(rawCSV))
	records, err := reader.ReadAll()
	if err != nil {
		log.Fatal("Gagal membaca CSV:", err)
	}

	count := 0
	for _, row := range records {
		nama := strings.TrimSpace(row[0])
		npm := strings.TrimSpace(row[1])

		// Ambil 3 digit terakhir NPM untuk ID
		tigaDigitAkhir := "000"
		if len(npm) >= 3 {
			tigaDigitAkhir = npm[len(npm)-3:]
		}

		var idBus uint
		var kodeBooking string

		// Logika Pemisahan Bus berdasarkan Digit 4-7
		if strings.Contains(npm, "1011") {
			idBus = bus1.ID
			kodeBooking = fmt.Sprintf("EMP-VA01-%s", tigaDigitAkhir) // VA = Vella Autotrans
		} else if strings.Contains(npm, "0611") {
			idBus = bus2.ID
			kodeBooking = fmt.Sprintf("EMP-SA01-%s", tigaDigitAkhir) // SA = Surya Agung
		} else {
			continue // Skip jika prodi tidak dikenali
		}

		// Buat record peserta
		peserta := models.Peserta{
			IDPeserta:   kodeBooking,
			NamaLengkap: nama,
			IDBus:       idBus,
			QRSecretKey: generateTOTPSecret(),
		}

		// Injeksi ke Database
		if err := config.DB.FirstOrCreate(&peserta, models.Peserta{IDPeserta: peserta.IDPeserta}).Error; err == nil {
			count++
		}
	}

	fmt.Printf("✅ SUKSES! %d data peserta berhasil disuntikkan ke dalam brankas PostgreSQL.\n", count)
}