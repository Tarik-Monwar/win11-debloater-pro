#Requires -Version 5.1
<#
.SYNOPSIS
    DebloaterPRO - Premium Windows Debloat Tool
.DESCRIPTION
    A premium GUI-based Windows debloater with animated progress,
    categorized app removal, system tweaks, and profile management.
.NOTES
    Must be run as Administrator.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
#  ADMIN CHECK
# ============================================================
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show(
        "DebloaterPRO must be run as Administrator.`n`nRight-click the script and choose 'Run as Administrator'.",
        "Elevation Required",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Shield
    ) | Out-Null
    exit 1
}

# ============================================================
#  LOGGING
# ============================================================
$logDir  = "$env:USERPROFILE\DebloaterPRO"
$logPath = "$logDir\debloat_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
Start-Transcript -Path $logPath -Append -NoClobber | Out-Null

function Write-Log {
    param([string]$Msg, [string]$Level = "INFO")
    $stamp = Get-Date -Format "HH:mm:ss"
    $line  = "[$stamp] [$Level] $Msg"
    Write-Host $line
    Add-Content -Path $logPath -Value $line -ErrorAction SilentlyContinue
}

# ============================================================
#  APP DEFINITIONS  (Name, PackagePattern, Description, Risk)
# ============================================================
$AppList = [ordered]@{
    "Social & Communication" = @(
        [PSCustomObject]@{ Name="TikTok";         Pkg="*TikTok*";                   Desc="Short-video social app";          Risk="Safe" }
        [PSCustomObject]@{ Name="Instagram";      Pkg="*Instagram*";                Desc="Photo/video social platform";     Risk="Safe" }
        [PSCustomObject]@{ Name="Facebook";       Pkg="*Facebook*";                 Desc="Social networking app";           Risk="Safe" }
        [PSCustomObject]@{ Name="Twitter / X";    Pkg="*Twitter*";                  Desc="Microblogging social app";        Risk="Safe" }
        [PSCustomObject]@{ Name="WhatsApp";       Pkg="*WhatsApp*";                 Desc="Messaging platform";              Risk="Safe" }
        [PSCustomObject]@{ Name="Skype";          Pkg="*SkypeApp*";                 Desc="Legacy Microsoft video calls";    Risk="Safe" }
    )
    "Microsoft Bloat" = @(
        [PSCustomObject]@{ Name="Bing News";      Pkg="*BingNews*";                 Desc="Microsoft news widget";           Risk="Safe" }
        [PSCustomObject]@{ Name="Bing Weather";   Pkg="*BingWeather*";              Desc="Microsoft weather widget";        Risk="Safe" }
        [PSCustomObject]@{ Name="Bing Finance";   Pkg="*BingFinance*";              Desc="Microsoft finance widget";        Risk="Safe" }
        [PSCustomObject]@{ Name="Bing Sports";    Pkg="*BingSports*";               Desc="Microsoft sports widget";         Risk="Safe" }
        [PSCustomObject]@{ Name="Feedback Hub";   Pkg="*WindowsFeedbackHub*";       Desc="Microsoft feedback collector";    Risk="Safe" }
        [PSCustomObject]@{ Name="Your Phone";     Pkg="*YourPhone*";                Desc="Phone link companion app";        Risk="Safe" }
        [PSCustomObject]@{ Name="Get Help";       Pkg="*GetHelp*";                  Desc="Microsoft help center app";       Risk="Safe" }
        [PSCustomObject]@{ Name="Mixed Reality";  Pkg="*MixedReality*";             Desc="VR/AR portal app";                Risk="Safe" }
        [PSCustomObject]@{ Name="3D Viewer";      Pkg="*Microsoft.Microsoft3DViewer*"; Desc="3D model viewer";              Risk="Safe" }
        [PSCustomObject]@{ Name="MSN Maps";       Pkg="*WindowsMaps*";              Desc="Built-in maps application";       Risk="Safe" }
        [PSCustomObject]@{ Name="Alarms";         Pkg="*WindowsAlarms*";            Desc="Alarms and clock app";            Risk="Safe" }
    )
    "Gaming & Xbox" = @(
        [PSCustomObject]@{ Name="Xbox App";       Pkg="*XboxApp*";                  Desc="Xbox gaming hub";                 Risk="Safe" }
        [PSCustomObject]@{ Name="Xbox Game Bar";  Pkg="*XboxGamingOverlay*";        Desc="In-game overlay (Win+G)";         Risk="Caution" }
        [PSCustomObject]@{ Name="Xbox Identity";  Pkg="*XboxIdentityProvider*";     Desc="Xbox account service";            Risk="Caution" }
        [PSCustomObject]@{ Name="Xbox Speech";    Pkg="*XboxSpeechToTextOverlay*";  Desc="Xbox voice recognition overlay";  Risk="Safe" }
        [PSCustomObject]@{ Name="Solitaire";      Pkg="*MicrosoftSolitaireCollection*"; Desc="Solitaire card game collection"; Risk="Safe" }
        [PSCustomObject]@{ Name="Disney Game";    Pkg="*DisneyMagicKingdoms*";      Desc="Preinstalled Disney game";        Risk="Safe" }
        [PSCustomObject]@{ Name="Candy Crush";    Pkg="*CandyCrush*";               Desc="Preinstalled Candy Crush game";   Risk="Safe" }
        [PSCustomObject]@{ Name="Minecraft Trial";Pkg="*MinecraftUWP*";             Desc="Minecraft trial edition";         Risk="Safe" }
    )
    "Productivity & Office" = @(
        [PSCustomObject]@{ Name="Microsoft Teams";Pkg="*MicrosoftTeams*";           Desc="Teams collaboration app";         Risk="Safe" }
        [PSCustomObject]@{ Name="Clipchamp";      Pkg="*Clipchamp*";                Desc="Video editor by Microsoft";       Risk="Safe" }
        [PSCustomObject]@{ Name="Power Automate"; Pkg="*PowerAutomateDesktop*";     Desc="Desktop automation tool";         Risk="Safe" }
        [PSCustomObject]@{ Name="OneNote";        Pkg="*OneNote*";                  Desc="Microsoft note-taking app";       Risk="Safe" }
        [PSCustomObject]@{ Name="Office Hub";     Pkg="*OfficeLens*";               Desc="Office document scanner";         Risk="Safe" }
        [PSCustomObject]@{ Name="To Do";          Pkg="*Todos*";                    Desc="Microsoft To Do list app";        Risk="Safe" }
    )
    "Media & Entertainment" = @(
        [PSCustomObject]@{ Name="Spotify";        Pkg="*SpotifyMusic*";             Desc="Music streaming app";             Risk="Safe" }
        [PSCustomObject]@{ Name="Netflix";        Pkg="*Netflix*";                  Desc="Video streaming app";             Risk="Safe" }
        [PSCustomObject]@{ Name="Disney+";        Pkg="*DisneyPlus*";               Desc="Disney streaming platform";       Risk="Safe" }
        [PSCustomObject]@{ Name="Groove Music";   Pkg="*ZuneMusic*";                Desc="Legacy Microsoft music player";   Risk="Safe" }
        [PSCustomObject]@{ Name="Movies & TV";    Pkg="*ZuneVideo*";                Desc="Microsoft video player";          Risk="Safe" }
        [PSCustomObject]@{ Name="Windows Media";  Pkg="*WindowsMediaPlayer*";       Desc="Legacy media player";             Risk="Safe" }
    )
}

