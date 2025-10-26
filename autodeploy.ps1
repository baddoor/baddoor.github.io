# autodeploy.ps1
# 自动生成并部署 Hexo 博客

function Deploy-Blog {
    try {
        Write-Host "Cleaning old files..."
        npx hexo clean

        Write-Host "Generating site..."
        npx hexo g

        Write-Host "Deploying to GitHub Pages..."
        npx hexo d

        Write-Host "Deployment completed!"
    }
    catch {
        Write-Host "Deployment error: $($_.Exception.Message)"
    }
}

Deploy-Blog
