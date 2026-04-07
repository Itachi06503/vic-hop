-- ==============================================================================
-- 🐝 BSS VICIOUS FARMER | PRO VERSION (OPTIMIZED REVISION)
-- ==============================================================================
local WebhookURL = "YOUR_WEBHOOK_URL_HERE" -- [!] PASTE YOUR WEBHOOK HERE

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(5) 

-- ==============================================================================
-- 🛡️ 1. ADVANCED SECURITY MODULE (TELEMETRY & STAT BLOCKER)
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
                elseif method == "SendStats" or method == "ReportAbuse" then
                    return
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

local TeleportService = GetSafeService("TeleportService")
local HttpService     = GetSafeService("HttpService")
local Players         = GetSafeService("Players")
local Workspace       = GetSafeService("Workspace")
local GuiService      = GetSafeService("GuiService")
local VirtualUser     = GetSafeService("VirtualUser")
local Lighting        = GetSafeService("Lighting")
local RunService      = GetSafeService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local GUI_NAME = GenerateRandomString(14)
local FRAME_NAME = GenerateRandomString(12)

-------------------------------------------------------------------------------
-- ⚙️ 2. INSTANT MOBILE FPS & BATTERY BOOSTER
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

pcall(function()
    if setfpscap then
        RunService.WindowFocusReleased:Connect(function() setfpscap(15) end)
        RunService.WindowFocused:Connect(function() setfpscap(60) end)
    end
end)

-------------------------------------------------------------------------------
-- 💾 3. DEVICE FILE SAVING & LOOT TRACKER
-------------------------------------------------------------------------------
local sessionGained = 0
local popupListener = nil
local SaveFileName = "ViciousSessionTotal_Pro.txt"
local sessionTotalFarmed = 0

pcall(function()
    if isfile and isfile(SaveFileName) then
        sessionTotalFarmed = tonumber(readfile(SaveFileName)) or 0
    end
end)

local function updateSessionFile(addedAmount)
    sessionTotalFarmed = sessionTotalFarmed + addedAmount
    pcall(function()
        if writefile then writefile(SaveFileName, tostring(sessionTotalFarmed)) end
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
                        if amount then sessionGained = sessionGained + amount end
                    end
                end)
            end)
        end
    end)
end

local function stopLootListener()
    if popupListener then popupListener:Disconnect(); popupListener = nil end
    return sessionGained
end

