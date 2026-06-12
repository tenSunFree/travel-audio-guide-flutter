# Changelog

---

## v1.0.3 - 2026-06-13

### Fixed
- 修正 CD workflow 未還原 Firebase 設定檔，導致 release build 在靜態分析階段失敗的問題

## v1.0.2 - 2026-06-12

### Added
- 新增歡迎畫面與啟動畫面動畫
- 新增圖片快取機制，支援依顯示尺寸設定快取圖片大小，減少不必要的圖片解碼與記憶體消耗

## v1.0.1 - 2026-05-12

### Added
- 新增詳情頁導航與分享按鈕

## v1.0.0 - 2026-05-07

### Added
- 旅遊語音導覽核心功能
- 景點列表、搜尋、排序與篩選
- 活動列表與行事曆整合
- 語音導覽下載與離線播放
- 本機資料庫快取（Drift + SQLite）
- 背景資料同步機制
- GitHub Actions CI/CD 自動化流程
- 本機開發腳本（`scripts/check.ps1`、`scripts/codegen.ps1`、`scripts/release.ps1`）