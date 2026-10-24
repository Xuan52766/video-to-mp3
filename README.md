# 影片一鍵轉 MP3 工具（智慧 ABR 動態位元速率匹配）

專為 Windows 設計的免安裝影音轉檔工具。自動結合 FFprobe 與 FFmpeg 雙層深度解析影片原始音訊平均位元速率，並採用 LAME 的智慧 ABR（Average Bit Rate，動態平均位元速率）技術轉換為 MP3。遇到複雜聲效自動借用高碼率以防破音、安靜間歇自動降低碼率，在精準還原原始動態音質的同時，完全不浪費磁碟空間。

---

## 快速開始（免安裝 Git，直接下載使用）

1. [點此下載 ZIP 壓縮包](https://github.com/Xuan52766/video-to-mp3/archive/refs/heads/main.zip)，並解壓縮至電腦任意資料夾。
2. 確認電腦已安裝 FFmpeg（若尚未安裝，請參考下方 [前置需求](#前置需求) 進行安裝）。
3. **滑鼠拖曳轉檔**：直接將任何影片檔案（或包含影片的資料夾），用滑鼠拖曳到 `convert_to_mp3.bat` 上放開，程式即會在同個目錄下輸出轉換後的 `.mp3` 檔案。

---

## 核心特色

1. **三層深度探測平均位元速率 (Deep Bitrate Detection)**：
   - 第一層：透過 `ffprobe` 讀取串流標頭中的 `bit_rate`。
   - 第二層：讀取容器標籤（如 `BPS`、`BPS-eng`）。
   - 第三層：調用 `ffmpeg` 解析串流特徵，精準捕捉動態 VBR AAC 等容器未標明固定數值的平均速率，不再輕易回退到保底值。
2. **智慧 ABR 動態編碼 (Adaptive Bit Rate, `-abr 1`)**：
   - 不採用生硬的固定碼率（CBR），而是啟用 LAME 的 ABR 動態模型。
   - 遇到複雜波形（如交響樂、強烈爆破音）時自動向高碼率浮動（最高可達 320 kbps）以保留瞬態細節；安靜人聲時調低碼率，全片平均值完全對齊原片，兼具極致音質與空間效益。
3. **原生 MP3 無損直出 (Stream Copy)**：
   - 若來源影片本身的音訊軌本來就是 MP3 編碼，程式會自動啟用 `-c:a copy` 直接提取，零轉碼失真且瞬間完成。
4. **智慧回退容錯機制**：
   - 若極端情況下完全無法探測出位元速率，程式會自動採用高品質 192 kbps ABR 進行動態編碼，確保轉檔流程不中斷。
5. **特殊字元與多檔支援**：
   - 完整支援檔名包含中括號（例如 `[1080P]` 等特殊符號）的檔案轉換。

---

## 操作方式

### 方式 A：滑鼠拖曳（最簡便）
將一個或多個影片檔案（或整個資料夾），直接用滑鼠拖曳放到 `convert_to_mp3.bat` 圖示上即可自動開始。

### 方式 B：資料夾批次處理
將 `convert_to_mp3.bat` 與 `convert_to_mp3.ps1` 放在存放影片的目錄下，直接雙擊執行 `convert_to_mp3.bat`，工具會自動掃描並轉出該目錄內所有支援的影片。

---

## 前置需求

本工具依賴開源多媒體引擎 FFmpeg。若電腦尚未安裝：

- **Windows 10 / 11 快速安裝**：  
  開啟 PowerShell，貼上以下指令並執行：
  ```powershell
  winget install Gyan.FFmpeg
  ```
  *(安裝完成後關閉並重開終端機即可生效)*
- **手動下載**：前往 [FFmpeg 官方網站](https://ffmpeg.org/download.html) 下載並加入系統環境變數 PATH。

---

## 檔案說明

- `convert_to_mp3.bat`：Windows 快速啟動捷徑（純 ASCII 規格，徹底相容 Windows 各語系 `cmd.exe`）。
- `convert_to_mp3.ps1`：PowerShell 核心處理邏輯（多層探測、智慧 ABR 轉碼與 UTF-8 BOM 支援）。
- `.gitignore`：防呆忽略清單，防止本地測試的大容量影片誤傳。
- `LICENSE`：MIT 開源授權條款。

---

## 授權條款

本專案採用 [MIT License](LICENSE) 開源授權，歡迎自由修改、分發與個人使用。