# ============================================================
#  COLOR PALETTE  (Catppuccin Mocha-inspired, darker premium)
# ============================================================
$C = @{
    BG        = [System.Drawing.ColorTranslator]::FromHtml("#0d0d1a")
    Surface   = [System.Drawing.ColorTranslator]::FromHtml("#13132b")
    Surface2  = [System.Drawing.ColorTranslator]::FromHtml("#1a1a35")
    Overlay   = [System.Drawing.ColorTranslator]::FromHtml("#252545")
    Border    = [System.Drawing.ColorTranslator]::FromHtml("#2a2a55")
    Accent    = [System.Drawing.ColorTranslator]::FromHtml("#7c6af7")
    AccentLt  = [System.Drawing.ColorTranslator]::FromHtml("#a89df9")
    Green     = [System.Drawing.ColorTranslator]::FromHtml("#3ddc84")
    GreenDk   = [System.Drawing.ColorTranslator]::FromHtml("#2ab36a")
    Red       = [System.Drawing.ColorTranslator]::FromHtml("#ff5c5c")
    Yellow    = [System.Drawing.ColorTranslator]::FromHtml("#f9c74f")
    Text      = [System.Drawing.ColorTranslator]::FromHtml("#e0e0ff")
    TextDim   = [System.Drawing.ColorTranslator]::FromHtml("#8888bb")
    TextMuted = [System.Drawing.ColorTranslator]::FromHtml("#555577")
    White     = [System.Drawing.Color]::White
}

$FontTitle   = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontSub     = New-Object System.Drawing.Font("Segoe UI", 9,  [System.Drawing.FontStyle]::Regular)
$FontBold    = New-Object System.Drawing.Font("Segoe UI", 9,  [System.Drawing.FontStyle]::Bold)
$FontMono    = New-Object System.Drawing.Font("Consolas",  8,  [System.Drawing.FontStyle]::Regular)
$FontCat     = New-Object System.Drawing.Font("Segoe UI", 8,  [System.Drawing.FontStyle]::Bold)
$FontBtn     = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontCounter = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# ============================================================
#  HELPER: Draw rounded rectangle
# ============================================================
Add-Type @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
public static class GfxHelper {
    public static GraphicsPath RoundRect(Rectangle r, int radius) {
        GraphicsPath p = new GraphicsPath();
        int d = radius * 2;
        p.AddArc(r.Left, r.Top, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Top, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.Left, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }
}
"@

# ============================================================
#  MAIN FORM
# ============================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "DebloaterPRO"
$Form.Size            = New-Object System.Drawing.Size(860, 740)
$Form.MinimumSize     = New-Object System.Drawing.Size(860, 740)
$Form.StartPosition   = "CenterScreen"
$Form.BackColor       = $C.BG
$Form.ForeColor       = $C.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox     = $false
$Form.Font            = $FontSub
$Form.Icon            = [System.Drawing.SystemIcons]::Shield

# ============================================================
#  HEADER PANEL
# ============================================================
$Header = New-Object System.Windows.Forms.Panel
$Header.Size      = New-Object System.Drawing.Size(860, 80)
$Header.Location  = New-Object System.Drawing.Point(0, 0)
$Header.BackColor = $C.Surface

$Header.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    # Gradient accent bar at top
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Point]::new(0,0),
        [System.Drawing.Point]::new(860,0),
        $C.Accent,
        $C.AccentLt
    )
    $g.FillRectangle($grad, 0, 0, 860, 3)
    $grad.Dispose()
    # Bottom border
    $pen = New-Object System.Drawing.Pen($C.Border, 1)
    $g.DrawLine($pen, 0, 79, 860, 79)
    $pen.Dispose()
})

