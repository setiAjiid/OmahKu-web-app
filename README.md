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

---

## Dokumentasi Database Bagian 2: Data Awal (`db/002_seed.sql`)

File `002_seed.sql` mengisi tabel-tabel kosong yang dibuat oleh `001_schema.sql` dengan data. Data ini terbagi menjadi dua jenis. Pertama, data master berupa kategori, fasilitas, dan lokasi yang menjadi acuan tetap. Kedua, data contoh berupa pengguna, properti, transaksi, dan ulasan yang dipakai untuk menguji query dan menampilkan isi pada aplikasi.

### Perintah `INSERT IGNORE`

Seluruh pengisian data memakai bentuk berikut:

```sql
INSERT IGNORE INTO nama_tabel (kolom1, kolom2, ...) VALUES
(nilai1, nilai2, ...),
(nilai1, nilai2, ...);
```

`INSERT INTO` memasukkan baris baru ke sebuah tabel. Daftar kolom ditulis di dalam tanda kurung setelah nama tabel, lalu nilai untuk setiap baris ditulis setelah `VALUES`. Beberapa baris dapat dimasukkan sekaligus dengan memisahkannya menggunakan koma.

Tambahan kata `IGNORE` membuat MySQL melewati baris yang akan menimbulkan error duplikasi, alih-alih menghentikan seluruh perintah. Sebagai contoh, jika kategori `Rumah` sudah ada, baris tersebut dilewati tanpa error. Dengan begitu file ini aman dijalankan ulang.

Urutan pengisian mengikuti ketergantungan antar tabel. Tabel acuan seperti `property_category`, `facility`, dan `location` diisi lebih dulu, kemudian `user`, lalu `property`, dan seterusnya. Urutan ini penting karena tabel `property` memuat Foreign Key yang harus menunjuk ke baris yang sudah ada pada tabel acuan dan tabel `user`.

### Data master

Tabel kategori properti diisi dengan lima kategori.

```sql
INSERT IGNORE INTO property_category(name, description) VALUES
('Rumah','Rumah tinggal'),
('Apartemen','Unit apartemen'),
('Ruko','Rumah toko'),
('Tanah','Kavling/lahan kosong'),
('Villa','Villa/rumah peristirahatan');
```

Setiap baris berisi nama kategori dan deskripsinya. Karena kolom `id` pada tabel ini bersifat `AUTO_INCREMENT`, nomornya terisi otomatis sehingga tidak ditulis di sini. Kategori pertama mendapat `id` 1, kategori kedua `id` 2, dan seterusnya. Nomor ini nantinya dipakai oleh tabel `property` melalui kolom `category_id`.

Tabel fasilitas diisi dengan sebelas fasilitas.

```sql
INSERT IGNORE INTO facility(name, is_countable, icon) VALUES
('Garasi', TRUE, 'car'),
('Carport', TRUE, 'car-front'),
('AC', TRUE, 'air-vent'),
('Water Heater', TRUE, 'flame'),
('Kolam Renang', FALSE, 'waves'),
('Gym', FALSE, 'dumbbell'),
('Balkon', TRUE, 'panels-top-left'),
('Taman', TRUE, 'trees'),
('CCTV', FALSE, 'cctv'),
('Security 24 Jam', FALSE, 'shield-check'),
('Smart Lock', FALSE, 'lock');
```

Kolom `is_countable` diisi `TRUE` untuk fasilitas yang dapat dihitung jumlahnya seperti Garasi dan AC, serta `FALSE` untuk fasilitas yang sifatnya ada atau tidak seperti Kolam Renang dan CCTV. Kolom `icon` menyimpan nama ikon untuk tampilan aplikasi.

Tabel lokasi diisi dengan delapan wilayah.

