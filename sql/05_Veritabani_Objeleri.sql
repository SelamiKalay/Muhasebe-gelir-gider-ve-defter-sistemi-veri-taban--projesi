-- ============================================================
-- Muhasebe Fiş, Gelir-Gider ve Defter Sistemi
-- Veritabanı Objeleri: View, Stored Procedure, Trigger, Function
-- RDBMS: SQL Server (T-SQL)
-- ============================================================

USE MuhasebeDB;
GO

-- ************************************************************
-- 1. VIEW: Günlük Gelir-Gider Özeti
-- ************************************************************
-- Açıklama: Her gün için toplam gelir, toplam gider ve net
-- kâr/zarar durumunu özetler. Raporlama ekranlarında ve
-- dashboard'larda kullanılmak üzere tasarlanmıştır.
-- Gelir = Gelir türü hesaplardaki alacak toplamı
-- Gider = Gider türü hesaplardaki borç toplamı
-- ************************************************************

IF OBJECT_ID('vw_GunlukGelirGiderOzeti', 'V') IS NOT NULL
    DROP VIEW vw_GunlukGelirGiderOzeti;
GO

CREATE VIEW vw_GunlukGelirGiderOzeti
AS
SELECT
    f.FisTarihi                                                         AS Tarih,
    d.DonemAdi                                                          AS Donem,

    -- Günlük toplam gelir (TRY cinsine çevrilmiş)
    ISNULL(SUM(
        CASE WHEN hp.HesapTuru = 'Gelir'
             THEN fs.AlacakTutari * fs.KurDegeri
             ELSE 0
        END
    ), 0)                                                               AS ToplamGelir,

    -- Günlük toplam gider (TRY cinsine çevrilmiş)
    ISNULL(SUM(
        CASE WHEN hp.HesapTuru = 'Gider'
             THEN fs.BorcTutari * fs.KurDegeri
             ELSE 0
        END
    ), 0)                                                               AS ToplamGider,

    -- Net kâr/zarar
    ISNULL(SUM(
        CASE WHEN hp.HesapTuru = 'Gelir'
             THEN fs.AlacakTutari * fs.KurDegeri
             ELSE 0
        END
    ), 0) -
    ISNULL(SUM(
        CASE WHEN hp.HesapTuru = 'Gider'
             THEN fs.BorcTutari * fs.KurDegeri
             ELSE 0
        END
    ), 0)                                                               AS NetKarZarar,

    -- İşlem sayısı
    COUNT(DISTINCT f.FisID)                                              AS FisAdedi

FROM MuhasebeFisleri f
    INNER JOIN FisSatirlari fs          ON f.FisID    = fs.FisID
    INNER JOIN HesapPlani hp            ON fs.HesapID = hp.HesapID
    INNER JOIN MuhasebeDonemleri d      ON f.DonemID  = d.DonemID
WHERE f.Durum = 'Aktif'
  AND hp.HesapTuru IN ('Gelir', 'Gider')
GROUP BY f.FisTarihi, d.DonemAdi;
GO

-- Kullanım örneği:
-- SELECT * FROM vw_GunlukGelirGiderOzeti ORDER BY Tarih DESC;

PRINT '>> View [vw_GunlukGelirGiderOzeti] oluşturuldu.';
GO


-- ************************************************************
-- 2. STORED PROCEDURE: Yeni Muhasebe Fişi Ekleme
-- ************************************************************
-- Açıklama: Yeni bir fiş başlığı ve bağlı satırları atomik
-- bir TRANSACTION içinde ekler. Aşağıdaki kontrolleri yapar:
--   1. Dönemin açık olup olmadığını kontrol eder
--   2. Borç-alacak dengesini doğrular
--   3. Hata durumunda ROLLBACK yapar
-- Parametreler satır bilgileri JSON formatında alınır (SQL Server 2016+)
-- ************************************************************

IF OBJECT_ID('sp_FisEkle', 'P') IS NOT NULL
    DROP PROCEDURE sp_FisEkle;
GO

CREATE PROCEDURE sp_FisEkle
    @FisNo          VARCHAR(20),
    @FisTarihi      DATE,
    @FisTuru        VARCHAR(20),
    @Aciklama       NVARCHAR(500),
    @DonemID        INT,
    @KullaniciID    INT,
    @Satirlar       NVARCHAR(MAX)   -- JSON formatında satır dizisi
