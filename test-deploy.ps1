# --- 1. Configuration ---
$BlogPath = "C:\Users\swire\my-blog"
$NpxPath = "C:\Program Files\nodejs\npx.cmd"

# --- 2. Script Core ---

# Validate Path
if (-not (Test-Path $NpxPath)) {
    Write-Host "ERROR: npx.cmd not found at '$NpxPath'." -ForegroundColor Red
    exit
}

Write-Host "This is a diagnostic script." -ForegroundColor Cyan
Write-Host "Press ENTER to manually trigger the Hexo deployment." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit."

# --- 3. Main Loop ---
while ($true) {
    # Check if a key has been pressed without blocking the script
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        # If the key is Enter, trigger deployment
        if ($key.VirtualKeyCode -eq 13) {
            
            Write-Host ""
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Enter key pressed. Manually starting deployment..." -ForegroundColor Green
            
            try {
                Write-Host "--> Running 'hexo clean'..."
                Start-Process -FilePath $NpxPath -ArgumentList "hexo clean" -WorkingDirectory $BlogPath -Wait -NoNewWindow
                
                Write-Host "--> Running 'hexo g -d'..."
                Start-Process -FilePath $NpxPath -ArgumentList "hexo g -d" -WorkingDirectory $BlogPath -Wait -NoNewWindow
                
                Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Deployment complete." -ForegroundColor Green
            }
            catch {
                Write-Host "ERROR: An error occurred during deployment: $($_.Exception.Message)" -ForegroundColor Red
            }
            finally {
                Write-Host "----------------------------------------------------"
                Write-Host "Test finished. You can press Enter again or Ctrl+C to exit." -ForegroundColor Cyan
            }
        }
    }
    
    # Sleep for a short interval to prevent high CPU usage
    Start-Sleep -Milliseconds 200
}