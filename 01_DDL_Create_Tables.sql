-- ============================================================
-- Muhasebe Fiş, Gelir-Gider ve Defter Sistemi
-- DDL Script — Tablo Oluşturma
-- RDBMS: SQL Server (T-SQL)
-- ============================================================

-- Veritabanı oluşturma
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'MuhasebeDB')
BEGIN
    CREATE DATABASE MuhasebeDB;
END
GO

USE MuhasebeDB;
GO

-- ============================================================
-- 1. Kullanicilar Tablosu
-- Sistemi kullanan personelin bilgilerini tutar.
-- ============================================================
CREATE TABLE Kullanicilar (
    KullaniciID     INT             IDENTITY(1,1)   NOT NULL,
    KullaniciAdi    VARCHAR(50)                     NOT NULL,
    SifreHash       VARCHAR(256)                    NOT NULL,   -- Şifre hash olarak saklanır
    AdSoyad         NVARCHAR(100)                   NOT NULL,
    Rol             VARCHAR(20)                     NOT NULL,
    Aktif           BIT                             NOT NULL    DEFAULT 1,
    KayitTarihi     DATETIME                        NOT NULL    DEFAULT GETDATE(),

    -- Kısıtlamalar
    CONSTRAINT PK_Kullanicilar          PRIMARY KEY (KullaniciID),
    CONSTRAINT UQ_KullaniciAdi          UNIQUE (KullaniciAdi),
    CONSTRAINT CK_Kullanicilar_Rol      CHECK (Rol IN ('Muhasebeci', 'Yonetici', 'SaltOkunur'))
);
GO

-- ============================================================
-- 2. MuhasebeDonemleri Tablosu
-- Yıllık/aylık muhasebe dönemlerini tanımlar.
-- ============================================================
CREATE TABLE MuhasebeDonemleri (
    DonemID           INT             IDENTITY(1,1)   NOT NULL,
    DonemAdi          NVARCHAR(50)                    NOT NULL,
    BaslangicTarihi   DATE                            NOT NULL,
    BitisTarihi       DATE                            NOT NULL,
    Durum             VARCHAR(10)                     NOT NULL    DEFAULT 'Acik',

    -- Kısıtlamalar
    CONSTRAINT PK_MuhasebeDonemleri             PRIMARY KEY (DonemID),
    CONSTRAINT UQ_DonemAdi                      UNIQUE (DonemAdi),
    CONSTRAINT CK_MuhasebeDonemleri_Durum       CHECK (Durum IN ('Acik', 'Kapali')),
    CONSTRAINT CK_MuhasebeDonemleri_Tarih       CHECK (BitisTarihi > BaslangicTarihi)
);
GO

-- ============================================================
-- 3. HesapPlani Tablosu
-- Muhasebe hesaplarını ağaç yapısında (self-referencing) tutar.
-- ============================================================
CREATE TABLE HesapPlani (
    HesapID       INT             IDENTITY(1,1)   NOT NULL,
    HesapKodu     VARCHAR(20)                     NOT NULL,
    HesapAdi      NVARCHAR(100)                   NOT NULL,
    HesapTuru     VARCHAR(20)                     NOT NULL,
    UstHesapID    INT                             NULL,           -- NULL ise ana hesaptır
    Aktif         BIT                             NOT NULL    DEFAULT 1,

    -- Kısıtlamalar
    CONSTRAINT PK_HesapPlani            PRIMARY KEY (HesapID),
    CONSTRAINT UQ_HesapKodu             UNIQUE (HesapKodu),
    CONSTRAINT CK_HesapPlani_Turu       CHECK (HesapTuru IN ('Aktif', 'Pasif', 'Gelir', 'Gider', 'Ozkaynaklar')),
    CONSTRAINT FK_HesapPlani_Ust        FOREIGN KEY (UstHesapID) REFERENCES HesapPlani(HesapID)
);
GO

