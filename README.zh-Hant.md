<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip 圖示">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  一個免費開源的 macOS 剪貼簿管理器。
</p>

<p align="center">
  <a href="README.md">🇺🇸 English</a> •
  <a href="README.de.md">🇩🇪 Deutsch</a> •
  <a href="README.tr.md">🇹🇷 Türkçe</a> •
  <a href="README.fr.md">🇫🇷 Français</a> •
  <a href="README.es.md">🇪🇸 Español</a> •
  <a href="README.zh-Hans.md">🇨🇳 简体中文</a> •
  <a href="README.zh-Hant.md">🇨🇳 繁體中文</a>
</p>



https://github.com/user-attachments/assets/f281b654-a0a2-4883-b09c-21aa2cd3efb4



## 簡介

DodoClip 是一個使用 SwiftUI 和 SwiftData 建立的輕量級原生剪貼簿管理器。它可以幫助您追蹤所有複製內容，並即時存取剪貼簿歷史記錄。

## 功能特性

- **剪貼簿歷史** - 自動儲存您複製的所有內容並持久化儲存
- **搜尋功能** - 快速在剪貼簿歷史中尋找項目
- **OCR 支援** - 在複製的圖片中尋找任何文字
- **鍵盤快速鍵** - 使用全域快速鍵存取剪貼簿（⇧⌘V）
- **釘選項目** - 讓重要的剪貼內容始終可存取
- **智慧型集合** - 按類型自動組織（連結、圖片、顏色）
- **圖片支援** - 與文字一起複製和管理圖片
- **連結預覽** - 自動取得網站圖示和 og:image
- **顏色偵測** - 識別十六進位顏色代碼並提供視覺化預覽
- **貼上堆疊** - 順序貼上模式（⇧⌘C）
- **隱私權控制** - 忽略密碼管理器和特定應用程式
- **選單列存取** - 從選單列快速存取

## 系統需求

- macOS 14.0 (Sonoma) 或更高版本

## 安裝方法

### Homebrew（推薦）

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
xattr -cr /Applications/DodoClip.app
```

或直接安裝而不新增 tap：

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### 直接下載

從 [Releases](https://github.com/bluewave-labs/dodoclip/releases) 頁面下載最新的 `.dmg` 檔案，開啟後將 DodoClip 拖到「應用程式」檔案夾。

安裝後，執行以下命令以允許應用程式開啟：

```bash
xattr -cr /Applications/DodoClip.app
```

## 從原始碼建立

1. 複製儲存庫：
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. 使用 Swift Package Manager 建立：
   ```bash
   swift build
   ```

3. 執行應用程式：
   ```bash
   swift run DodoClip
   ```

## 常見問題

### 「DodoClip 已損毀，無法開啟」

此訊息出現是因為應用程式未使用 Apple 開發者憑證簽署，實際上並未損毀。要解決此問題，請開啟「終端機」並執行：

```bash
xattr -cr /Applications/DodoClip.app
```

然後再次開啟 DodoClip。

### 我按兩下了應用程式但什麼都沒發生

DodoClip 是一個**選單列應用程式** - 它在背景執行，並在選單列（螢幕右上角）顯示為一個圖示。按 **⇧⌘V**（Shift+Command+V）即可開啟剪貼簿面板。

### 如何結束 DodoClip？

點選選單列中的 DodoClip 圖示並選擇「結束」，或在面板開啟時按 **⌘Q**。

### DodoClip 是否安全地儲存我的剪貼簿資料？

您的剪貼簿歷史記錄使用 SwiftData 本機儲存在您的 Mac 上。不會傳送任何資料到外部伺服器。您還可以啟用隱私權控制來忽略密碼管理器和特定應用程式。

### 我可以搜尋圖片中的文字嗎？

可以！DodoClip 支援 OCR（光學字元辨識）。當您複製圖片時，它會自動擷取其中的文字。然後您就可以在剪貼簿面板中搜尋這些文字。

### 貼上堆疊功能是什麼？

貼上堆疊（⇧⌘C）可以讓您排列多個項目並按順序逐個貼上。非常適合填寫表單或移動多個資料片段。

## 授權條款

本專案採用 MIT 授權條款 - 詳情請參閱 [LICENSE](LICENSE) 檔案。

## 貢獻

歡迎貢獻！請隨時提交 Pull Request。

---

Dodo 應用程式家族的一部分（[DodoPulse](https://github.com/bluewave-labs/dodopulse)、[DodoTidy](https://github.com/bluewave-labs/dodotidy)、[DodoClip](https://github.com/bluewave-labs/dodoclip)、[DodoNest](https://github.com/bluewave-labs/dodonest)）
