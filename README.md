# OmahKu-web-app

Marketplace properti OmahKu. Repositori ini berisi implementasi basis data pada folder `db/` beserta aplikasi webnya pada folder `frontend/`.

Dokumentasi berikut membahas bagian basis data secara rinci

---

## Dokumentasi Database Bagian 1: Skema (`db/001_schema.sql`)

File `001_schema.sql` membuat kerangka basis data berupa 15 tabel kosong tanpa data. Pengisian data dilakukan pada file berikutnya. Sebelum menjalankan file ini, basis data harus dibuat dan dipilih terlebih dahulu melalui `CREATE DATABASE omahku;` lalu `USE omahku;`.

### Pengaturan di awal dan akhir file

```sql
SET FOREIGN_KEY_CHECKS = 0;
-- seluruh perintah CREATE TABLE berada di sini
SET FOREIGN_KEY_CHECKS = 1;
```

Tabel-tabel pada basis data ini saling merujuk satu sama lain. Sebagai contoh, tabel `property` membutuhkan tabel `user` untuk menyimpan pemiliknya. Bila pemeriksaan relasi aktif, MySQL akan menolak pembuatan `property` selama `user` belum ada, sehingga urutan pembuatan tabel menjadi rumit.

Perintah `SET FOREIGN_KEY_CHECKS = 0` mematikan pemeriksaan relasi untuk sementara, sehingga seluruh tabel dapat dibuat dalam urutan bebas. Perintah `SET FOREIGN_KEY_CHECKS = 1` di akhir mengaktifkannya kembali agar integritas relasi tetap terjaga setelah seluruh tabel selesai dibuat.

### Mesin penyimpanan InnoDB

Setiap definisi tabel diakhiri dengan `ENGINE=InnoDB`. InnoDB adalah mesin penyimpanan MySQL yang mendukung Foreign Key (relasi antar tabel) dan transaksi (rangkaian operasi yang dapat dibatalkan secara utuh bila terjadi kegagalan di tengah proses). Kedua kemampuan tersebut dibutuhkan oleh basis data ini, sehingga InnoDB dipakai pada seluruh tabel.

### Konsep dasar yang berlaku umum

Sebagian besar elemen pada tabel-tabel berikut bersifat berulang. Tabel `user` di bawah ini menjadi contoh untuk menjelaskannya.

```sql
CREATE TABLE IF NOT EXISTS `user` (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  NIK           CHAR(16) NOT NULL UNIQUE,
  username      VARCHAR(50) NOT NULL UNIQUE,
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  phone_number  VARCHAR(20) NOT NULL UNIQUE,
  password      VARCHAR(255) NOT NULL,
  role          ENUM('user','agent','admin') NOT NULL DEFAULT 'user',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at    DATETIME NULL
) ENGINE=InnoDB;
```

`CREATE TABLE IF NOT EXISTS` membuat tabel baru, namun tidak memunculkan error jika tabel dengan nama tersebut sudah ada. Hal ini membuat file aman dijalankan ulang.

Nama tabel ditulis dengan tanda backtick menjadi `` `user` `` karena `user` termasuk kata kunci milik MySQL. Backtick menandakan bahwa kata tersebut adalah nama tabel, bukan perintah.

`id INT AUTO_INCREMENT PRIMARY KEY` adalah kolom identitas. `INT` berarti bilangan bulat. `AUTO_INCREMENT` membuat nilainya bertambah otomatis (1, 2, 3, dan seterusnya) setiap ada baris baru, sehingga tidak perlu diisi manual. `PRIMARY KEY` menjadikan kolom ini penanda utama tiap baris yang nilainya tidak boleh kembar maupun kosong.

Tipe data teks yang digunakan:
- `CHAR(16)` menyimpan teks dengan panjang tetap 16 karakter, sesuai NIK yang selalu 16 digit.
- `VARCHAR(50)` menyimpan teks dengan panjang bervariasi hingga maksimal 50 karakter.
- `TEXT` menyimpan teks panjang tanpa batas praktis.

`NOT NULL` menandakan kolom wajib diisi dan tidak boleh dikosongkan.

