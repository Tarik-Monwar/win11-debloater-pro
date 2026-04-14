#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================================================
# BLOAT DATABASE (REFERENCE ONLY - NOT UI SOURCE)
# =========================================================

$BloatDB = @(
    @{ Pattern="*Xbox*"; Score=3; Category="Gaming" },
    @{ Pattern="*TikTok*"; Score=5; Category="Social" },
    @{ Pattern="*Instagram*"; Score=5; Category="Social" },
    @{ Pattern="*Facebook*"; Score=4; Category="Social" },
    @{ Pattern="*CandyCrush*"; Score=4; Category="Games" },
    @{ Pattern="*Solitaire*"; Score=2; Category="Games" },
    @{ Pattern="*Clipchamp*"; Score=3; Category="Media" },
    @{ Pattern="*Bing*"; Score=3; Category="Microsoft" },
    @{ Pattern="*YourPhone*"; Score=3; Category="System" },
    @{ Pattern="*PhoneLink*"; Score=3; Category="System" },
    @{ Pattern="*Teams*"; Score=3; Category="Productivity" },
    @{ Pattern="*MixedReality*"; Score=4; Category="System" },
    @{ Pattern="*Zune*"; Score=2; Category="Legacy" },
    @{ Pattern="*SkypeApp*"; Score=3; Category="Communication" }
)

# =========================================================
# GET BLOAT DATABASE (LOCAL SAFE)
# =========================================================

function Get-BloatDatabase {
    return $BloatDB
}

# =========================================================
# DEVICE-FIRST SCANNER (FIXED CORE)
# =========================================================

function Get-SystemApps {

    $db = Get-BloatDatabase
    $installed = Get-AppxPackage -AllUsers

    $results = foreach ($app in $installed) {

        foreach ($rule in $db) {

            if ($app.Name -like $rule.Pattern) {

                [PSCustomObject]@{
                    Name        = $app.Name
                    Package     = $app.PackageFullName
                    Category    = $rule.Category
                    Score       = $rule.Score
                    Recommended = ($rule.Score -ge 3)
                }

                break
            }
        }
    }

    return $results | Sort-Object Score -Descending -Unique
}

# =========================================================
# RECOMMENDATION ENGINE (FIXED)
# =========================================================

function Get-Recommendation($apps, $mode) {

    switch ($mode) {

        "Recommended" {
            return $apps | Where-Object { $_.Recommended -eq $true }
        }

        "Safe" {
            return $apps | Where-Object { $_.Score -ge 4 }
        }

        "Balanced" {
            return $apps | Where-Object { $_.Score -ge 3 }
        }

        "Aggressive" {
            return $apps | Where-Object { $_.Score -ge 2 }
        }
    }
}

# =========================================================
# REMOVE ENGINE (STABLE)
# =========================================================

function Remove-App($app) {
    try {
        Get-AppxPackage -AllUsers |
            Where-Object { $_.PackageFullName -eq $app.Package } |
            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

        Get-AppxProvisionedPackage -Online |
            Where-Object { $_.DisplayName -like $app.Name } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        return $true
    }
    catch {
        return $false
    }
}

# =========================================================
# UI SETUP
# =========================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "DebloaterPRO v4 FIXED"
$form.Size = New-Object System.Drawing.Size(900,700)
$form.StartPosition = "CenterScreen"

$tree = New-Object System.Windows.Forms.TreeView
$tree.Location = New-Object System.Drawing.Point(10,10)
$tree.Size = New-Object System.Drawing.Size(600,600)
$tree.CheckBoxes = $true

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan Device"
$btnScan.Location = New-Object System.Drawing.Point(620,20)

$btnRecommended = New-Object System.Windows.Forms.Button
$btnRecommended.Text = "Recommended"
$btnRecommended.Location = New-Object System.Drawing.Point(620,60)

$btnSafe = New-Object System.Windows.Forms.Button
$btnSafe.Text = "Safe Mode"
$btnSafe.Location = New-Object System.Drawing.Point(620,100)

