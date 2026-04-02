<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  macOS için ücretsiz, açık kaynaklı pano yöneticisi.
</p>

## Açıklama

DodoClip, SwiftUI ve SwiftData ile geliştirilmiş hafif, yerel bir pano yöneticisidir. Kopyaladığınız her şeyi takip etmenize ve pano geçmişinize anında erişmenize yardımcı olur.

## Özellikler

- **Pano geçmişi** - Kopyaladığınız her şeyi kalıcı olarak otomatik kaydeder
- **Arama** - Pano geçmişinizde öğeleri hızlıca bulun
- **Klavye kısayolları** - Global kısayollarla panonuza erişin (⇧⌘V)
- **Sabitlenmiş öğeler** - Önemli klipleri her zaman erişilebilir tutun
- **Akıllı koleksiyonlar** - Türe göre otomatik düzenleme (Bağlantılar, Resimler, Renkler)
- **Resim desteği** - Resimleri metinle birlikte kopyalayın ve yönetin
- **Bağlantı önizlemesi** - Otomatik favicon ve og:image çekme
- **Renk algılama** - Görsel önizleme ile hex renk kodlarını tanır
- **Yapıştırma yığını** - Sıralı yapıştırma modu (⇧⌘C)
- **Gizlilik kontrolleri** - Parola yöneticilerini ve belirli uygulamaları yoksay
- **Menü çubuğu erişimi** - Menü çubuğundan hızlı erişim

## Gereksinimler

- macOS 14.0 (Sonoma) veya üstü

## Kurulum

### Homebrew (önerilen)

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
xattr -cr /Applications/DodoClip.app
```

Veya tap eklemeden doğrudan yükleyin:

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### Doğrudan indirme

[Releases](https://github.com/bluewave-labs/dodoclip/releases) sayfasından en son `.dmg` dosyasını indirin, açın ve DodoClip'i Uygulamalar klasörünüze sürükleyin.

Kurulumdan sonra uygulamayı açmak için bu komutu çalıştırın:

```bash
xattr -cr /Applications/DodoClip.app
```

Ardından global yapıştırmanın çalışması için DodoClip'e macOS'ta şu gizlilik listelerinde izin verin:

- `Sistem Ayarları > Gizlilik ve Güvenlik > Erişilebilirlik`
- `Sistem Ayarları > Gizlilik ve Güvenlik > Giriş İzleme`, eğer DodoClip sisteminizde bu listede görünüyorsa

DodoClip açılıyor ama bir öğe seçildiğinde sadece pano güncelleniyor ve önceki uygulamaya yapıştırılmıyorsa, DodoClip'i bu listelerden kaldırın, yeniden ekleyin ve uygulamayı tekrar açın. Bazı macOS kurulumlarında bu yenileme kurulum veya güncellemeden sonra gerekli oluyor.

## Kaynak Koddan Derleme

1. Depoyu klonlayın:
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. Swift Package Manager ile derleyin:
   ```bash
   swift build
   ```

3. Uygulamayı çalıştırın:
   ```bash
   swift run DodoClip
   ```

## Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Pull Request göndermekten çekinmeyin.
