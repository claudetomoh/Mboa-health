-- =============================================================================
-- MBOA HEALTH — MySQL Database Schema
-- Database: mboa_health  (create this in phpMyAdmin first)
-- Charset:  utf8mb4 / utf8mb4_unicode_ci
-- =============================================================================

CREATE DATABASE IF NOT EXISTS mboa_health
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE mboa_health;

-- ─── Users ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100)  NOT NULL,
  email         VARCHAR(255)  NOT NULL UNIQUE,
  phone         VARCHAR(20)   DEFAULT NULL,
  password_hash VARCHAR(255)  NOT NULL,          -- bcrypt(sha256Hash)
  salt          VARCHAR(100)  NOT NULL,           -- client-generated salt
  role          ENUM('patient','doctor','admin') NOT NULL DEFAULT 'patient',
  blood_type    VARCHAR(5)    DEFAULT NULL,
  allergies     TEXT          DEFAULT NULL,
  avatar_url    VARCHAR(500)  DEFAULT NULL,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_role  (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Health Records ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS health_records (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  type       ENUM('prescription','lab_result','x_ray','vaccination',
                   'consultation','surgery','other') NOT NULL DEFAULT 'other',
  title      VARCHAR(200) NOT NULL,
  doctor     VARCHAR(150) DEFAULT NULL,
  facility   VARCHAR(200) DEFAULT NULL,
  date       DATE         NOT NULL,
  file_url   VARCHAR(500) DEFAULT NULL,
  notes      TEXT         DEFAULT NULL,
  is_active  TINYINT(1)   NOT NULL DEFAULT 1,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                          ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id  (user_id),
  INDEX idx_date     (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Reminders ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reminders (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id         INT UNSIGNED NOT NULL,
  medication_name VARCHAR(150) NOT NULL,
  dosage          VARCHAR(100) DEFAULT NULL,
  frequency       ENUM('daily','twice_daily','thrice_daily','weekly',
                        'as_needed') NOT NULL DEFAULT 'daily',
  reminder_time   TIME         NOT NULL,
  days_of_week    VARCHAR(50)  DEFAULT NULL,   -- comma-separated: Mon,Tue,Wed
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  start_date      DATE         DEFAULT NULL,
  end_date        DATE         DEFAULT NULL,
  notes           TEXT         DEFAULT NULL,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Clinics ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clinics (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(200) NOT NULL,
  address     VARCHAR(400) NOT NULL,
  city        VARCHAR(100) DEFAULT 'Yaoundé',
  country     VARCHAR(50)  DEFAULT 'Cameroon',
  latitude    DECIMAL(10,7) DEFAULT NULL,
  longitude   DECIMAL(10,7) DEFAULT NULL,
  phone       VARCHAR(30)  DEFAULT NULL,
  email       VARCHAR(255) DEFAULT NULL,
  website     VARCHAR(500) DEFAULT NULL,
  type        ENUM('hospital','clinic','pharmacy','laboratory',
                    'specialist','dental','eye_care','other')
              NOT NULL DEFAULT 'clinic',
  rating      DECIMAL(3,1) DEFAULT NULL CHECK (rating BETWEEN 1.0 AND 5.0),
  is_24h      TINYINT(1)   NOT NULL DEFAULT 0,
  hours       VARCHAR(200) DEFAULT NULL,    -- e.g. "Mon-Fri 7am-6pm"
  services    TEXT         DEFAULT NULL,    -- comma-separated
  is_active   TINYINT(1)   NOT NULL DEFAULT 1,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_city (city),
  INDEX idx_type (type),
  FULLTEXT ft_search (name, address, services)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Notifications ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  type       ENUM('reminder','appointment','system','alert','info')
             NOT NULL DEFAULT 'info',
  title      VARCHAR(200) NOT NULL,
  body       TEXT         DEFAULT NULL,
  is_read    TINYINT(1)   NOT NULL DEFAULT 0,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Emergency Contacts ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNSIGNED NOT NULL,
  full_name    VARCHAR(100) NOT NULL,
  phone        VARCHAR(30)  NOT NULL,
  relationship VARCHAR(50)  DEFAULT NULL,   -- e.g. Spouse, Parent
  is_primary   TINYINT(1)   NOT NULL DEFAULT 0,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- SEED DATA — Cameroonian Clinics
-- =============================================================================
INSERT INTO clinics (name, address, city, latitude, longitude, phone, type,
                     rating, is_24h, hours, services) VALUES
('Central Hospital Yaoundé',
 'Rue Henri Dunant, Yaoundé', 'Yaoundé',
 3.8667, 11.5167, '+237 222 22 10 87',
 'hospital', 4.2, 1, '24 hours / 7 days',
 'Emergency,Surgery,Maternity,Cardiology,Pediatrics,Radiology'),

('Clinique La Cathedrale',
 'Avenue Monseigneur Vogt, Yaoundé', 'Yaoundé',
 3.8710, 11.5154, '+237 222 20 09 20',
 'clinic', 4.5, 0, 'Mon-Fri 7am-7pm, Sat 8am-5pm',
 'General Medicine,Gynecology,Dermatology,Ophthalmology,Dental'),

('Chantal Biya Foundation Hospital',
 'Rue Joseph Mballa Eloumden, Yaoundé', 'Yaoundé',
 3.8756, 11.5123, '+237 222 21 30 60',
 'hospital', 4.7, 0, 'Mon-Fri 7:30am-3:30pm',
 'Pediatrics,Oncology,Cardiology,Neurology'),

('Douala General Hospital',
 'Boulevard de la Liberté, Douala', 'Douala',
 4.0511, 9.7679, '+237 233 42 36 36',
 'hospital', 4.0, 1, '24 hours / 7 days',
 'Emergency,Surgery,Maternity,Orthopedics,Radiology'),

('Polyclinique La Concorde',
 'Rue Joffre, Douala', 'Douala',
 4.0479, 9.7011, '+237 233 42 56 78',
 'clinic', 4.3, 0, 'Mon-Sat 7am-8pm',
 'General Medicine,Cardiology,Gastroenterology'),

('Laquintinie Hospital',
 'Route Bonabéri, Douala', 'Douala',
 4.0612, 9.7095, '+237 233 40 10 33',
 'hospital', 3.9, 1, '24 hours / 7 days',
 'Emergency,Surgery,Nephrology,Pediatrics'),

('City Pharmacy Centre',
 'Centre Ville, Yaoundé', 'Yaoundé',
 3.8680, 11.5180, '+237 222 22 50 00',
 'pharmacy', 4.1, 0, 'Mon-Sat 8am-8pm, Sun 9am-5pm',
 'Prescriptions,OTC Medications,Vaccines'),

('BioLab Diagnostic Centre',
 'Quartier Bastos, Yaoundé', 'Yaoundé',
 3.8830, 11.5140, '+237 222 20 12 34',
 'laboratory', 4.4, 0, 'Mon-Fri 6:30am-6pm, Sat 7am-2pm',
 'Blood Tests,Urology,Bacteriology,Parasitology,PCR'),

('Clinique du Plateau',
 'Plateau, Bafoussam', 'Bafoussam',
 5.4781, 10.4178, '+237 233 44 89 10',
 'clinic', 4.0, 0, 'Mon-Sat 8am-6pm',
 'General Medicine,Pediatrics,Maternity'),

('Centre Medical d''Olézoa',
 'Rue Olézoa, Yaoundé', 'Yaoundé',
 3.8590, 11.5310, '+237 222 23 45 60',
 'specialist', 4.6, 0, 'Mon-Fri 8am-5pm',
 'Cardiology,Endocrinology,Neurology,Rheumatology');
