-- OmahKu — Stored Routines & Triggers (requirement 1.2.d–g)

-- 10.1 Trigger validasi rent_period saat INSERT (aturan bisnis #5)
DROP TRIGGER IF EXISTS trg_property_validate_rent_insert;
DELIMITER //
CREATE TRIGGER trg_property_validate_rent_insert
BEFORE INSERT ON property
FOR EACH ROW
BEGIN
  IF NEW.listing_type = 'rent' AND NEW.rent_period IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rent_period wajib untuk listing_type=rent';
  END IF;
END//
DELIMITER ;

-- 10.1b Versi BEFORE UPDATE 
DROP TRIGGER IF EXISTS trg_property_validate_rent_update;
DELIMITER //
CREATE TRIGGER trg_property_validate_rent_update
BEFORE UPDATE ON property
FOR EACH ROW
BEGIN
  IF NEW.listing_type = 'rent' AND NEW.rent_period IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rent_period wajib untuk listing_type=rent';
  END IF;
END//
DELIMITER ;

-- 10.2 Trigger audit price history (1.2.g)
-- changed_by diambil dari session var @app_user_id bila di-set oleh aplikasi,
-- selain itu NULL (berarti perubahan oleh sistem).
DROP TRIGGER IF EXISTS trg_property_price_audit;
DELIMITER //
CREATE TRIGGER trg_property_price_audit
BEFORE UPDATE ON property
FOR EACH ROW
BEGIN
  IF NEW.price <> OLD.price THEN
    INSERT INTO price_history(property_id, old_price, new_price, changed_by, changed_at)
    VALUES (OLD.id, OLD.price, NEW.price,
            NULLIF(@app_user_id, 0), NOW());
  END IF;
END//
DELIMITER ;

-- 10.3 Trigger update status properti saat transaksi success (1.2.f) 
DROP TRIGGER IF EXISTS trg_transaction_success;
DELIMITER //
CREATE TRIGGER trg_transaction_success
AFTER UPDATE ON `transaction`
FOR EACH ROW
BEGIN
  IF NEW.status = 'success' AND OLD.status <> 'success' THEN
    UPDATE property
    SET status = CASE NEW.transaction_type
                   WHEN 'sale' THEN 'sold'
                   WHEN 'rent' THEN 'rented'
                 END
    WHERE id = NEW.property_id;
  END IF;
END//
DELIMITER ;

-- 10.4 Function hitung biaya sewa (1.2.e) 
DROP FUNCTION IF EXISTS fn_hitung_biaya_sewa;
DELIMITER //
CREATE FUNCTION fn_hitung_biaya_sewa(p_transaction_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_period ENUM('day','month','year');
  DECLARE v_start DATE; DECLARE v_end DATE;
  DECLARE v_price DECIMAL(15,2); DECLARE v_fee DECIMAL(15,2);
  DECLARE v_count INT; DECLARE v_total DECIMAL(15,2);

  SELECT p.rent_period, rt.start_date, rt.end_date, rt.price_per_period, rt.additional_fee
    INTO v_period, v_start, v_end, v_price, v_fee
  FROM rent_transaction rt
  JOIN `transaction` t ON rt.transaction_id = t.id
  JOIN property p ON t.property_id = p.id
  WHERE rt.transaction_id = p_transaction_id;

  SET v_count = CASE v_period
    WHEN 'day'   THEN DATEDIFF(v_end, v_start)
    WHEN 'month' THEN TIMESTAMPDIFF(MONTH, v_start, v_end)
    WHEN 'year'  THEN TIMESTAMPDIFF(YEAR, v_start, v_end)
  END;

  SET v_total = (v_count * v_price) + COALESCE(v_fee, 0);
  RETURN v_total;
END//
DELIMITER ;

-- 10.5 Stored Procedure transaksi atomik (1.2.d) 
DROP PROCEDURE IF EXISTS sp_create_transaction;
DELIMITER //
CREATE PROCEDURE sp_create_transaction(
  IN  p_booking_id       INT,
  IN  p_agreed_amount    DECIMAL(15,2),
  IN  p_transfer_date    DATE,
  IN  p_cert_number      VARCHAR(50),
  IN  p_start_date       DATE,
  IN  p_end_date         DATE,
  IN  p_price_per_period DECIMAL(15,2),
  IN  p_additional_fee   DECIMAL(15,2),
  OUT p_transaction_id   INT
)
BEGIN
  DECLARE v_property_id INT; DECLARE v_customer_id INT;
  DECLARE v_agent_id INT; DECLARE v_type ENUM('sale','rent');
  DECLARE v_status ENUM('pending','confirmed','cancelled','expired');

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- ambil & kunci baris booking + properti
  SELECT b.property_id, b.customer_id, b.status, p.agent_id, p.listing_type
    INTO v_property_id, v_customer_id, v_status, v_agent_id, v_type
  FROM booking b JOIN property p ON b.property_id = p.id
  WHERE b.id = p_booking_id FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking tidak ditemukan';
  END IF;

  IF v_status <> 'confirmed' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking harus berstatus confirmed';
  END IF;

  -- buat transaction induk
  INSERT INTO `transaction`(booking_id, property_id, customer_id, agent_id,
                            transaction_type, agreed_amount, status)
  VALUES (p_booking_id, v_property_id, v_customer_id, v_agent_id,
          v_type, p_agreed_amount, 'pending');

  SET p_transaction_id = LAST_INSERT_ID();

  -- buat subtype sesuai tipe (disjoint total)
  IF v_type = 'sale' THEN
    INSERT INTO sale_transaction(transaction_id, transfer_date, certificate_number)
    VALUES (p_transaction_id, p_transfer_date, p_cert_number);
  ELSE
    INSERT INTO rent_transaction(transaction_id, start_date, end_date,
                                 price_per_period, additional_fee)
    VALUES (p_transaction_id, p_start_date, p_end_date,
            p_price_per_period, COALESCE(p_additional_fee, 0));
  END IF;

  COMMIT;
END//
DELIMITER ;
