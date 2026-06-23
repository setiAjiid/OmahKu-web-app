-- OmahKu — Seed master data (idempotent via INSERT IGNORE)

-- Kategori properti
INSERT IGNORE INTO property_category(name, description) VALUES
('Rumah','Rumah tinggal'),
('Apartemen','Unit apartemen'),
('Ruko','Rumah toko'),
('Tanah','Kavling/lahan kosong'),
('Villa','Villa/rumah peristirahatan');

-- Fasilitas
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

-- Lokasi contoh
INSERT IGNORE INTO location(province, city, district, postal_code) VALUES
('DKI Jakarta','Jakarta Selatan','Kebayoran Baru','12110'),
('DKI Jakarta','Jakarta Pusat','Menteng','10310'),
('Jawa Barat','Bandung','Coblong','40132'),
('Jawa Barat','Bekasi','Bekasi Selatan','17141'),
('Jawa Tengah','Semarang','Semarang Tengah','50132'),
('DI Yogyakarta','Sleman','Depok','55281'),
('Jawa Timur','Surabaya','Gubeng','60281'),
('Bali','Badung','Kuta','80361');

-- Semua password = 'password123' (bcrypt cost 10, hash valid)

-- User (id 1=admin, 2=agen Budi, 3=agen Sari, 4=Andi pembeli, 5=Rini pembeli)
INSERT IGNORE INTO `user` (NIK, username, full_name, email, phone_number, password, role) VALUES
('3171000000000001', 'admin_omahku', 'Admin OmahKu', 'admin@omahku.id', '081200000001', '$2b$10$XzrnC8nm3fPB0Gipy7htwevDDjlYpzHdFGdDPM8/ohhSEsiPoYsIW', 'admin'),
('3171000000000002', 'budi_agent',   'Budi Santoso', 'budi@omahku.id',  '081200000002', '$2b$10$XzrnC8nm3fPB0Gipy7htwevDDjlYpzHdFGdDPM8/ohhSEsiPoYsIW', 'agent'),
('3171000000000003', 'sari_agent',   'Sari Dewi',    'sari@omahku.id',  '081200000003', '$2b$10$XzrnC8nm3fPB0Gipy7htwevDDjlYpzHdFGdDPM8/ohhSEsiPoYsIW', 'agent'),
('3171000000000004', 'andi_user',    'Andi Pratama', 'andi@omahku.id',  '081200000004', '$2b$10$XzrnC8nm3fPB0Gipy7htwevDDjlYpzHdFGdDPM8/ohhSEsiPoYsIW', 'user'),
('3171000000000005', 'rini_user',    'Rini Kusuma',  'rini@omahku.id',  '081200000005', '$2b$10$XzrnC8nm3fPB0Gipy7htwevDDjlYpzHdFGdDPM8/ohhSEsiPoYsIW', 'user');

-- Agent profile (user_id 2=Budi, 3=Sari)
INSERT IGNORE INTO agent_profile (user_id, agency_name, license_number, bio, verified_at) VALUES
(2, 'Budi Property', 'LIC-JKT-001', 'Agen properti berpengalaman 5 tahun di Jakarta.', '2023-01-15 10:00:00'),
(3, 'Sari Realty',   'LIC-BDG-002', 'Spesialis properti residensial Bandung & Bali.',  '2023-03-10 10:00:00');

-- Properti (5 properti)
-- category: 1=Rumah, 2=Apartemen, 3=Ruko, 4=Tanah, 5=Villa
-- location:  1=Jaksel, 2=Jakpus, 3=Bandung, 7=Surabaya, 8=Bali
INSERT IGNORE INTO property
  (owner_id, agent_id, category_id, location_id, title, address_detail,
   land_area, building_area, bedrooms, bathrooms, floors, year_built,
   certificate_type, listing_type, price, rent_period, status) VALUES
(4, 2, 1, 1, 'Rumah Mewah Kebayoran Baru',    'Jl. Melati No. 12, Kebayoran Baru',    200.00, 350.00, 4, 3, 2, 2018, 'SHM', 'sale', 2500000000.00, NULL,    'sold'),
(4, 2, 2, 2, 'Apartemen Modern Menteng',       'Jl. Diponegoro No. 5, Menteng',         NULL,    72.00, 2, 1, 1, 2020, 'SHM', 'rent',   15000000.00, 'month', 'rented'),
(5, 3, 5, 8, 'Villa Tepi Pantai Kuta',         'Jl. Pantai Kuta No. 88, Badung',       500.00, 250.00, 4, 4, 1, 2019, 'SHM', 'rent',    5000000.00, 'day',   'available'),
(5, 3, 3, 3, 'Ruko Strategis Coblong Bandung', 'Jl. Setiabudi No. 21, Coblong',        100.00, 200.00, 0, 2, 3, 2015, 'HGB', 'sale', 1800000000.00, NULL,    'available'),
(4, 2, 4, 7, 'Tanah Kavling Gubeng Surabaya',  'Jl. Raya Gubeng No. 45, Gubeng',       300.00,   NULL, 0, 0, 0, NULL,  NULL,  'sale',  800000000.00, NULL,    'available');