```sql
INSERT IGNORE INTO location(province, city, district, postal_code) VALUES
('DKI Jakarta','Jakarta Selatan','Kebayoran Baru','12110'),
('DKI Jakarta','Jakarta Pusat','Menteng','10310'),
('Jawa Barat','Bandung','Coblong','40132'),
('Jawa Barat','Bekasi','Bekasi Selatan','17141'),
('Jawa Tengah','Semarang','Semarang Tengah','50132'),
('DI Yogyakarta','Sleman','Depok','55281'),
('Jawa Timur','Surabaya','Gubeng','60281'),
('Bali','Badung','Kuta','80361');
```

Setiap baris berisi provinsi, kota, kecamatan, dan kode pos. Kombinasi provinsi, kota, dan kecamatan tidak boleh kembar karena dibatasi oleh constraint `UNIQUE` pada tabel `location`.

### Data contoh: pengguna

```sql
INSERT IGNORE INTO `user` (NIK, username, full_name, email, phone_number, password, role) VALUES
('3171000000000001', 'admin_omahku', 'Admin OmahKu', 'admin@omahku.id', '081200000001', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh3u', 'admin'),
('3171000000000002', 'budi_agent',   'Budi Santoso', 'budi@omahku.id',  '081200000002', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh3u', 'agent'),
('3171000000000003', 'sari_agent',   'Sari Dewi',    'sari@omahku.id',  '081200000003', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh3u', 'agent'),
('3171000000000004', 'andi_user',    'Andi Pratama', 'andi@omahku.id',  '081200000004', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh3u', 'user'),
('3171000000000005', 'rini_user',    'Rini Kusuma',  'rini@omahku.id',  '081200000005', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lh3u', 'user');
```

Lima pengguna dibuat dengan peran berbeda. Pengguna pertama adalah admin, pengguna kedua dan ketiga adalah agen (Budi dan Sari), serta pengguna keempat dan kelima adalah pengguna biasa (Andi dan Rini). Sesuai urutan pemasukan, Budi mendapat `id` 2, Sari `id` 3, Andi `id` 4, dan Rini `id` 5. Nomor-nomor ini dipakai pada tabel berikutnya untuk menentukan pemilik, agen, dan pelanggan.

Kolom `password` berisi teks acak hasil hash, bukan kata sandi asli. Seluruh pengguna contoh memakai nilai hash yang sama untuk menyederhanakan data uji.

### Data contoh: profil agen

```sql
INSERT IGNORE INTO agent_profile (user_id, agency_name, license_number, bio, verified_at) VALUES
(2, 'Budi Property', 'LIC-JKT-001', 'Agen properti berpengalaman 5 tahun di Jakarta.', '2023-01-15 10:00:00'),
(3, 'Sari Realty',   'LIC-BDG-002', 'Spesialis properti residensial Bandung & Bali.',  '2023-03-10 10:00:00');
```

Hanya pengguna dengan peran agen yang memiliki profil. Kolom `user_id` bernilai 2 dan 3 yang menunjuk ke Budi dan Sari pada tabel `user`. Kolom `verified_at` diisi tanggal sehingga kedua agen dianggap sudah terverifikasi.

### Data contoh: properti

```sql
INSERT IGNORE INTO property
  (owner_id, agent_id, category_id, location_id, title, address_detail,
   land_area, building_area, bedrooms, bathrooms, floors, year_built,
   certificate_type, listing_type, price, rent_period, status) VALUES
(4, 2, 1, 1, 'Rumah Mewah Kebayoran Baru',    'Jl. Melati No. 12, Kebayoran Baru',    200.00, 350.00, 4, 3, 2, 2018, 'SHM', 'sale', 2500000000.00, NULL,    'sold'),
(4, 2, 2, 2, 'Apartemen Modern Menteng',       'Jl. Diponegoro No. 5, Menteng',         NULL,    72.00, 2, 1, 1, 2020, 'SHM', 'rent',   15000000.00, 'month', 'rented'),
(5, 3, 5, 8, 'Villa Tepi Pantai Kuta',         'Jl. Pantai Kuta No. 88, Badung',       500.00, 250.00, 4, 4, 1, 2019, 'SHM', 'rent',    5000000.00, 'day',   'available'),
(5, 3, 3, 3, 'Ruko Strategis Coblong Bandung', 'Jl. Setiabudi No. 21, Coblong',        100.00, 200.00, 0, 2, 3, 2015, 'HGB', 'sale', 1800000000.00, NULL,    'available'),
(4, 2, 4, 7, 'Tanah Kavling Gubeng Surabaya',  'Jl. Raya Gubeng No. 45, Gubeng',       300.00,   NULL, 0, 0, 0, NULL,  NULL,  'sale',  800000000.00, NULL,    'available');
```