AS
BEGIN
    SET NOCOUNT ON;

    -- --------------------------------------------------------
    -- Değişken tanımlamaları
    -- --------------------------------------------------------
    DECLARE @ToplamBorc      DECIMAL(18,2);
    DECLARE @ToplamAlacak    DECIMAL(18,2);
    DECLARE @YeniFisID       INT;
    DECLARE @DonemDurum      VARCHAR(10);

    -- --------------------------------------------------------
    -- KONTROL 1: Dönem açık mı?
    -- --------------------------------------------------------
    SELECT @DonemDurum = Durum
    FROM MuhasebeDonemleri
    WHERE DonemID = @DonemID;

    IF @DonemDurum IS NULL
    BEGIN
        RAISERROR(N'Hata: Belirtilen dönem bulunamadı (DonemID: %d).', 16, 1, @DonemID);
        RETURN;
    END

    IF @DonemDurum = 'Kapali'
    BEGIN
        RAISERROR(N'Hata: Kapatılmış bir döneme fiş eklenemez (DonemID: %d).', 16, 1, @DonemID);
        RETURN;
    END

    -- --------------------------------------------------------
    -- KONTROL 2: JSON satırları geçerli mi?
    -- --------------------------------------------------------
    IF ISJSON(@Satirlar) = 0
    BEGIN
        RAISERROR(N'Hata: Satır verileri geçerli JSON formatında değil.', 16, 1);
        RETURN;
    END

    -- --------------------------------------------------------
    -- KONTROL 3: Borç-Alacak dengesi
    -- --------------------------------------------------------
    SELECT
        @ToplamBorc   = ISNULL(SUM(CAST(JSON_VALUE(s.[value], '$.BorcTutari')   AS DECIMAL(18,2))), 0),
        @ToplamAlacak = ISNULL(SUM(CAST(JSON_VALUE(s.[value], '$.AlacakTutari') AS DECIMAL(18,2))), 0)
    FROM OPENJSON(@Satirlar) s;

    IF @ToplamBorc <> @ToplamAlacak
    BEGIN
        RAISERROR(N'Hata: Borç-alacak dengesi tutmuyor. Borç: %s, Alacak: %s',
                  16, 1,
                  @ToplamBorc, @ToplamAlacak);
        RETURN;
    END

    IF @ToplamBorc = 0
    BEGIN
        RAISERROR(N'Hata: Fiş satırlarında en az bir borç-alacak kaydı bulunmalıdır.', 16, 1);
        RETURN;
    END

    -- --------------------------------------------------------
    -- TRANSACTION ile fiş ve satırları ekle
    -- --------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Fiş başlığını ekle
        INSERT INTO MuhasebeFisleri (FisNo, FisTarihi, FisTuru, Aciklama, DonemID, KullaniciID)
        VALUES (@FisNo, @FisTarihi, @FisTuru, @Aciklama, @DonemID, @KullaniciID);

        SET @YeniFisID = SCOPE_IDENTITY();

        -- Fiş satırlarını JSON'dan parse ederek ekle
        INSERT INTO FisSatirlari (FisID, HesapID, CariID, KategoriID, BorcTutari, AlacakTutari, Aciklama, ParaBirimi, KurDegeri)
        SELECT
            @YeniFisID,
            CAST(JSON_VALUE(s.[value], '$.HesapID')      AS INT),
            CAST(JSON_VALUE(s.[value], '$.CariID')        AS INT),
            CAST(JSON_VALUE(s.[value], '$.KategoriID')    AS INT),
            CAST(JSON_VALUE(s.[value], '$.BorcTutari')    AS DECIMAL(18,2)),
            CAST(JSON_VALUE(s.[value], '$.AlacakTutari')  AS DECIMAL(18,2)),
            JSON_VALUE(s.[value], '$.Aciklama'),
            ISNULL(JSON_VALUE(s.[value], '$.ParaBirimi'), 'TRY'),
            ISNULL(CAST(JSON_VALUE(s.[value], '$.KurDegeri') AS DECIMAL(10,4)), 1.0000)
        FROM OPENJSON(@Satirlar) s;

        COMMIT TRANSACTION;

        -- Başarılı sonuç
        SELECT
            @YeniFisID      AS FisID,
            @FisNo          AS FisNo,
            N'Başarılı'     AS Durum,
            N'Fiş ve satırları başarıyla eklendi.' AS Mesaj;

    END TRY
    BEGIN CATCH
        -- Hata durumunda geri al
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Hata bilgisini döndür
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Kullanım örneği:
-- EXEC sp_FisEkle
--     @FisNo       = 'FIS-2026-0005',
--     @FisTarihi   = '2026-03-01',
--     @FisTuru     = 'Mahsup',
--     @Aciklama    = N'Test fişi',
--     @DonemID     = 2,
--     @KullaniciID = 2,
--     @Satirlar    = N'[
--         {"HesapID":1,"CariID":null,"KategoriID":null,"BorcTutari":1000,"AlacakTutari":0,"Aciklama":"Test borç"},
--         {"HesapID":2,"CariID":null,"KategoriID":null,"BorcTutari":0,"AlacakTutari":1000,"Aciklama":"Test alacak"}
--     ]';

PRINT '>> Stored Procedure [sp_FisEkle] oluşturuldu.';
GO


-- ************************************************************
-- 3. TRIGGER: Fiş Güncelleme ve Silme Logu
-- ************************************************************
-- Açıklama: MuhasebeFisleri tablosundan bir kayıt UPDATE veya
-- DELETE edildiğinde, eski ve yeni değerleri JSON formatında
-- FisLog tablosuna yazar. Bu sayede tam denetim izi sağlanır.
-- ************************************************************

