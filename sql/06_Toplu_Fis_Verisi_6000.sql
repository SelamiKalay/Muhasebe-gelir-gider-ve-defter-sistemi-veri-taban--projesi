-- ============================================================
-- Muhasebe Fiş Sistemi — 6000 Rastgele Fiş Verisi Üretme
-- RDBMS: SQL Server (T-SQL)
-- Tarih: 2026-03-24
-- ============================================================
-- Bu script MuhasebeFisleri tablosuna 6000 adet rastgele fiş,
-- her fişe 2-5 arası rastgele sayıda satır ekler.
-- Gelir ve gider tutarları rastgele ve gerçekçi değerlerdedir.
-- ============================================================

USE MuhasebeDB;
GO

SET NOCOUNT ON;

-- ============================================================
-- Mevcut FK referans verilerinin ID'lerini alalım
-- ============================================================
DECLARE @DonemID_2025 INT = (SELECT DonemID FROM MuhasebeDonemleri WHERE DonemAdi = N'2025 Mali Yılı');
DECLARE @DonemID_2026 INT = (SELECT DonemID FROM MuhasebeDonemleri WHERE DonemAdi = N'2026 Mali Yılı');

-- Kullanıcı ID'leri
DECLARE @KullaniciID_Admin INT = (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi = 'admin');
DECLARE @KullaniciID_Muhasebeci INT = (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi = 'muhasebeci1');
DECLARE @KullaniciID_Okuyucu INT = (SELECT KullaniciID FROM Kullanicilar WHERE KullaniciAdi = 'okuyucu1');

-- Hesap ID'leri
DECLARE @HesapID_Kasa INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '100');
DECLARE @HesapID_Bankalar INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '102');
DECLARE @HesapID_Alicilar INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '120');
DECLARE @HesapID_Saticilar INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '320');
DECLARE @HesapID_Satis INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '600');
DECLARE @HesapID_GenelYonetim INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '770');
DECLARE @HesapID_MerkezKasa INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '100.01');
DECLARE @HesapID_DovizKasa INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '100.02');
DECLARE @HesapID_Ziraat INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '102.01');
DECLARE @HesapID_IsBankasi INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '102.02');
DECLARE @HesapID_UrunSatis INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '600.01');
DECLARE @HesapID_KiraGider INT = (SELECT HesapID FROM HesapPlani WHERE HesapKodu = '770.01');

-- Cari ID'leri
DECLARE @CariID_ABC INT = (SELECT CariID FROM CariHesaplar WHERE CariKodu = 'C001');
DECLARE @CariID_XYZ INT = (SELECT CariID FROM CariHesaplar WHERE CariKodu = 'C002');
DECLARE @CariID_DEF INT = (SELECT CariID FROM CariHesaplar WHERE CariKodu = 'C003');
DECLARE @CariID_GHI INT = (SELECT CariID FROM CariHesaplar WHERE CariKodu = 'C004');
DECLARE @CariID_Ali INT = (SELECT CariID FROM CariHesaplar WHERE CariKodu = 'C005');

-- Kategori ID'leri
DECLARE @KatID_UrunSatis INT = (SELECT KategoriID FROM GelirGiderKategorileri WHERE KategoriAdi = N'Ürün Satışı');
DECLARE @KatID_HizmetGelir INT = (SELECT KategoriID FROM GelirGiderKategorileri WHERE KategoriAdi = N'Hizmet Geliri');
DECLARE @KatID_FaizGelir INT = (SELECT KategoriID FROM GelirGiderKategorileri WHERE KategoriAdi = N'Faiz Geliri');
DECLARE @KatID_KiraGider INT = (SELECT KategoriID FROM GelirGiderKategorileri WHERE KategoriAdi = N'Kira Gideri');
DECLARE @KatID_PersonelGider INT = (SELECT KategoriID FROM GelirGiderKategorileri WHERE KategoriAdi = N'Personel Gideri');
DECLARE @KatID_OfisMalzeme INT = (SELECT KategoriID FROM GelirGiderKategorileri WHERE KategoriAdi = N'Ofis Malzemesi');

-- ============================================================
-- Referans dizileri için geçici tablolar
-- ============================================================

-- Fiş türleri
CREATE TABLE #FisTurleri (Idx INT IDENTITY(1,1), FisTuru VARCHAR(20));
INSERT INTO #FisTurleri (FisTuru) VALUES ('Mahsup'), ('Tahsil'), ('Tediye'), ('Acilis'), ('Kapanis');