`UNIQUE` menandakan nilai pada kolom tersebut tidak boleh ada yang sama di seluruh tabel. Karena `email` bersifat `UNIQUE`, dua baris tidak mungkin memiliki email yang sama.

`DEFAULT 'user'` membuat kolom `role` otomatis bernilai `'user'` bila tidak diisi saat memasukkan data.

`ENUM('user','agent','admin')` adalah tipe kolom yang isinya hanya boleh salah satu dari daftar yang ditentukan. Bila diisi nilai di luar daftar, MySQL menolaknya.

`DATETIME` menyimpan tanggal sekaligus jam. `CURRENT_TIMESTAMP` mengisi otomatis dengan waktu saat baris dibuat, sehingga `created_at` terisi sendiri.

Dua pola berikut dipakai di hampir semua tabel:

Kolom `deleted_at DATETIME NULL` digunakan untuk soft delete. Ketika sebuah data dihapus, barisnya tidak benar-benar dihilangkan, melainkan kolom `deleted_at` diisi dengan waktu penghapusan. Selama `deleted_at` masih bernilai `NULL`, data dianggap aktif. Pendekatan ini menjaga agar data lama tetap dapat ditelusuri.

Kolom `created_at` mencatat otomatis waktu pembuatan baris.

### Foreign Key

Foreign Key (FK) adalah kolom pada satu tabel yang nilainya harus menunjuk ke baris yang benar-benar ada pada tabel lain. Bentuk paling sederhana terdapat pada tabel `agent_profile`:

```sql
CONSTRAINT fk_agentprofile_user FOREIGN KEY (user_id) REFERENCES `user`(id)
```

Baris tersebut menetapkan bahwa kolom `user_id` harus berisi salah satu `id` yang ada pada tabel `user`. Bila diisi `user_id` yang tidak ada di tabel `user`, MySQL menolaknya. Mekanisme ini mencegah munculnya data tanpa induk, misalnya profil agen yang menunjuk ke user yang tidak ada.

---

## Penjelasan 15 Tabel

### Tabel 1: `user`

```sql
CREATE TABLE IF NOT EXISTS `user` (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  NIK           CHAR(16) NOT NULL UNIQUE,
  username      VARCHAR(50) NOT NULL UNIQUE,
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  phone_number  VARCHAR(20) NOT NULL UNIQUE,
  password      VARCHAR(255) NOT NULL,
  role          ENUM('user','agent','admin') NOT NULL DEFAULT 'user',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at    DATETIME NULL
) ENGINE=InnoDB;
```

Tabel ini menyimpan seluruh pengguna sistem, baik pembeli, agen, maupun admin. Pembedanya adalah kolom `role`.

Nilai `role` memiliki tiga pilihan:
- `user` untuk pengguna biasa yang mencari, memesan, atau membeli properti.
- `agent` untuk agen yang mengelola dan memasarkan properti.
- `admin` untuk pengelola sistem.

Kolom `NIK`, `username`, `email`, dan `phone_number` bersifat `UNIQUE`, sehingga tidak ada dua pengguna dengan nilai yang sama pada kolom-kolom tersebut. Kolom `password` menyimpan kata sandi dalam bentuk acak hasil hash, bukan teks asli, demi keamanan.

### Tabel 2: `agent_profile`

```sql
CREATE TABLE IF NOT EXISTS agent_profile (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  user_id         INT NOT NULL UNIQUE,
  agency_name     VARCHAR(100) NULL,
  license_number  VARCHAR(50) NULL,
  bio             TEXT NULL,
  verified_at     DATETIME NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at      DATETIME NULL,
  CONSTRAINT fk_agentprofile_user FOREIGN KEY (user_id) REFERENCES `user`(id)
) ENGINE=InnoDB;
```

Tidak semua pengguna adalah agen, dan data khusus agen seperti nama agensi, nomor lisensi, dan bio tidak relevan bagi pengguna biasa. Data tersebut dipisah ke tabel sendiri agar tabel `user` tidak penuh kolom kosong.

Kolom `user_id` adalah Foreign Key ke tabel `user` dan bersifat `UNIQUE`, sehingga satu pengguna hanya dapat memiliki satu profil agen. Ini merupakan relasi satu ke satu. Kolom `verified_at` mencatat waktu verifikasi agen. Bila masih `NULL`, agen belum terverifikasi.

