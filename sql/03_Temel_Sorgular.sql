-- ============================================================
-- Muhasebe Fiş, Gelir-Gider ve Defter Sistemi
-- Temel SQL Sorguları (3 Adet)
-- RDBMS: SQL Server (T-SQL)
-- ============================================================

USE MuhasebeDB;
GO

-- ============================================================
-- SORGU 1: Belirli tarih aralığındaki fişleri getirme
-- Açıklama: 2026-01-01 ile 2026-01-31 arasındaki tüm aktif
--           fişleri tarih sırasıyla listeler.
-- ============================================================
SELECT
    f.FisID,
    f.FisNo,
    f.FisTarihi,
    f.FisTuru,
    f.Aciklama,
    f.Durum,
    k.AdSoyad       AS OlusturanKullanici,
    d.DonemAdi
FROM MuhasebeFisleri f
    INNER JOIN Kullanicilar k        ON f.KullaniciID = k.KullaniciID
    INNER JOIN MuhasebeDonemleri d   ON f.DonemID     = d.DonemID
WHERE f.FisTarihi BETWEEN '2026-01-01' AND '2026-01-31'
  AND f.Durum = 'Aktif'
ORDER BY f.FisTarihi ASC, f.FisNo ASC;
GO

-- ============================================================
-- SORGU 2: Bir cariye ait gelir-gider hareketlerini listeleme
-- Açıklama: "ABC Ticaret Ltd. Şti." (CariKodu = 'C001') adlı
--           carinin tüm fiş satırlarını listeler.
-- ============================================================
SELECT
    c.CariKodu,
    c.CariAdi,
    f.FisNo,
    f.FisTarihi,
    hp.HesapKodu,
    hp.HesapAdi,
    fs.BorcTutari,
    fs.AlacakTutari,
    fs.Aciklama      AS SatirAciklama,
    kat.KategoriAdi,
    kat.Tur           AS KategoriTuru
FROM FisSatirlari fs
    INNER JOIN MuhasebeFisleri f     ON fs.FisID    = f.FisID
    INNER JOIN CariHesaplar c        ON fs.CariID   = c.CariID
    INNER JOIN HesapPlani hp         ON fs.HesapID  = hp.HesapID
    LEFT  JOIN GelirGiderKategorileri kat ON fs.KategoriID = kat.KategoriID
WHERE c.CariKodu = 'C001'
  AND f.Durum = 'Aktif'
ORDER BY f.FisTarihi ASC;
GO

-- ============================================================
-- SORGU 3: Aktif hesap planını hiyerarşik listeleme
-- Açıklama: Hesap planındaki tüm aktif hesapları, ana hesap-
--           alt hesap ilişkisiyle birlikte listeler.
-- ============================================================
SELECT
    hp.HesapID,
    hp.HesapKodu,
    hp.HesapAdi,
    hp.HesapTuru,
    ust.HesapKodu    AS UstHesapKodu,
    ust.HesapAdi     AS UstHesapAdi,
    CASE 
        WHEN hp.UstHesapID IS NULL THEN N'Ana Hesap'
        ELSE N'Alt Hesap'
    END              AS HesapSeviyesi
FROM HesapPlani hp
    LEFT JOIN HesapPlani ust ON hp.UstHesapID = ust.HesapID
WHERE hp.Aktif = 1
ORDER BY hp.HesapKodu ASC;
GO
