/**
 * Muhasebe Sistemi — Frontend JavaScript
 * ========================================
 * Fiş ekleme formu dinamik satır yönetimi ve fetch API ile backend bağlantısı.
 */

document.addEventListener('DOMContentLoaded', () => {
    // ── Fiş ekleme sayfası mı? ──
    const fisForm = document.getElementById('fisForm');
    if (fisForm) {
        initFisForm();
    }

    // Bugünün tarihini varsayılan olarak ayarla
    const fisTarihiInput = document.getElementById('fisTarihi');
    if (fisTarihiInput && !fisTarihiInput.value) {
        fisTarihiInput.value = new Date().toISOString().split('T')[0];
    }
});


// ══════════════════════════════════════════════
// FİŞ EKLEME FORMU
// ══════════════════════════════════════════════

let satirSayac = 0;

function initFisForm() {
    const btnSatirEkle = document.getElementById('btnSatirEkle');
    const fisForm = document.getElementById('fisForm');

    // İlk satırı otomatik ekle
    satirEkle();
    satirEkle();

    // Satır ekle butonu
    btnSatirEkle.addEventListener('click', () => satirEkle());

    // Form submit — fetch API ile POST
    fisForm.addEventListener('submit', (e) => {
        e.preventDefault();
        fisKaydet();
    });
}


/**
 * Yeni bir fiş satırı ekler (dinamik).
 * Hesap, Cari ve Kategori dropdown'ları HESAPLAR, CARILER, KATEGORILER
 * global değişkenlerinden (fis_ekle.html'de Jinja ile inject edilen) doldurulur.
 */
function satirEkle() {
    satirSayac++;
    const tbody = document.getElementById('satirlarBody');

    // Hesap <option>'ları
    let hesapOptions = '<option value="">Hesap seçin...</option>';
    if (typeof HESAPLAR !== 'undefined') {
        HESAPLAR.forEach(h => {
            hesapOptions += `<option value="${h.HesapID}">${h.HesapKodu} — ${h.HesapAdi}</option>`;
        });
    }

    // Cari <option>'ları
    let cariOptions = '<option value="">— Opsiyonel —</option>';
    if (typeof CARILER !== 'undefined') {
        CARILER.forEach(c => {
            cariOptions += `<option value="${c.CariID}">${c.CariKodu} — ${c.CariAdi}</option>`;
        });
    }

    // Kategori <option>'ları
    let katOptions = '<option value="">— Opsiyonel —</option>';
    if (typeof KATEGORILER !== 'undefined') {
        KATEGORILER.forEach(k => {
            katOptions += `<option value="${k.KategoriID}">[${k.Tur}] ${k.KategoriAdi}</option>`;
        });
    }

    const tr = document.createElement('tr');
    tr.id = `satir-${satirSayac}`;
    tr.innerHTML = `
        <td class="text-muted fw-semibold">${satirSayac}</td>
        <td>
            <select class="satir-input satir-hesap" required>
                ${hesapOptions}
            </select>
        </td>
        <td>
            <select class="satir-input satir-cari">
                ${cariOptions}
            </select>
        </td>
        <td>
            <select class="satir-input satir-kategori">
                ${katOptions}
            </select>
        </td>
        <td>
            <input type="number" class="satir-input satir-borc text-end" placeholder="0.00"
                   min="0" step="0.01" value="0" oninput="toplamHesapla()">
        </td>
        <td>
            <input type="number" class="satir-input satir-alacak text-end" placeholder="0.00"
                   min="0" step="0.01" value="0" oninput="toplamHesapla()">
        </td>
        <td>
            <input type="text" class="satir-input satir-aciklama" placeholder="Açıklama...">
        </td>
        <td class="text-center">
            <button type="button" class="btn-satir-sil" onclick="satirSil(${satirSayac})" title="Satırı sil">
                <i class="bi bi-trash3"></i>
            </button>
        </td>
    `;

    tbody.appendChild(tr);
    toplamHesapla();
}


/**
 * Belirli bir satırı siler.
 */
function satirSil(no) {
    const tr = document.getElementById(`satir-${no}`);
    if (tr) {
        tr.remove();
        toplamHesapla();
    }
}


/**
 * Toplam borç ve alacak hesaplar, denge durumunu gösterir.
 */