### Tabel 3: `location`

```sql
CREATE TABLE IF NOT EXISTS location (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  province    VARCHAR(50) NOT NULL,
  city        VARCHAR(50) NOT NULL,
  district    VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NULL,
  UNIQUE KEY uq_location (province, city, district)
) ENGINE=InnoDB;
```

Tabel ini menyimpan data wilayah berupa provinsi, kota, dan kecamatan. Lokasi disimpan terpisah agar alamat tidak ditulis berulang pada setiap properti. Banyak properti dapat berada pada lokasi yang sama, sehingga lokasi cukup disimpan sekali lalu dirujuk oleh properti.

Baris `UNIQUE KEY uq_location (province, city, district)` membuat kombinasi provinsi, kota, dan kecamatan tidak boleh kembar, sehingga tidak muncul lokasi ganda. Kolom `postal_code` boleh `NULL` karena tidak selalu tersedia.

### Tabel 4: `property_category`

```sql
CREATE TABLE IF NOT EXISTS property_category (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(30) NOT NULL UNIQUE,
  description TEXT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at  DATETIME NULL
) ENGINE=InnoDB;
```

Tabel master untuk kategori properti seperti Rumah, Apartemen, Ruko, Tanah, dan Villa. Kolom `name` bersifat `UNIQUE` agar nama kategori tidak ganda. Kolom `description` menyimpan keterangan kategori dan boleh dikosongkan.

### Tabel 5: `property`

```sql
CREATE TABLE IF NOT EXISTS property (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  owner_id          INT NOT NULL,
  agent_id          INT NULL,
  category_id       INT NOT NULL,
  location_id       INT NOT NULL,
  title             VARCHAR(150) NOT NULL,
  description       TEXT NULL,
  address_detail    VARCHAR(255) NOT NULL,
  land_area         DECIMAL(10,2) NULL,
  building_area     DECIMAL(10,2) NULL,
  bedrooms          TINYINT UNSIGNED NOT NULL DEFAULT 0,
  bathrooms         TINYINT UNSIGNED NOT NULL DEFAULT 0,
  floors            TINYINT UNSIGNED NOT NULL DEFAULT 1,
  year_built        SMALLINT UNSIGNED NULL,
  certificate_type  ENUM('SHM','HGB','SHGB','Girik','Lainnya') NULL,
  facing_direction  ENUM('utara','timur','selatan','barat','timur_laut','tenggara','barat_daya','barat_laut') NULL,
  listing_type      ENUM('sale','rent') NOT NULL,
  price             DECIMAL(15,2) NOT NULL,
  rent_period       ENUM('day','month','year') NULL,
  status            ENUM('available','booked','sold','rented','inactive') NOT NULL DEFAULT 'available',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at        DATETIME NULL,
  CONSTRAINT fk_property_owner    FOREIGN KEY (owner_id)    REFERENCES `user`(id),
  CONSTRAINT fk_property_agent    FOREIGN KEY (agent_id)    REFERENCES `user`(id),
  CONSTRAINT fk_property_category FOREIGN KEY (category_id) REFERENCES property_category(id),
  CONSTRAINT fk_property_location FOREIGN KEY (location_id) REFERENCES location(id),
  INDEX idx_property_status (status),
  INDEX idx_property_listing (listing_type),
  INDEX idx_property_price (price)
) ENGINE=InnoDB;
```

Tabel ini merupakan inti basis data. Setiap baris mewakili satu listing properti.

Tabel ini memiliki empat Foreign Key sekaligus:
- `owner_id` menunjuk ke `user`, yaitu pemilik properti.
- `agent_id` menunjuk ke `user`, yaitu agen yang menangani. Kolom ini boleh `NULL` karena sebuah properti dapat belum dipegang agen.
- `category_id` menunjuk ke `property_category`.
- `location_id` menunjuk ke `location`.

