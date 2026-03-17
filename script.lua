-- Wait for the game to fully load before Delta does anything
if not game:IsLoaded() then game.Loaded:Wait() end

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local visitedServers = {}

local scriptState = "SCANNING"
local fightStartTime = 0

local fetchReq = nil
pcall(function() fetchReq = request or http_request or (http and http.request) or (syn and syn.request) end)

-------------------------------------------------------------------------------
-- 0. ON-SCREEN CONSOLE UI (Delta-Optimized)
-------------------------------------------------------------------------------
pcall(function()
    local hiddenGui = gethui()
    for _, v in pairs(hiddenGui:GetChildren()) do if v.Name == "VicHopConsole" then v:Destroy() end end
    for _, v in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do if v.Name == "VicHopConsole" then v:Destroy() end end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VicHopConsole"
ScreenGui.ResetOnSpawn = false

local successUI = pcall(function() ScreenGui.Parent = gethui() end)
if not successUI then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 200)
MainFrame.Position = UDim2.new(0, 15, 0, 15)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = " 🐝 Vic Hop Console (Delta)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.BorderSizePixel = 0

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, 0, 1, -25)
Scroll.Position = UDim2.new(0, 0, 0, 25)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local logCount = 0
local function Log(msg, level)
    level = level or "INFO"
    local color = Color3.fromRGB(220, 220, 220)
    
    if level == "ERROR" then color = Color3.fromRGB(255, 80, 80)
    elseif level == "WARN" then color = Color3.fromRGB(255, 200, 80)
    elseif level == "SUCCESS" then color = Color3.fromRGB(80, 255, 80) end

    local txt = Instance.new("TextLabel", Scroll)
    txt.Size = UDim2.new(1, -5, 0, 16)
    txt.BackgroundTransparency = 1
    txt.Text = " [" .. level .. "] " .. tostring(msg)
    txt.TextColor3 = color
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.Code
    txt.TextSize = 12
    txt.TextWrapped = true
    txt.AutomaticSize = Enum.AutomaticSize.Y
    
    logCount = logCount + 1
    txt.LayoutOrder = logCount

    task.delay(0.05, function() Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y) end)
    print("[VIC HOP] " .. tostring(msg))
end

Log("Script loaded! Checking character...", "SUCCESS")

-------------------------------------------------------------------------------
-- 1. ANTI-AFK
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        Log("Anti-AFK triggered to prevent kick.", "WARN")
    end)
end)