-- Kullanıcılar
CREATE TABLE #Kullanicilar (Idx INT IDENTITY(1,1), KullaniciID INT);
INSERT INTO #Kullanicilar (KullaniciID) VALUES (@KullaniciID_Admin), (@KullaniciID_Muhasebeci);

-- Borç hesapları (fişin borç tarafı)
CREATE TABLE #BorcHesaplari (Idx INT IDENTITY(1,1), HesapID INT);
INSERT INTO #BorcHesaplari (HesapID) VALUES 
    (@HesapID_MerkezKasa), (@HesapID_DovizKasa), (@HesapID_Ziraat), 
    (@HesapID_IsBankasi), (@HesapID_Alicilar), (@HesapID_Saticilar),
    (@HesapID_UrunSatis), (@HesapID_KiraGider),
    (@HesapID_Kasa), (@HesapID_Bankalar), (@HesapID_Satis), (@HesapID_GenelYonetim);

-- Alacak hesapları (fişin alacak tarafı)  
CREATE TABLE #AlacakHesaplari (Idx INT IDENTITY(1,1), HesapID INT);
INSERT INTO #AlacakHesaplari (HesapID) VALUES 
    (@HesapID_MerkezKasa), (@HesapID_DovizKasa), (@HesapID_Ziraat), 
    (@HesapID_IsBankasi), (@HesapID_Alicilar), (@HesapID_Saticilar),
    (@HesapID_UrunSatis), (@HesapID_KiraGider),
    (@HesapID_Kasa), (@HesapID_Bankalar), (@HesapID_Satis), (@HesapID_GenelYonetim);

-- Cariler
CREATE TABLE #Cariler (Idx INT IDENTITY(1,1), CariID INT);
INSERT INTO #Cariler (CariID) VALUES 
    (@CariID_ABC), (@CariID_XYZ), (@CariID_DEF), (@CariID_GHI), (@CariID_Ali);

-- Gelir Kategorileri
CREATE TABLE #GelirKategorileri (Idx INT IDENTITY(1,1), KategoriID INT);
INSERT INTO #GelirKategorileri (KategoriID) VALUES 
    (@KatID_UrunSatis), (@KatID_HizmetGelir), (@KatID_FaizGelir);

-- Gider Kategorileri
CREATE TABLE #GiderKategorileri (Idx INT IDENTITY(1,1), KategoriID INT);
INSERT INTO #GiderKategorileri (KategoriID) VALUES 
    (@KatID_KiraGider), (@KatID_PersonelGider), (@KatID_OfisMalzeme);

-- Açıklama şablonları
CREATE TABLE #Aciklamalar (Idx INT IDENTITY(1,1), Sab NVARCHAR(200));
INSERT INTO #Aciklamalar (Sab) VALUES 
    (N'Müşteri tahsilat - banka havalesi'),
    (N'Tedarikçi ödeme - nakit'),
    (N'Kira ödemesi'),
    (N'Personel maaş ödemesi'),
    (N'Ofis malzemesi alımı'),
    (N'Ürün satış geliri'),
    (N'Hizmet bedeli tahsilat'),
    (N'Fatura ödemesi'),
    (N'Kargo ve nakliye ücreti'),
    (N'Bakım ve onarım gideri'),
    (N'Reklam ve pazarlama harcaması'),
    (N'Sigorta primi ödemesi'),
    (N'Vergi ödemesi'),
    (N'Elektrik faturası'),
    (N'Su faturası'),
    (N'Doğalgaz faturası'),
    (N'İnternet ve telefon faturası'),
    (N'Danışmanlık hizmeti'),
    (N'Yazılım lisans ücreti'),
    (N'Araç yakıt gideri'),
    (N'Temizlik hizmeti'),
    (N'Matbaa ve baskı gideri'),
    (N'Eğitim ve seminer ücreti'),
    (N'Depo kirası'),
    (N'Hammadde alımı'),
    (N'Stok devir işlemi'),
    (N'Avans ödemesi'),
    (N'Cari hesap mahsuplaşma'),
    (N'Döviz alım işlemi'),
    (N'Döviz satım işlemi');