Kolom ukuran dan jumlah:
- `land_area` dan `building_area` memakai `DECIMAL(10,2)` untuk menyimpan luas tanah dan luas bangunan dalam satuan meter persegi dengan dua angka di belakang koma. Keduanya boleh `NULL`, misalnya tanah kosong yang tidak memiliki bangunan.
- `bedrooms`, `bathrooms`, dan `floors` memakai `TINYINT UNSIGNED`, yaitu bilangan bulat kecil tanpa nilai negatif. `UNSIGNED` dipilih karena jumlah kamar atau lantai tidak mungkin negatif. `floors` memiliki `DEFAULT 1` karena bangunan minimal satu lantai.
- `year_built` memakai `SMALLINT UNSIGNED` untuk menyimpan tahun pembuatan bangunan, dan boleh `NULL`.

Kolom `title` menyimpan judul listing, `address_detail` menyimpan alamat lengkap, dan `description` menyimpan deskripsi yang boleh dikosongkan.

Kolom `price` memakai `DECIMAL(15,2)`, yaitu angka dengan total 15 digit dan 2 angka di belakang koma. Tipe ini dipilih, bukan `FLOAT`, karena `FLOAT` dapat menimbulkan kesalahan pembulatan, sedangkan nilai uang harus akurat.

Kolom `certificate_type` menyimpan jenis sertifikat dengan nilai:
- `SHM` untuk Sertifikat Hak Milik.
- `HGB` untuk Hak Guna Bangunan.
- `SHGB` untuk Sertifikat Hak Guna Bangunan.
- `Girik` untuk bukti kepemilikan tanah adat.
- `Lainnya` untuk jenis di luar daftar di atas.

Kolom `facing_direction` menyimpan arah hadap bangunan dengan delapan nilai arah mata angin: `utara`, `timur`, `selatan`, `barat`, `timur_laut`, `tenggara`, `barat_daya`, dan `barat_laut`.

Kolom `listing_type` menentukan jenis penawaran:
- `sale` berarti properti dijual.
- `rent` berarti properti disewakan.

Kolom `rent_period` hanya relevan untuk properti sewa, dengan nilai:
- `day` untuk sewa harian.
- `month` untuk sewa bulanan.
- `year` untuk sewa tahunan.

Untuk properti yang dijual, kolom ini dibiarkan `NULL`. Kewajiban properti sewa untuk mengisi `rent_period` ditegakkan oleh trigger pada file `003`.

Kolom `status` menggambarkan kondisi properti saat ini dengan lima nilai:
- `available` berarti properti tersedia dan dapat dipesan.
- `booked` berarti properti sedang dalam proses pemesanan.
- `sold` berarti properti sudah terjual.
- `rented` berarti properti sedang disewa.
- `inactive` berarti properti dinonaktifkan, misalnya ditarik sementara oleh pemilik.

Kolom `updated_at` memakai `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`. Bagian `ON UPDATE CURRENT_TIMESTAMP` membuat kolom ini otomatis diperbarui ke waktu terkini setiap kali baris diubah, sehingga selalu mencerminkan kapan data terakhir disunting.

Tiga baris `INDEX` di bagian bawah, yaitu `idx_property_status`, `idx_property_listing`, dan `idx_property_price`, berfungsi mempercepat pencarian berdasarkan status, jenis listing, dan harga. Index bekerja seperti daftar isi yang membuat MySQL tidak perlu memeriksa seluruh baris satu per satu. Pembahasan index lebih lengkap terdapat pada file `006`.

### Tabel 6: `property_image`

```sql
CREATE TABLE IF NOT EXISTS property_image (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  property_id INT NOT NULL,
  image_url   VARCHAR(255) NOT NULL,
  is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order  INT NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at  DATETIME NULL,
  CONSTRAINT fk_image_property FOREIGN KEY (property_id) REFERENCES property(id) ON DELETE CASCADE
) ENGINE=InnoDB;
```

Tabel ini menyimpan foto-foto properti. Satu properti dapat memiliki banyak foto, sehingga ini merupakan relasi satu ke banyak.

Pada baris Foreign Key terdapat `ON DELETE CASCADE`. Artinya bila sebuah properti dihapus, seluruh fotonya ikut terhapus otomatis, karena foto tanpa properti tidak memiliki kegunaan. Kolom `is_primary` memakai tipe `BOOLEAN` (bernilai benar atau salah) untuk menandai foto utama, dengan `DEFAULT FALSE`. Kolom `sort_order` mengatur urutan tampil foto, dengan `DEFAULT 0`.