Lima properti dibuat. Empat kolom pertama pada setiap baris adalah Foreign Key. Sebagai contoh pada baris pertama, `owner_id` bernilai 4 menunjuk Andi sebagai pemilik, `agent_id` bernilai 2 menunjuk Budi sebagai agen, `category_id` bernilai 1 menunjuk kategori Rumah, dan `location_id` bernilai 1 menunjuk Kebayoran Baru.

Kolom `listing_type` dan `rent_period` perlu diperhatikan. Properti yang dijual diisi `'sale'` dengan `rent_period` bernilai `NULL`. Properti yang disewa diisi `'rent'` dan wajib mengisi `rent_period`, misalnya `'month'` untuk Apartemen Menteng dan `'day'` untuk Villa Kuta. Kewajiban ini ditegakkan oleh trigger pada file `003`, sehingga properti sewa tanpa `rent_period` akan ditolak.

Kolom `land_area` dan `building_area` boleh `NULL`. Apartemen tidak memiliki luas tanah sehingga `land_area` bernilai `NULL`, dan tanah kavling tidak memiliki bangunan sehingga `building_area` bernilai `NULL`. Kolom `status` diisi beragam, yaitu `sold`, `rented`, dan `available`, untuk menggambarkan berbagai kondisi properti.

### Data contoh: foto, fasilitas, dan wishlist

```sql
INSERT IGNORE INTO property_image (property_id, image_url, is_primary, sort_order) VALUES
(1, 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80', TRUE,  1),
(1, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80', FALSE, 2),
(2, 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80', TRUE,  1),
(3, 'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=800&q=80', TRUE,  1),
(3, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=800&q=80', FALSE, 2),
(4, 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80', TRUE,  1),
(5, 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80', TRUE,  1);
```

Foto dihubungkan ke properti melalui `property_id`. Beberapa properti memiliki lebih dari satu foto. Foto dengan `is_primary` bernilai `TRUE` menjadi foto utama, dan `sort_order` mengatur urutan tampil.

```sql
INSERT IGNORE INTO property_facility (property_id, facility_id, quantity) VALUES
(1, 1, 2), (1, 3, 5), (1, 9, 1),
(2, 3, 2), (2, 7, 1),
(3, 5, 1), (3, 6, 1), (3, 8, 2),
(4, 2, 2), (4, 3, 4),
(5, 8, 1);
```

Tabel ini menghubungkan properti dengan fasilitasnya. Setiap baris berisi `property_id`, `facility_id`, dan `quantity`. Sebagai contoh, baris `(1, 1, 2)` berarti properti 1 memiliki fasilitas 1 (Garasi) sebanyak 2 unit, dan `(1, 3, 5)` berarti properti 1 memiliki fasilitas 3 (AC) sebanyak 5 unit.

```sql
INSERT IGNORE INTO wishlist (user_id, property_id) VALUES
(5, 1),
(4, 3),
(4, 4);
```

Tabel wishlist mencatat properti favorit pengguna. Baris `(5, 1)` berarti Rini menyukai properti 1, sedangkan Andi menyukai properti 3 dan 4.

### Data contoh: pemesanan

```sql
INSERT IGNORE INTO booking (property_id, customer_id, requested_start_date, requested_end_date, status, notes) VALUES
(1, 5, '2024-02-01', NULL,         'confirmed', 'Berminat beli cash.'),
(2, 5, '2024-01-01', '2024-07-01', 'confirmed', 'Sewa 6 bulan.'),
(3, 4, '2024-02-10', '2024-02-17', 'confirmed', 'Liburan 1 minggu.');
```

