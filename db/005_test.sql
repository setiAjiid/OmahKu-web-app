-- OmahKu — Skrip UJI objek database (requirement 1.2.c-g)
-- Membuktikan trigger, function, SP, dan query benar-benar jalan.

USE omahku;

-- 5.-1 — BERSIHKAN data uji lama (NIK 1111.../2222...)
-- ngebikin skrip 5.-1 ini biar AMAN di-run berulang tanpa numpuk duplikat.
-- HANYA menghapus data uji (kalo sebelumnya dah jalanin test sql 5.0 - selesai); seed (NIK 3171...) & data lain TIDAK tersentuh.
-- Urut dependency (anak dulu, induk belakangan) biar FK tetep aman.

SET @t1 := '1111111111111111';   -- NIK owner uji
SET @t2 := '2222222222222222';   -- NIK customer uji

DELETE FROM review
 WHERE reviewer_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2))
    OR property_id  IN (SELECT id FROM property
                         WHERE owner_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2)));

DELETE FROM price_history
 WHERE changed_by  IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2))
    OR property_id IN (SELECT id FROM property
                        WHERE owner_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2)));

DELETE FROM `transaction`
 WHERE customer_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2))
    OR agent_id    IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2))
    OR property_id IN (SELECT id FROM property
                        WHERE owner_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2)));

DELETE FROM booking
 WHERE customer_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2))
    OR property_id IN (SELECT id FROM property
                        WHERE owner_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2)));

DELETE FROM wishlist
 WHERE user_id     IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2))
    OR property_id IN (SELECT id FROM property
                        WHERE owner_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2)));

DELETE FROM property
 WHERE owner_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2));

DELETE FROM agent_profile
 WHERE user_id IN (SELECT id FROM `user` WHERE NIK IN (@t1,@t2));

DELETE FROM `user`
 WHERE NIK IN (@t1,@t2);




-- 5.0 — Siapkan data uji (idempotent via INSERT IGNORE + lookup id)
INSERT IGNORE INTO `user`(NIK, username, full_name, email, phone_number, password, role) VALUES
('1111111111111111','owner_test','Owner Test','owner_test@test.com','08110000001','dummy','agent'),
('2222222222222222','cust_test', 'Customer Test','cust_test@test.com','08220000002','dummy','user');

SET @owner := (SELECT id FROM `user` WHERE username='owner_test');
SET @cust  := (SELECT id FROM `user` WHERE username='cust_test');

-- Properti JUAL (category_id=1, location_id=1 berasal dari seed)
INSERT INTO property(owner_id, agent_id, category_id, location_id, title, address_detail,
                     listing_type, price, status)
VALUES (@owner, @owner, 1, 1, 'Rumah Uji Jual', 'Jl. Uji No.1', 'sale', 1000000000, 'available');
SET @prop_sale := LAST_INSERT_ID();

-- Properti SEWA (rent_period WAJIB, kalau tidak trigger menolak)
INSERT INTO property(owner_id, agent_id, category_id, location_id, title, address_detail,
                     listing_type, price, rent_period, status)
VALUES (@owner, @owner, 1, 1, 'Kontrakan Uji', 'Jl. Uji No.2', 'rent', 2000000, 'month', 'available');
SET @prop_rent := LAST_INSERT_ID();

SELECT @owner AS owner_id, @cust AS cust_id, @prop_sale AS prop_sale, @prop_rent AS prop_rent;


-- 5.1 — Trigger validasi rent_period (aturan bisnis #5) — HARUS GAGAL
-- Diharapkan ERROR 1644: "rent_period wajib untuk listing_type=rent".
INSERT INTO property(owner_id, category_id, location_id, title, address_detail, listing_type, price)
VALUES (@owner, 1, 1, 'Properti Salah', 'Jl. Salah', 'rent', 1000000);


-- 5.2 — Trigger audit harga trg_property_price_audit (1.2.g)
SET @app_user_id := @owner;        -- siapa yang mengubah (dibaca oleh trigger)
UPDATE property SET price = 1200000000 WHERE id = @prop_sale;

-- Harusnya muncul 1 baris: old_price=1.000.000.000, new_price=1.200.000.000, changed_by=@owner
SELECT * FROM price_history WHERE property_id = @prop_sale;


-- 5.3 — Stored Procedure sp_create_transaction (1.2.d) + trigger status (1.2.f)
-- Booking HARUS 'confirmed' agar SP mau memproses.
INSERT INTO booking(property_id, customer_id, status) VALUES (@prop_sale, @cust, 'confirmed');
SET @bk_sale := LAST_INSERT_ID();

-- Param: booking, agreed, transfer_date, cert, start, end, price_per_period, fee, OUT id
-- (param sewa diisi NULL untuk transaksi JUAL)
CALL sp_create_transaction(@bk_sale, 1200000000, '2026-06-01', 'SHM-001',
                           NULL, NULL, NULL, NULL, @trx_sale);

SELECT @trx_sale AS id_transaksi_baru;
SELECT id, status FROM `transaction` WHERE id = @trx_sale;          -- status 'pending'
SELECT * FROM sale_transaction WHERE transaction_id = @trx_sale;

-- Ubah ke 'success' => trigger trg_transaction_success mengubah properti jadi 'sold'
UPDATE `transaction` SET status='success', completed_at=NOW() WHERE id = @trx_sale;
-- status properti harus berubah otomatis jadi 'sold' (BUKTI trigger 1.2.f jalan)
SELECT id, title, status FROM property WHERE id = @prop_sale;


-- 5.3b — SP menolak booking yang belum confirmed (uji ROLLBACK)
INSERT INTO booking(property_id, customer_id, status) VALUES (@prop_rent, @cust, 'pending');
SET @bk_bad := LAST_INSERT_ID();

-- Diharapkan ERROR: "Booking harus berstatus confirmed" (seluruh transaksi di-ROLLBACK)
CALL sp_create_transaction(@bk_bad, 1, NULL, NULL, NULL, NULL, NULL, NULL, @buang);


-- 5.4 — Function fn_hitung_biaya_sewa (1.2.e)
INSERT INTO booking(property_id, customer_id, status) VALUES (@prop_rent, @cust, 'confirmed');
SET @bk_rent := LAST_INSERT_ID();

-- Sewa 6 bulan, 2.000.000/bulan, fee 500.000
CALL sp_create_transaction(@bk_rent, 12500000, NULL, NULL,
                           '2026-07-01', '2027-01-01', 2000000, 500000, @trx_rent);

-- Hasil harus = 12.500.000 (6 x 2.000.000 + 500.000), sama dengan agreed_amount
SELECT fn_hitung_biaya_sewa(@trx_rent) AS total_biaya_sewa;


-- 5.5 — Advanced query (1.2.c)
-- Tambah 1 ulasan supaya Q2 (properti rating tertinggi) ada isinya.
INSERT INTO review(transaction_id, property_id, reviewer_id, rating, comment)
VALUES (@trx_sale, @prop_sale, @cust, 5, 'Transaksi lancar');

-- Lalu tinggal jalanin keempat query di 004_queries.sql. Yang diharapin:
--   Q1  => 'Owner Test' muncul dengan total_transaction & total_revenue
--   Q1b => pendapatan 'Owner Test' terkelompok per bulan
--   Q2  => 'Rumah Uji Jual' dengan avg_rating = 5
--   Q3  => jumlah properti aktif per kategori
--   Q4  => properti di atas harga rata-rata
