
-- ─────────────────────────────────────────────────────────────────
-- TheEpicBook Database Initialisation
--
-- Runs automatically when MySQL container starts for the first time
-- Creates the bookstore database, all tables and seeds data
--
-- Based on: db/BuyTheBook_Schema.sql
-- Seeds:    db/books_seed.sql + db/author_seed.sql
-- ─────────────────────────────────────────────────────────────────

-- Create the database
CREATE DATABASE IF NOT EXISTS bookstore;

-- Use the database
USE bookstore;

-- ── Author Table ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `Author` (
  `id`        INT         NOT NULL AUTO_INCREMENT,
  `firstName` VARCHAR(45) NOT NULL,
  `lastName`  VARCHAR(45) NOT NULL,
  `createdAt` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- ── Book Table ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `Book` (
  `id`              INT           NOT NULL AUTO_INCREMENT,
  `title`           VARCHAR(255)  NOT NULL,
  `genre`           VARCHAR(255)  NOT NULL,
  `pubYear`         INT           NOT NULL,
  `price`           DECIMAL(13,2) NOT NULL,
  `inventory`       INT           NOT NULL,
  `bookDescription` TEXT          NOT NULL,
  `createdAt`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `AuthorId`        INT           NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `AuthorId_idx` (`AuthorId` ASC),
  CONSTRAINT `AuthorId`
    FOREIGN KEY (`AuthorId`)
    REFERENCES `Author` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- ── Cart Table ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `Cart` (
  `id`        INT           NOT NULL AUTO_INCREMENT,
  `quantity`  INT           NOT NULL,
  `price`     DECIMAL(13,2) NOT NULL,
  `createdAt` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- ── Seed Authors ──────────────────────────────────────────────────
INSERT IGNORE INTO `Author`
  (`id`, `firstName`, `lastName`, `createdAt`, `updatedAt`)
VALUES
  (1,  'Toni',       'Morrison',  NOW(), NOW()),
  (2,  'James',      'Baldwin',   NOW(), NOW()),
  (3,  'Chimamanda', 'Adichie',   NOW(), NOW()),
  (4,  'Colson',     'Whitehead', NOW(), NOW()),
  (5,  'Ta-Nehisi',  'Coates',    NOW(), NOW()),
  (6,  'Jesmyn',     'Ward',      NOW(), NOW()),
  (7,  'ZZ',         'Packer',    NOW(), NOW()),
  (8,  'Edwidge',    'Danticat',  NOW(), NOW()),
  (9,  'Walter',     'Mosley',    NOW(), NOW()),
  (10, 'Paul',       'Beatty',    NOW(), NOW());

-- ── Seed Books ────────────────────────────────────────────────────
INSERT IGNORE INTO `Book`
  (`title`, `genre`, `pubYear`, `price`,
   `inventory`, `bookDescription`, `AuthorId`,
   `createdAt`, `updatedAt`)
VALUES
  ('Beloved',
   'Fiction', 1987, 14.99, 10,
   'A powerful story about the legacy of slavery and its aftermath.',
   1, NOW(), NOW()),

  ('The Bluest Eye',
   'Fiction', 1970, 12.99, 8,
   'A young Black girl wishes for blue eyes in 1940s Ohio.',
   1, NOW(), NOW()),

  ('Go Tell It on the Mountain',
   'Fiction', 1953, 13.99, 6,
   'A semi-autobiographical novel about faith and family.',
   2, NOW(), NOW()),

  ('Giovanni''s Room',
   'Fiction', 1956, 11.99, 5,
   'A story of identity and love set in 1950s Paris.',
   2, NOW(), NOW()),

  ('Purple Hibiscus',
   'Fiction', 2003, 13.99, 9,
   'A Nigerian coming-of-age story of faith and freedom.',
   3, NOW(), NOW()),

  ('Half of a Yellow Sun',
   'Historical Fiction', 2006, 15.99, 7,
   'The devastating story of the Nigerian civil war.',
   3, NOW(), NOW()),

  ('The Underground Railroad',
   'Historical Fiction', 2016, 14.99, 12,
   'An alternate history reimagining of the Underground Railroad.',
   4, NOW(), NOW()),

  ('Between the World and Me',
   'Non-Fiction', 2015, 16.99, 15,
   'A letter to his teenage son about being Black in America.',
   5, NOW(), NOW()),

  ('Sing Unburied Sing',
   'Fiction', 2017, 14.99, 8,
   'A haunting road trip through the American South.',
   6, NOW(), NOW()),

  ('Drinking Coffee Elsewhere',
   'Short Stories', 2003, 12.99, 6,
   'Vivid stories of race, sexuality and belonging.',
   7, NOW(), NOW());
