local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local visitedServers = {}

-- [[ SCRIPT STATE TRACKER ]] --
local scriptState = "SCANNING"
local fightStartTime = 0

-------------------------------------------------------------------------------
-- 0. ON-SCREEN CONSOLE UI
-------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VicHopConsole"
-- Attempt to hide it in CoreGui, fallback to PlayerGui if executor restricts it
if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 200)
MainFrame.Position = UDim2.new(0, 15, 0, 15) -- Top left corner
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = " 🐝 Vic Hop Console"
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
    local color = Color3.fromRGB(220, 220, 220) -- Default white
    
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

    -- Auto-scroll to bottom
    task.delay(0.05, function()
        Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
    end)
end

Log("Vic Hop script initialized.", "INFO")

-------------------------------------------------------------------------------
-- 1. ANTI-AFK
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    Log("Anti-AFK: Prevented idle disconnect.", "WARN")
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
        local serversApi = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local success, result = pcall(function() 
            return HttpService:JSONDecode(game:HttpGet(serversApi)) 
        end)
        
        if success and result and result.data then
            local availableServers = {}
            for _, server in ipairs(result.data) do
                if server.playing <= (server.maxPlayers - 2) and server.id ~= game.JobId and not visitedServers[server.id] then
                    table.insert(availableServers, server)
                end
            end
            
            if #availableServers > 0 then
                local chosenServer = availableServers[math.random(1, #availableServers)]
                visitedServers[chosenServer.id] = true
                
                Log("Teleporting -> Player Count: " .. chosenServer.playing .. "/" .. chosenServer.maxPlayers, "SUCCESS")
                TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
            else
                Log("No safe servers found this batch.", "ERROR")
            end
        else
            Log("Failed to fetch server list. Retrying...", "ERROR")
        end
        
        task.wait(10)
        isHopping = false
    end)
end

-------------------------------------------------------------------------------
-- 3. BACKGROUND WATCHDOG (60s Failsafe)
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(60) do
        if scriptState == "HOPPING" or scriptState == "SCANNING" then
            Log("Watchdog: Stuck for 60s. Forcing hop...", "ERROR")
            isHopping = false 
            serverHop()
        elseif scriptState == "FIGHTING" and (tick() - fightStartTime) > 180 then
            Log("Watchdog: Fight timed out (3+ mins). Hopping...", "ERROR")
            serverHop()
        end
    end
end)

-------------------------------------------------------------------------------
-- 4. AUTO-RECONNECT
-------------------------------------------------------------------------------
GuiService.ErrorMessageChanged:Connect(function(errMsg)
    Log("Roblox Disconnect: " .. tostring(errMsg), "ERROR")
    task.wait(5)
    isHopping = false
    serverHop()
end)

pcall(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui", 5):WaitForChild("promptOverlay", 5)
    if promptOverlay then
        promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                Log("Error prompt detected. Hopping...", "WARN")
                task.wait(2)
                isHopping = false
                serverHop()
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 5. UTILITY FUNCTIONS
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
    
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == nil then
            local pad = hive:FindFirstChild("SpawnPos")
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if pad and root then
                root.CFrame = pad.CFrame
                local timeout = tick() + 5 
                while tick() < timeout do
                    if owner.Value == LocalPlayer then
                        Log("Hive successfully claimed. Waiting 3s for bees...", "SUCCESS")
                        task.wait(3) 
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
-- 6. MAIN EXECUTION THREAD
-------------------------------------------------------------------------------
task.spawn(function()
    Log("Waiting for character to load...", "INFO")
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    task.wait(3) 
    
    Log("Scanning memory for Vicious Bee...", "INFO")
    local viciousSpike = scanDataForVicious()
    
    if viciousSpike then
        Log("Vicious Bee located! Claiming hive...", "SUCCESS")
        
        if claimHiveAndWait() then
            scriptState = "FIGHTING"
            fightStartTime = tick()
            Log("Tweening to boss safely...", "INFO")
            
            local targetPivot = viciousSpike:IsA("Model") and viciousSpike:GetPivot() or viciousSpike.CFrame
            local safeCFrame = targetPivot + Vector3.new(0, 30, 0) 
            
            tweenTo(safeCFrame)
            local platform = createPlatform(safeCFrame.Position)
            Log("Hovering at 30 studs. Waiting for boss to die...", "WARN")
            
            while viciousSpike and viciousSpike.Parent do
                task.wait(0.5)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = safeCFrame
                end
            end
            
            Log("Boss defeated! Dropping down for stingers...", "SUCCESS")
            platform:Destroy()
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPivot + Vector3.new(0, 5, 0)
            end
            
            task.wait(2) 
            serverHop()
        else
            Log("Failed to claim a hive. Aborting...", "ERROR")
            serverHop()
        end
    else
        Log("No Vicious Bee found in this server.", "WARN")
        serverHop()
    end
end)
