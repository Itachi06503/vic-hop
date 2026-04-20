-- ==============================================================================
-- 👑 BSS VICIOUS FARMER | THE OVERNIGHT MASTERPIECE (V3)
-- ==============================================================================
local WebhookURL = "https://discord.com/api/webhooks/1487070973827219538/80wfTSKpFD4tYONg7oG4y6uqO3ayAdXrbwwIf6WjUySN7VaH5EDH110lWcfMThZBrCW9"

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(2)

-- ==========================================
-- 🛡️ 1. CORE SERVICES & SECURITY
-- ==========================================
local function GetSafeService(serviceName)
    local service = game:GetService(serviceName)
    if cloneref then return cloneref(service) end
    return service
end

-- Block telemetry
pcall(function()
    if hookmetamethod and getnamecallmethod and checkcaller then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and (method == "SendStats" or method == "ReportAbuse" or method == "GetLogHistory") then return end
            return oldNamecall(self, ...)
        end)
    end
end)

local TeleportService = GetSafeService("TeleportService")
local HttpService     = GetSafeService("HttpService")
local Players         = GetSafeService("Players")
local Workspace       = GetSafeService("Workspace")
local GuiService      = GetSafeService("GuiService")
local CoreGui         = GetSafeService("CoreGui")
local VirtualUser     = GetSafeService("VirtualUser")
local Lighting        = GetSafeService("Lighting")
local LocalPlayer     = Players.LocalPlayer
local PlaceId         = game.PlaceId

-- ==========================================
-- 📱 2. MASTERPIECE UI & LOGGING
-- ==========================================
local GUI_NAME = "BSS_Overnight_Master"
pcall(function()
    local target = gethui and gethui() or CoreGui
    if target:FindFirstChild(GUI_NAME) then target[GUI_NAME]:Destroy() end
end)

local sg = Instance.new("ScreenGui", gethui and gethui() or CoreGui)
sg.Name = GUI_NAME
sg.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 320, 0, 280)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local header = Instance.new("TextLabel", mainFrame)
header.Size = UDim2.new(1, 0, 0, 35)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for Masterpiece
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.Text = " 👑 Overnight Masterpiece V3"
header.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

local statsBar = Instance.new("TextLabel", mainFrame)
statsBar.Size = UDim2.new(1, -20, 0, 25)
statsBar.Position = UDim2.new(0, 10, 0, 45)
statsBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statsBar.TextColor3 = Color3.fromRGB(100, 255, 100)
statsBar.Font = Enum.Font.GothamBold
statsBar.TextSize = 12
statsBar.Text = " 🗡️ Stingers Saved: Loading..."
statsBar.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 4)

local logScroll = Instance.new("ScrollingFrame", mainFrame)
logScroll.Size = UDim2.new(1, -20, 1, -90)
logScroll.Position = UDim2.new(0, 10, 0, 80)
logScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.ScrollBarThickness = 2
Instance.new("UICorner", logScroll).CornerRadius = UDim.new(0, 6)
local logLayout = Instance.new("UIListLayout", logScroll)
logLayout.Padding = UDim.new(0, 2)

local function addLog(text, color)
    local lbl = Instance.new("TextLabel", logScroll)
    lbl.Size = UDim2.new(1, -10, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.Text = " " .. text
    logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteWindowSize.Y + 1000)
end

-- ==========================================
-- 💾 3. PERSISTENT LOOT TRACKER
-- ==========================================
local SaveFileName = "ViciousOvernight_Data.txt"
local sessionTotalFarmed = 0
local sessionGained = 0
local popupListener = nil

pcall(function()
    if isfile and isfile(SaveFileName) then
        sessionTotalFarmed = tonumber(readfile(SaveFileName)) or 0
    end
end)
statsBar.Text = " 🗡️ Stingers Saved: " .. tostring(sessionTotalFarmed)

local function updateSessionFile(addedAmount)
    sessionTotalFarmed = sessionTotalFarmed + addedAmount
    statsBar.Text = " 🗡️ Stingers Saved: " .. tostring(sessionTotalFarmed)
    pcall(function() if writefile then writefile(SaveFileName, tostring(sessionTotalFarmed)) end end)
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
                            addLog("+" .. amount .. " Stingers!", Color3.fromRGB(255, 215, 0))
                        end
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

-- ==========================================
-- 🚀 4. BULLETPROOF ANTI-DISCONNECT ENGINE
-- ==========================================
-- Anti-AFK
if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect() end
getgenv().AntiAfkConnection = LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Native Error Catcher (Listens directly to Roblox Engine)
if getgenv().ErrorCatcher then getgenv().ErrorCatcher:Disconnect() end
getgenv().ErrorCatcher = GuiService.ErrorMessageChanged:Connect(function(errorMsg)
    if errorMsg and errorMsg ~= "" then
        addLog("CRITICAL ERROR: " .. errorMsg, Color3.fromRGB(255, 50, 50))
        addLog("Force Reconnecting in 5s...", Color3.fromRGB(255, 100, 100))
        task.wait(5)
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end
end)