-- ============================================================
-- 4. CariHesaplar Tablosu
-- Müşteri, tedarikçi, personel gibi cari hesapları tutar.
-- ============================================================
CREATE TABLE CariHesaplar (
    CariID      INT             IDENTITY(1,1)   NOT NULL,
    CariKodu    VARCHAR(20)                     NOT NULL,
    CariAdi     NVARCHAR(100)                   NOT NULL,
    CariTuru    VARCHAR(20)                     NOT NULL,
    VergiNo     VARCHAR(20)                     NULL,
    Telefon     VARCHAR(20)                     NULL,
    Adres       NVARCHAR(250)                   NULL,
    Aktif       BIT                             NOT NULL    DEFAULT 1,

    -- Kısıtlamalar
    CONSTRAINT PK_CariHesaplar          PRIMARY KEY (CariID),
    CONSTRAINT UQ_CariKodu              UNIQUE (CariKodu),
    CONSTRAINT CK_CariHesaplar_Turu     CHECK (CariTuru IN ('Musteri', 'Tedarikci', 'Personel', 'Diger'))
);
GO

-- ============================================================
-- 5. GelirGiderKategorileri Tablosu
-- Gelir ve gider kalemlerini sınıflandırır.
-- ============================================================
CREATE TABLE GelirGiderKategorileri (
    KategoriID    INT             IDENTITY(1,1)   NOT NULL,
    KategoriAdi   NVARCHAR(100)                   NOT NULL,
    Tur           VARCHAR(10)                     NOT NULL,

    -- Kısıtlamalar
    CONSTRAINT PK_GelirGiderKategorileri             PRIMARY KEY (KategoriID),
    CONSTRAINT UQ_KategoriAdi_Tur                    UNIQUE (KategoriAdi, Tur),
    CONSTRAINT CK_GelirGiderKategorileri_Tur         CHECK (Tur IN ('Gelir', 'Gider'))
);
GO

-- ============================================================
-- 6. MuhasebeFisleri Tablosu
-- Fiş başlık bilgilerini tutar (her fiş bir veya daha fazla satırdan oluşur).
-- ============================================================
CREATE TABLE MuhasebeFisleri (
    FisID               INT             IDENTITY(1,1)   NOT NULL,
    FisNo               VARCHAR(20)                     NOT NULL,
    FisTarihi           DATE                            NOT NULL,
    FisTuru             VARCHAR(20)                     NOT NULL,
    Aciklama            NVARCHAR(500)                   NULL,
    DonemID             INT                             NOT NULL,
    KullaniciID         INT                             NOT NULL,
    Durum               VARCHAR(10)                     NOT NULL    DEFAULT 'Aktif',
    OlusturmaTarihi     DATETIME                        NOT NULL    DEFAULT GETDATE(),
    GuncellemeTarihi    DATETIME                        NULL,

    -- Kısıtlamalar
    CONSTRAINT PK_MuhasebeFisleri               PRIMARY KEY (FisID),
    CONSTRAINT UQ_FisNo                         UNIQUE (FisNo),
    CONSTRAINT CK_MuhasebeFisleri_Turu          CHECK (FisTuru IN ('Mahsup', 'Tahsil', 'Tediye', 'Acilis', 'Kapanis')),
    CONSTRAINT CK_MuhasebeFisleri_Durum         CHECK (Durum IN ('Aktif', 'Pasif', 'Iptal')),
    CONSTRAINT FK_MuhasebeFisleri_Donem         FOREIGN KEY (DonemID) REFERENCES MuhasebeDonemleri(DonemID),
    CONSTRAINT FK_MuhasebeFisleri_Kullanici     FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);
GO