### Tabel 7: `facility`

```sql
CREATE TABLE IF NOT EXISTS facility (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(50) NOT NULL UNIQUE,
  is_countable BOOLEAN NOT NULL DEFAULT TRUE,
  icon         VARCHAR(100) NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at   DATETIME NULL
) ENGINE=InnoDB;
```

Tabel master daftar fasilitas seperti AC, Kolam Renang, atau CCTV. Kolom `is_countable` menandai apakah fasilitas dapat dihitung jumlahnya. AC dapat berjumlah beberapa unit sehingga bernilai benar, sedangkan kolam renang bersifat ada atau tidak sehingga bernilai salah. Kolom `icon` menyimpan nama ikon untuk tampilan dan boleh dikosongkan.

### Tabel 8: `property_facility`

```sql
CREATE TABLE IF NOT EXISTS property_facility (
  property_id INT NOT NULL,
  facility_id INT NOT NULL,
  quantity    SMALLINT NOT NULL DEFAULT 1,
  notes       VARCHAR(100) NULL,
  PRIMARY KEY (property_id, facility_id),
  CONSTRAINT fk_pf_property FOREIGN KEY (property_id) REFERENCES property(id) ON DELETE CASCADE,
  CONSTRAINT fk_pf_facility FOREIGN KEY (facility_id) REFERENCES facility(id)
) ENGINE=InnoDB;
```

Tabel ini menghubungkan properti dengan fasilitas. Satu properti dapat memiliki banyak fasilitas, dan satu fasilitas dapat dimiliki banyak properti. Hubungan seperti ini disebut banyak ke banyak dan diselesaikan dengan tabel penghubung seperti ini.

Baris `PRIMARY KEY (property_id, facility_id)` menerapkan Composite Primary Key, yaitu kunci utama yang terdiri dari gabungan dua kolom. Akibatnya kombinasi properti dan fasilitas tidak boleh kembar, sehingga satu properti tidak dapat memiliki fasilitas yang sama tercatat dua kali. Kolom `quantity` menyimpan jumlah fasilitas tersebut, dengan `DEFAULT 1`. Kolom `notes` menyimpan catatan tambahan dan boleh dikosongkan.

### Tabel 9: `wishlist`

```sql
CREATE TABLE IF NOT EXISTS wishlist (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  property_id INT NOT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at  DATETIME NULL,
  UNIQUE KEY uq_wishlist (user_id, property_id),
  CONSTRAINT fk_wishlist_user     FOREIGN KEY (user_id)     REFERENCES `user`(id),
  CONSTRAINT fk_wishlist_property FOREIGN KEY (property_id) REFERENCES property(id)
) ENGINE=InnoDB;
```

Tabel ini menyimpan daftar properti favorit milik pengguna, dan merupakan relasi banyak ke banyak antara pengguna dan properti. Baris `UNIQUE KEY uq_wishlist (user_id, property_id)` memastikan satu pengguna tidak dapat menambahkan properti yang sama ke wishlist lebih dari sekali.

### Tabel 10: `booking`

```sql
CREATE TABLE IF NOT EXISTS booking (
  id                   INT AUTO_INCREMENT PRIMARY KEY,
  property_id          INT NOT NULL,
  customer_id          INT NOT NULL,
  requested_start_date DATE NULL,
  requested_end_date   DATE NULL,
  status               ENUM('pending','confirmed','cancelled','expired') NOT NULL DEFAULT 'pending',
  notes                TEXT NULL,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at           DATETIME NULL,
  CONSTRAINT fk_booking_property FOREIGN KEY (property_id) REFERENCES property(id),
  CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id) REFERENCES `user`(id),
  INDEX idx_booking_status (status)
) ENGINE=InnoDB;
```

Tabel ini menyimpan pemesanan, yaitu tahap sebelum transaksi resmi terbentuk. Kolom `property_id` menunjuk properti yang dipesan dan `customer_id` menunjuk pengguna yang memesan.