# Logo/Title
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text      = "  ⚡ DebloaterPRO"
$LblTitle.Font      = $FontTitle
$LblTitle.ForeColor = $C.Text
$LblTitle.Location  = New-Object System.Drawing.Point(15, 18)
$LblTitle.Size      = New-Object System.Drawing.Size(320, 40)
$LblTitle.BackColor = [System.Drawing.Color]::Transparent

$LblVersion = New-Object System.Windows.Forms.Label
$LblVersion.Text      = "v2.0  |  Windows 10/11  |  Run as Admin ✓"
$LblVersion.Font      = $FontSub
$LblVersion.ForeColor = $C.Green
$LblVersion.Location  = New-Object System.Drawing.Point(18, 54)
$LblVersion.Size      = New-Object System.Drawing.Size(400, 20)
$LblVersion.BackColor = [System.Drawing.Color]::Transparent

# Windows info
$winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
$LblWinInfo = New-Object System.Windows.Forms.Label
$LblWinInfo.Text      = $winVer
$LblWinInfo.Font      = $FontSub
$LblWinInfo.ForeColor = $C.TextDim
$LblWinInfo.Location  = New-Object System.Drawing.Point(500, 18)
$LblWinInfo.Size      = New-Object System.Drawing.Size(340, 20)
$LblWinInfo.TextAlign = "MiddleRight"
$LblWinInfo.BackColor = [System.Drawing.Color]::Transparent

$LblDate = New-Object System.Windows.Forms.Label
$LblDate.Text      = (Get-Date -Format "dddd, dd MMM yyyy  HH:mm")
$LblDate.Font      = $FontSub
$LblDate.ForeColor = $C.TextMuted
$LblDate.Location  = New-Object System.Drawing.Point(500, 42)
$LblDate.Size      = New-Object System.Drawing.Size(340, 20)
$LblDate.TextAlign = "MiddleRight"
$LblDate.BackColor = [System.Drawing.Color]::Transparent

$Header.Controls.AddRange(@($LblTitle, $LblVersion, $LblWinInfo, $LblDate))
$Form.Controls.Add($Header)

# ============================================================
#  LEFT PANEL - App List
# ============================================================
$LeftPanel = New-Object System.Windows.Forms.Panel
$LeftPanel.Location  = New-Object System.Drawing.Point(10, 90)
$LeftPanel.Size      = New-Object System.Drawing.Size(540, 500)
$LeftPanel.BackColor = $C.BG

# Section label
$LblApps = New-Object System.Windows.Forms.Label
$LblApps.Text      = "SELECT APPS TO REMOVE"
$LblApps.Font      = $FontCat
$LblApps.ForeColor = $C.AccentLt
$LblApps.Location  = New-Object System.Drawing.Point(0, 0)
$LblApps.Size      = New-Object System.Drawing.Size(400, 18)

# Select All / None buttons row
$BtnSelAll = New-Object System.Windows.Forms.Button
$BtnSelAll.Text      = "+ All"
$BtnSelAll.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$BtnSelAll.ForeColor = $C.Green
$BtnSelAll.BackColor = $C.Overlay
$BtnSelAll.FlatStyle = "Flat"
$BtnSelAll.FlatAppearance.BorderColor = $C.GreenDk
$BtnSelAll.FlatAppearance.BorderSize  = 1
$BtnSelAll.Size      = New-Object System.Drawing.Size(60, 22)
$BtnSelAll.Location  = New-Object System.Drawing.Point(0, 22)
$BtnSelAll.Cursor    = [System.Windows.Forms.Cursors]::Hand

$BtnSelNone = New-Object System.Windows.Forms.Button
$BtnSelNone.Text      = "− None"
$BtnSelNone.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$BtnSelNone.ForeColor = $C.Red
$BtnSelNone.BackColor = $C.Overlay
$BtnSelNone.FlatStyle = "Flat"
$BtnSelNone.FlatAppearance.BorderColor = $C.Red
$BtnSelNone.FlatAppearance.BorderSize  = 1
$BtnSelNone.Size      = New-Object System.Drawing.Size(60, 22)
$BtnSelNone.Location  = New-Object System.Drawing.Point(65, 22)
$BtnSelNone.Cursor    = [System.Windows.Forms.Cursors]::Hand

$BtnSafePreset = New-Object System.Windows.Forms.Button
$BtnSafePreset.Text      = "★ Safe Preset"
$BtnSafePreset.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$BtnSafePreset.ForeColor = $C.Yellow
$BtnSafePreset.BackColor = $C.Overlay
$BtnSafePreset.FlatStyle = "Flat"
$BtnSafePreset.FlatAppearance.BorderColor = $C.Yellow
$BtnSafePreset.FlatAppearance.BorderSize  = 1
$BtnSafePreset.Size      = New-Object System.Drawing.Size(95, 22)
$BtnSafePreset.Location  = New-Object System.Drawing.Point(130, 22)
$BtnSafePreset.Cursor    = [System.Windows.Forms.Cursors]::Hand

