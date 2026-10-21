# NoSpace: Arena — Gizlilik Politikası TASLAĞI

**Yayımlanmamıştır. Tarih: 21 Ekim 2026.** Bu metin, mevcut Android koduna göre
hazırlanmış çalışma taslağıdır; yayıncı onayı ve aşağıdaki boşluklar tamamlanmadan
mağazaya veya uygulamaya konulmamalıdır. Production reklamları şu anda kapalıdır;
geliştirme/smoke build'leri Google test reklamlarını kullanır.

## Yayıncı ve iletişim — tamamlanacak

- Veri sorumlusu/yayıncı tüzel veya gerçek kişi ve ülke: **ONAY BEKLİYOR**.
- Gizlilik talepleri için iletişim adresi: **ONAY BEKLİYOR**.
- Yürürlük tarihi, hedef ülkeler, yaş grubu ve yayımlanacak politika adresi: **ONAY BEKLİYOR**.
- Kod/telif sahibinin Tuğra Hekimoğlu olması, mağaza yayıncısının hukuki kimliğini
  veya veri sorumlusu adresini tek başına doğrulamaz.

## Oyun verileri

Mevcut oyun kodu ilerlemeyi, oyun içi parayı, görevleri, yerel skorları/ghost
kayıtlarını, dil/ses/kontrol tercihlerini cihazda saklar. Oyuncu hesabı açma,
bulut profil eşitleme ve sunucuya skor gönderme akışı uygulanmamıştır. Bu tespit
üçüncü taraf reklam SDK'sının ağ işlemlerini kapsamaz. Reklamdan kazanılan ödül
oyunun yerel ilerlemesine işlenir; ayrı bir yayıncı analiz servisi bulunmamıştır.

## Reklamlar ve gizlilik seçimleri — yayın öncesi teyit edilecek bölüm

Android build'i Poing AdMob 5.1.0, Google GMA Next-Gen 1.4.0 ve UMP içerir.
Google'ın güncel SDK açıklaması; IP'den genel konum, reklam/uygulama etkileşimleri,
tanılama ve cihaz/hesap tanımlayıcılarının reklam, analiz ve kötüye kullanımın
önlenmesi için işlenebildiğini belirtir. Bu açıklama en güncel SDK'yı kapsar;
kurulu 1.4.0 sürümü, son build ve hesap seçenekleri için kapsam teyidi gereklidir.
Google ve varsa etkinleştirilecek reklam ortakları: **KESİN LİSTE ONAY BEKLİYOR**.
Test reklamları kullanılması, SDK'nın hiç veri işlemediği anlamına gelmez.

Uygulama UMP bilgilerini oturum başlangıcında günceller; reklam SDK'sını başlatma
ve reklam yükleme, bu sonuca ve geçerli reklam yapılandırmasına bağlıdır. UMP'nin
gerekli gördüğü durumlarda mevcut Ayarlar gizlilik-seçimleri eylemi yeniden seçim
formunu açar. Bu kontrol bir politika görüntüleyicisi değildir. Formların bölge,
yaş ve hesap kurallarına göre gerçek davranışı yayın öncesi doğrulanacaktır.

## Saklama, silme ve haklar — tamamlanacak

Cihazdaki oyun verilerinin Android uygulama-verisi temizleme/kaldırma akışı ve
kayıp ilerleme etkisi kullanıcıya açıklanmalıdır. Google/ortak sistemlerindeki
veriler için saklama süreleri, silme kanalı, uluslararası aktarım, alıcılar ve
ülkeye bağlı hakların uygulanması **YAYINCI ONAYI BEKLİYOR**; yerel veriyi silmenin
üçüncü taraf verisini de sildiği iddia edilmemektedir. Çocuklara yönelik kullanım,
veli talepleri ve hukuki dayanak metni hedef kitle belirlendikten sonra tamamlanır.

## Uygulamaya bağlama noktası

Settings tasarımı donmuştur. `scripts/ui/settings_panel.gd` içindeki `_open_legal()`
mevcut Legal görünümünü açar; `_open_privacy_options()` yalnız UMP seçenekleridir.
Onaylı HTTPS politika adresi geldikten sonra mevcut Legal içeriğine yerelleştirilmiş
erişim ekleme noktası ayrı görevde ele alınmalıdır; gerekli mağaza ve uygulama içi
erişim tamamlanmadan release onayı verilmemelidir. R2 kırık/uydurma link eklemez.

Kanıtlar: `scripts/meta/save_data.gd`, `save_store.gd`, `settings_store.gd`,
`leaderboard_store.gd`, `scripts/autoload/Economy.gd`, reklam/UMP servisleri.
SDK kapsam kaynağı: [Google GMA veri açıklaması](https://developers.google.com/admob/android/next-gen/privacy/play-data-disclosure).
Yayıncı yükümlülüğü: [Play User Data](https://support.google.com/googleplay/android-developer/answer/10144311).
