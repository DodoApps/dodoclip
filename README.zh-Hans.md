<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip 图标">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  一个免费开源的 macOS 剪贴板管理器。
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



## 简介

DodoClip 是一个使用 SwiftUI 和 SwiftData 构建的轻量级原生剪贴板管理器。它可以帮助您跟踪所有复制内容，并即时访问剪贴板历史记录。

## 功能特性

- **剪贴板历史** - 自动保存您复制的所有内容并持久化存储
- **搜索功能** - 快速在剪贴板历史中查找项目
- **OCR 支持** - 在复制的图片中查找任何文字
- **键盘快捷键** - 使用全局快捷键访问剪贴板（⇧⌘V）
- **固定项目** - 让重要的剪贴内容始终可访问
- **智能集合** - 按类型自动组织（链接、图片、颜色）
- **图片支持** - 与文本一起复制和管理图片
- **链接预览** - 自动获取网站图标和 og:image
- **颜色检测** - 识别十六进制颜色代码并提供可视化预览
- **粘贴栈** - 顺序粘贴模式（⇧⌘C）
- **隐私控制** - 忽略密码管理器和特定应用
- **菜单栏访问** - 从菜单栏快速访问

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本

## 安装方法

### Homebrew（推荐）

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
xattr -cr /Applications/DodoClip.app
```

或直接安装而不添加 tap：

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### 直接下载

从 [Releases](https://github.com/bluewave-labs/dodoclip/releases) 页面下载最新的 `.dmg` 文件，打开后将 DodoClip 拖到应用程序文件夹。

安装后，运行以下命令以允许应用打开：

```bash
xattr -cr /Applications/DodoClip.app
```

## 从源代码构建

1. 克隆仓库：
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. 使用 Swift Package Manager 构建：
   ```bash
   swift build
   ```

3. 运行应用：
   ```bash
   swift run DodoClip
   ```

## 常见问题

### "DodoClip 已损坏，无法打开"

此消息出现是因为应用未使用 Apple 开发者证书签名，实际上并未损坏。要解决此问题，请打开终端并运行：

```bash
xattr -cr /Applications/DodoClip.app
```

然后再次打开 DodoClip。

### 我双击了应用但什么都没发生

DodoClip 是一个**菜单栏应用** - 它在后台运行，并在菜单栏（屏幕右上角）显示为一个图标。按 **⇧⌘V**（Shift+Command+V）即可打开剪贴板面板。

### 如何退出 DodoClip？

点击菜单栏中的 DodoClip 图标并选择"退出"，或在面板打开时按 **⌘Q**。

### DodoClip 是否安全地存储我的剪贴板数据？

您的剪贴板历史记录使用 SwiftData 本地存储在您的 Mac 上。不会发送任何数据到外部服务器。您还可以启用隐私控制来忽略密码管理器和特定应用。

### 我可以搜索图片中的文字吗？

可以！DodoClip 支持 OCR（光学字符识别）。当您复制图片时，它会自动提取其中的文字。然后您就可以在剪贴板面板中搜索这些文字。

### 粘贴栈功能是什么？

粘贴栈（⇧⌘C）可以让您排列多个项目并按顺序逐个粘贴。非常适合填写表单或移动多个数据片段。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。

## 贡献

欢迎贡献！请随时提交 Pull Request。

---

Dodo 应用家族的一部分（[DodoPulse](https://github.com/bluewave-labs/dodopulse)、[DodoTidy](https://github.com/bluewave-labs/dodotidy)、[DodoClip](https://github.com/bluewave-labs/dodoclip)、[DodoNest](https://github.com/bluewave-labs/dodonest)）