$btnBalanced = New-Object System.Windows.Forms.Button
$btnBalanced.Text = "Balanced Mode"
$btnBalanced.Location = New-Object System.Drawing.Point(620,140)

$btnAggressive = New-Object System.Windows.Forms.Button
$btnAggressive.Text = "Aggressive Mode"
$btnAggressive.Location = New-Object System.Drawing.Point(620,180)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "REMOVE SELECTED"
$btnRemove.Location = New-Object System.Drawing.Point(620,240)
$btnRemove.Width = 200

$form.Controls.AddRange(@(
    $tree,$btnScan,$btnRecommended,
    $btnSafe,$btnBalanced,$btnAggressive,
    $btnRemove
))

# =========================================================
# GLOBAL STORE
# =========================================================

$script:AppData = @()

# =========================================================
# TREE LOADER (FIXED REAL DATA)
# =========================================================

function Load-Tree($apps) {

    $tree.Nodes.Clear()

    $groups = $apps | Group-Object Category

    foreach ($group in $groups) {

        $catNode = New-Object System.Windows.Forms.TreeNode($group.Name)

        foreach ($app in $group.Group) {

            $node = New-Object System.Windows.Forms.TreeNode($app.Name)
            $node.Tag = $app

            $catNode.Nodes.Add($node) | Out-Null
        }

        $tree.Nodes.Add($catNode) | Out-Null
    }

    $tree.ExpandAll()
}

# =========================================================
# SCAN BUTTON
# =========================================================

$btnScan.Add_Click({
    $script:AppData = Get-SystemApps

    if (-not $script:AppData -or $script:AppData.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No bloat apps detected on this system.")
        return
    }

    Load-Tree $script:AppData
})

# =========================================================
# RECOMMENDED BUTTON (FIXED LOGIC)
# =========================================================

$btnRecommended.Add_Click({
    $selected = Get-Recommendation $script:AppData "Recommended"

    foreach ($cat in $tree.Nodes) {
        foreach ($node in $cat.Nodes) {

            $node.Checked = $false

            if ($selected.Package -contains $node.Tag.Package) {
                $node.Checked = $true
            }
        }
    }
})

# =========================================================
# MODE BUTTONS (FIXED)
# =========================================================

$btnSafe.Add_Click({
    $selected = Get-Recommendation $script:AppData "Safe"

    foreach ($cat in $tree.Nodes) {
        foreach ($node in $cat.Nodes) {
            $node.Checked = ($selected.Package -contains $node.Tag.Package)
        }
    }
})

$btnBalanced.Add_Click({
    $selected = Get-Recommendation $script:AppData "Balanced"

    foreach ($cat in $tree.Nodes) {
        foreach ($node in $cat.Nodes) {
            $node.Checked = ($selected.Package -contains $node.Tag.Package)
        }
    }
})

$btnAggressive.Add_Click({
    $selected = Get-Recommendation $script:AppData "Aggressive"

    foreach ($cat in $tree.Nodes) {
        foreach ($node in $cat.Nodes) {
            $node.Checked = ($selected.Package -contains $node.Tag.Package)
        }
    }
})

# =========================================================
# REMOVE SELECTED
# =========================================================

$btnRemove.Add_Click({

    $toRemove = @()

    foreach ($cat in $tree.Nodes) {
        foreach ($node in $cat.Nodes) {
            if ($node.Checked) {
                $toRemove += $node.Tag
            }
        }
    }

    if ($toRemove.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nothing selected.")
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Remove $($toRemove.Count) apps?",
        "Confirm",
        "YesNo"
    )

    if ($confirm -ne "Yes") { return }

    foreach ($app in $toRemove) {
        Remove-App $app
    }

    [System.Windows.Forms.MessageBox]::Show("Completed.")
})

# =========================================================
# RUN APP
# =========================================================

[System.Windows.Forms.Application]::Run($form)
