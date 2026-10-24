[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Files
)

# 設定主控台輸出編碼為 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 檢查 FFmpeg 與 FFprobe 是否已安裝
$ffmpegCmd = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
$ffprobeCmd = Get-Command "ffprobe" -ErrorAction SilentlyContinue

if (-not $ffmpegCmd -or -not $ffprobeCmd) {
    Write-Host ""
    Write-Host "[錯誤] 系統中找不到 ffmpeg 或 ffprobe！" -ForegroundColor Red
    Write-Host "建議安裝方式（開啟 PowerShell 貼上並執行）：" -ForegroundColor Cyan
    Write-Host "   winget install Gyan.FFmpeg" -ForegroundColor Yellow
    Write-Host "   或至官網下載：https://ffmpeg.org/download.html`n" -ForegroundColor Gray
    exit 1
}

# 支援的常見影片副檔名
$supportedExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".flv", ".webm", ".wmv", ".ts", ".m4v", ".m2ts")
$targetFiles = [System.Collections.Generic.List[string]]::new()

# 2. 收集待處理檔案（使用 -LiteralPath 避免檔名包含 [ ] 等特殊符號被視為萬用字元）
if ($Files -and $Files.Count -gt 0) {
    foreach ($item in $Files) {
        $cleanPath = $item.Trim('"').Trim("'")
        if (Test-Path -LiteralPath $cleanPath -PathType Container) {
            Get-ChildItem -LiteralPath $cleanPath -File | Where-Object { $supportedExtensions -contains $_.Extension.ToLower() } | ForEach-Object {
                $targetFiles.Add($_.FullName)
            }
        } elseif (Test-Path -LiteralPath $cleanPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($cleanPath).ToLower()
            if ($supportedExtensions -contains $ext) {
                $targetFiles.Add((Resolve-Path -LiteralPath $cleanPath).Path)
            }
        }
    }
} else {
    # 未傳入參數：優先掃描腳本所在目錄，再掃描當前工作目錄
    $searchDirs = @()
    if ($PSScriptRoot -and (Test-Path -LiteralPath $PSScriptRoot)) { $searchDirs += $PSScriptRoot }
    $currentDir = (Get-Location).Path
    if ($searchDirs -notcontains $currentDir) { $searchDirs += $currentDir }

    foreach ($sDir in $searchDirs) {
        Get-ChildItem -LiteralPath $sDir -File | Where-Object { $supportedExtensions -contains $_.Extension.ToLower() } | ForEach-Object {
            if (-not $targetFiles.Contains($_.FullName)) {
                $targetFiles.Add($_.FullName)
            }
        }
    }
}

if ($targetFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "[提示] 未找到任何支援的影片檔案。" -ForegroundColor Yellow
    Write-Host "使用方式說明：" -ForegroundColor Cyan
    Write-Host "  1. 拖放：將影片檔案直接拖曳放到 convert_to_mp3.bat 圖示上。"
    Write-Host "  2. 雙擊：將影片放在此資料夾內，直接按兩下執行 convert_to_mp3.bat。"
    Write-Host ""
    exit 0
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  影片一鍵轉 MP3 工具 (自動匹配原音訊位元速率)" -ForegroundColor Cyan
Write-Host "  找到 $($targetFiles.Count) 個待處理影片" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$successCount = 0
$failCount = 0

foreach ($file in $targetFiles) {
    $dir = [System.IO.Path]::GetDirectoryName($file)
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $outputMp3 = Join-Path $dir "$fileNameWithoutExt.mp3"

    Write-Host ""
    Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[正在處理] $fileNameWithoutExt" -ForegroundColor White
    Write-Host "來源路徑: $file" -ForegroundColor DarkGray

    # 3. 取得音訊編碼名稱
    $codecOutput = & ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" 2>$null
    $codec = if ($codecOutput) { ($codecOutput -join "").Trim() } else { "" }

    if (-not $codec) {
        Write-Host "  [跳過] 未偵測到音訊串流或無法讀取音軌。" -ForegroundColor Yellow
        $failCount++
        continue
    }

    # 4. 判斷音訊編碼
    if ($codec.ToLower() -eq "mp3") {
        Write-Host "  -> 原音訊即為 MP3，採用無損直接複製 (-c:a copy)，極速且零失真！" -ForegroundColor Green
        & ffmpeg -hide_banner -loglevel error -stats -y -i "$file" -map 0:a:0 -c:a copy "$outputMp3"
    } else {
        # 取得位元速率 (bit_rate)
        $rawBitrateOutput = & ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>$null
        $rawBitrate = if ($rawBitrateOutput) { ($rawBitrateOutput -join "").Trim() } else { "" }

        # 若 stream 查無，嘗試從 tag BPS 讀取
        if (-not $rawBitrate -or $rawBitrate -eq "N/A" -or $rawBitrate -eq "0") {
            $bpsTagOutput = & ffprobe -v error -select_streams a:0 -show_entries stream_tags=BPS,BPS-eng -of default=noprint_wrappers=1:nokey=1 "$file" 2>$null
            if ($bpsTagOutput) {
                $rawBitrate = ($bpsTagOutput -join "").Trim()
            }
        }

        $parsedBps = 0.0
        $bitrateArg = "192k"

        if ($rawBitrate -and $rawBitrate -ne "N/A" -and [double]::TryParse($rawBitrate, [ref]$parsedBps) -and $parsedBps -gt 0) {
            $targetKbps = [math]::Round($parsedBps / 1000)
            Write-Host "  -> 原音訊編碼: $codec | 偵測到原始速率: ${targetKbps} kbps" -ForegroundColor Cyan
            Write-Host "  -> 採用目標速率: ${targetKbps}k 進行 libmp3lame 轉碼..." -ForegroundColor DarkCyan
            $bitrateArg = "${targetKbps}k"
        } else {
            Write-Host "  -> 原音訊編碼: $codec | 容器未記錄固定位元速率" -ForegroundColor Yellow
            Write-Host "  -> 自動採用高品質 192 kbps 進行轉碼..." -ForegroundColor Yellow
            $bitrateArg = "192k"
        }

        & ffmpeg -hide_banner -loglevel error -stats -y -i "$file" -map 0:a:0 -c:a libmp3lame -b:a $bitrateArg "$outputMp3"
    }

    # 使用 -LiteralPath 精準檢查輸出檔案（支援包含中括號 [] 的檔名）
    if (Test-Path -LiteralPath $outputMp3) {
        $outSize = (Get-Item -LiteralPath $outputMp3).Length
        $sizeMB = [math]::Round($outSize / 1MB, 2)
        Write-Host "  [完成] 轉檔成功！檔案大小: $sizeMB MB" -ForegroundColor Green
        Write-Host "  輸出位置: $outputMp3" -ForegroundColor Gray
        $successCount++
    } else {
        Write-Host "  [失敗] FFmpeg 執行後未產生目標 MP3 檔案。" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  處理完成！成功: $successCount 個，失敗/跳過: $failCount 個" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
