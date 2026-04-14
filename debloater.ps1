#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# DATA LAYER (NO UI MIXED LOGIC)
# ============================================================
$Apps = @(
    @{ Name="TikTok";     Pattern="*TikTok*" },
    @{ Name="Instagram";  Pattern="*Instagram*" },
    @{ Name="Facebook";   Pattern="*Facebook*" },
    @{ Name="Bing News";  Pattern="*BingNews*" },
    @{ Name="Bing Weather";Pattern="*BingWeather*" },
    @{ Name="Solitaire";  Pattern="*MicrosoftSolitaireCollection*" },
    @{ Name="Xbox";       Pattern="*Xbox*" },
    @{ Name="Clipchamp";  Pattern="*Clipchamp*" },
    @{ Name="Your Phone"; Pattern="*YourPhone*" },
    @{ Name="Teams";      Pattern="*MicrosoftTeams*" }
)

# ============================================================
# UI FORM
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Debloater PRO (Stable Build)"
$form.Size = New-Object System.Drawing.Size(520, 650)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(18,18,28)
$form.ForeColor = [System.Drawing.Color]::White

$title = New-Object System.Windows.Forms.Label
$title.Text = "Windows Debloater PRO"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White
$title.Location = New-Object System.Drawing.Point(20, 15)
$title.Size = New-Object System.Drawing.Size(400, 30)
$form.Controls.Add($title)

# ============================================================
# CHECKBOX PANEL (SCROLL SAFE)
# ============================================================
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 60)
$panel.Size = New-Object System.Drawing.Size(460, 420)
$panel.AutoScroll = $true
$panel.BackColor = [System.Drawing.Color]::FromArgb(25,25,40)
$form.Controls.Add($panel)

$checkboxes = @{}
$y = 10

foreach ($app in $Apps) {

    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $app.Name
    $cb.Location = New-Object System.Drawing.Point(15, $y)
    $cb.Size = New-Object System.Drawing.Size(300, 22)
    $cb.ForeColor = [System.Drawing.Color]::White
    $cb.FlatStyle = "Flat"

    $panel.Controls.Add($cb)
    $checkboxes[$app.Name] = $cb

    $y += 28
}

# ============================================================
# BUTTONS
# ============================================================

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(20, 500)
$btnSelectAll.Size = New-Object System.Drawing.Size(140, 35)

$btnSelectNone = New-Object System.Windows.Forms.Button
$btnSelectNone.Text = "Clear"
$btnSelectNone.Location = New-Object System.Drawing.Point(170, 500)
$btnSelectNone.Size = New-Object System.Drawing.Size(140, 35)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "RUN DEBLOAT"
$btnRun.Location = New-Object System.Drawing.Point(320, 500)
$btnRun.Size = New-Object System.Drawing.Size(160, 35)
$btnRun.BackColor = [System.Drawing.Color]::Green
$btnRun.ForeColor = [System.Drawing.Color]::Black

$form.Controls.AddRange(@($btnSelectAll,$btnSelectNone,$btnRun))

# ============================================================
# LOGIC (SAFE + NO PARSER TRAPS)
# ============================================================

$btnSelectAll.Add_Click({
    foreach ($k in $checkboxes.Keys) { $checkboxes[$k].Checked = $true }
})

$btnSelectNone.Add_Click({
    foreach ($k in $checkboxes.Keys) { $checkboxes[$k].Checked = $false }
})

# ============================================================
# CORE REMOVAL ENGINE (FIXED & SAFE)
# ============================================================
$btnRun.Add_Click({

    $selected = $Apps | Where-Object { $checkboxes[$_.Name].Checked }

    if (-not $selected) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one app.")
        return
    }

    # SAFE MESSAGE BUILD (NO ":" BUG EVER)
    $names = ($selected.Name -join "`n")

    $msg = "You are about to remove:`n`n$names`n`nContinue?"

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "Confirm",
        "YesNo",
        "Warning"
    )

    if ($confirm -ne "Yes") { return }

    foreach ($app in $selected) {

        Write-Host "Processing $($app.Name)..." -ForegroundColor Yellow

        try {
            # Installed apps
            Get-AppxPackage -AllUsers |
                Where-Object { $_.Name -like $app.Pattern } |
                ForEach-Object {
                    Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
                }

            # Provisioned apps
            Get-AppxProvisionedPackage -Online |
                Where-Object { $_.DisplayName -like $app.Pattern } |
                ForEach-Object {
                    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
                }

            Write-Host "Removed: $($app.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $($app.Name)" -ForegroundColor Red
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Debloat Complete!")
})

# ============================================================
# RUN
# ============================================================
[System.Windows.Forms.Application]::Run($form)