# Counter label
$LblCounter = New-Object System.Windows.Forms.Label
$LblCounter.Text      = "0 selected"
$LblCounter.Font      = $FontCounter
$LblCounter.ForeColor = $C.Accent
$LblCounter.Location  = New-Object System.Drawing.Point(380, 18)
$LblCounter.Size      = New-Object System.Drawing.Size(160, 28)
$LblCounter.TextAlign = "MiddleRight"
$LblCounter.BackColor = [System.Drawing.Color]::Transparent

# Scrollable container for app checkboxes
$AppScroll = New-Object System.Windows.Forms.Panel
$AppScroll.Location   = New-Object System.Drawing.Point(0, 50)
$AppScroll.Size       = New-Object System.Drawing.Size(540, 450)
$AppScroll.AutoScroll = $true
$AppScroll.BackColor  = $C.BG

$LeftPanel.Controls.AddRange(@($LblApps, $BtnSelAll, $BtnSelNone, $BtnSafePreset, $LblCounter, $AppScroll))
$Form.Controls.Add($LeftPanel)

# ============================================================
#  BUILD CHECKBOX LIST
# ============================================================
$AllCheckboxes = [System.Collections.Generic.List[System.Collections.Hashtable]]::new()
$yPos = 5

foreach ($category in $AppList.Keys) {
    # Category header
    $catPnl = New-Object System.Windows.Forms.Panel
    $catPnl.Size      = New-Object System.Drawing.Size(518, 26)
    $catPnl.Location  = New-Object System.Drawing.Point(2, $yPos)
    $catPnl.BackColor = $C.Overlay

    $catPnl.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $pen = New-Object System.Drawing.Pen($C.Accent, 2)
        $g.DrawLine($pen, 0, 0, 0, $s.Height)
        $pen.Dispose()
    })

    $catLbl = New-Object System.Windows.Forms.Label
    $catLbl.Text      = "  $category"
    $catLbl.Font      = $FontCat
    $catLbl.ForeColor = $C.AccentLt
    $catLbl.Dock      = "Fill"
    $catLbl.TextAlign = "MiddleLeft"
    $catLbl.BackColor = [System.Drawing.Color]::Transparent
    $catPnl.Controls.Add($catLbl)

    $AppScroll.Controls.Add($catPnl)
    $yPos += 30

    foreach ($app in $AppList[$category]) {
        $rowPnl = New-Object System.Windows.Forms.Panel
        $rowPnl.Size      = New-Object System.Drawing.Size(518, 38)
        $rowPnl.Location  = New-Object System.Drawing.Point(2, $yPos)
        $rowPnl.BackColor = $C.Surface
        $rowPnl.Tag       = $false   # hover state

        # Hover effect
        $rowPnl.Add_MouseEnter({
            $this.BackColor = $C.Surface2
        })
        $rowPnl.Add_MouseLeave({
            # Only reset if checkbox not checked
            $cb = $this.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] } | Select-Object -First 1
            if (-not $cb.Checked) { $this.BackColor = $C.Surface }
        })

        # Checkbox
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text      = $app.Name
        $cb.Font      = $FontBold
        $cb.ForeColor = $C.Text
        $cb.BackColor = [System.Drawing.Color]::Transparent
        $cb.Location  = New-Object System.Drawing.Point(10, 5)
        $cb.Size      = New-Object System.Drawing.Size(200, 22)
        $cb.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $cb.FlatStyle = "Flat"

        # Risk badge
        $riskColor = if ($app.Risk -eq "Caution") { $C.Yellow } else { $C.Green }
        $riskLbl = New-Object System.Windows.Forms.Label
        $riskLbl.Text      = $app.Risk
        $riskLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
        $riskLbl.ForeColor = $riskColor
        $riskLbl.BackColor = [System.Drawing.Color]::Transparent
        $riskLbl.Location  = New-Object System.Drawing.Point(218, 3)
        $riskLbl.Size      = New-Object System.Drawing.Size(55, 14)
        $riskLbl.TextAlign = "MiddleCenter"

        # Description
        $descLbl = New-Object System.Windows.Forms.Label
        $descLbl.Text      = $app.Desc
        $descLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Regular)
        $descLbl.ForeColor = $C.TextDim
        $descLbl.BackColor = [System.Drawing.Color]::Transparent
        $descLbl.Location  = New-Object System.Drawing.Point(218, 18)
        $descLbl.Size      = New-Object System.Drawing.Size(280, 16)

        # Package label
        $pkgLbl = New-Object System.Windows.Forms.Label
        $pkgLbl.Text      = $app.Pkg
        $pkgLbl.Font      = New-Object System.Drawing.Font("Consolas", 6.5, [System.Drawing.FontStyle]::Regular)
        $pkgLbl.ForeColor = $C.TextMuted
        $pkgLbl.BackColor = [System.Drawing.Color]::Transparent
        $pkgLbl.Location  = New-Object System.Drawing.Point(10, 24)
        $pkgLbl.Size      = New-Object System.Drawing.Size(200, 14)

        $rowPnl.Controls.AddRange(@($cb, $riskLbl, $descLbl, $pkgLbl))
        $AppScroll.Controls.Add($rowPnl)

        $entry = @{ CB = $cb; App = $app; Row = $rowPnl }
        $AllCheckboxes.Add($entry)

        # Checkbox change → update counter + row color
        $cb.Add_CheckedChanged({
            $count = ($AllCheckboxes | Where-Object { $_.CB.Checked }).Count
            $LblCounter.Text = "$count selected"
            $LblCounter.ForeColor = if ($count -gt 0) { $C.Accent } else { $C.TextMuted }
            # Highlight row
            $parent = $this.Parent
            if ($parent) {
                $parent.BackColor = if ($this.Checked) { $C.Overlay } else { $C.Surface }
            }
        })

        $yPos += 42
    }
    $yPos += 8
}