-- Backup CoreGui Error Catcher (For tricky 268/279 errors)
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
            if prompt and prompt:FindFirstChild("promptOverlay") then
                local errorPrompt = prompt.promptOverlay:FindFirstChild("ErrorPrompt")
                if errorPrompt and errorPrompt.Visible then
                    GuiService:ClearError() 
                    addLog("UI POPUP BLOCKED! Forcing Reconnect...", Color3.fromRGB(255, 50, 50))
                    task.wait(2)
                    TeleportService:Teleport(PlaceId, LocalPlayer)
                end
            end
        end)
    end
end)

-- FPS Booster (For overnight stability)
task.spawn(function()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Workspace.Terrain.Decoration = false
    end)
end)

-- ==========================================
-- 🔄 5. SERVER QUEUE (ANTI-RATE LIMIT HOPPER)
-- ==========================================
getgenv().ServerQueue = getgenv().ServerQueue or {}
local isHopping = false

local function ScrapeServers()
    addLog("Scraping Roblox API for servers...", Color3.fromRGB(150, 200, 255))
    local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
    local success, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
    
    if success and result and result.data then
        local tempQueue = {}
        for _, srv in ipairs(result.data) do
            if srv.id ~= game.JobId and srv.playing >= 2 and srv.playing <= 8 and (type(srv.ping) == "number" and srv.ping < 200) then
                table.insert(tempQueue, srv.id)
            end
        end
        
        -- Shuffle array for randomization
        for i = #tempQueue, 2, -1 do
            local j = math.random(i)
            tempQueue[i], tempQueue[j] = tempQueue[j], tempQueue[i]
        end
        
        getgenv().ServerQueue = tempQueue
        addLog("Cached " .. #getgenv().ServerQueue .. " optimal servers.", Color3.fromRGB(100, 255, 100))
    else
        addLog("API Rate Limit! Retrying in 10s...", Color3.fromRGB(255, 100, 100))
        task.wait(10)
    end
end

local function performHop()
    if isHopping then return end
    isHopping = true

    if #getgenv().ServerQueue == 0 then ScrapeServers() end
    
    local targetServer = table.remove(getgenv().ServerQueue, 1)
    
    if targetServer then
        addLog("Insta-Hopping to queued server...", Color3.fromRGB(200, 150, 255))
        TeleportService:TeleportToPlaceInstance(PlaceId, targetServer, LocalPlayer)
    else
        addLog("Queue empty. Random fallback hop...", Color3.fromRGB(255, 150, 100))
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end

    -- Watchdog: If TP hangs for 15 seconds, unlock hopping
    task.delay(15, function() isHopping = false end)
end

-- Catch Teleport Failures and INSTANTLY try the next queue server
if getgenv().TpFailConnection then getgenv().TpFailConnection:Disconnect() end
getgenv().TpFailConnection = TeleportService.TeleportInitFailed:Connect(function(player, result, msg)
    addLog("TP FAILED: " .. tostring(msg), Color3.fromRGB(255, 80, 80))
    addLog("Pulling next server from queue...", Color3.fromRGB(255, 150, 50))
    isHopping = false
    task.wait(1)
    performHop()
end)

-- ==========================================
-- ⚔️ 6. VICIOUS ENGINE & LOGIC
-- ==========================================
local atlasExecuted = false
local hopCountdown = 6 -- Much faster wait time

local function isViciousAlive()
    for _, folder in ipairs({Workspace:FindFirstChild("Particles"), Workspace:FindFirstChild("Monsters")}) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if string.find(string.lower(obj.Name), "vicious") then return true end
            end
        end
    end
    return false
end

task.spawn(function()
    addLog("Engine Online. Commencing Hunt.", Color3.fromRGB(100, 255, 100))
    while task.wait(0.5) do
        if isHopping then continue end 
        
        if isViciousAlive() then
            if not atlasExecuted then
                addLog("🚨 VICIOUS FOUND! Executing Macro...", Color3.fromRGB(255, 50, 50))
                startLootListener()
                atlasExecuted = true
                pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))() end)
            end
        else
            if atlasExecuted then
                addLog("Boss Terminated! Waiting for loot...", Color3.fromRGB(100, 255, 255))
                task.wait(6)
                local gainedStingers = stopLootListener()
                updateSessionFile(gainedStingers)
                
                -- Webhook Logic (Unchanged)
                if WebhookURL ~= "" and gainedStingers > 0 then
                    addLog("Transmitting data to Discord...", Color3.fromRGB(150, 150, 255))
                    pcall(function()
                        local data = {["embeds"] = {{["title"] = "👑 Vicious Defeated [OVERNIGHT]", ["description"] = "**Server ID:** ||" .. game.JobId .. "||", ["color"] = 16766720, ["fields"] = {{["name"] = "🗡️ Stingers", ["value"] = "+"..gainedStingers, ["inline"] = true}, {["name"] = "📈 Session Total", ["value"] = tostring(sessionTotalFarmed), ["inline"] = true}}}}}
                        local httpRequest = (request or http_request or HttpPost or syn.request)
                        if httpRequest then httpRequest({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end
                    end)
                end
                
                performHop()
            else
                local clockTime = Lighting.ClockTime
                if clockTime >= 17.5 or clockTime < 6 then
                    if hopCountdown > 0 then
                        hopCountdown -= 0.5
                    else
                        performHop()
                    end
                else
                    performHop() -- Insta hop if daytime
                end
            end
        end
    end
end)
