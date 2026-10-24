# 影片一鍵轉 MP3 工具（自動匹配原影片音訊速率）

專為 Windows 設計的免安裝影音轉檔工具。自動透過 FFprobe 精準解析影片原始音訊位元速率（Bitrate），以完全對應的音質轉換為 MP3，不浪費磁碟空間、不損失原始音質。

---

## 快速開始（免安裝 Git，直接下載使用）

1. [點此下載 ZIP 壓縮包](https://github.com/Xuan52766/video-to-mp3/archive/refs/heads/main.zip)，並解壓縮至電腦任意資料夾。
2. 確認電腦已安裝 FFmpeg（若尚未安裝，請參考下方 [前置需求](#前置需求) 進行安裝）。
3. **滑鼠拖曳轉檔**：直接將任何影片檔案（或包含影片的資料夾），用滑鼠拖曳到 `convert_to_mp3.bat` 上放開，程式即會在同個目錄下輸出轉換後的 `.mp3` 檔案。

---

## 核心特色

1. **自動精準匹配音訊位元速率 (Bitrate Matching)**：
   - 透過 `ffprobe` 讀取影片第一音軌的真實位元速率（例如 128 kbps、192 kbps、256 kbps、320 kbps 等）。
   - 自動將目標 MP3 的編碼速率設為完全吻合的數值，避免不必要的音質二次壓縮損耗，也不會無謂膨脹檔案容量。
2. **原生 MP3 無損直出 (Stream Copy)**：
   - 若來源影片本身的音訊軌本來就是 MP3 編碼，程式會自動啟用 `-c:a copy` 直接提取，零轉碼失真且瞬間完成。
3. **智慧回退容錯機制**：
   - 若影片容器（如某些動態 VBR AAC 的 MP4/MKV）未在中繼資料記錄固定速率，程式會自動採用高品質 192 kbps 進行編碼，確保轉檔流程不中斷。
4. **特殊字元支援**：
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

- `convert_to_mp3.bat`：Windows 快速啟動捷徑，支援滑鼠拖放、目錄雙擊與 UTF-8 編碼支援。
- `convert_to_mp3.ps1`：PowerShell 核心處理邏輯（自動呼叫 FFprobe 解析參數並執行 FFmpeg）。
- `.gitignore`：防呆忽略清單，防止本地測試的大容量影片誤傳。
- `LICENSE`：MIT 開源授權條款。

---

## 授權條款

本專案採用 [MIT License](LICENSE) 開源授權，歡迎自由修改、分發與個人使用。