# ============================================================
#  SELECT ALL / NONE / PRESET ACTIONS
# ============================================================
$BtnSelAll.Add_Click({
    foreach ($e in $AllCheckboxes) { $e.CB.Checked = $true }
})

$BtnSelNone.Add_Click({
    foreach ($e in $AllCheckboxes) { $e.CB.Checked = $false }
})

$BtnSafePreset.Add_Click({
    foreach ($e in $AllCheckboxes) {
        $e.CB.Checked = ($e.App.Risk -eq "Safe")
    }
})

# ============================================================
#  RIGHT PANEL - Options & Controls
# ============================================================
$RightPanel = New-Object System.Windows.Forms.Panel
$RightPanel.Location  = New-Object System.Drawing.Point(558, 90)
$RightPanel.Size      = New-Object System.Drawing.Size(290, 500)
$RightPanel.BackColor = $C.BG

$Form.Controls.Add($RightPanel)

# ----- Options Section -----
$LblOptions = New-Object System.Windows.Forms.Label
$LblOptions.Text      = "OPTIONS"
$LblOptions.Font      = $FontCat
$LblOptions.ForeColor = $C.AccentLt
$LblOptions.Location  = New-Object System.Drawing.Point(0, 0)
$LblOptions.Size      = New-Object System.Drawing.Size(290, 18)

$OptionsBorder = New-Object System.Windows.Forms.Panel
$OptionsBorder.Location  = New-Object System.Drawing.Point(0, 22)
$OptionsBorder.Size      = New-Object System.Drawing.Size(286, 160)
$OptionsBorder.BackColor = $C.Surface
$OptionsBorder.BorderStyle = "None"

$OptionsBorder.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $pen = New-Object System.Drawing.Pen($C.Border, 1)
    $g.DrawRectangle($pen, 0, 0, $s.Width-1, $s.Height-1)
    $pen.Dispose()
})

function New-OptionCheck {
    param($Text, $Y, $Checked=$false, $Tooltip="")
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text      = $Text
    $c.Font      = $FontSub
    $c.ForeColor = $C.Text
    $c.BackColor = [System.Drawing.Color]::Transparent
    $c.Location  = New-Object System.Drawing.Point(12, $Y)
    $c.Size      = New-Object System.Drawing.Size(260, 22)
    $c.Checked   = $Checked
    $c.FlatStyle = "Flat"
    $c.Cursor    = [System.Windows.Forms.Cursors]::Hand
    return $c
}

$ChkRestorePoint = New-OptionCheck "Create restore point first"   10  $true
$ChkProvision    = New-OptionCheck "Remove provisioned packages"  34  $true
$ChkAllUsers     = New-OptionCheck "Remove for all users"         58  $true
$ChkDryRun       = New-OptionCheck "⚠ Dry run (simulate only)"   82  $false
$ChkTweaks       = New-OptionCheck "Apply performance tweaks"    106  $false

$OptionsBorder.Controls.AddRange(@($ChkRestorePoint, $ChkProvision, $ChkAllUsers, $ChkDryRun, $ChkTweaks))
$RightPanel.Controls.AddRange(@($LblOptions, $OptionsBorder))

# ----- System Info Section -----
$LblSysInfo = New-Object System.Windows.Forms.Label
$LblSysInfo.Text      = "SYSTEM INFO"
$LblSysInfo.Font      = $FontCat
$LblSysInfo.ForeColor = $C.AccentLt
$LblSysInfo.Location  = New-Object System.Drawing.Point(0, 196)
$LblSysInfo.Size      = New-Object System.Drawing.Size(290, 18)

$SysInfoBox = New-Object System.Windows.Forms.Panel
$SysInfoBox.Location  = New-Object System.Drawing.Point(0, 218)
$SysInfoBox.Size      = New-Object System.Drawing.Size(286, 100)
$SysInfoBox.BackColor = $C.Surface

$SysInfoBox.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $pen = New-Object System.Drawing.Pen($C.Border, 1)
    $g.DrawRectangle($pen, 0, 0, $s.Width-1, $s.Height-1)
    $pen.Dispose()
})

function Add-SysLabel {
    param($Label, $Value, $Y)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Label
    $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Regular)
    $lbl.ForeColor = $C.TextDim
    $lbl.Location  = New-Object System.Drawing.Point(10, $Y)
    $lbl.Size      = New-Object System.Drawing.Size(100, 18)

    $val = New-Object System.Windows.Forms.Label
    $val.Text      = $Value
    $val.Font      = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
    $val.ForeColor = $C.Text
    $val.Location  = New-Object System.Drawing.Point(115, $Y)
    $val.Size      = New-Object System.Drawing.Size(165, 18)

    $SysInfoBox.Controls.AddRange(@($lbl, $val))
}

