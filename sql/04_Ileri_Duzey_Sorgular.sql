-- ============================================================
-- Muhasebe Fiş, Gelir-Gider ve Defter Sistemi
-- İleri Düzey SQL Sorguları (3 Adet)
-- JOIN, GROUP BY, HAVING, Subquery içerir
-- RDBMS: SQL Server (T-SQL)
-- ============================================================

USE MuhasebeDB;
GO

-- ============================================================
-- SORGU 1: Aylık Bazda Kâr/Zarar Durumu
-- Açıklama: Her ay için toplam gelir, toplam gider ve net
--           kâr/zarar hesaplar. Gelir hesapları (HesapTuru='Gelir')
--           ve gider hesapları (HesapTuru='Gider') ayrıştırılır.
-- Kullanılan: JOIN, GROUP BY, CASE, SUM
-- ============================================================
SELECT
    YEAR(f.FisTarihi)   AS Yil,
    MONTH(f.FisTarihi)  AS Ay,
    FORMAT(f.FisTarihi, 'yyyy-MM')  AS Donem,

    -- Gelir: Gelir türü hesaplara yapılan alacak kayıtları
    SUM(CASE WHEN hp.HesapTuru = 'Gelir' THEN fs.AlacakTutari * fs.KurDegeri ELSE 0 END)
        AS ToplamGelir,

    -- Gider: Gider türü hesaplara yapılan borç kayıtları
    SUM(CASE WHEN hp.HesapTuru = 'Gider' THEN fs.BorcTutari * fs.KurDegeri ELSE 0 END)
        AS ToplamGider,

    -- Net Kâr/Zarar = Gelir - Gider
    SUM(CASE WHEN hp.HesapTuru = 'Gelir' THEN fs.AlacakTutari * fs.KurDegeri ELSE 0 END) -
    SUM(CASE WHEN hp.HesapTuru = 'Gider' THEN fs.BorcTutari * fs.KurDegeri ELSE 0 END)
        AS NetKarZarar

FROM FisSatirlari fs
    INNER JOIN MuhasebeFisleri f   ON fs.FisID   = f.FisID
    INNER JOIN HesapPlani hp       ON fs.HesapID = hp.HesapID
WHERE f.Durum = 'Aktif'
  AND hp.HesapTuru IN ('Gelir', 'Gider')
GROUP BY
    YEAR(f.FisTarihi),
    MONTH(f.FisTarihi),
    FORMAT(f.FisTarihi, 'yyyy-MM')
ORDER BY Yil, Ay;
GO

-- ============================================================
-- SORGU 2: En Çok Gider Yapılan Kategoriler
-- Açıklama: Toplam gider tutarı 5.000 TL'yi aşan kategorileri
--           büyükten küçüğe sıralar. Ortalama giderin üzerinde
--           kalan kategorileri Subquery ile filtreler.
-- Kullanılan: JOIN, GROUP BY, HAVING, Subquery
-- ============================================================
SELECT
    kat.KategoriID,
    kat.KategoriAdi,
    COUNT(DISTINCT f.FisID)                     AS FisAdedi,
    COUNT(fs.SatirID)                           AS SatirAdedi,
    SUM(fs.BorcTutari * fs.KurDegeri)           AS ToplamGider,
    AVG(fs.BorcTutari * fs.KurDegeri)           AS OrtalamaGider
FROM FisSatirlari fs
    INNER JOIN MuhasebeFisleri f                ON fs.FisID      = f.FisID
    INNER JOIN GelirGiderKategorileri kat        ON fs.KategoriID = kat.KategoriID
    INNER JOIN HesapPlani hp                     ON fs.HesapID   = hp.HesapID
WHERE kat.Tur = 'Gider'
  AND f.Durum = 'Aktif'
  AND fs.BorcTutari > 0
GROUP BY
    kat.KategoriID,
    kat.KategoriAdi
HAVING
    -- Yalnızca toplam gideri 5.000 TL'den fazla olan kategoriler
    SUM(fs.BorcTutari * fs.KurDegeri) > 5000
    -- VE ortalama kategori giderinden yüksek olanlar (Subquery)
    AND SUM(fs.BorcTutari * fs.KurDegeri) > (
        SELECT AVG(ToplamKategoriGider)
        FROM (
            SELECT SUM(fs2.BorcTutari * fs2.KurDegeri) AS ToplamKategoriGider
            FROM FisSatirlari fs2
                INNER JOIN MuhasebeFisleri f2            ON fs2.FisID      = f2.FisID
                INNER JOIN GelirGiderKategorileri kat2    ON fs2.KategoriID = kat2.KategoriID
            WHERE kat2.Tur = 'Gider'
              AND f2.Durum = 'Aktif'
              AND fs2.BorcTutari > 0
            GROUP BY kat2.KategoriID
        ) AS KategoriToplamlar
    )
ORDER BY ToplamGider DESC;
GO

-- ============================================================
-- SORGU 3: Cari Bazında Borç-Alacak Bakiye Analizi
-- Açıklama: Her cari hesabın toplam borç, toplam alacak ve
--           net bakiyesini hesaplar. Yalnızca bakiyesi 0'dan
--           farklı olan carileri gösterir.
-- Kullanılan: JOIN, GROUP BY, HAVING, Subquery (bakiye kontrolü)
-- ============================================================
SELECT
    c.CariKodu,
    c.CariAdi,
    c.CariTuru,
    SUM(fs.BorcTutari * fs.KurDegeri)                                   AS ToplamBorc,
    SUM(fs.AlacakTutari * fs.KurDegeri)                                 AS ToplamAlacak,
    SUM(fs.BorcTutari * fs.KurDegeri) - SUM(fs.AlacakTutari * fs.KurDegeri) AS NetBakiye,

    -- Son işlem tarihi (Subquery)
    (SELECT MAX(f2.FisTarihi)
     FROM FisSatirlari fs2
         INNER JOIN MuhasebeFisleri f2 ON fs2.FisID = f2.FisID
     WHERE fs2.CariID = c.CariID
       AND f2.Durum = 'Aktif'
    ) AS SonIslemTarihi,

    -- İşlem sayısı
    COUNT(DISTINCT f.FisID) AS IslemSayisi

FROM FisSatirlari fs
    INNER JOIN MuhasebeFisleri f     ON fs.FisID  = f.FisID
    INNER JOIN CariHesaplar c        ON fs.CariID = c.CariID
WHERE f.Durum = 'Aktif'
GROUP BY
    c.CariID,
    c.CariKodu,
    c.CariAdi,
    c.CariTuru
HAVING
    -- Yalnızca bakiyesi sıfır olmayan cariler
    ABS(SUM(fs.BorcTutari * fs.KurDegeri) - SUM(fs.AlacakTutari * fs.KurDegeri)) > 0.01
ORDER BY
    ABS(SUM(fs.BorcTutari * fs.KurDegeri) - SUM(fs.AlacakTutari * fs.KurDegeri)) DESC;
GO