function toplamHesapla() {
    const borcInputlar = document.querySelectorAll('.satir-borc');
    const alacakInputlar = document.querySelectorAll('.satir-alacak');

    let toplamBorc = 0;
    let toplamAlacak = 0;

    borcInputlar.forEach(input => {
        toplamBorc += parseFloat(input.value) || 0;
    });
    alacakInputlar.forEach(input => {
        toplamAlacak += parseFloat(input.value) || 0;
    });

    document.getElementById('toplamBorc').textContent = toplamBorc.toLocaleString('tr-TR', {
        minimumFractionDigits: 2, maximumFractionDigits: 2
    });
    document.getElementById('toplamAlacak').textContent = toplamAlacak.toLocaleString('tr-TR', {
        minimumFractionDigits: 2, maximumFractionDigits: 2
    });

    // Denge durumu badge'i
    const dengeEl = document.getElementById('dengeStatus');
    const fark = Math.abs(toplamBorc - toplamAlacak);

    if (toplamBorc === 0 && toplamAlacak === 0) {
        dengeEl.className = 'badge bg-secondary';
        dengeEl.innerHTML = '—';
    } else if (fark < 0.01) {
        dengeEl.className = 'badge denge-ok';
        dengeEl.innerHTML = '<i class="bi bi-check-circle me-1"></i>Dengeli';
    } else {
        dengeEl.className = 'badge denge-fail';
        dengeEl.innerHTML = `<i class="bi bi-exclamation-triangle me-1"></i>Fark: ${fark.toLocaleString('tr-TR', {
            minimumFractionDigits: 2, maximumFractionDigits: 2
        })}`;
    }
}


/**
 * Fişi backend'e kaydeder (fetch API — POST).
 * Parametrik sorgular backend tarafında uygulanır; frontend
 * yalnızca JSON veri gönderir.
 */
async function fisKaydet() {
    const alertContainer = document.getElementById('fisAlertContainer');
    alertContainer.innerHTML = '';

    // ── Başlık verilerini topla ──
    const fisNo = document.getElementById('fisNo').value.trim();
    const fisTarihi = document.getElementById('fisTarihi').value;
    const fisTuru = document.getElementById('fisTuru').value;
    const aciklama = document.getElementById('aciklama').value.trim();
    const donemId = document.getElementById('donemId').value;

    // ── Satır verilerini topla ──
    const satirRows = document.querySelectorAll('#satirlarBody tr');
    const satirlar = [];

    satirRows.forEach(row => {
        const hesapId = row.querySelector('.satir-hesap')?.value;
        const cariId = row.querySelector('.satir-cari')?.value || null;
        const kategoriId = row.querySelector('.satir-kategori')?.value || null;
        const borc = parseFloat(row.querySelector('.satir-borc')?.value) || 0;
        const alacak = parseFloat(row.querySelector('.satir-alacak')?.value) || 0;
        const satAciklama = row.querySelector('.satir-aciklama')?.value || '';

        if (hesapId) {
            satirlar.push({
                hesapId: parseInt(hesapId),
                cariId: cariId ? parseInt(cariId) : null,
                kategoriId: kategoriId ? parseInt(kategoriId) : null,
                borcTutari: borc,
                alacakTutari: alacak,
                aciklama: satAciklama,
                paraBirimi: 'TRY',
                kurDegeri: 1.0
            });
        }
    });

    // ── Ön doğrulama ──
    if (!fisNo || !fisTarihi || !fisTuru || !donemId) {
        showAlert('danger', 'Lütfen tüm zorunlu alanları doldurun.');
        return;
    }

    if (satirlar.length === 0) {
        showAlert('danger', 'En az bir fiş satırı eklemelisiniz.');
        return;
    }

    // ── Kaydet butonu durumu ──
    const btnKaydet = document.getElementById('btnKaydet');
    const originalText = btnKaydet.innerHTML;
    btnKaydet.disabled = true;
    btnKaydet.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Kaydediliyor...';

    try {
        // ── fetch API ile POST ──
        const response = await fetch('/api/fis-ekle', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                fisNo,
                fisTarihi,
                fisTuru,
                aciklama,
                donemId: parseInt(donemId),
                satirlar
            })
        });

        const result = await response.json();

        if (result.success) {
            showAlert('success', result.message);

            // 2 saniye sonra fiş detay sayfasına yönlendir
            setTimeout(() => {
                window.location.href = `/fis/${result.fisId}`;
            }, 1500);
        } else {
            showAlert('danger', result.message);
        }
    } catch (error) {
        showAlert('danger', `Bağlantı hatası: ${error.message}`);
    } finally {
        btnKaydet.disabled = false;
        btnKaydet.innerHTML = originalText;
    }
}


/**
 * Alert mesajı gösterir.
 */
function showAlert(type, message) {
    const container = document.getElementById('fisAlertContainer');
    if (!container) return;

    const icon = type === 'success' ? 'check-circle' : 'exclamation-triangle';

    container.innerHTML = `
        <div class="alert alert-${type} alert-dismissible fade show glass-alert" role="alert">
            <i class="bi bi-${icon} me-2"></i>${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;

    // Sayfanın üstüne scroll
    window.scrollTo({ top: 0, behavior: 'smooth' });
}