$totalRAM  = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$freeRAM   = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)
$cpuName   = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+',' '
if ($cpuName.Length -gt 28) { $cpuName = $cpuName.Substring(0, 28) + "…" }

$sysDrive  = $env:SystemDrive
$disk      = Get-PSDrive -Name ($sysDrive.Replace(":","")) -ErrorAction SilentlyContinue
$diskFree  = if ($disk) { [math]::Round($disk.Free / 1GB, 1) } else { "N/A" }

Add-SysLabel "CPU:"     $cpuName     8
Add-SysLabel "RAM:"     "${totalRAM} GB total / ${freeRAM} GB free"   30
Add-SysLabel "Drive $sysDrive" "${diskFree} GB free"   52
Add-SysLabel "User:"    $env:USERNAME   74

$RightPanel.Controls.AddRange(@($LblSysInfo, $SysInfoBox))

# ----- Profile Buttons -----
$LblProfiles = New-Object System.Windows.Forms.Label
$LblProfiles.Text      = "PROFILES"
$LblProfiles.Font      = $FontCat
$LblProfiles.ForeColor = $C.AccentLt
$LblProfiles.Location  = New-Object System.Drawing.Point(0, 332)
$LblProfiles.Size      = New-Object System.Drawing.Size(290, 18)

$BtnExport = New-Object System.Windows.Forms.Button
$BtnExport.Text      = "⬆  Export Profile"
$BtnExport.Font      = $FontSub
$BtnExport.ForeColor = $C.AccentLt
$BtnExport.BackColor = $C.Overlay
$BtnExport.FlatStyle = "Flat"
$BtnExport.FlatAppearance.BorderColor = $C.Accent
$BtnExport.FlatAppearance.BorderSize  = 1
$BtnExport.Size      = New-Object System.Drawing.Size(138, 32)
$BtnExport.Location  = New-Object System.Drawing.Point(0, 354)
$BtnExport.Cursor    = [System.Windows.Forms.Cursors]::Hand

$BtnImport = New-Object System.Windows.Forms.Button
$BtnImport.Text      = "⬇  Import Profile"
$BtnImport.Font      = $FontSub
$BtnImport.ForeColor = $C.AccentLt
$BtnImport.BackColor = $C.Overlay
$BtnImport.FlatStyle = "Flat"
$BtnImport.FlatAppearance.BorderColor = $C.Accent
$BtnImport.FlatAppearance.BorderSize  = 1
$BtnImport.Size      = New-Object System.Drawing.Size(138, 32)
$BtnImport.Location  = New-Object System.Drawing.Point(148, 354)
$BtnImport.Cursor    = [System.Windows.Forms.Cursors]::Hand

$BtnViewLog = New-Object System.Windows.Forms.Button
$BtnViewLog.Text      = "📋  Open Log File"
$BtnViewLog.Font      = $FontSub
$BtnViewLog.ForeColor = $C.TextDim
$BtnViewLog.BackColor = $C.Surface
$BtnViewLog.FlatStyle = "Flat"
$BtnViewLog.FlatAppearance.BorderColor = $C.Border
$BtnViewLog.FlatAppearance.BorderSize  = 1
$BtnViewLog.Size      = New-Object System.Drawing.Size(286, 28)
$BtnViewLog.Location  = New-Object System.Drawing.Point(0, 392)
$BtnViewLog.Cursor    = [System.Windows.Forms.Cursors]::Hand

$RightPanel.Controls.AddRange(@($LblProfiles, $BtnExport, $BtnImport, $BtnViewLog))

# ============================================================
#  BOTTOM AREA - Progress + Log + Run
# ============================================================
$BottomPanel = New-Object System.Windows.Forms.Panel
$BottomPanel.Location  = New-Object System.Drawing.Point(10, 598)
$BottomPanel.Size      = New-Object System.Drawing.Size(838, 100)
$BottomPanel.BackColor = $C.BG

$Form.Controls.Add($BottomPanel)

# Progress label
$LblProgress = New-Object System.Windows.Forms.Label
$LblProgress.Text      = "Ready"
$LblProgress.Font      = $FontSub
$LblProgress.ForeColor = $C.TextDim
$LblProgress.Location  = New-Object System.Drawing.Point(0, 0)
$LblProgress.Size      = New-Object System.Drawing.Size(540, 18)

# Custom-drawn progress bar
$ProgressHost = New-Object System.Windows.Forms.Panel
$ProgressHost.Location  = New-Object System.Drawing.Point(0, 20)
$ProgressHost.Size      = New-Object System.Drawing.Size(540, 22)
$ProgressHost.BackColor = $C.Surface

$script:ProgressValue = 0
$script:ProgressMax   = 1

$ProgressHost.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $w = $s.Width
    $h = $s.Height
    # Background
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($C.Overlay)), 0, 0, $w, $h)
    # Fill
    if ($script:ProgressMax -gt 0) {
        $fillW = [int]([double]$script:ProgressValue / $script:ProgressMax * $w)
        if ($fillW -gt 0) {
            $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                [System.Drawing.Rectangle]::new(0,0,$fillW,$h),
                $C.Accent, $C.Green,
                [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
            )
            $g.FillRectangle($grad, 0, 0, $fillW, $h)
            $grad.Dispose()
        }
    }
    # Border
    $pen = New-Object System.Drawing.Pen($C.Border, 1)
    $g.DrawRectangle($pen, 0, 0, $w-1, $h-1)
    $pen.Dispose()
    # Text
    $pct = if ($script:ProgressMax -gt 0) { [int]([double]$script:ProgressValue / $script:ProgressMax * 100) } else { 0 }
    $g.DrawString("$pct%  ($script:ProgressValue / $script:ProgressMax)",
        (New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)),
        (New-Object System.Drawing.SolidBrush($C.Text)),
        [System.Drawing.Point]::new(6, 4)
    )
})

