#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================================================
# CONFIG - ONLINE BLOAT DATABASE (GitHub RAW JSON)
# =========================================================

$BloatDBUrl = "https://raw.githubusercontent.com/Tarik-Monwar/win11-debloater-pro/main/bloatdb.json"

function Get-BloatDatabase {
    try {
        return Invoke-RestMethod -Uri $BloatDBUrl -UseBasicParsing -ErrorAction Stop
    } catch {
        # fallback offline DB (critical apps included)
        return @(
            @{ Pattern="*TikTok*"; Score=5; Category="Social" },
            @{ Pattern="*Instagram*"; Score=5; Category="Social" },
            @{ Pattern="*Facebook*"; Score=4; Category="Social" },
            @{ Pattern="*Xbox*"; Score=3; Category="Gaming" },
            @{ Pattern="*CandyCrush*"; Score=4; Category="Games" },
            @{ Pattern="*Solitaire*"; Score=2; Category="Games" },
            @{ Pattern="*Bing*"; Score=3; Category="Microsoft" },
            @{ Pattern="*Clipchamp*"; Score=3; Category="Media" },
            @{ Pattern="*YourPhone*"; Score=3; Category="System" },
            @{ Pattern="*PhoneLink*"; Score=3; Category="System" },
            @{ Pattern="*Teams*"; Score=3; Category="Productivity" },
            @{ Pattern="*MixedReality*"; Score=4; Category="System" },
            @{ Pattern="*Zune*"; Score=2; Category="Legacy" }
        )
    }
}

# =========================================================
# SCAN SYSTEM APPS
# =========================================================

function Get-SystemApps {
    $db = Get-BloatDatabase
    $apps = Get-AppxPackage -AllUsers

    $result = foreach ($app in $apps) {

        $match = $db | Where-Object { $app.Name -like $_.Pattern }

        if ($match) {
            $score = ($match.Score | Measure-Object -Maximum).Maximum

            [PSCustomObject]@{
                Name     = $app.Name
                Package  = $app.PackageFullName
                Category = ($match.Category | Select-Object -First 1)
                Score    = $score
                Keep     = $false
            }
        }
    }

    return $result | Sort-Object Score -Descending
}

# =========================================================
# RECOMMENDATION ENGINE
# =========================================================

function Get-Recommendations($apps, $mode) {

    switch ($mode) {
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
# REMOVE ENGINE
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
    } catch {
        return $false
    }
}

# =========================================================
# UI SETUP
# =========================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "DebloaterPRO v4 Enterprise"
$form.Size = New-Object System.Drawing.Size(900,700)
$form.StartPosition = "CenterScreen"

$tree = New-Object System.Windows.Forms.TreeView
$tree.Location = New-Object System.Drawing.Point(10,10)
$tree.Size = New-Object System.Drawing.Size(600,600)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan Apps"
$btnScan.Location = New-Object System.Drawing.Point(620,20)

$btnRecommend = New-Object System.Windows.Forms.Button
$btnRecommend.Text = "Recommended"
$btnRecommend.Location = New-Object System.Drawing.Point(620,60)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove Selected"
$btnRemove.Location = New-Object System.Drawing.Point(620,100)

$modeBox = New-Object System.Windows.Forms.ComboBox
$modeBox.Items.AddRange(@("Safe","Balanced","Aggressive"))
$modeBox.SelectedIndex = 1
$modeBox.Location = New-Object System.Drawing.Point(620,140)

$form.Controls.AddRange(@($tree,$btnScan,$btnRecommend,$btnRemove,$modeBox))

# =========================================================
# GLOBAL DATA STORE
# =========================================================

$script:AppData = @()

# =========================================================
# BUILD TREE VIEW
# =========================================================

function Load-Tree($apps) {

    $tree.Nodes.Clear()

    $grouped = $apps | Group-Object Category

    foreach ($group in $grouped) {

        $catNode = New-Object System.Windows.Forms.TreeNode($group.Name)

        foreach ($app in $group.Group) {

            $node = New-Object System.Windows.Forms.TreeNode($app.Name)
            $node.Tag = $app

            if ($app.Keep -eq $true) {
                $node.Checked = $true
            }

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
    Load-Tree $script:AppData
})

# =========================================================
# RECOMMENDED BUTTON (YOUR REQUEST FEATURE)
# =========================================================

$btnRecommend.Add_Click({

    $mode = $modeBox.SelectedItem
    $recommended = Get-Recommendations $script:AppData $mode

    foreach ($cat in $tree.Nodes) {
        foreach ($node in $cat.Nodes) {

            $match = $recommended | Where-Object {
                $_.Package -eq $node.Tag.Package
            }

            if ($match) {
                $node.Checked = $true
            }
        }
    }
})

# =========================================================
# REMOVE BUTTON
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
        [System.Windows.Forms.MessageBox]::Show("No apps selected")
        return
    }

    foreach ($app in $toRemove) {
        Remove-App $app
    }

    [System.Windows.Forms.MessageBox]::Show("Done removing selected apps")
})

# =========================================================
# RUN APP
# =========================================================

[System.Windows.Forms.Application]::Run($form)