-- 3a. UPDATE Trigger
IF OBJECT_ID('trg_FisLog_Update', 'TR') IS NOT NULL
    DROP TRIGGER trg_FisLog_Update;
GO

CREATE TRIGGER trg_FisLog_Update
ON MuhasebeFisleri
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO FisLog (FisID, Islem, EskiDegerler, YeniDegerler, IslemTarihi, KullaniciID)
    SELECT
        d.FisID,
        'UPDATE',
        -- Eski değerler (deleted tablosundan — JSON formatında)
        (SELECT
            d.FisNo          AS FisNo,
            d.FisTarihi      AS FisTarihi,
            d.FisTuru        AS FisTuru,
            d.Aciklama       AS Aciklama,
            d.Durum          AS Durum,
            d.DonemID        AS DonemID
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        -- Yeni değerler (inserted tablosundan — JSON formatında)
        (SELECT
            i.FisNo          AS FisNo,
            i.FisTarihi      AS FisTarihi,
            i.FisTuru        AS FisTuru,
            i.Aciklama       AS Aciklama,
            i.Durum          AS Durum,
            i.DonemID        AS DonemID
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        GETDATE(),
        i.KullaniciID
    FROM deleted d
        INNER JOIN inserted i ON d.FisID = i.FisID;

    -- Güncelleme tarihini otomatik güncelle
    UPDATE f
    SET GuncellemeTarihi = GETDATE()
    FROM MuhasebeFisleri f
        INNER JOIN inserted i ON f.FisID = i.FisID;
END;
GO

-- 3b. DELETE Trigger
IF OBJECT_ID('trg_FisLog_Delete', 'TR') IS NOT NULL
    DROP TRIGGER trg_FisLog_Delete;
GO

CREATE TRIGGER trg_FisLog_Delete
ON MuhasebeFisleri
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO FisLog (FisID, Islem, EskiDegerler, YeniDegerler, IslemTarihi, KullaniciID)
    SELECT
        d.FisID,
        'DELETE',
        -- Silinen kayıt bilgileri (deleted tablosundan)
        (SELECT
            d.FisNo          AS FisNo,
            d.FisTarihi      AS FisTarihi,
            d.FisTuru        AS FisTuru,
            d.Aciklama       AS Aciklama,
            d.Durum          AS Durum,
            d.DonemID        AS DonemID,
            d.KullaniciID    AS KullaniciID
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        NULL,   -- Silme işleminde yeni değer yoktur
        GETDATE(),
        d.KullaniciID
    FROM deleted d;
END;
GO

PRINT '>> Trigger [trg_FisLog_Update] ve [trg_FisLog_Delete] oluşturuldu.';
GO


-- ************************************************************
-- 4. FUNCTION: Hesap Bakiyesi Hesaplama
-- ************************************************************
-- Açıklama: Verilen HesapID için tüm aktif fişlerdeki borç ve
-- alacak toplamlarından güncel bakiyeyi hesaplar.
-- Bakiye = Toplam Borç - Toplam Alacak
--   Pozitif bakiye → Borç bakiyesi (bu hesap borçludur)
--   Negatif bakiye → Alacak bakiyesi (bu hesap alacaklıdır)
-- Tüm tutarlar kur değerine göre TRY'ye çevrilir.
-- ************************************************************

IF OBJECT_ID('fn_HesapBakiyesi', 'FN') IS NOT NULL
    DROP FUNCTION fn_HesapBakiyesi;
GO

CREATE FUNCTION fn_HesapBakiyesi
(
    @HesapID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Bakiye DECIMAL(18,2);

    SELECT @Bakiye = ISNULL(
        SUM(fs.BorcTutari * fs.KurDegeri) - SUM(fs.AlacakTutari * fs.KurDegeri),
        0.00
    )
    FROM FisSatirlari fs
        INNER JOIN MuhasebeFisleri f ON fs.FisID = f.FisID
    WHERE fs.HesapID = @HesapID
      AND f.Durum = 'Aktif';

    RETURN @Bakiye;
END;
GO

-- Kullanım örnekleri:
-- Tek bir hesabın bakiyesi:
-- SELECT dbo.fn_HesapBakiyesi(1) AS KasaBakiyesi;
--
-- Tüm hesapların bakiyesi ile birlikte:
-- SELECT
--     hp.HesapKodu,
--     hp.HesapAdi,
--     dbo.fn_HesapBakiyesi(hp.HesapID) AS GuncelBakiye
-- FROM HesapPlani hp
-- WHERE hp.Aktif = 1
-- ORDER BY hp.HesapKodu;

PRINT '>> Function [fn_HesapBakiyesi] oluşturuldu.';
GO

PRINT '>> Tüm veritabanı objeleri başarıyla oluşturuldu.';
GO