Nilai `status` pada booking:
- `pending` berarti pemesanan baru masuk dan menunggu konfirmasi.
- `confirmed` berarti pemesanan sudah dikonfirmasi dan siap dilanjutkan ke transaksi.
- `cancelled` berarti pemesanan dibatalkan.
- `expired` berarti pemesanan kedaluwarsa karena tidak ditindaklanjuti.

Kolom `requested_start_date` dan `requested_end_date` memakai tipe `DATE`, yaitu tanggal tanpa jam, untuk menyimpan rentang tanggal yang diminta, terutama pada properti sewa. Index `idx_booking_status` mempercepat penyaringan berdasarkan status.

### Tabel 11: `transaction`

```sql
CREATE TABLE IF NOT EXISTS `transaction` (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  booking_id       INT NOT NULL UNIQUE,
  property_id      INT NOT NULL,
  customer_id      INT NOT NULL,
  agent_id         INT NULL,
  transaction_type ENUM('sale','rent') NOT NULL,
  agreed_amount    DECIMAL(15,2) NOT NULL,
  status           ENUM('pending','success','failed','cancelled') NOT NULL DEFAULT 'pending',
  notes            TEXT NULL,
  completed_at     DATETIME NULL,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at       DATETIME NULL,
  CONSTRAINT fk_trx_booking  FOREIGN KEY (booking_id)  REFERENCES booking(id),
  CONSTRAINT fk_trx_property FOREIGN KEY (property_id) REFERENCES property(id),
  CONSTRAINT fk_trx_customer FOREIGN KEY (customer_id) REFERENCES `user`(id),
  CONSTRAINT fk_trx_agent    FOREIGN KEY (agent_id)    REFERENCES `user`(id),
  INDEX idx_trx_status (status),
  INDEX idx_trx_type (transaction_type)
) ENGINE=InnoDB;
```

Tabel ini menyimpan transaksi resmi yang terbentuk dari sebuah booking. Kolom `booking_id` adalah Foreign Key ke `booking` dan bersifat `UNIQUE`, sehingga satu booking hanya dapat menghasilkan satu transaksi. Kolom `agreed_amount` menyimpan nilai kesepakatan akhir transaksi. Kolom `completed_at` mencatat waktu transaksi diselesaikan dan boleh `NULL` selama transaksi belum selesai.

Nilai `transaction_type`:
- `sale` untuk transaksi jual.
- `rent` untuk transaksi sewa.

Nilai `status`:
- `pending` berarti transaksi sedang diproses.
- `success` berarti transaksi berhasil dan dianggap lunas.
- `failed` berarti transaksi gagal.
- `cancelled` berarti transaksi dibatalkan.

Ketika status berubah menjadi `success`, status properti terkait akan diperbarui otomatis melalui trigger pada file `003`.

### Tabel 12: `sale_transaction`

```sql
CREATE TABLE IF NOT EXISTS sale_transaction (
  transaction_id     INT PRIMARY KEY,
  transfer_date      DATE NULL,
  certificate_number VARCHAR(50) NULL,
  CONSTRAINT fk_sale_trx FOREIGN KEY (transaction_id) REFERENCES `transaction`(id) ON DELETE CASCADE
) ENGINE=InnoDB;
```

### Tabel 13: `rent_transaction`

```sql
CREATE TABLE IF NOT EXISTS rent_transaction (
  transaction_id   INT PRIMARY KEY,
  start_date       DATE NOT NULL,
  end_date         DATE NOT NULL,
  price_per_period DECIMAL(15,2) NOT NULL,
  additional_fee   DECIMAL(15,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_rent_trx FOREIGN KEY (transaction_id) REFERENCES `transaction`(id) ON DELETE CASCADE,
  CONSTRAINT chk_rent_dates CHECK (end_date > start_date)
) ENGINE=InnoDB;
```

Kedua tabel ini menerapkan pola Subtype. Transaksi jual dan transaksi sewa membutuhkan detail yang berbeda. Transaksi jual membutuhkan tanggal serah terima sertifikat dan nomor sertifikat. Transaksi sewa membutuhkan tanggal mulai, tanggal akhir, harga per periode, dan biaya tambahan.

Bila seluruh detail tersebut digabung dalam satu tabel `transaction`, akan banyak kolom kosong karena transaksi jual tidak memiliki tanggal sewa dan transaksi sewa tidak memiliki nomor sertifikat. Untuk menghindarinya, detail dipecah ke dua tabel anak. Setiap transaksi memiliki tepat satu baris pada salah satu tabel anak sesuai jenisnya.

