#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================
# ADMIN CHECK
# =========================
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Run as Administrator required")
    exit
}

# =========================
# REAL DEVICE APPS FETCH
# =========================
$InstalledApps = Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName

# =========================
# ENTERPRISE BLOAT DATABASE
# =========================
$BloatDB = @(
    "*TikTok*",
    "*Instagram*",
    "*Facebook*",
    "*Twitter*",
    "*WhatsApp*",
    "*Spotify*",
    "*Disney*",
    "*CandyCrush*",
    "*Solitaire*",
    "*Xbox*",
    "*XboxGamingOverlay*",
    "*BingNews*",
    "*BingWeather*",
    "*BingSports*",
    "*GetHelp*",
    "*WindowsFeedbackHub*",
    "*YourPhone*",
    "*Skype*",
    "*Clipchamp*",
    "*MicrosoftTeams*",
    "*ZuneMusic*",
    "*ZuneVideo*"
)

# =========================
# MATCH BLOAT WITH DEVICE
# =========================
$MatchedApps = foreach ($app in $InstalledApps) {
    foreach ($pattern in $BloatDB) {
        if ($app.Name -like $pattern) {
            [PSCustomObject]@{
                Name = $app.Name
                PackageFullName = $app.PackageFullName
            }
            break
        }
    }
}

# Remove duplicates
$MatchedApps = $MatchedApps | Sort-Object Name -Unique

# =========================
# FORM UI
# =========================
$form = New-Object Windows.Forms.Form
$form.Text = "DebloaterPRO v4 Enterprise"
$form.Size = New-Object Drawing.Size(850,600)
$form.StartPosition = "CenterScreen"

$listBox = New-Object Windows.Forms.CheckedListBox
$listBox.Dock = "Left"
$listBox.Width = 550

foreach ($app in $MatchedApps) {
    [void]$listBox.Items.Add($app.Name)
}

# =========================
# BUTTONS
# =========================

$btnRecommend = New-Object Windows.Forms.Button
$btnRecommend.Text = "Recommended Select"
$btnRecommend.Top = 20
$btnRecommend.Left = 570
$btnRecommend.Width = 220

$btnSelectAll = New-Object Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Top = 60
$btnSelectAll.Left = 570
$btnSelectAll.Width = 220

$btnClear = New-Object Windows.Forms.Button
$btnClear.Text = "Clear"
$btnClear.Top = 100
$btnClear.Left = 570
$btnClear.Width = 220

$btnRun = New-Object Windows.Forms.Button
$btnRun.Text = "RUN DEBLOAT"
$btnRun.Top = 160
$btnRun.Left = 570
$btnRun.Width = 220
$btnRun.BackColor = "LightGreen"

# =========================
# RECOMMENDED LOGIC
# =========================
$Recommended = @("*TikTok*","*Instagram*","*CandyCrush*","*BingNews*","*BingWeather*","*Solitaire*","*YourPhone*")

$btnRecommend.Add_Click({
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        $name = $listBox.Items[$i]
        $listBox.SetItemChecked($i, ($Recommended | Where-Object { $name -like $_ }))
    }
})

$btnSelectAll.Add_Click({
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        $listBox.SetItemChecked($i,$true)
    }
})

$btnClear.Add_Click({
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        $listBox.SetItemChecked($i,$false)
    }
})

# =========================
# RUN DEBLOAT (FIXED SAFE)
# =========================
$btnRun.Add_Click({

    $selected = @()
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        if ($listBox.GetItemChecked($i)) {
            $selected += $listBox.Items[$i]
        }
    }

    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nothing selected")
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Remove $($selected.Count) apps?",
        "Confirm",
        "YesNo"
    )

    if ($confirm -ne "Yes") { return }

    foreach ($name in $selected) {

        $pkg = $MatchedApps | Where-Object { $_.Name -eq $name }

        if ($pkg) {
            try {
                Get-AppxPackage -AllUsers |
                    Where-Object { $_.Name -eq $pkg.Name } |
                    Remove-AppxPackage -ErrorAction SilentlyContinue

                Write-Host "Removed $name"
            }
            catch {
                Write-Host "Failed $name"
            }
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Done")
})

# =========================
# ADD CONTROLS
# =========================
$form.Controls.Add($listBox)
$form.Controls.Add($btnRecommend)
$form.Controls.Add($btnSelectAll)
$form.Controls.Add($btnClear)
$form.Controls.Add($btnRun)

# =========================
# RUN UI
# =========================
[void]$form.ShowDialog()
