# NoSpace: Arena — Data Safety çalışma sayfası (TASLAK)

21 Ekim 2026. Console'a gönderilmiş bir beyan değildir. Kaynak kod, paketlenmiş
SDK/manifest kanıtı ve Google belgeleri ayrı kanıt türleridir; manifest izni tek
başına belirli bir verinin toplandığını kanıtlamaz. Yayıncı nihai formu onaylamalıdır.

## Doğrulanmış envanter

| Bileşen | Projede kanıt | Sınır |
|---|---|---|
| Yerel profil/tercihler, görev ve skor | `scripts/meta/`, `Economy.SAVE_PATH`, `SeedManager` | Yayıncı sunucusuna gönderim/hesap açma/ayrı analytics istemcisi bulunmadı; SDK trafiği hariç |
| Reklam | Poing 5.1.0; `addons/admob/android/bin/ads/poing_godot_admob_ads.gd`: GMA Next-Gen **1.4.0** | Test modu açık, production kapalı; yalnız rewarded proje akışı |
| UMP | `ads_consent_coordinator.gd`, `poing_ads_bridge.gd`, `settings_panel.gd` | Oturum güncellemesi, gerekli form, koşullu privacy-options erişimi; hesap mesajları bilinmiyor |
| Billing | Vendored 3.3.0 / Billing 9.1.0; varsayılan katalog boş | Yeni ürün/satış eklenmedi; mevcut SDK kapsamı son formda ayrıca incelenmeli |
| Android izinleri | R1 final manifest: internet/network state, iki ad-ID izni, basic phone state, Billing, wake lock, foreground service, dynamic receiver | Kod kamera/konum/rehber/mikrofon izni istemiyor; SDK ekleri final manifestten tekrar kontrol edilmeli |

## SDK veri eşlemesi — yayıncı teyidi gerekli

[Google'ın GMA açıklaması](https://developers.google.com/admob/android/next-gen/privacy/play-data-disclosure)
**yalnız en güncel sürüm içindir**; güncel kurulum rehberi 1.5.0 gösterirken proje
1.4.0 kullanır. Aşağıdakiler beyan adaylarıdır; 1.4.0'a ait kesin trafik ölçümü
veya nihai Console yanıtı olarak okunmamalıdır. SDK güncellemesi R2 kapsamına alınmadı.

| Veri / önerilen Play alanı | Google belgesine dayalı aday | Onaylanacak |
|---|---|---|
| IP → yaklaşık konum | Toplama/paylaşma adayı | 1.4.0 ve son hesap yapılandırmasındaki gerçek kapsam |
| Uygulama/reklam etkileşimleri → app activity | Toplama/paylaşma adayı | Reklam, analiz, kötüye kullanım önleme amaçlarının eşlemesi |
| Tanılama → app info/performance | Toplama/paylaşma adayı | Gerçekte kullanılan alt alanlar; crash log dahil mi ayrıca doğrula |
| Reklam/app-set/uygulanabilir hesap ID'leri → device or other IDs | Toplama/paylaşma adayı | İzinler, cihaz ayarları, limited ads ve ortakların kapsamı |

Google son SDK verisi için TLS aktarımı tarif eder; bu bilgi tüm uygulama/ortaklar
için otomatik bir güvenlik beyanı değildir. Saklama süresi ve formdaki geçici işleme,
zorunlu/isteğe bağlı veri, kullanıcı silme ve paylaşım istisnası alanları henüz
onaylanmadı. UMP izni reddi, her SDK verisinin durduğu veya sıfır veri toplandığı
şeklinde yorumlanmamalıdır.

## Gönderim öncesi tamamlanacaklar

1. Yayıncı kimliği/ülke/iletişim, hedef yaş/ülkeler ve gerçek politika HTTPS adresi.
2. Yayıncıdan Android App ID ve aynı app'e ait rewarded unit; sahiplik/format/hesap
   onayı. AdMob IDs signing secret değildir, fakat gerçek hesap ayarları repo dışı kalır.
3. AdMob Privacy & messaging: yayımlanan mesajlar, bölgeler, child-directed ve
   under-age ayarları; isteğe bağlı özellik/mediation listesi ve `app-ads.txt` doğrulaması.
4. Son SDK sürümüne uygun veri dokümanı, son artifact envanteri ve native cihaz
   doğrulamasıyla yukarıdaki toplama/paylaşma/amaç/saklama/silme alanlarını kesinleştir.
5. Politikayı yayıncı onayıyla yayımla; mevcut Legal görünümünden erişimi ayrı görevde
   bağla, Play Console politika alanı/Data Safety ve reklam/hedef kitle beyanlarını tamamla.

Referanslar: [GMA yapılandırması](https://developers.google.com/admob/android/next-gen/quick-start),
[UMP akışı](https://developers.google.com/admob/android/next-gen/privacy),
[Play User Data](https://support.google.com/googleplay/android-developer/answer/10144311).
Bu çalışma sayfası hesap erişimi veya yayımlama işlemi gerçekleştirmez.
