-- OmahKu — Advanced Queries (requirement 1.2.c)


-- Q1. Laporan pendapatan per agen (total keseluruhan)
-- Hanya menghitung transaksi yang sukses.
SELECT u.id                              AS agent_id,
       u.full_name                       AS agent_name,
       COUNT(t.id)                       AS total_transaction,
       COALESCE(SUM(t.agreed_amount), 0) AS total_revenue
FROM `user` u
JOIN `transaction` t ON t.agent_id = u.id
WHERE t.status = 'success'
  AND t.deleted_at IS NULL
GROUP BY u.id, u.full_name
ORDER BY total_revenue DESC;


-- Q1b. Laporan pendapatan BULANAN per agen (requirement 1.2.c)
-- Dikelompokkan per agen + per bulan berdasarkan tanggal transaksi selesai.
SELECT u.id                              AS agent_id,
       u.full_name                       AS agent_name,
       YEAR(t.completed_at)              AS revenue_year,
       MONTH(t.completed_at)             AS revenue_month,
       COUNT(t.id)                       AS total_transaction,
       COALESCE(SUM(t.agreed_amount), 0) AS monthly_revenue
FROM `user` u
JOIN `transaction` t ON t.agent_id = u.id
WHERE t.status = 'success'
  AND t.completed_at IS NOT NULL
  AND t.deleted_at IS NULL
GROUP BY u.id, u.full_name, YEAR(t.completed_at), MONTH(t.completed_at)
ORDER BY revenue_year DESC, revenue_month DESC, monthly_revenue DESC;


-- Q2. Properti dengan rating rata-rata tertinggi
-- Hanya properti yang punya minimal 1 ulasan.
SELECT p.id           AS property_id,
       p.title        AS title,
       AVG(rv.rating) AS avg_rating,
       COUNT(rv.id)   AS review_count
FROM property p
JOIN review rv ON rv.property_id = p.id AND rv.deleted_at IS NULL
WHERE p.deleted_at IS NULL
GROUP BY p.id, p.title
HAVING COUNT(rv.id) > 0
ORDER BY avg_rating DESC, review_count DESC
LIMIT 10;


-- Q3. (Bonus) Jumlah properti aktif per kategori
SELECT c.id                AS category_id,
       c.name              AS category_name,
       COUNT(p.id)         AS total_property
FROM property_category c
LEFT JOIN property p
       ON p.category_id = c.id
      AND p.deleted_at IS NULL
      AND p.status = 'available'
WHERE c.deleted_at IS NULL
GROUP BY c.id, c.name
ORDER BY total_property DESC;


-- Q4. (Bonus) Properti dengan harga di atas rata-rata pasar
SELECT p.id,
       p.title,
       p.price
FROM property p
WHERE p.deleted_at IS NULL
  AND p.price > (
        SELECT AVG(price)
        FROM property
        WHERE deleted_at IS NULL
      )
ORDER BY p.price DESC;