-------------------------------------------------------------------------------
-- 2. SMART SERVER HOPPING
-------------------------------------------------------------------------------
local isHopping = false
local function serverHop()
    scriptState = "HOPPING"
    if isHopping then return end
    isHopping = true
    
    Log("Searching for a new server...", "INFO")
    
    task.spawn(function()
        local serversApi = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        
        local success, result = pcall(function() 
            if fetchReq then
                local response = fetchReq({Url = serversApi, Method = "GET"})
                return HttpService:JSONDecode(response.Body)
            else
                return HttpService:JSONDecode(game:HttpGet(serversApi)) 
            end
        end)
        
        if success and result and result.data then
            local availableServers = {}
            for _, server in ipairs(result.data) do
                if server.playing and server.playing < server.maxPlayers and server.id ~= game.JobId and not visitedServers[server.id] then
                    table.insert(availableServers, server)
                end
            end
            
            if #availableServers > 0 then
                local chosenServer = availableServers[math.random(1, #availableServers)]
                visitedServers[chosenServer.id] = true
                Log("Teleporting -> " .. chosenServer.playing .. "/" .. chosenServer.maxPlayers .. " players", "SUCCESS")
                task.wait(1)
                TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
                return 
            end
        end
        
        Log("No specific servers found. Random Hopping...", "WARN")
        TeleportService:Teleport(PlaceId, LocalPlayer)
        task.wait(10)
        isHopping = false
    end)
end

-------------------------------------------------------------------------------
-- 3. BACKGROUND WATCHDOG
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(60) do
        if scriptState == "HOPPING" or scriptState == "SCANNING" then
            Log("Watchdog: Stuck for 60s. Forcing hop...", "ERROR")
            isHopping = false 
            serverHop()
        elseif scriptState == "FIGHTING" and (tick() - fightStartTime) > 240 then
            Log("Watchdog: Fight timed out (4+ mins). Hopping...", "ERROR")
            serverHop()
        end
    end
end)

GuiService.ErrorMessageChanged:Connect(function(errMsg)
    Log("Disconnect: " .. tostring(errMsg), "ERROR")
    task.wait(5)
    isHopping = false
    serverHop()
end)

-------------------------------------------------------------------------------
-- 4. UTILITY FUNCTIONS (Fixed Hive Check)
-------------------------------------------------------------------------------
local function scanDataForVicious()
    local targetFolders = {Workspace:FindFirstChild("Particles"), Workspace:FindFirstChild("Monsters")}
    for _, folder in ipairs(targetFolders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if string.find(string.lower(obj.Name), "vicious") then
                    return obj
                end
            end
        end
    end
    return nil
end

local function claimHiveAndWait()
    local honeycombs = Workspace:WaitForChild("Honeycombs", 5)
    if not honeycombs then return false end
    
    -- STEP 1: Verify ownership thoroughly (checks both Instance and String names)
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner then
            if owner.Value == LocalPlayer or tostring(owner.Value) == LocalPlayer.Name then
                Log("Already own a hive! Ready to fight.", "SUCCESS")
                return true
            end
        end
    end
    
    -- STEP 2: Claim an empty hive
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == nil then
            local pad = hive:FindFirstChild("SpawnPos")
            if pad then
                -- Drop onto the pad to trigger the physical 'Touch' event
                root.CFrame = pad.CFrame + Vector3.new(0, 2, 0)
                if LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Jump = true
                end
                
                local timeout = tick() + 4 
                while tick() < timeout do
                    if owner.Value == LocalPlayer or tostring(owner.Value) == LocalPlayer.Name then
                        Log("Hive successfully claimed!", "SUCCESS")
                        task.wait(2) 
                        return true
                    end
                    task.wait(0.2)
                end
            end
        end
    end
    return false
end

local function tweenTo(targetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local tweenInfo = TweenInfo.new(distance / 45, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.5)
end

local function createPlatform(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(15, 1, 15)
    part.Position = position - Vector3.new(0, 3.5, 0)
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = true
    part.Parent = Workspace
    return part
end

-------------------------------------------------------------------------------
-- 5. MAIN EXECUTION THREAD (Fixed Boss Trigger)
-------------------------------------------------------------------------------
task.spawn(function()
    while not LocalPlayer.Character do task.wait(0.5) end
    task.wait(2) 
    
    Log("Scanning for Vicious Bee...", "INFO")
    local viciousSpike = scanDataForVicious()
    
    if viciousSpike then
        Log("Vicious Bee spike located!", "SUCCESS")
        
        if claimHiveAndWait() then
            scriptState = "FIGHTING"
            fightStartTime = tick()
            
            local spikeCFrame = viciousSpike:IsA("Model") and viciousSpike:GetPivot() or viciousSpike.CFrame
            
            -- FIX: Walk directly INTO the spike to summon the boss first
            Log("Touching spike to summon boss...", "WARN")
            tweenTo(spikeCFrame)
            task.wait(2) -- Wait for the spawn animation
            
            -- Re-scan to find the actual flying boss monster
            local actualBoss = scanDataForVicious()
            if actualBoss then
                Log("Boss spawned! Hovering 30 studs...", "INFO")
                local safeCFrame = spikeCFrame + Vector3.new(0, 30, 0) 
                tweenTo(safeCFrame)
                local platform = createPlatform(safeCFrame.Position)
                
                while actualBoss and actualBoss.Parent do
                    task.wait(0.5)
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        -- Follow the boss slowly from above if it moves
                        local bossPos = actualBoss:IsA("Model") and actualBoss:GetPivot().Position or actualBoss.Position
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(bossPos + Vector3.new(0, 30, 0))
                        platform.Position = (bossPos + Vector3.new(0, 30, 0)) - Vector3.new(0, 3.5, 0)
                    end
                end
                
                Log("Boss defeated! Collecting stingers...", "SUCCESS")
                platform:Destroy()
                
                -- Drop down to collect tokens
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = spikeCFrame + Vector3.new(0, 3, 0)
                end
            else
                Log("Boss didn't spawn or died instantly.", "WARN")
            end
            
            task.wait(3) 
            serverHop()
        else
            Log("Failed to claim hive. Hopping...", "ERROR")
            serverHop()
        end
    else
        Log("No Vicious Bee found. Hopping...", "WARN")
        serverHop()
    end
end)
