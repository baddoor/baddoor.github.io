# --- Vercel + Gitee 私有仓库自动部署脚本 ---
# 此脚本监控文件变化，自动推送源码到 Gitee 私有仓库
# Vercel 会自动从 Gitee 拉取代码并构建部署

# --- 1. Configuration ---
$BlogPath = "C:\Users\swire\my-blog"
$WatchFolder = Join-Path $BlogPath "source\_posts"
$GitPath = "git"  # 假设 git 在 PATH 中
# 延迟推送的时间（秒）
$DebounceSeconds = 3

# --- 2. State Variables ---
$global:changePending = $false
$global:lastChangeTimestamp = $null

# --- 3. Script Core ---

# Validate paths
if (-not (Test-Path $WatchFolder)) {
    Write-Host "ERROR: Watch folder '$WatchFolder' not found." -ForegroundColor Red
    exit
}

# 检查是否是 Git 仓库
if (-not (Test-Path (Join-Path $BlogPath ".git"))) {
    Write-Host "WARNING: This is not a Git repository. Please run 'git init' first." -ForegroundColor Yellow
    Write-Host "Please follow the setup instructions to initialize Git repository." -ForegroundColor Yellow
    exit
}

# Create the file system watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchFolder
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define the action for when a file change is detected
$FileChangedAction = {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): File change detected. Source code will be pushed after delay..." -ForegroundColor Yellow
    $global:changePending = $true
    $global:lastChangeTimestamp = Get-Date
}

# Register the file events
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $FileChangedAction
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $FileChangedAction
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $FileChangedAction
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $FileChangedAction

# Initial script startup message
Write-Host "=== Vercel + Gitee 自动部署脚本启动 ===" -ForegroundColor Cyan
Write-Host "正在监控: '$WatchFolder'" -ForegroundColor Cyan
Write-Host "检测到文件变化后，将自动推送源码到 Gitee 私有仓库" -ForegroundColor Cyan
Write-Host "Vercel 会自动构建和部署" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止监控" -ForegroundColor Cyan
Write-Host ""

# --- 4. Main Loop ---
while ($true) {
    if ($global:changePending) {
        # Calculate elapsed time
        $elapsed = (Get-Date) - $global:lastChangeTimestamp
        
        # If enough time has passed, push source code
        if ($elapsed.TotalSeconds -ge $DebounceSeconds) {
            Write-Host ""
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): 文件变化稳定 $($DebounceSeconds) 秒，开始推送源码..." -ForegroundColor Green
            
            # Reset the flag immediately
            $global:changePending = $false
            
            try {
                # Change to blog directory
                Set-Location $BlogPath
                
                Write-Host "--> 添加所有变更到 Git..." -ForegroundColor White
                & $GitPath add .
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Git add failed with exit code $LASTEXITCODE"
                }
                
                Write-Host "--> 提交变更..." -ForegroundColor White
                $commitMessage = "Auto update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                & $GitPath commit -m $commitMessage
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "No changes to commit or commit failed." -ForegroundColor Yellow
                } else {
                    Write-Host "--> 推送到 Gitee 私有仓库..." -ForegroundColor White
                    & $GitPath push origin main
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Git push failed with exit code $LASTEXITCODE"
                    }
                    
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): 源码推送完成！" -ForegroundColor Green
                    Write-Host "Vercel 将自动检测到变更并开始构建部署" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "ERROR: 推送过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "请检查 Git 配置和网络连接" -ForegroundColor Red
            }
            finally {
                Write-Host "----------------------------------------------------" -ForegroundColor Gray
                Write-Host "继续监控 '$WatchFolder'..." -ForegroundColor Cyan
                Write-Host ""
            }
        }
    }
    
    # Wait for 1 second before checking again
    Start-Sleep -Seconds 1
}