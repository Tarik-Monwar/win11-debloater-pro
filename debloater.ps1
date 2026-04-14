#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================
# APP DATABASE
# =========================
$Apps = [ordered]@{
    "TikTok"            = "*TikTok*"
    "Instagram"         = "*Instagram*"
    "Facebook"          = "*Facebook*"
    "Bing News"         = "*BingNews*"
    "Bing Weather"      = "*BingWeather*"
    "Solitaire"         = "*MicrosoftSolitaireCollection*"
    "Xbox Apps"         = "*Xbox*"
    "Clipchamp"         = "*Clipchamp*"
    "Your Phone"        = "*YourPhone*"
    "Teams"             = "*MicrosoftTeams*"
}

$DefaultRemoval = @(
    "TikTok",
    "Instagram",
    "Bing News",
    "Bing Weather",
    "Solitaire"
)

# =========================
# FORM
# =========================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Win11 Debloater PRO (Stable)"
$form.Size = New-Object System.Drawing.Size(420, 600)
$form.StartPosition = "CenterScreen"

$checkboxes = @{}
$y = 20

# =========================
# CHECKBOX CREATION
# =========================
foreach ($key in $Apps.Keys) {

    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $key
    $cb.Location = New-Object System.Drawing.Point(20, $y)
    $cb.Size = New-Object System.Drawing.Size(300, 20)

    if ($DefaultRemoval -contains $key) {
        $cb.Checked = $true
    }

    $form.Controls.Add($cb)
    $checkboxes[$key] = $cb
    $y += 25
}

# =========================
# SELECT DEFAULT BUTTON
# =========================
$btnDefault = New-Object System.Windows.Forms.Button
$btnDefault.Text = "Select Default"
$btnDefault.Location = New-Object System.Drawing.Point(20, $y + 10)
$btnDefault.Size = New-Object System.Drawing.Size(150, 30)

$btnDefault.Add_Click({
    foreach ($k in $checkboxes.Keys) {
        $checkboxes[$k].Checked = $DefaultRemoval -contains $k
    }
})

$form.Controls.Add($btnDefault)

# =========================
# RUN BUTTON
# =========================
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "RUN DEBLOAT"
$btnRun.Location = New-Object System.Drawing.Point(200, $y + 10)
$btnRun.Size = New-Object System.Drawing.Size(150, 30)

$btnRun.Add_Click({

    $selected = $checkboxes.Keys | Where-Object { $checkboxes[$_].Checked }

    if (-not $selected) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one app")
        return
    }

    # SAFE STRING FIX (IMPORTANT)
    $dryTag = ""

    $msg = "You are about to remove $($selected.Count) app(s)${dryTag}:`n`n" +
           ($selected -join "`n")

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "Confirm",
        "YesNo",
        "Warning"
    )

    if ($confirm -ne "Yes") { return }

    foreach ($item in $selected) {

        $pattern = $Apps[$item]

        Write-Host "Removing $item..."

        try {
            Get-AppxPackage -AllUsers |
                Where-Object { $_.Name -like $pattern } |
                Remove-AppxPackage -ErrorAction SilentlyContinue

            Get-AppxProvisionedPackage -Online |
                Where-Object { $_.DisplayName -like $pattern } |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

            Write-Host "Removed: $item" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $item" -ForegroundColor Yellow
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Debloat Complete!")
})

$form.Controls.Add($btnRun)

# =========================
# START GUI
# =========================
[System.Windows.Forms.Application]::Run($form)