Tiga pemesanan dibuat, semuanya berstatus `confirmed` agar dapat dilanjutkan menjadi transaksi. Kolom `customer_id` menunjuk pengguna yang memesan, dan `property_id` menunjuk properti yang dipesan. Pemesanan untuk properti jual mengisi `requested_start_date` saja, sedangkan pemesanan sewa mengisi rentang tanggal mulai dan akhir.

### Data contoh: transaksi dan detailnya

```sql
INSERT IGNORE INTO `transaction`
  (booking_id, property_id, customer_id, agent_id, transaction_type, agreed_amount, status, completed_at) VALUES
(1, 1, 5, 2, 'sale', 2500000000.00, 'success', '2024-03-01 14:00:00'),
(2, 2, 5, 2, 'rent',     90500000.00, 'success', '2024-01-05 10:00:00'),
(3, 3, 4, 3, 'rent',     35000000.00, 'success', '2024-02-12 09:00:00');
```

Tiga transaksi dibuat dari tiga pemesanan, semuanya berstatus `success`. Kolom `booking_id` menunjuk pemesanan asal, dan bersifat unik sehingga satu pemesanan hanya menghasilkan satu transaksi. Kolom `agreed_amount` menyimpan nilai kesepakatan.

Nilai pada transaksi sewa dibuat konsisten dengan perhitungan biaya sewa. Transaksi kedua adalah sewa apartemen selama enam bulan seharga 15.000.000 per bulan ditambah biaya tambahan 500.000, sehingga totalnya 90.500.000. Transaksi ketiga adalah sewa villa selama tujuh hari seharga 5.000.000 per hari, sehingga totalnya 35.000.000.

```sql
INSERT IGNORE INTO sale_transaction (transaction_id, transfer_date, certificate_number) VALUES
(1, '2024-03-01', 'SHM-JKT-2024-001');

INSERT IGNORE INTO rent_transaction (transaction_id, start_date, end_date, price_per_period, additional_fee) VALUES
(2, '2024-01-01', '2024-07-01', 15000000.00, 500000.00),
(3, '2024-02-10', '2024-02-17',  5000000.00,       0.00);
```

Detail transaksi dipisah sesuai jenisnya. Transaksi 1 adalah transaksi jual, sehingga detailnya masuk ke `sale_transaction` berupa tanggal serah terima dan nomor sertifikat. Transaksi 2 dan 3 adalah transaksi sewa, sehingga detailnya masuk ke `rent_transaction` berupa rentang tanggal, harga per periode, dan biaya tambahan.

### Data contoh: ulasan dan riwayat harga

```sql
INSERT IGNORE INTO review (transaction_id, property_id, reviewer_id, rating, comment) VALUES
(1, 1, 5, 5, 'Rumah sangat bagus, lokasi strategis! Proses jual beli lancar.'),
(2, 2, 5, 4, 'Apartemen bersih dan nyaman, harga sesuai.'),
(3, 3, 4, 5, 'Villa luar biasa, view pantai keren banget!');
```

Setiap transaksi memiliki satu ulasan. Kolom `reviewer_id` menunjuk pengguna yang memberi ulasan, dan `rating` berisi nilai 1 sampai 5 sesuai batasan constraint pada tabel `review`.

```sql
INSERT IGNORE INTO price_history (property_id, old_price, new_price, changed_by, changed_at) VALUES
(1, 2800000000.00, 2500000000.00, 2, '2024-01-10 08:00:00'),
(4, 2000000000.00, 1800000000.00, 3, '2024-03-05 09:30:00');
```

Riwayat harga diisi langsung sebagai data awal untuk menggambarkan properti yang pernah berubah harga. Baris pertama menunjukkan properti 1 turun harga dari 2.800.000.000 menjadi 2.500.000.000 oleh pengguna 2. Pada operasi normal, baris seperti ini dibuat otomatis oleh trigger pada file `003` setiap kali harga properti diubah.
