-- ==============================================================================
-- 🐝 BSS VICIOUS FARMER | ERROR 279 PATCH (GHOST SERVER EVASION)
-- ==============================================================================
local WebhookURL = "https://discord.com/api/webhooks/1487070973827219538/80wfTSKpFD4tYONg7oG4y6uqO3ayAdXrbwwIf6WjUySN7VaH5EDH110lWcfMThZBrCW9"

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(5) 

-- ==============================================================================
-- 🛡️ 1. ADVANCED SECURITY MODULE (TELEMETRY BLOCKER & CLONEREF)
-- ==============================================================================
local function GetSafeService(serviceName)
    local service = game:GetService(serviceName)
    if cloneref then return cloneref(service) end
    return service
end

pcall(function()
    if hookmetamethod and getnamecallmethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "GetLogHistory" or method == "GetMessage" then
                    return {} 
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

local function GenerateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. string.sub(chars, rand, rand)
    end
    return result
end

-- Safe Services
local TeleportService = GetSafeService("TeleportService")
local HttpService     = GetSafeService("HttpService")
local Players         = GetSafeService("Players")
local Workspace       = GetSafeService("Workspace")
local GuiService      = GetSafeService("GuiService")
local CoreGui         = GetSafeService("CoreGui")
local VirtualUser     = GetSafeService("VirtualUser")
local Lighting        = GetSafeService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GUI_NAME = GenerateRandomString(14)
local FRAME_NAME = GenerateRandomString(12)

-------------------------------------------------------------------------------
-- ⚙️ 2. INSTANT MOBILE FPS BOOSTER
-------------------------------------------------------------------------------
task.spawn(function()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Workspace.Terrain.Decoration = false
        
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("Terrain") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
    end)
end)

-------------------------------------------------------------------------------
-- 💾 3. DEVICE FILE SAVING & LOOT TRACKER
-------------------------------------------------------------------------------
local sessionGained = 0
local popupListener = nil
local SaveFileName = "ViciousSessionTotal_Secured.txt"
local sessionTotalFarmed = 0

pcall(function()
    if isfile and isfile(SaveFileName) then
        sessionTotalFarmed = tonumber(readfile(SaveFileName)) or 0
    end
end)

local function updateSessionFile(addedAmount)
    sessionTotalFarmed = sessionTotalFarmed + addedAmount
    pcall(function()
        if writefile then
            writefile(SaveFileName, tostring(sessionTotalFarmed))
        end
    end)
end

local function startLootListener()
    sessionGained = 0
    if popupListener then popupListener:Disconnect(); popupListener = nil end
    
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    popupListener = playerGui.DescendantAdded:Connect(function(desc)
        if desc:IsA("TextLabel") then
            task.delay(0.2, function()
                pcall(function()
                    local text = string.lower(desc.Text)
                    if string.find(text, "stinger") then
                        local amount = tonumber(string.match(text, "%d+"))
                        if amount then
                            sessionGained = sessionGained + amount
                        end
                    end
                end)
            end)
        end
    end)
end

local function stopLootListener()
    if popupListener then 
        popupListener:Disconnect()
        popupListener = nil 
    end
    return sessionGained
end

local function sendDiscordLog(gained, sessionTotal)
    if WebhookURL == "" or WebhookURL == "YOUR_WEBHOOK_URL_HERE" then return end
    
    task.spawn(function()
        pcall(function()
            local embedColor = gained > 0 and tonumber("0x00FF00") or tonumber("0xFFA500") 
            
            local data = {
                ["embeds"] = {{
                    ["title"] = "🐝 Vicious Bee Defeated!",
                    ["description"] = `Successfully cleared a server!\n**Server ID:** ||{game.JobId}||`,
                    ["color"] = embedColor,
                    ["fields"] = {
                        {
                            ["name"] = "🗡️ Stingers Gained",
                            ["value"] = `+{gained}`,
                            ["inline"] = true
                        },
                        {
                            ["name"] = "📈 Session Farmed",
                            ["value"] = tostring(sessionTotal),
                            ["inline"] = true
                        }
                    },
                    ["footer"] = {["text"] = "Delta Auto-Hopper • Stealth Version"}
                }}
            }
            local jsonData = HttpService:JSONEncode(data)
            local httpRequest = (request or http_request or HttpPost or syn.request)
            
            if httpRequest then
                httpRequest({
                    Url = WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsonData
                })
            end
        end)
    end)
end

-------------------------------------------------------------------------------
-- 💤 4. GARBAGE-COLLECTED ANTI-AFK
-------------------------------------------------------------------------------
if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect() end

