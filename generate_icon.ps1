Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Colors
$bg = [System.Drawing.ColorTranslator]::FromHtml("#FDF7F2")
$brownDark = [System.Drawing.ColorTranslator]::FromHtml("#5D4037")
$brownLight = [System.Drawing.ColorTranslator]::FromHtml("#8D6E63")
$orange = [System.Drawing.ColorTranslator]::FromHtml("#FFA726")
$gold = [System.Drawing.ColorTranslator]::FromHtml("#FFD700")
$goldDark = [System.Drawing.ColorTranslator]::FromHtml("#FBC02D")

$brushBg = New-Object System.Drawing.SolidBrush($bg)
$brushWallet = New-Object System.Drawing.SolidBrush($brownDark)
$brushFlap = New-Object System.Drawing.SolidBrush($brownLight)
$brushCoin = New-Object System.Drawing.SolidBrush($gold)
$brushCoinEdge = New-Object System.Drawing.Pen($goldDark, 4)
$penStitch = New-Object System.Drawing.Pen($orange, 8)
$penStitch.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash

# Background
$g.FillRectangle($brushBg, 0, 0, 1024, 1024)

# Wallet Dimensions
$rectWallet = New-Object System.Drawing.Rectangle 162, 262, 700, 500

# Draw Coins (sticking out top)
$g.FillEllipse($brushCoin, 300, 200, 150, 150)
$g.DrawEllipse($brushCoinEdge, 300, 200, 150, 150)

$g.FillEllipse($brushCoin, 450, 180, 150, 150)
$g.DrawEllipse($brushCoinEdge, 450, 180, 150, 150)

$g.FillEllipse($brushCoin, 600, 220, 150, 150)
$g.DrawEllipse($brushCoinEdge, 600, 220, 150, 150)


# Draw Wallet Body
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddArc($rectWallet.X, $rectWallet.Y, 100, 100, 180, 90)
$path.AddArc($rectWallet.X + $rectWallet.Width - 100, $rectWallet.Y, 100, 100, 270, 90)
$path.AddArc($rectWallet.X + $rectWallet.Width - 100, $rectWallet.Y + $rectWallet.Height - 100, 100, 100, 0, 90)
$path.AddArc($rectWallet.X, $rectWallet.Y + $rectWallet.Height - 100, 100, 100, 90, 90)
$path.CloseFigure()

$g.FillPath($brushWallet, $path)

# Draw Stitching
$g.DrawPath($penStitch, $path)

# Draw Flap (Strap)
$rectFlap = New-Object System.Drawing.Rectangle 462, 262, 100, 300
$g.FillRectangle($brushFlap, $rectFlap)
$g.DrawRectangle($penStitch, $rectFlap)

# Button on Flap
$g.FillEllipse($brushCoin, 482, 480, 60, 60)

$bmp.Save("d:\budget_tracker\assets\icon\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host "Improved Icon generated successfully at d:\budget_tracker\assets\icon\icon.png"
