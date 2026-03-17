-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local visitedServers = {}

local scriptState = "SCANNING"
local fightStartTime = 0

local fetchReq = nil
pcall(function() fetchReq = request or http_request or (http and http.request) or (syn and syn.request) end)

-------------------------------------------------------------------------------
-- 0. ON-SCREEN CONSOLE UI
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
Title.Text = " 🐝 Vic Hop Console (Tween Claim)"
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
end

Log("Script loaded! Checking character...", "SUCCESS")

-------------------------------------------------------------------------------
-- 1. ANTI-AFK & WATCHDOG
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
end)

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
                if server.playing and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(availableServers, server)
                end
            end
            if #availableServers > 0 then
                local chosenServer = availableServers[math.random(1, #availableServers)]
                Log("Teleporting -> " .. chosenServer.playing .. "/" .. chosenServer.maxPlayers .. " players", "SUCCESS")
                task.wait(1)
                TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
                return 
            end
        end
        Log("Random Hopping...", "WARN")
        TeleportService:Teleport(PlaceId, LocalPlayer)
        task.wait(10)
        isHopping = false
    end)
end

task.spawn(function()
    while task.wait(60) do
        if scriptState == "HOPPING" or scriptState == "SCANNING" then
            Log("Watchdog: Stuck for 60s. Forcing hop...", "ERROR")
            isHopping = false; serverHop()
        elseif scriptState == "FIGHTING" and (tick() - fightStartTime) > 240 then
            Log("Watchdog: Fight timed out. Hopping...", "ERROR")
            serverHop()
        end
    end
end)

GuiService.ErrorMessageChanged:Connect(function() task.wait(5); isHopping = false; serverHop() end)

-------------------------------------------------------------------------------
-- 2. UTILITY FUNCTIONS
-------------------------------------------------------------------------------
local function scanDataForVicious()
    local targetFolders = {Workspace:FindFirstChild("Particles"), Workspace:FindFirstChild("Monsters")}
    for _, folder in ipairs(targetFolders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if string.find(string.lower(obj.Name), "vicious") and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- Moved tweenTo ABOVE claimHiveAndWait so we can use it!
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

local function claimHiveAndWait()
    local honeycombs = Workspace:WaitForChild("Honeycombs", 5)
    if not honeycombs then return false end
    
    -- 1. Check if we already own one
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            Log("Already own a hive!", "SUCCESS")
            return true
        end
    end
    
    Log("Tweening to empty hive to claim...", "WARN")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    -- 2. Find and tween to an empty one
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == nil then
            local pad = hive:FindFirstChild("SpawnPos")
            local hiveID = hive:FindFirstChild("HiveID")
            
            if pad then
                -- Tween directly to the pad smoothly
                tweenTo(pad.CFrame + Vector3.new(0, 3, 0))
                
                -- Drop onto it gently to trigger the game's physical touch
                root.CFrame = pad.CFrame + Vector3.new(0, 1.5, 0)
                
                -- Wait 2 full seconds for the game to register the claim
                task.wait(2)
                
                -- Send the backup server command just in case
                if hiveID then
                    pcall(function() 
                        game:GetService("ReplicatedStorage").Events.ClaimHive:InvokeServer(tonumber(hiveID.Value)) 
                    end)
                end
                
                task.wait(1.5)
                
                if owner.Value == LocalPlayer then
                    Log("Hive claimed successfully!", "SUCCESS")
                    return true
                end
            end
        end
    end
    
    return false
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
-- 3. MAIN THREAD
-------------------------------------------------------------------------------
task.spawn(function()
    while not LocalPlayer.Character do task.wait(0.5) end
    task.wait(2) 
    
    Log("Scanning for Vicious Bee...", "INFO")
    local viciousSpike = scanDataForVicious()
    
    if viciousSpike then
        Log("Vicious target located!", "SUCCESS")
        
        if claimHiveAndWait() then
            scriptState = "FIGHTING"
            fightStartTime = tick()
            
            local spikeCFrame = viciousSpike:IsA("Model") and viciousSpike:GetPivot() or viciousSpike.CFrame
            
            Log("Approaching target...", "WARN")
            tweenTo(spikeCFrame)
            task.wait(2) 
            
            Log("Hovering and fighting...", "INFO")
            local safeCFrame = spikeCFrame + Vector3.new(0, 30, 0) 
            tweenTo(safeCFrame)
            local platform = createPlatform(safeCFrame.Position)
            
            local activeBoss = viciousSpike
            while activeBoss and activeBoss.Parent do
                task.wait(0.5)
                activeBoss = scanDataForVicious() or activeBoss
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local bossPos = activeBoss:IsA("Model") and activeBoss:GetPivot().Position or (activeBoss:IsA("BasePart") and activeBoss.Position or spikeCFrame.Position)
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(bossPos + Vector3.new(0, 30, 0))
                    platform.Position = (bossPos + Vector3.new(0, 30, 0)) - Vector3.new(0, 3.5, 0)
                end
            end
            
            Log("Target eliminated! Collecting...", "SUCCESS")
            platform:Destroy()
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = spikeCFrame + Vector3.new(0, 3, 0)
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
