-- OmahKu — SQL Query Evaluation (Demonstrasi Analisis & Optimasi Query)
-- Requirement: Analisis performa query menggunakan EXPLAIN, ANALYZE TABLE,
-- index scan, file scan, join strategy, dan estimasi biaya eksekusi.

USE omahku;

-- ============================================================
-- QE.1  ANALYZE TABLE — Memperbarui Statistik Optimizer
-- ============================================================
-- MySQL query optimizer mengandalkan statistik tabel (distribusi nilai,
-- kardinalitas kolom) untuk menyusun execution plan yang optimal.
-- ANALYZE TABLE memperbarui statistik tersebut via full table-scan.
-- Jalankan setelah perubahan data signifikan atau sebelum analisis query.

ANALYZE TABLE
  `user`,
  property,
  property_category,
  location,
  booking,
  `transaction`,
  rent_transaction,
  sale_transaction,
  review,
  price_history;

-- ============================================================
-- QE.2  SELECT OPERATION — File Scan vs. Index Scan
-- ============================================================
-- Membandingkan biaya akses data: kolom tanpa index (type=ALL = file scan)
-- vs kolom berindex (type=ref/range = index scan).

-- QE.2a — FILE SCAN: year_built tidak memiliki index.
-- EXPLAIN menunjukkan type=ALL (MySQL membaca semua blok tabel).
EXPLAIN
SELECT id, title, year_built
FROM   property
WHERE  year_built = 2019;

-- QE.2b — INDEX SCAN: status sudah memiliki idx_property_status.
-- Optimizer memilih type=ref; jauh lebih efisien dari file scan.
EXPLAIN
SELECT id, title, status
FROM   property
WHERE  status = 'available';

-- QE.2c — INDEX SCAN pada price: kolom price memiliki idx_property_price.
-- type=range digunakan untuk kondisi perbandingan (>, <, BETWEEN).
EXPLAIN
SELECT id, title, listing_type, price
FROM   property
WHERE  price > 1000000000
  AND  deleted_at IS NULL;

-- QE.2d — Buat index SEMENTARA pada year_built untuk demonstrasi efek index.
CREATE INDEX idx_demo_year ON property(year_built);

-- Setelah index: optimizer beralih ke type=ref.
-- Perhatikan perbedaan kolom 'key' dan estimasi 'rows'.
EXPLAIN
SELECT id, title, year_built
FROM   property
WHERE  year_built = 2019;

-- Hapus index demonstrasi agar tidak mengganggu skema asli.
DROP INDEX idx_demo_year ON property;

-- QE.2e — Index KOMPOSIT: gabungkan listing_type + price.
-- Menguntungkan untuk filter dua kolom sekaligus (leftmost prefix rule).
CREATE INDEX idx_demo_listing_price ON property(listing_type, price);

EXPLAIN
SELECT id, title, listing_type, price
FROM   property
WHERE  listing_type = 'sale'
  AND  price        > 1000000000
  AND  deleted_at   IS NULL;

DROP INDEX idx_demo_listing_price ON property;

-- ============================================================
-- QE.3  PROJECT OPERATION — Lakukan Seleksi Sebelum Proyeksi
-- ============================================================
-- Heuristik: terapkan σ (SELECT/filter) sedini mungkin untuk memperkecil
-- jumlah baris SEBELUM π (PROJECT/pilih kolom) bekerja,
-- sehingga biaya CPU dan memori berkurang signifikan.

-- QE.3a — TIDAK OPTIMAL: SELECT * tanpa filter awal.
-- MySQL membaca dan meneruskan SEMUA kolom semua baris.
EXPLAIN
SELECT *
FROM   property
WHERE  deleted_at IS NULL;

-- QE.3b — OPTIMAL: σ dulu (filter status + listing_type + price), π kemudian.
-- Filter memperkecil working set SEBELUM kolom yang tidak perlu dibawa.
EXPLAIN
SELECT id, title, price, listing_type, status
FROM   property
WHERE  deleted_at    IS NULL
  AND  status        = 'available'
  AND  listing_type  = 'sale'
  AND  price BETWEEN 500000000 AND 5000000000;

-- ============================================================
-- QE.4  JOIN OPERATIONS — Nested-Loop & Indexed Nested-Loop
-- ============================================================
-- MySQL mengimplementasikan join dengan strategi Nested-Loop Join (NLJ).
-- Jika kolom join berindeks pada inner table, MySQL menggunakan
-- Indexed Nested-Loop Join (INL) yang jauh lebih efisien.

-- QE.4a — INDEXED NL JOIN: property ↔ location via FK location_id.
-- location.id adalah PRIMARY KEY → type=eq_ref pada inner table.
EXPLAIN
SELECT p.title, l.city, l.province, l.district
FROM   property p
JOIN   location l ON l.id = p.location_id
WHERE  p.deleted_at IS NULL;

-- QE.4b — INDEXED NL JOIN: transaction ↔ booking via UNIQUE (booking_id).
-- booking.id adalah PRIMARY KEY → type=eq_ref pada inner table.
EXPLAIN
SELECT t.id              AS trx_id,
       t.transaction_type,
       t.agreed_amount,
       b.status          AS booking_status,
       b.notes
FROM   `transaction` t
JOIN   booking b ON b.id = t.booking_id
WHERE  t.status     = 'success'
  AND  t.deleted_at IS NULL;

-- QE.4c — MULTI-TABLE JOIN CHAIN: transaction ↔ booking ↔ property ↔ user.
-- MySQL memilih urutan join (driving table) berdasarkan estimasi biaya.
EXPLAIN
SELECT u.full_name          AS agent_name,
       p.title              AS property_title,
       t.transaction_type,
       t.agreed_amount,
       t.completed_at