-- ============================================================
-- 7. FisSatirlari Tablosu
-- Fişe bağlı borç-alacak kalemlerini tutar.
-- ============================================================
CREATE TABLE FisSatirlari (
    SatirID         INT             IDENTITY(1,1)   NOT NULL,
    FisID           INT                             NOT NULL,
    HesapID         INT                             NOT NULL,
    CariID          INT                             NULL,       -- Opsiyonel: her satır cariye bağlı olmayabilir
    KategoriID      INT                             NULL,       -- Opsiyonel: gelir-gider kategorisi
    BorcTutari      DECIMAL(18,2)                   NOT NULL    DEFAULT 0.00,
    AlacakTutari    DECIMAL(18,2)                   NOT NULL    DEFAULT 0.00,
    Aciklama        NVARCHAR(250)                   NULL,
    ParaBirimi      VARCHAR(3)                      NOT NULL    DEFAULT 'TRY',
    KurDegeri       DECIMAL(10,4)                   NOT NULL    DEFAULT 1.0000,

    -- Kısıtlamalar
    CONSTRAINT PK_FisSatirlari                  PRIMARY KEY (SatirID),
    CONSTRAINT FK_FisSatirlari_Fis              FOREIGN KEY (FisID)       REFERENCES MuhasebeFisleri(FisID),
    CONSTRAINT FK_FisSatirlari_Hesap            FOREIGN KEY (HesapID)     REFERENCES HesapPlani(HesapID),
    CONSTRAINT FK_FisSatirlari_Cari             FOREIGN KEY (CariID)      REFERENCES CariHesaplar(CariID),
    CONSTRAINT FK_FisSatirlari_Kategori         FOREIGN KEY (KategoriID)  REFERENCES GelirGiderKategorileri(KategoriID),
    CONSTRAINT CK_FisSatirlari_BorcPositif      CHECK (BorcTutari >= 0),
    CONSTRAINT CK_FisSatirlari_AlacakPositif    CHECK (AlacakTutari >= 0),
    -- İş kuralı: Bir satırda hem borç hem alacak aynı anda pozitif olamaz
    CONSTRAINT CK_FisSatirlari_BorcAlacak       CHECK (NOT (BorcTutari > 0 AND AlacakTutari > 0))
);
GO

-- ============================================================
-- 8. FisLog Tablosu
-- Fiş üzerinde yapılan değişikliklerin tarihçesini tutar (audit trail).
-- ============================================================
CREATE TABLE FisLog (
    LogID           INT             IDENTITY(1,1)   NOT NULL,
    FisID           INT                             NOT NULL,
    Islem           VARCHAR(10)                     NOT NULL,
    EskiDegerler    NVARCHAR(MAX)                   NULL,       -- JSON formatında eski değerler
    YeniDegerler    NVARCHAR(MAX)                   NULL,       -- JSON formatında yeni değerler
    IslemTarihi     DATETIME                        NOT NULL    DEFAULT GETDATE(),
    KullaniciID     INT                             NULL,

    -- Kısıtlamalar
    CONSTRAINT PK_FisLog                PRIMARY KEY (LogID),
    CONSTRAINT CK_FisLog_Islem          CHECK (Islem IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO

-- ============================================================
-- İndeksler — Performans optimizasyonu
-- ============================================================

-- Fiş tarihine göre hızlı arama
CREATE NONCLUSTERED INDEX IX_MuhasebeFisleri_Tarih
    ON MuhasebeFisleri (FisTarihi);
GO

-- Fiş satırlarında hesap bazlı arama
CREATE NONCLUSTERED INDEX IX_FisSatirlari_HesapID
    ON FisSatirlari (HesapID);
GO

-- Fiş satırlarında cari bazlı arama
CREATE NONCLUSTERED INDEX IX_FisSatirlari_CariID
    ON FisSatirlari (CariID)
    WHERE CariID IS NOT NULL;
GO

-- Fiş satırlarında fiş bazlı arama
CREATE NONCLUSTERED INDEX IX_FisSatirlari_FisID
    ON FisSatirlari (FisID);
GO

-- Log tablosunda fiş bazlı arama
CREATE NONCLUSTERED INDEX IX_FisLog_FisID
    ON FisLog (FisID);
GO

PRINT '>> Tüm tablolar ve indeksler başarıyla oluşturuldu.';
GO