# Live log box
$LogBox = New-Object System.Windows.Forms.RichTextBox
$LogBox.Location    = New-Object System.Drawing.Point(0, 48)
$LogBox.Size        = New-Object System.Drawing.Size(540, 50)
$LogBox.BackColor   = $C.Surface
$LogBox.ForeColor   = $C.TextDim
$LogBox.Font        = $FontMono
$LogBox.ReadOnly    = $true
$LogBox.BorderStyle = "None"
$LogBox.ScrollBars  = "Vertical"

function Append-Log {
    param([string]$Msg, [string]$Color="dim")
    $fgColor = switch ($Color) {
        "success" { $C.Green  }
        "error"   { $C.Red    }
        "warn"    { $C.Yellow }
        "accent"  { $C.AccentLt }
        default   { $C.TextDim }
    }
    $stamp = "[$(Get-Date -Format 'HH:mm:ss')] "
    $LogBox.SelectionStart  = $LogBox.TextLength
    $LogBox.SelectionLength = 0
    $LogBox.SelectionColor  = $C.TextMuted
    $LogBox.AppendText($stamp)
    $LogBox.SelectionColor  = $fgColor
    $LogBox.AppendText("$Msg`n")
    $LogBox.ScrollToCaret()
}

# RUN button (custom drawn)
$RunBtn = New-Object System.Windows.Forms.Button
$RunBtn.Text      = "▶  RUN DEBLOAT"
$RunBtn.Font      = $FontBtn
$RunBtn.ForeColor = [System.Drawing.Color]::Black
$RunBtn.BackColor = $C.Green
$RunBtn.FlatStyle = "Flat"
$RunBtn.FlatAppearance.BorderColor = $C.GreenDk
$RunBtn.FlatAppearance.BorderSize  = 1
$RunBtn.Size      = New-Object System.Drawing.Size(270, 48)
$RunBtn.Location  = New-Object System.Drawing.Point(554, 10)
$RunBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand

$RunBtn.Add_MouseEnter({ $this.BackColor = $C.GreenDk })
$RunBtn.Add_MouseLeave({ $this.BackColor = $C.Green })

$BottomPanel.Controls.AddRange(@($LblProgress, $ProgressHost, $LogBox, $RunBtn))