getgenv().AntiAfkConnection = LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-------------------------------------------------------------------------------
-- 🖥️ 5. OBFUSCATED UI CREATION 
-------------------------------------------------------------------------------
pcall(function()
    local hiddenGui = gethui and gethui() or CoreGui
    for _, v in ipairs(hiddenGui:GetChildren()) do 
        if v:IsA("ScreenGui") and v:FindFirstChildOfClass("Frame") and v.Frame.Size.Y.Offset == 70 then 
            v:Destroy() 
        end 
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false

local successMount = pcall(function() ScreenGui.Parent = gethui() end)
if not successMount or not ScreenGui.Parent then 
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = FRAME_NAME
MainFrame.Size = UDim2.new(0, 240, 0, 70) 
MainFrame.Position = UDim2.new(0.5, -120, 0, 20) 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Initializing Stealth UI..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainFrame

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, 0, 0, 30)
ResetBtn.Position = UDim2.new(0, 0, 0, 40)
ResetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ResetBtn.BackgroundTransparency = 0.3
ResetBtn.BorderSizePixel = 1
ResetBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
ResetBtn.Text = `Reset Session (Saved: {sessionTotalFarmed})`
ResetBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
ResetBtn.Font = Enum.Font.Code
ResetBtn.TextSize = 14
ResetBtn.Parent = MainFrame

ResetBtn.MouseButton1Click:Connect(function()
    sessionTotalFarmed = 0
    pcall(function() if writefile then writefile(SaveFileName, "0") end end)
    ResetBtn.Text = "Reset Session (Saved: 0)"
    StatusLabel.Text = "Internal memory wiped!"
    StatusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
end)

-------------------------------------------------------------------------------
-- 🔄 6. ANTI-STUCK & STATE VARIABLES
-------------------------------------------------------------------------------
local atlasExecuted = false
local isHopping = false
local hopCountdown = 10 
local hopStartTime = 0 

local blacklistedServers = {} 
local currentTargetId = nil   
local failedAttempts = 0 
local lastFailTime = 0 

local function checkAntiStuck()
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if char.HumanoidRootPart.Position.Y < -50 then
                StatusLabel.Text = "Stuck in void! Resetting..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                char:BreakJoints()
                task.wait(6) 
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- 🚀 7. SAFER TELEPORT LOGIC
-------------------------------------------------------------------------------
if getgenv().TpFailConnection then getgenv().TpFailConnection:Disconnect() end

getgenv().TpFailConnection = TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        if currentTargetId then blacklistedServers[currentTargetId] = true end
        
        if os.time() - lastFailTime > 2 then
            failedAttempts += 1
            lastFailTime = os.time()
        end
        
        StatusLabel.Text = "Roblox TP Fail! 15s Timeout..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        
        task.wait(15)
        isHopping = false
    end
end)

local function executeTeleport(targetId, pCountLabel)
    currentTargetId = targetId
    StatusLabel.Text = `Teleporting ({pCountLabel})...`
    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, targetId, LocalPlayer)
    end)
    
    if not success then
        blacklistedServers[targetId] = true
        if os.time() - lastFailTime > 2 then
            failedAttempts += 1
            lastFailTime = os.time()
        end
        
        StatusLabel.Text = "TP Error! 15s Timeout..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(15)
        isHopping = false
    end
end

