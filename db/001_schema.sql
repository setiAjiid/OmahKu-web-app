-- OmahKu — Schema (15 tabel)
SET FOREIGN_KEY_CHECKS = 0;

# 1. USER 
CREATE TABLE IF NOT EXISTS `user` (
  id			INT AUTO_INCREMENT PRIMARY KEY,
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

# 2. AGENT_PROFILE
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

# 3. LOCATION 
CREATE TABLE IF NOT EXISTS location (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  province    VARCHAR(50) NOT NULL,
  city        VARCHAR(50) NOT NULL,
  district    VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NULL,
  UNIQUE KEY uq_location (province, city, district)
) ENGINE=InnoDB;

# 4. PROPERTY_CATEGORY
CREATE TABLE IF NOT EXISTS property_category (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(30) NOT NULL UNIQUE,
  description TEXT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at  DATETIME NULL
) ENGINE=InnoDB;

# 5. PROPERTY
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

# 6. PROPERTY_IMAGE
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

# 7. FACILITY
CREATE TABLE IF NOT EXISTS facility (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(50) NOT NULL UNIQUE,
  is_countable BOOLEAN NOT NULL DEFAULT TRUE,
  icon         VARCHAR(100) NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at   DATETIME NULL
) ENGINE=InnoDB;

# 8. PROPERTY_FACILITY 
CREATE TABLE IF NOT EXISTS property_facility (
  property_id INT NOT NULL,
  facility_id INT NOT NULL,
  quantity    SMALLINT NOT NULL DEFAULT 1,
  notes       VARCHAR(100) NULL,
  PRIMARY KEY (property_id, facility_id),
  CONSTRAINT fk_pf_property FOREIGN KEY (property_id) REFERENCES property(id) ON DELETE CASCADE,
  CONSTRAINT fk_pf_facility FOREIGN KEY (facility_id) REFERENCES facility(id)
) ENGINE=InnoDB;

# 9. WISHLIST
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

# 10. BOOKING
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

# 11. TRANSACTION
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

# 12. SALE_TRANSACTION
CREATE TABLE IF NOT EXISTS sale_transaction (
  transaction_id     INT PRIMARY KEY,
  transfer_date      DATE NULL,
  certificate_number VARCHAR(50) NULL,
  CONSTRAINT fk_sale_trx FOREIGN KEY (transaction_id) REFERENCES `transaction`(id) ON DELETE CASCADE
) ENGINE=InnoDB;

# 13. RENT_TRANSACTION 
CREATE TABLE IF NOT EXISTS rent_transaction (
  transaction_id   INT PRIMARY KEY,
  start_date       DATE NOT NULL,
  end_date         DATE NOT NULL,
  price_per_period DECIMAL(15,2) NOT NULL,
  additional_fee   DECIMAL(15,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_rent_trx FOREIGN KEY (transaction_id) REFERENCES `transaction`(id) ON DELETE CASCADE,
  CONSTRAINT chk_rent_dates CHECK (end_date > start_date)
) ENGINE=InnoDB;

# 14. REVIEW 
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

# 15. PRICE_HISTORY (immutable, tanpa deleted_at) 
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

SET FOREIGN_KEY_CHECKS = 1;