-- Satır açıklamaları
CREATE TABLE #SatirAciklamalari (Idx INT IDENTITY(1,1), Sab NVARCHAR(200));
INSERT INTO #SatirAciklamalari (Sab) VALUES 
    (N'Banka hesabına giriş'),
    (N'Kasadan çıkış'),
    (N'Alıcılar hesabından düşüş'),
    (N'Satıcılara ödeme kaydı'),
    (N'Gelir kaydı'),
    (N'Gider tahakkuku'),
    (N'Havale ile ödeme'),
    (N'Nakit tahsilat'),
    (N'Çek ile tahsilat'),
    (N'Senet ile ödeme'),
    (N'Mahsup kaydı'),
    (N'Devir bakiye kaydı'),
    (N'KDV hesaplama'),
    (N'Stopaj kesintisi'),
    (N'Kur farkı kaydı'),
    (N'Vade farkı kaydı'),
    (N'Kasa sayım farkı'),
    (N'Banka masrafı'),
    (N'Kredi kartı tahsilat'),
    (N'POS cihazı tahsilat');

-- Para birimleri
CREATE TABLE #ParaBirimleri (Idx INT IDENTITY(1,1), Birim VARCHAR(3), MinKur DECIMAL(10,4), MaxKur DECIMAL(10,4));
INSERT INTO #ParaBirimleri (Birim, MinKur, MaxKur) VALUES 
    ('TRY', 1.0000, 1.0000),
    ('USD', 35.5000, 37.8000),
    ('EUR', 38.2000, 40.5000);

-- Durum değerleri
CREATE TABLE #Durumlar (Idx INT IDENTITY(1,1), Durum VARCHAR(10));
INSERT INTO #Durumlar (Durum) VALUES ('Aktif'), ('Aktif'), ('Aktif'), ('Aktif'), ('Aktif'),
                                      ('Aktif'), ('Aktif'), ('Aktif'), ('Pasif'), ('Iptal');
-- %80 Aktif, %10 Pasif, %10 İptal

-- ============================================================
-- Sayaçlar
-- ============================================================
DECLARE @FisSayaci INT = 5;  -- Mevcut 4 fiş var, 5'ten başla
DECLARE @ToplamFis INT = 6000;
DECLARE @i INT = 1;

-- ============================================================
-- ANA DÖNGÜ — 6000 FİŞ OLUŞTUR
-- ============================================================
PRINT '>> 6000 adet fiş ve satır oluşturma başlatılıyor...';