local function sendDiscordLog(gained, sessionTotal)
    if WebhookURL == "" or WebhookURL == "YOUR_WEBHOOK_URL_HERE" then return end
    
    task.spawn(function()
        pcall(function()
            local embedColor = gained > 0 and 65280 or 16753920 -- Hex to Dec
            local data = {
                ["embeds"] = {{
                    ["title"] = "🐝 Vicious Bee Defeated!",
                    ["description"] = `Successfully cleared a server!\n**Server ID:** ||{game.JobId}||`,
                    ["color"] = embedColor,
                    ["fields"] = {
                        {["name"] = "🗡️ Stingers Gained", ["value"] = `+{gained}`, ["inline"] = true},
                        {["name"] = "📈 Session Farmed", ["value"] = tostring(sessionTotal), ["inline"] = true}
                    },
                    ["footer"] = {["text"] = "Delta Auto-Hopper • Pro Version"}
                }}
            }
            local httpRequest = (request or http_request or HttpPost or syn.request)
            if httpRequest then
                httpRequest({
                    Url = WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(data)
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
-- 🖥️ 5. OBFUSCATED COLLAPSIBLE UI 
-------------------------------------------------------------------------------
pcall(function()
    local hiddenGui = gethui and gethui() or game:GetService("CoreGui")
    for _, v in ipairs(hiddenGui:GetChildren()) do 
        if v:IsA("ScreenGui") and v:FindFirstChildOfClass("Frame") and v.Frame.Size.Y.Offset >= 70 then 
            v:Destroy() 
        end 
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = gethui() end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = FRAME_NAME
MainFrame.Size = UDim2.new(0, 240, 0, 70) 
MainFrame.Position = UDim2.new(0.5, -120, 0, 20) 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 15)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TopBar.BorderSizePixel = 0

local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "[-]"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 12

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 15)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Initializing Pro Stealth..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 13
StatusLabel.TextWrapped = true

local ResetBtn = Instance.new("TextButton", MainFrame)
ResetBtn.Size = UDim2.new(1, -10, 0, 25)
ResetBtn.Position = UDim2.new(0, 5, 0, 40)
ResetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ResetBtn.BackgroundTransparency = 0.3
ResetBtn.BorderSizePixel = 1
ResetBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
ResetBtn.Text = `Reset (Saved: {sessionTotalFarmed})`
ResetBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
ResetBtn.Font = Enum.Font.Code
ResetBtn.TextSize = 13

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 240, 0, 15) or UDim2.new(0, 240, 0, 70)
    StatusLabel.Visible = not minimized
    ResetBtn.Visible = not minimized
    MinBtn.Text = minimized and "[+]" or "[-]"
end)

ResetBtn.MouseButton1Click:Connect(function()
    sessionTotalFarmed = 0
    pcall(function() if writefile then writefile(SaveFileName, "0") end end)
    ResetBtn.Text = "Reset (Saved: 0)"
    StatusLabel.Text = "Memory wiped!"
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
local failedAttempts = 0 
local lastFailTime = 0 

local function checkAntiStuck()
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position.Y < -50 then
            StatusLabel.Text = "Stuck in void! Resetting..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            char:BreakJoints()
            task.wait(6) 
        end
    end)
end

-------------------------------------------------------------------------------
-- 🚀 7. SAFER TELEPORT LOGIC
-------------------------------------------------------------------------------
if getgenv().TpFailConnection then getgenv().TpFailConnection:Disconnect() end
getgenv().TpFailConnection = TeleportService.TeleportInitFailed:Connect(function(player)
    if player == LocalPlayer then
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
    blacklistedServers[targetId] = true
    StatusLabel.Text = `Teleporting ({pCountLabel})...`
    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    
    local success = pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, targetId, LocalPlayer) end)
    if not success then
        failedAttempts += 1
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
        task.delay(20, function() isHopping = false end)
        return 
    end
    
    task.spawn(function()
        local cursor = ""
        local page = 1
        local validServers, fallbackServers = {}, {}
        
        while page <= 50 do
            StatusLabel.Text = `Scanning Network Pg {page}...`
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            
            local url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100`
            if cursor ~= "" then url ..= `&cursor={cursor}` end
            
            local success, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
            
            if success and result and result.data then
                for _, srv in ipairs(result.data) do
                    if srv.id ~= game.JobId and not blacklistedServers[srv.id] and type(srv.ping) == "number" and srv.ping < 500 then
                        if srv.playing >= 2 and srv.playing <= 6 then table.insert(validServers, srv)
                        elseif srv.playing == 1 then table.insert(fallbackServers, srv) end
                    end
                end
                
                if #validServers > 0 then
                    table.sort(validServers, function(a, b) return a.playing < b.playing end)
                    local bestTarget = validServers[math.random(1, math.min(#validServers, 5))]
                    executeTeleport(bestTarget.id, `{bestTarget.playing} players`)
                    return 
                end
                
                if result.nextPageCursor then
                    cursor = result.nextPageCursor
                    page += 1
                    task.wait(1) 
                else break end
            else
                StatusLabel.Text = "Rate limited. Waiting 15s..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(15) 
                break
            end
        end
        
        if #fallbackServers > 0 then
            executeTeleport(fallbackServers[math.random(1, #fallbackServers)].id, "1 player fallback")
        else
            StatusLabel.Text = "No Valid Servers! Random Hop..."
            failedAttempts += 1
            pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
            task.delay(20, function() isHopping = false end)
        end
    end)
end

-------------------------------------------------------------------------------
-- 🔨 9. ERROR 279 & 268 (KICK) CRUSHER (NATIVE UI EVENT)
-------------------------------------------------------------------------------
if getgenv().KickConnection then getgenv().KickConnection:Disconnect() end
getgenv().KickConnection = GuiService.ErrorMessageChanged:Connect(function(message)
    if message == "" then return end
    local lowerMsg = string.lower(message)
    
    if string.find(lowerMsg, "268") or string.find(lowerMsg, "unexpected client behavior") then
        StatusLabel.Text = "SOFT KICK (268)! Cooling down 30s..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
        task.wait(30)
    elseif string.find(lowerMsg, "279") or string.find(lowerMsg, "disconnected") then
        StatusLabel.Text = "DISCONNECTED! Reconnecting in 10s..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(10)
    end
    
    pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
end)

-------------------------------------------------------------------------------
-- 🐝 10. OPTIMIZED VICIOUS DETECTOR (EVENT DRIVEN)
-------------------------------------------------------------------------------
local viciousExists = false
local activeViciousNodes = {}

local function checkViciousNode(node)
    if node and string.find(string.lower(node.Name), "vicious") then
        activeViciousNodes[node] = true
        viciousExists = true
    end
end

local function removeViciousNode(node)
    if activeViciousNodes[node] then
        activeViciousNodes[node] = nil
        if next(activeViciousNodes) == nil then viciousExists = false end
    end
end

-- Hook onto Monsters and Particles safely
local function setupFolderTracker(folderName)
    local folder = Workspace:WaitForChild(folderName, 5)
    if folder then
        for _, child in ipairs(folder:GetChildren()) do checkViciousNode(child) end
        folder.ChildAdded:Connect(checkViciousNode)
        folder.ChildRemoved:Connect(removeViciousNode)
    end
end

setupFolderTracker("Monsters")
setupFolderTracker("Particles")

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

        if viciousExists then
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
                
                ResetBtn.Text = `Reset (Saved: {sessionTotalFarmed})`
                sendDiscordLog(gainedStingers, sessionTotalFarmed)
                
                atlasExecuted = false -- Reset state for next server
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