Pada kedua tabel, `transaction_id` berperan sebagai PRIMARY KEY sekaligus Foreign Key ke tabel `transaction`. Peran ganda ini menjamin hubungan satu ke satu dengan transaksi induk, sekaligus memastikan setiap baris detail terhubung ke transaksi yang benar-benar ada.

Pada `rent_transaction` terdapat `CHECK (end_date > start_date)`. CHECK adalah aturan validasi yang membatasi nilai yang boleh masuk. Baris ini memastikan tanggal akhir sewa selalu setelah tanggal mulai, sehingga rentang tanggal yang tidak masuk akal ditolak. Kolom `additional_fee` menyimpan biaya tambahan atau denda, dengan `DEFAULT 0`.

### Tabel 14: `review`

```sql
CREATE TABLE IF NOT EXISTS review (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id INT NOT NULL UNIQUE,
  property_id    INT NOT NULL,
  reviewer_id    INT NOT NULL,
  rating         TINYINT NOT NULL,
  comment        TEXT NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at     DATETIME NULL,
  CONSTRAINT fk_review_trx      FOREIGN KEY (transaction_id) REFERENCES `transaction`(id),
  CONSTRAINT fk_review_property FOREIGN KEY (property_id)    REFERENCES property(id),
  CONSTRAINT fk_review_user     FOREIGN KEY (reviewer_id)    REFERENCES `user`(id),
  CONSTRAINT chk_review_rating  CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;
```

Tabel ini menyimpan ulasan yang diberikan setelah transaksi. Kolom `transaction_id` bersifat `UNIQUE`, sehingga satu transaksi hanya dapat menghasilkan satu ulasan. Karena ulasan terikat pada transaksi, hanya pihak yang benar-benar bertransaksi yang dapat memberi ulasan.

Kolom `rating` memakai `TINYINT`, yaitu bilangan bulat kecil, dan dibatasi oleh `CHECK (rating BETWEEN 1 AND 5)` agar nilainya selalu berada di rentang 1 sampai 5. Kolom `comment` menyimpan isi ulasan dan boleh dikosongkan.

### Tabel 15: `price_history`

```sql
CREATE TABLE IF NOT EXISTS price_history (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  property_id INT NOT NULL,
  old_price   DECIMAL(15,2) NULL,
  new_price   DECIMAL(15,2) NOT NULL,
  changed_by  INT NULL,
  changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pricehistory_property FOREIGN KEY (property_id) REFERENCES property(id),
  CONSTRAINT fk_pricehistory_user     FOREIGN KEY (changed_by)  REFERENCES `user`(id)
) ENGINE=InnoDB;
```

Tabel ini menyimpan riwayat perubahan harga properti sebagai jejak audit. Tabel ini satu-satunya yang tidak memiliki kolom `deleted_at`, karena catatan audit bersifat permanen dan tidak boleh dihapus agar riwayat harga selalu utuh.

Setiap kali harga sebuah properti berubah, satu baris baru otomatis masuk ke tabel ini melalui trigger pada file `003`. Kolom `old_price` menyimpan harga sebelum perubahan dan boleh `NULL` untuk pencatatan harga pertama. Kolom `new_price` menyimpan harga sesudah perubahan. Kolom `changed_by` menyimpan pengguna yang melakukan perubahan dan boleh `NULL` bila perubahan dilakukan oleh sistem. Kolom `changed_at` menyimpan waktu perubahan.

---

## Relasi antar tabel

Peta berikut menggambarkan hubungan antar tabel.

```
user  ───<  property  >───  location
                │
                ├───< property_image
                ├───< property_facility >─── facility
                └───< price_history

user  ───<  booking  ────  transaction  ─┬─── sale_transaction
                                          └─── rent_transaction

transaction  ───<  review
```

Tanda `>───` dan `───<` menunjukkan sisi banyak dari sebuah relasi. Sebagai contoh, satu `user` dapat memiliki banyak `property`, dan satu `property` dapat memiliki banyak baris foto pada `property_image`.