# ============================================================
#  PROFILE EXPORT / IMPORT
# ============================================================
$BtnExport.Add_Click({
    $selected = $AllCheckboxes | Where-Object { $_.CB.Checked } | ForEach-Object { $_.App.Name }
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No apps selected to export.", "Export Profile",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Title      = "Save Debloat Profile"
    $dlg.Filter     = "JSON Profile (*.json)|*.json"
    $dlg.FileName   = "debloat_profile_$(Get-Date -Format 'yyyyMMdd')"
    $dlg.InitialDirectory = $logDir
    if ($dlg.ShowDialog() -eq "OK") {
        $profile = @{ CreatedAt = (Get-Date -Format "o"); Apps = @($selected) }
        $profile | ConvertTo-Json -Depth 5 | Out-File -FilePath $dlg.FileName -Encoding UTF8
        Append-Log "Profile exported → $($dlg.FileName)" "success"
        [System.Windows.Forms.MessageBox]::Show("Profile saved to:`n$($dlg.FileName)", "Export OK",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
})

$BtnImport.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title  = "Load Debloat Profile"
    $dlg.Filter = "JSON Profile (*.json)|*.json"
    $dlg.InitialDirectory = $logDir
    if ($dlg.ShowDialog() -eq "OK") {
        try {
            $data = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            $names = @($data.Apps)
            foreach ($e in $AllCheckboxes) {
                $e.CB.Checked = ($names -contains $e.App.Name)
            }
            $count = ($AllCheckboxes | Where-Object { $_.CB.Checked }).Count
            Append-Log "Profile loaded: $count apps selected from $($dlg.FileName)" "accent"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to load profile.`n$($_.Exception.Message)", "Import Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    }
})

$BtnViewLog.Add_Click({
    if (Test-Path $logPath) {
        Start-Process notepad.exe $logPath
    } else {
        [System.Windows.Forms.MessageBox]::Show("Log file not yet created.", "Log",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
})

# ============================================================
#  PERFORMANCE TWEAKS
# ============================================================
function Apply-PerformanceTweaks {
    Append-Log "Applying performance tweaks…" "accent"

    # Disable telemetry
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction Stop
        Append-Log "Telemetry disabled." "success"
    } catch { Append-Log "Telemetry tweak failed: $_" "warn" }

    # Disable Cortana
    try {
        $cortanaKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $cortanaKey)) { New-Item -Path $cortanaKey -Force | Out-Null }
        Set-ItemProperty -Path $cortanaKey -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction Stop
        Append-Log "Cortana disabled." "success"
    } catch { Append-Log "Cortana tweak failed: $_" "warn" }

    # Disable Windows Tips
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
            -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Append-Log "Windows Tips disabled." "success"
    } catch { Append-Log "Tips tweak skipped." "warn" }

    # Disable background apps (global)
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Append-Log "Background apps restricted." "success"
    } catch { Append-Log "Background apps tweak skipped." "warn" }
}

# ============================================================
#  MAIN RUN BUTTON
# ============================================================
$RunBtn.Add_Click({

    $selected = $AllCheckboxes | Where-Object { $_.CB.Checked }

    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select at least one app to remove.",
            "Nothing Selected",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $isDryRun = $ChkDryRun.Checked
    $dryTag   = if ($isDryRun) { " [DRY RUN]" } else { "" }

    $appNames = ($selected | ForEach-Object { $_.App.Name }) -join ", "
    $msg = "You are about to remove $($selected.Count) app(s)$dryTag:`n`n$appNames`n`nProceed?"
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $msg, "Confirm Removal",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne "Yes") { return }

    # Disable controls during run
    $RunBtn.Enabled    = $false
    $RunBtn.Text       = "⏳  Running…"
    $BtnSelAll.Enabled = $false
    $BtnSelNone.Enabled= $false

    # Restore point
    if ($ChkRestorePoint.Checked -and -not $isDryRun) {
        Append-Log "Creating system restore point…" "accent"
        try {
            # Ensure System Restore is enabled on C:
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "DebloaterPRO_$(Get-Date -Format 'yyyyMMdd_HHmmss')" `
                -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Append-Log "Restore point created ✓" "success"
        } catch {
            Append-Log "Restore point failed (non-critical): $($_.Exception.Message)" "warn"
        }
    }

    $script:ProgressMax   = $selected.Count
    $script:ProgressValue = 0
    $ProgressHost.Invalidate()

    $successCount = 0
    $failCount    = 0
    $skipCount    = 0

    foreach ($entry in $selected) {
        $app  = $entry.App
        $pkg  = $app.Pkg

        $LblProgress.Text = "Processing: $($app.Name)"
        $Form.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        Write-Log "Processing: $($app.Name) [$pkg]"

        if ($isDryRun) {
            Append-Log "[DRY RUN] Would remove: $($app.Name)" "warn"
            $skipCount++
        } else {
            $removed = $false

            # Remove installed packages (wildcard safe approach)
            try {
                $pkgs = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like $pkg -or $_.PackageFullName -like $pkg }

                if ($pkgs) {
                    $pkgs | Remove-AppxPackage -ErrorAction Stop
                    $removed = $true
                }
            } catch {
                Append-Log "User pkg failed ($($app.Name)): $($_.Exception.Message)" "warn"
                Write-Log "User pkg failed: $($_.Exception.Message)" "WARN"
            }

            # Remove provisioned (pre-installed) packages
            if ($ChkProvision.Checked) {
                try {
                    $provPkgs = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                        Where-Object { $_.DisplayName -like $pkg -or $_.PackageName -like $pkg }

                    if ($provPkgs) {
                        $provPkgs | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
                        $removed = $true
                    }
                } catch {
                    Append-Log "Provisioned pkg failed ($($app.Name)): $($_.Exception.Message)" "warn"
                    Write-Log "Provisioned pkg failed: $($_.Exception.Message)" "WARN"
                }
            }

            if ($removed) {
                Append-Log "✓ Removed: $($app.Name)" "success"
                Write-Log "Removed: $($app.Name)"
                $successCount++
                # Gray out the row
                $entry.Row.BackColor   = $C.Surface
                $entry.CB.ForeColor    = $C.TextMuted
                $entry.CB.Enabled      = $false
            } else {
                Append-Log "⚠ Not found / skipped: $($app.Name)" "warn"
                Write-Log "Not found: $($app.Name)" "WARN"
                $skipCount++
            }
        }

        $script:ProgressValue++
        $ProgressHost.Invalidate()
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 80
    }

    # Apply tweaks if requested
    if ($ChkTweaks.Checked -and -not $isDryRun) {
        Apply-PerformanceTweaks
    }

    $script:ProgressValue = $script:ProgressMax
    $ProgressHost.Invalidate()
    $LblProgress.Text = "Complete!  ✓ $successCount removed  ⚠ $skipCount skipped  ✗ $failCount failed"

    Append-Log "────────────────────────────────" "accent"
    Append-Log "Done!  Removed: $successCount  Skipped: $skipCount  Log: $logPath" "success"

    # Re-enable controls
    $RunBtn.Enabled     = $true
    $RunBtn.Text        = "▶  RUN DEBLOAT"
    $BtnSelAll.Enabled  = $true
    $BtnSelNone.Enabled = $true

    $resultMsg = "Debloat Complete!`n`n  ✅  Removed:  $successCount app(s)`n  ⚠️   Skipped:  $skipCount (not found)`n`nLog saved to:`n$logPath"
    if ($isDryRun) { $resultMsg = "[DRY RUN] No changes were made.`n$resultMsg" }

    [System.Windows.Forms.MessageBox]::Show(
        $resultMsg, "DebloaterPRO — Done",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

# ============================================================
#  FORM CLOSING
# ============================================================
$Form.Add_FormClosing({
    try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}
})

# ============================================================
#  LAUNCH
# ============================================================
Append-Log "DebloaterPRO loaded. Select apps and click RUN." "accent"
Append-Log "Log path: $logPath" "dim"

[System.Windows.Forms.Application]::Run($Form)