-------------------------------------------------------------------------------
-- 🔍 8. THE GHOST-EVADING SERVER SCANNER
-------------------------------------------------------------------------------
local function performHop()
    if isHopping then return end
    isHopping = true
    hopStartTime = os.time() 
    
    if failedAttempts >= 3 then
        StatusLabel.Text = "Loop Detected! Random Hop..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        failedAttempts = 0 
        
        pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
        task.defer(function()
            task.wait(20)
            isHopping = false 
        end)
        return 
    end
    
    task.spawn(function()
        local cursor = ""
        local page = 1
        local maxPages = 50 
        local rateLimitRetries = 0
        
        local validServers = {}
        local fallbackServers = {}
        
        while page <= maxPages do
            StatusLabel.Text = `Scanning Network Pg {page}...`
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            
            local url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100`
            if cursor ~= "" then url ..= `&cursor={cursor}` end
            url ..= `&_={math.random(10000, 99999)}`
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if success and result and result.data then
                rateLimitRetries = 0 
                
                for _, srv in ipairs(result.data) do
                    -- Filter out servers with crazy high ping (likely dead)
                    if srv.id ~= game.JobId and not blacklistedServers[srv.id] and type(srv.ping) == "number" and srv.ping < 500 then
                        if srv.playing >= 2 and srv.playing <= 6 then
                            table.insert(validServers, srv)
                        elseif srv.playing == 1 then
                            table.insert(fallbackServers, srv)
                        end
                    end
                end
                
                if #validServers > 0 then
                    table.sort(validServers, function(a, b) return a.playing < b.playing end)
                    
                    -- GHOST EVASION: Pick a random server from the top 5 instead of the absolute lowest
                    -- This prevents the script from constantly hitting the exact same dead "1-player" server
                    local selectionRange = math.min(#validServers, 5)
                    local bestTarget = validServers[math.random(1, selectionRange)]
                    
                    executeTeleport(bestTarget.id, `{bestTarget.playing} players`)
                    return 
                end
                
                if result.nextPageCursor then
                    cursor = result.nextPageCursor
                    page += 1
                    task.wait(1.5) 
                else
                    break 
                end
            else
                rateLimitRetries += 1
                if rateLimitRetries > 3 then break end
                
                StatusLabel.Text = "Rate limited. Waiting 15s..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(15) 
            end
        end
        
        if #fallbackServers > 0 then
            local target = fallbackServers[math.random(1, #fallbackServers)]
            executeTeleport(target.id, "1 player fallback")
        else
            StatusLabel.Text = "No Valid Servers! Random Hop..."
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 255)
            failedAttempts += 1
            pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
            task.wait(20)
            isHopping = false 
        end
    end)
end

-------------------------------------------------------------------------------
-- 🔨 9. ERROR 279 CRUSHER & RECONNECT HANDLER
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
            if prompt then
                local overlay = prompt:FindFirstChild("promptOverlay")
                if overlay then
                    local errorPrompt = overlay:FindFirstChild("ErrorPrompt")
                    if errorPrompt and errorPrompt.Visible then
                        
                        -- Check specifically if it's a 279 error
                        local is279 = false
                        pcall(function()
                            local msg = errorPrompt.MessageArea.ErrorFrame.ErrorMessage.Text
                            if string.find(msg, "279") then is279 = true end
                        end)

                        GuiService:ClearError() 
                        
                        if is279 then
                            StatusLabel.Text = "ERROR 279 DETECTED! Waiting 10s..."
                            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                            task.wait(10) -- Give network time to clear ghost connection
                        else
                            StatusLabel.Text = "DISCONNECTED! Forcing reconnect..."
                            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                        end
                        
                        -- Teleport to a totally fresh random server
                        TeleportService:Teleport(PlaceId, LocalPlayer)
                        task.wait(15)
                    end
                end
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 🐝 10. VICIOUS DETECTOR
-------------------------------------------------------------------------------
local function isViciousAlive()
    local folders = {Workspace:FindFirstChild("Particles"), Workspace:FindFirstChild("Monsters")}
    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if string.find(string.lower(obj.Name), "vicious") and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    return true
                end
            end
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- ⏳ 11. MAIN TIMELINE LOOP
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if isHopping then
            if os.time() - hopStartTime > 120 then
                isHopping = false
                failedAttempts += 1
                StatusLabel.Text = "Watchdog Reset! Retrying hop..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
            continue 
        end 
        
        checkAntiStuck() 
        
        local viciousHere = isViciousAlive()

        if viciousHere then
            if not atlasExecuted then
                StatusLabel.Text = "Vicious Found! Tracking Screen..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                
                startLootListener()
                atlasExecuted = true
                
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
                end)
            else
                StatusLabel.Text = "Killing Vicious..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        else
            if atlasExecuted then
                StatusLabel.Text = "Bee dead! Waiting for popup..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 255)
                
                task.wait(5)
                
                local gainedStingers = stopLootListener()
                updateSessionFile(gainedStingers)
                
                ResetBtn.Text = `Reset Session (Saved: {sessionTotalFarmed})`
                sendDiscordLog(gainedStingers, sessionTotalFarmed)
                
                performHop()
            else
                local clockTime = Lighting.ClockTime
                local isNight = clockTime >= 17.5 or clockTime < 6
                
                if not isNight then
                    StatusLabel.Text = "Daytime/Dusk. Speed Skipping..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    performHop()
                else
                    if hopCountdown > 0 then
                        StatusLabel.Text = `Night Search. Hopping in {hopCountdown}s`
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                        hopCountdown -= 1
                    else
                        performHop()
                    end
                end
            end
        end
    end
end)
