#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================
# ADMIN CHECK
# =========================
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Run PowerShell as Administrator")
    exit
}

# =========================
# GET REAL INSTALLED APPS
# =========================
$InstalledApps = Get-AppxPackage -AllUsers |
Select-Object Name, PackageFullName

# =========================
# BLOAT INTELLIGENCE RULES
# (NOT FIXED LIST — MATCH ENGINE)
# =========================
$BloatRules = @(
    "*tiktok*",
    "*instagram*",
    "*facebook*",
    "*twitter*",
    "*whatsapp*",

    "*xbox*",
    "*gaming*",
    "*solitaire*",
    "*minecraft*",
    "*candycrush*",

    "*bing*",
    "*zune*",
    "*clipchamp*",
    "*gethelp*",
    "*feedbackhub*",
    "*yourphone*",

    "*spotify*",
    "*netflix*",
    "*disney*",

    "*windowscommunicationsapps*"
)

# =========================
# DETECT REAL BLOAT ON DEVICE
# =========================
$Detected = foreach ($app in $InstalledApps) {

    foreach ($rule in $BloatRules) {

        if ($app.Name -like $rule) {

            [PSCustomObject]@{
                Name    = $app.Name
                Package = $app.PackageFullName
            }

            break
        }
    }
}

$Detected = $Detected | Sort-Object Name -Unique

# =========================
# UI
# =========================
$form = New-Object System.Windows.Forms.Form
$form.Text = "DebloaterPRO v4 (Fixed Engine)"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Dock = "Left"
$listBox.Width = 500

foreach ($app in $Detected) {
    [void]$listBox.Items.Add($app.Name)
}

# =========================
# BUTTONS
# =========================
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(520, 20)
$btnSelectAll.Width = 220

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear"
$btnClear.Location = New-Object System.Drawing.Point(520, 60)
$btnClear.Width = 220

$btnRecommend = New-Object System.Windows.Forms.Button
$btnRecommend.Text = "Recommended"
$btnRecommend.Location = New-Object System.Drawing.Point(520, 100)
$btnRecommend.Width = 220

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "RUN DEBLOAT"
$btnRun.Location = New-Object System.Drawing.Point(520, 160)
$btnRun.Width = 220
$btnRun.BackColor = [System.Drawing.Color]::LightGreen

# =========================
# RECOMMENDED SET
# =========================
$Recommended = @(
    "*tiktok*",
    "*instagram*",
    "*facebook*",
    "*candycrush*",
    "*solitaire*",
    "*bingnews*",
    "*bingweather*",
    "*yourphone*"
)

# =========================
# EVENTS
# =========================
$btnSelectAll.Add_Click({
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        $listBox.SetItemChecked($i, $true)
    }
})

$btnClear.Add_Click({
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        $listBox.SetItemChecked($i, $false)
    }
})

$btnRecommend.Add_Click({
    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        $name = $listBox.Items[$i]

        $match = $false
        foreach ($r in $Recommended) {
            if ($name -like $r) {
                $match = $true
                break
            }
        }

        $listBox.SetItemChecked($i, $match)
    }
})

# =========================
# REMOVE ENGINE (SAFE FIXED)
# =========================
$btnRun.Add_Click({

    $selected = @()

    for ($i=0; $i -lt $listBox.Items.Count; $i++) {
        if ($listBox.GetItemChecked($i)) {
            $selected += $listBox.Items[$i]
        }
    }

    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No apps selected")
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Remove $($selected.Count) apps?",
        "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo
    )

    if ($confirm -ne "Yes") { return }

    foreach ($name in $selected) {

        $pkg = $Detected | Where-Object { $_.Name -eq $name }

        if ($pkg) {
            try {
                Get-AppxPackage -AllUsers |
                    Where-Object { $_.Name -eq $pkg.Name } |
                    Remove-AppxPackage -ErrorAction SilentlyContinue

                Write-Host "Removed: $name"
            }
            catch {
                Write-Host "Failed: $name"
            }
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Debloat Complete")
})

# =========================
# ADD CONTROLS
# =========================
$form.Controls.Add($listBox)
$form.Controls.Add($btnSelectAll)
$form.Controls.Add($btnClear)
$form.Controls.Add($btnRecommend)
$form.Controls.Add($btnRun)

# =========================
# RUN
# =========================
[void]$form.ShowDialog()