-- Gambar properti
INSERT IGNORE INTO property_image (property_id, image_url, is_primary, sort_order) VALUES
-- Rumah Mewah Kebayoran Baru
(1, 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80', TRUE,  1),
(1, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80', FALSE, 2),
-- Apartemen Modern Menteng
(2, 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80', TRUE,  1),
-- Villa Tepi Pantai Kuta
(3, 'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=800&q=80', TRUE,  1),
(3, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=800&q=80', FALSE, 2),
-- Ruko Strategis Coblong Bandung
(4, 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80', TRUE,  1),
-- Tanah Kavling Gubeng Surabaya
(5, 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80', TRUE,  1);

-- Fasilitas properti
-- facility: 1=Garasi, 2=Carport, 3=AC, 5=Kolam Renang, 6=Gym, 7=Balkon, 8=Taman, 9=CCTV
INSERT IGNORE INTO property_facility (property_id, facility_id, quantity) VALUES
(1, 1, 2), (1, 3, 5), (1, 9, 1),
(2, 3, 2), (2, 7, 1),
(3, 5, 1), (3, 6, 1), (3, 8, 2),
(4, 2, 2), (4, 3, 4),
(5, 8, 1);

-- Wishlist
INSERT IGNORE INTO wishlist (user_id, property_id) VALUES
(5, 1),
(4, 3),
(4, 4);

-- Booking (3 transaksi yang sudah confirmed)
INSERT IGNORE INTO booking (property_id, customer_id, requested_start_date, requested_end_date, status, notes) VALUES
(1, 5, '2024-02-01', NULL,         'confirmed', 'Berminat beli cash.'),
(2, 5, '2024-01-01', '2024-07-01', 'confirmed', 'Sewa 6 bulan.'),
(3, 4, '2024-02-10', '2024-02-17', 'confirmed', 'Liburan 1 minggu.');

-- Transaksi (status success agar muncul di Q1)
INSERT IGNORE INTO `transaction`
  (booking_id, property_id, customer_id, agent_id, transaction_type, agreed_amount, status, completed_at) VALUES
(1, 1, 5, 2, 'sale', 2500000000.00, 'success', '2024-03-01 14:00:00'),
(2, 2, 5, 2, 'rent',     90500000.00, 'success', '2024-01-05 10:00:00'),  -- 15jt x 6 bln + fee 500rb
(3, 3, 4, 3, 'rent',     35000000.00, 'success', '2024-02-12 09:00:00');  -- 5jt x 7 hari

-- Detail transaksi jual (transaction_id=1)
INSERT IGNORE INTO sale_transaction (transaction_id, transfer_date, certificate_number) VALUES
(1, '2024-03-01', 'SHM-JKT-2024-001');

-- Detail transaksi sewa (transaction_id=2 dan 3)
INSERT IGNORE INTO rent_transaction (transaction_id, start_date, end_date, price_per_period, additional_fee) VALUES
(2, '2024-01-01', '2024-07-01', 15000000.00, 500000.00),
(3, '2024-02-10', '2024-02-17',  5000000.00,       0.00);

-- Review (satu per transaksi)
INSERT IGNORE INTO review (transaction_id, property_id, reviewer_id, rating, comment) VALUES
(1, 1, 5, 5, 'Rumah sangat bagus, lokasi strategis! Proses jual beli lancar.'),
(2, 2, 5, 4, 'Apartemen bersih dan nyaman, harga sesuai.'),
(3, 3, 4, 5, 'Villa luar biasa, view pantai keren banget!');

-- Riwayat harga (properti 1 sempat turun harga)
INSERT IGNORE INTO price_history (property_id, old_price, new_price, changed_by, changed_at) VALUES
(1, 2800000000.00, 2500000000.00, 2, '2024-01-10 08:00:00'),
(4, 2000000000.00, 1800000000.00, 3, '2024-03-05 09:30:00');