FROM   `transaction` t
JOIN   booking  b ON b.id = t.booking_id
JOIN   property p ON p.id = t.property_id
JOIN   `user`   u ON u.id = t.agent_id
WHERE  t.status     = 'success'
  AND  t.deleted_at IS NULL
  AND  p.deleted_at IS NULL
ORDER  BY t.completed_at DESC;

-- QE.4d — LEFT JOIN STRATEGY: property_category ↔ property (Q3).
-- Filter pada klausa ON (bukan WHERE) menjaga semantik LEFT JOIN.
-- Kategori tanpa properti tetap muncul dengan COUNT = 0.
EXPLAIN
SELECT c.id              AS category_id,
       c.name            AS category_name,
       COUNT(p.id)       AS total_property
FROM   property_category c
LEFT JOIN property p
       ON p.category_id  = c.id
      AND p.deleted_at   IS NULL
      AND p.status       = 'available'
WHERE  c.deleted_at IS NULL
GROUP  BY c.id, c.name
ORDER  BY total_property DESC;

-- ============================================================
-- QE.5  OPTIMASI RENCANA EKSEKUSI — Ekuivalensi Query
-- ============================================================
-- Query optimizer menghasilkan rencana alternatif menggunakan
-- equivalence rules. Tiga teknik: reformulasi subquery, predicate
-- pushdown, dan pemanfaatan index komposit.

-- QE.5a — SEBELUM OPTIMASI: subquery skalar dieksekusi ulang per-baris.
-- Untuk tabel besar, subquery AVG bisa menjadi bottleneck signifikan.
EXPLAIN
SELECT p.id, p.title, p.price
FROM   property p
WHERE  p.deleted_at IS NULL
  AND  p.price > (
         SELECT AVG(price)
         FROM   property
         WHERE  deleted_at IS NULL
       )
ORDER  BY p.price DESC;

-- QE.5b — SESUDAH OPTIMASI: materialisasi rata-rata ke variabel sesi.
-- Subquery hanya dihitung SEKALI; query utama menggunakan nilai skalar.
SET @avg_market_price := (
  SELECT AVG(price) FROM property WHERE deleted_at IS NULL
);

EXPLAIN
SELECT p.id, p.title, p.price
FROM   property p
WHERE  p.deleted_at IS NULL
  AND  p.price > @avg_market_price
ORDER  BY p.price DESC;

-- QE.5c — INDEX KOMPOSIT: menggabungkan agent_id + status untuk Q1.
-- SEBELUM index komposit:
EXPLAIN
SELECT u.id, u.full_name,
       COUNT(t.id)                       AS total_transaction,
       COALESCE(SUM(t.agreed_amount), 0) AS total_revenue
FROM   `user` u
JOIN   `transaction` t ON t.agent_id = u.id
WHERE  t.status     = 'success'
  AND  t.deleted_at IS NULL
GROUP  BY u.id, u.full_name
ORDER  BY total_revenue DESC;

-- Buat index komposit untuk mendukung filter agent_id + status:
CREATE INDEX idx_opt_agent_status ON `transaction`(agent_id, status);

-- SESUDAH index komposit — perhatikan perubahan kolom key dan rows:
EXPLAIN
SELECT u.id, u.full_name,
       COUNT(t.id)                       AS total_transaction,
       COALESCE(SUM(t.agreed_amount), 0) AS total_revenue
FROM   `user` u
JOIN   `transaction` t ON t.agent_id = u.id
WHERE  t.status     = 'success'
  AND  t.deleted_at IS NULL
GROUP  BY u.id, u.full_name
ORDER  BY total_revenue DESC;

-- Hapus index demonstrasi:
DROP INDEX idx_opt_agent_status ON `transaction`;

-- ============================================================
-- QE.6  BIAYA EVALUASI QUERY — EXPLAIN FORMAT=JSON
-- ============================================================
-- Format JSON mengungkap estimasi biaya tiap node execution plan.
-- Komponen: read_cost (I/O), eval_cost (CPU), query_cost (total).

-- QE.6a — Biaya Q1: laporan pendapatan per agen.
EXPLAIN FORMAT=JSON
SELECT u.id, u.full_name,
       COUNT(t.id)                       AS total_transaction,
       COALESCE(SUM(t.agreed_amount), 0) AS total_revenue
FROM   `user` u
JOIN   `transaction` t ON t.agent_id = u.id
WHERE  t.status = 'success' AND t.deleted_at IS NULL
GROUP  BY u.id, u.full_name
ORDER  BY total_revenue DESC;

-- QE.6b — Biaya Q2: properti dengan rating tertinggi.
EXPLAIN FORMAT=JSON
SELECT p.id, p.title,
       AVG(rv.rating) AS avg_rating,
       COUNT(rv.id)   AS review_count
FROM   property p
JOIN   review rv ON rv.property_id = p.id AND rv.deleted_at IS NULL
WHERE  p.deleted_at IS NULL
GROUP  BY p.id, p.title
HAVING COUNT(rv.id) > 0
ORDER  BY avg_rating DESC, review_count DESC
LIMIT  10;

-- QE.6c — Biaya analisis SELECT...FOR UPDATE di dalam sp_create_transaction.
-- Menunjukkan bagaimana row lock berpengaruh terhadap rencana eksekusi.
EXPLAIN FORMAT=JSON
SELECT b.property_id, b.customer_id, b.status, p.agent_id, p.listing_type
FROM   booking b
JOIN   property p ON b.property_id = p.id
WHERE  b.id = 1
FOR    UPDATE;