WHILE @i <= @ToplamFis
BEGIN
    -- Rastgele değerler üret
    DECLARE @RandFisTuru INT = (ABS(CHECKSUM(NEWID())) % 5) + 1;
    DECLARE @FisTuru VARCHAR(20) = (SELECT FisTuru FROM #FisTurleri WHERE Idx = @RandFisTuru);
    
    -- Tarih: 2025-01-01 ile 2026-03-24 arası rastgele (449 gün)
    DECLARE @GunFarki INT = ABS(CHECKSUM(NEWID())) % 449;
    DECLARE @FisTarihi DATE = DATEADD(DAY, @GunFarki, '2025-01-01');
    
    -- Dönem seç (tarihe göre)
    DECLARE @SeciliDonem INT;
    IF @FisTarihi < '2026-01-01'
        SET @SeciliDonem = @DonemID_2025;
    ELSE
        SET @SeciliDonem = @DonemID_2026;
    
    -- Kullanıcı (rastgele admin veya muhasebeci)
    DECLARE @RandKullanici INT = (ABS(CHECKSUM(NEWID())) % 2) + 1;
    DECLARE @SeciliKullanici INT = (SELECT KullaniciID FROM #Kullanicilar WHERE Idx = @RandKullanici);
    
    -- Fiş numarası (FIS-YYYY-NNNNNN formatı)
    DECLARE @FisYil INT = YEAR(@FisTarihi);
    DECLARE @FisNo VARCHAR(20) = 'FIS-' + CAST(@FisYil AS VARCHAR(4)) + '-' + RIGHT('000000' + CAST(@FisSayaci AS VARCHAR(6)), 6);
    
    -- Açıklama (rastgele)
    DECLARE @RandAciklama INT = (ABS(CHECKSUM(NEWID())) % 30) + 1;
    DECLARE @Aciklama NVARCHAR(500) = (SELECT Sab FROM #Aciklamalar WHERE Idx = @RandAciklama);
    
    -- Durum (rastgele)
    DECLARE @RandDurum INT = (ABS(CHECKSUM(NEWID())) % 10) + 1;
    DECLARE @SeciliDurum VARCHAR(10) = (SELECT Durum FROM #Durumlar WHERE Idx = @RandDurum);
    
    -- Oluşturma tarihi (fiş tarihinden 0-3 gün sonra, saat rastgele)
    DECLARE @SaatFarki INT = ABS(CHECKSUM(NEWID())) % 72;  -- 0-71 saat
    DECLARE @OlusturmaTarihi DATETIME = DATEADD(HOUR, @SaatFarki, CAST(@FisTarihi AS DATETIME));
    DECLARE @DakikaFarki INT = ABS(CHECKSUM(NEWID())) % 60;
    SET @OlusturmaTarihi = DATEADD(MINUTE, @DakikaFarki, @OlusturmaTarihi);
    DECLARE @SaniyeFarki INT = ABS(CHECKSUM(NEWID())) % 60;
    SET @OlusturmaTarihi = DATEADD(SECOND, @SaniyeFarki, @OlusturmaTarihi);
    
    -- Güncelleme tarihi (%30 ihtimalle)
    DECLARE @GuncellemeTarihi DATETIME = NULL;
    IF ABS(CHECKSUM(NEWID())) % 100 < 30
        SET @GuncellemeTarihi = DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 15) + 1, @OlusturmaTarihi);

    -- ============================================================
    -- FİŞ HEADER EKLE
    -- ============================================================
    INSERT INTO MuhasebeFisleri (FisNo, FisTarihi, FisTuru, Aciklama, DonemID, KullaniciID, Durum, OlusturmaTarihi, GuncellemeTarihi)
    VALUES (@FisNo, @FisTarihi, @FisTuru, @Aciklama, @SeciliDonem, @SeciliKullanici, @SeciliDurum, @OlusturmaTarihi, @GuncellemeTarihi);
    
    DECLARE @YeniFisID INT = SCOPE_IDENTITY();
    
    -- ============================================================
    -- FİŞ SATIRLARI EKLE (2-5 satır, borç = alacak dengeli)
    -- ============================================================
    DECLARE @SatirSayisi INT = (ABS(CHECKSUM(NEWID())) % 4) + 2;  -- 2 ila 5 satır
    -- Çift satır sayısı olsun ki borç-alacak dengeli olsun
    IF @SatirSayisi % 2 != 0
        SET @SatirSayisi = @SatirSayisi + 1;
    -- Max 4 çift = 4 satır çifti (en fazla 6)
    
    DECLARE @CiftSayisi INT = @SatirSayisi / 2;
    DECLARE @j INT = 1;
    
    WHILE @j <= @CiftSayisi
    BEGIN
        -- Rastgele tutar üret (düz olmayan sayılar)
        -- Ana tutar: 100-250000 arası
        DECLARE @AnaTutar DECIMAL(18,2);
        DECLARE @TutarTipi INT = ABS(CHECKSUM(NEWID())) % 100;
        
        IF @TutarTipi < 15
            -- Küçük tutar: 73.50 - 999.99 arası
            SET @AnaTutar = CAST(73.00 + (ABS(CHECKSUM(NEWID())) % 92700) / 100.0 AS DECIMAL(18,2));
        ELSE IF @TutarTipi < 40
            -- Orta küçük: 1000 - 9999 arası
            SET @AnaTutar = CAST(1000.00 + (ABS(CHECKSUM(NEWID())) % 899900) / 100.0 AS DECIMAL(18,2));
        ELSE IF @TutarTipi < 70
            -- Orta: 10000 - 49999 arası  
            SET @AnaTutar = CAST(10000.00 + (ABS(CHECKSUM(NEWID())) % 3999900) / 100.0 AS DECIMAL(18,2));
        ELSE IF @TutarTipi < 90
            -- Büyük: 50000 - 149999 arası
            SET @AnaTutar = CAST(50000.00 + (ABS(CHECKSUM(NEWID())) % 9999900) / 100.0 AS DECIMAL(18,2));
        ELSE
            -- Çok büyük: 150000 - 500000 arası
            SET @AnaTutar = CAST(150000.00 + (ABS(CHECKSUM(NEWID())) % 35000000) / 100.0 AS DECIMAL(18,2));
        
        -- Kuruş ekle (düz sayı olmasın diye)
        DECLARE @KurusEkleme INT = ABS(CHECKSUM(NEWID())) % 100;
        IF @KurusEkleme > 20  -- %80 ihtimalle kuruşlu tutar
            SET @AnaTutar = @AnaTutar + CAST((ABS(CHECKSUM(NEWID())) % 99 + 1) AS DECIMAL(18,2)) / 100.0;
        
        -- Borç hesabı seç
        DECLARE @RandBorcHesap INT = (ABS(CHECKSUM(NEWID())) % 12) + 1;
        DECLARE @BorcHesapID INT = (SELECT HesapID FROM #BorcHesaplari WHERE Idx = @RandBorcHesap);
        
        -- Alacak hesabı seç (borçtan farklı olsun)
        DECLARE @RandAlacakHesap INT = (ABS(CHECKSUM(NEWID())) % 12) + 1;
        DECLARE @AlacakHesapID INT = (SELECT HesapID FROM #AlacakHesaplari WHERE Idx = @RandAlacakHesap);
        -- Aynıysa değiştir
        IF @AlacakHesapID = @BorcHesapID
            SET @AlacakHesapID = (SELECT HesapID FROM #AlacakHesaplari WHERE Idx = ((@RandAlacakHesap % 12) + 1));
        
        -- Cari seç (%70 ihtimalle cari bağlı, %30 NULL)
        DECLARE @SeciliCariID INT = NULL;
        IF ABS(CHECKSUM(NEWID())) % 100 < 70
        BEGIN
            DECLARE @RandCari INT = (ABS(CHECKSUM(NEWID())) % 5) + 1;
            SET @SeciliCariID = (SELECT CariID FROM #Cariler WHERE Idx = @RandCari);
        END
        
        -- Kategori seç (fiş türüne göre)
        DECLARE @SeciliKategoriID INT = NULL;
        IF @FisTuru IN ('Tahsil', 'Acilis')
        BEGIN
            -- Gelir kategorisi
            DECLARE @RandGelirKat INT = (ABS(CHECKSUM(NEWID())) % 3) + 1;
            SET @SeciliKategoriID = (SELECT KategoriID FROM #GelirKategorileri WHERE Idx = @RandGelirKat);
        END
        ELSE IF @FisTuru IN ('Tediye', 'Kapanis')
        BEGIN
            -- Gider kategorisi
            DECLARE @RandGiderKat INT = (ABS(CHECKSUM(NEWID())) % 3) + 1;
            SET @SeciliKategoriID = (SELECT KategoriID FROM #GiderKategorileri WHERE Idx = @RandGiderKat);
        END
        ELSE  -- Mahsup
        BEGIN
            -- %50 gelir, %50 gider
            IF ABS(CHECKSUM(NEWID())) % 2 = 0
            BEGIN
                DECLARE @RandMahsupGelir INT = (ABS(CHECKSUM(NEWID())) % 3) + 1;
                SET @SeciliKategoriID = (SELECT KategoriID FROM #GelirKategorileri WHERE Idx = @RandMahsupGelir);
            END
            ELSE
            BEGIN
                DECLARE @RandMahsupGider INT = (ABS(CHECKSUM(NEWID())) % 3) + 1;
                SET @SeciliKategoriID = (SELECT KategoriID FROM #GiderKategorileri WHERE Idx = @RandMahsupGider);
            END
        END
        
        -- Para birimi (%85 TRY, %10 USD, %5 EUR)
        DECLARE @ParaBirimi VARCHAR(3) = 'TRY';
        DECLARE @KurDegeri DECIMAL(10,4) = 1.0000;
        DECLARE @ParaRand INT = ABS(CHECKSUM(NEWID())) % 100;
        IF @ParaRand >= 95
        BEGIN
            SET @ParaBirimi = 'EUR';
            SET @KurDegeri = CAST(38.2000 + (ABS(CHECKSUM(NEWID())) % 23000) / 10000.0 AS DECIMAL(10,4));
        END
        ELSE IF @ParaRand >= 85
        BEGIN
            SET @ParaBirimi = 'USD';
            SET @KurDegeri = CAST(35.5000 + (ABS(CHECKSUM(NEWID())) % 23000) / 10000.0 AS DECIMAL(10,4));
        END
        
        -- Satır açıklaması
        DECLARE @RandSatirAck1 INT = (ABS(CHECKSUM(NEWID())) % 20) + 1;
        DECLARE @SatirAck1 NVARCHAR(200) = (SELECT Sab FROM #SatirAciklamalari WHERE Idx = @RandSatirAck1);
        DECLARE @RandSatirAck2 INT = (ABS(CHECKSUM(NEWID())) % 20) + 1;
        DECLARE @SatirAck2 NVARCHAR(200) = (SELECT Sab FROM #SatirAciklamalari WHERE Idx = @RandSatirAck2);
        
        -- BORÇ SATIRI
        INSERT INTO FisSatirlari (FisID, HesapID, CariID, KategoriID, BorcTutari, AlacakTutari, Aciklama, ParaBirimi, KurDegeri)
        VALUES (@YeniFisID, @BorcHesapID, @SeciliCariID, @SeciliKategoriID, @AnaTutar, 0.00, @SatirAck1, @ParaBirimi, @KurDegeri);
        
        -- ALACAK SATIRI (aynı tutar, borç-alacak dengesi)
        -- Alacak satırında farklı cari olabilir
        DECLARE @AlacakCariID INT = @SeciliCariID;
        IF ABS(CHECKSUM(NEWID())) % 100 < 30 AND @SeciliCariID IS NOT NULL
        BEGIN
            DECLARE @RandCari2 INT = (ABS(CHECKSUM(NEWID())) % 5) + 1;
            SET @AlacakCariID = (SELECT CariID FROM #Cariler WHERE Idx = @RandCari2);
        END
        
        INSERT INTO FisSatirlari (FisID, HesapID, CariID, KategoriID, BorcTutari, AlacakTutari, Aciklama, ParaBirimi, KurDegeri)
        VALUES (@YeniFisID, @AlacakHesapID, @AlacakCariID, @SeciliKategoriID, 0.00, @AnaTutar, @SatirAck2, @ParaBirimi, @KurDegeri);
        
        SET @j = @j + 1;
    END
    
    SET @FisSayaci = @FisSayaci + 1;
    SET @i = @i + 1;
    
    -- Her 1000 fişte bir bilgi ver
    IF @i % 1000 = 1
        PRINT '  >> ' + CAST(@i - 1 AS VARCHAR(10)) + ' fiş oluşturuldu...';
END

-- ============================================================
-- Temizlik
-- ============================================================
DROP TABLE #FisTurleri;
DROP TABLE #Kullanicilar;
DROP TABLE #BorcHesaplari;
DROP TABLE #AlacakHesaplari;
DROP TABLE #Cariler;
DROP TABLE #GelirKategorileri;
DROP TABLE #GiderKategorileri;
DROP TABLE #Aciklamalar;
DROP TABLE #SatirAciklamalari;
DROP TABLE #ParaBirimleri;
DROP TABLE #Durumlar;

-- ============================================================
-- Özet Rapor
-- ============================================================
PRINT '';
PRINT '============================================================';
PRINT '>> 6000 adet fiş başarıyla oluşturuldu!';
PRINT '============================================================';

SELECT 'TOPLAM FİŞ SAYISI' AS Metrik, COUNT(*) AS Deger FROM MuhasebeFisleri
UNION ALL
SELECT 'TOPLAM SATIR SAYISI', COUNT(*) FROM FisSatirlari
UNION ALL
SELECT 'TOPLAM BORÇ TUTARI (TRY)', CAST(SUM(BorcTutari) AS INT) FROM FisSatirlari WHERE ParaBirimi = 'TRY'
UNION ALL
SELECT 'TOPLAM ALACAK TUTARI (TRY)', CAST(SUM(AlacakTutari) AS INT) FROM FisSatirlari WHERE ParaBirimi = 'TRY';

-- Fiş türlerine göre dağılım
SELECT FisTuru, COUNT(*) AS FisSayisi 
FROM MuhasebeFisleri 
GROUP BY FisTuru 
ORDER BY FisSayisi DESC;

-- Durum dağılımı
SELECT Durum, COUNT(*) AS FisSayisi 
FROM MuhasebeFisleri 
GROUP BY Durum 
ORDER BY FisSayisi DESC;

-- Dönem dağılımı
SELECT d.DonemAdi, COUNT(*) AS FisSayisi 
FROM MuhasebeFisleri f 
JOIN MuhasebeDonemleri d ON f.DonemID = d.DonemID 
GROUP BY d.DonemAdi 
ORDER BY d.DonemAdi;

PRINT '';
PRINT '>> İşlem tamamlandı.';
GO
