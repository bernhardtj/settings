# Install/Update arkenfox into Firefox on Windows
# Dependencies: git, firefox

$originalLocation = Get-Location
$iniPath = Join-Path -Path $env:APPDATA -ChildPath "Mozilla\Firefox\profiles.ini"

if (-Not (Test-Path $iniPath)) {
    Write-Error "Firefox profiles.ini not found. Is Firefox installed?"
    exit 1
}

# Parse profiles.ini
$profiles = @()
$currentProfile = @{}
$inProfileSection = $false

foreach ($line in Get-Content $iniPath) {
    $trimmed = $line.Trim()

    if ($trimmed -match "^\[.*\]") {
        if ($currentProfile.Count -gt 0) {
            $profiles += $currentProfile
            $currentProfile = @{}
        }
        $inProfileSection = $trimmed -match "^\[Profile\d+\]"
    } elseif ($inProfileSection -and $trimmed -match "=") {
        $key, $value = $trimmed -split "=", 2
        $currentProfile[$key.Trim()] = $value.Trim()
    }
}
if ($inProfileSection -and $currentProfile.Count -gt 0) {
    $profiles += $currentProfile
}

if ($profiles.Count -eq 0) {
    Write-Error "No Firefox profiles found in profiles.ini."
    exit 1
}


# Filter and display valid profiles
Write-Host "`nAvailable Firefox Profiles (with prefs.js):" -ForegroundColor Cyan
$validProfiles = @()
for ($i = 0; $i -lt $profiles.Count; $i++) {
    $myprofile = $profiles[$i]
    $relativePath = $myprofile["Path"]
    $isRelative = $myprofile["IsRelative"]
    $basePath = if ($isRelative -eq "1") { "$env:APPDATA\Mozilla\Firefox" } else { "" }
    $folder = Join-Path -Path $basePath -ChildPath $relativePath
    $prefsPath = Join-Path $folder "prefs.js"

    if (Test-Path $prefsPath) {
        $validProfiles += [PSCustomObject]@{
            Index = $validProfiles.Count
            Name  = $myprofile["Name"]
            Path  = $relativePath
            FullPath = $folder
            ProfileData = $myprofile
        }
        Write-Host "$($validProfiles.Count - 1) - $($myprofile["Name"]) ($relativePath)"
    }
}

if ($validProfiles.Count -eq 0) {
    Write-Error "No initialized profiles with prefs.js found. Please run Firefox at least once with your profile."
    exit 1
}

$inputValue = Read-Host "`nEnter the number of the profile you want to use (default 0)"
if ([string]::IsNullOrWhiteSpace($inputValue)) {
    $index = 0
} elseif ($inputValue -match "^\d+$" -and [int]$inputValue -lt $validProfiles.Count) {
    $index = [int]$inputValue
} else {
    Write-Error "Invalid selection."
    exit 1
}

# Continue with the selected profile
$selected = $validProfiles[$index]
$folder = $selected.FullPath

try {
    Set-Location -Path $folder -ErrorAction Stop

    git init
    if ($LASTEXITCODE -ne 0) { throw "Failed to initialize Git repository." }

    $existingRemotes = git remote
    if ($existingRemotes -match "origin") {
        git checkout master
        if ($LASTEXITCODE -ne 0) { throw "Failed to checkout 'master' branch." }
    } else {
        git remote add origin https://github.com/arkenfox/user.js
        git checkout -b master
    }

    git pull origin master
    if ($LASTEXITCODE -ne 0) { throw "Failed to pull from remote repository." }

    $prefsCleaner = Join-Path $folder "prefsCleaner.bat"
    Write-Host "`nRunning prefsCleaner.bat..." -ForegroundColor Green
    Start-Process -FilePath $prefsCleaner -Wait

    $updater = Join-Path $folder "updater.bat"
    Write-Host "`nRunning updater.bat..." -ForegroundColor Green
    Start-Process -FilePath $updater -Wait

    Write-Host "`nAll tasks completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    Set-Location -Path $originalLocation
}
