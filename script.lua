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

-- [[ CONFIGURATION ]] --
local MAX_TIME_IN_SERVER = 150 -- 150 seconds (2.5 minutes). Change this if you need more/less time to kill the boss.

-------------------------------------------------------------------------------
-- 1. ANTI-AFK (Prevents 20-minute idle kick)
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("Anti-AFK: Simulated input to prevent disconnect.")
end)

-------------------------------------------------------------------------------
-- 2. SMART SERVER HOPPING
-------------------------------------------------------------------------------
local isHopping = false
local function serverHop()
    if isHopping then return end
    isHopping = true
    
    print("Finding a safe server to hop to...")
    local serversApi = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    
    local success, result = pcall(function() 
        return HttpService:JSONDecode(game:HttpGet(serversApi)) 
    end)
    
    if success and result and result.data then
        local availableServers = {}
        for _, server in ipairs(result.data) do
            -- Ensure it's not full, not our current server, and not blacklisted
            if server.playing <= (server.maxPlayers - 2) and server.id ~= game.JobId and not visitedServers[server.id] then
                table.insert(availableServers, server)
            end
        end
        
        if #availableServers > 0 then
            local chosenServer = availableServers[math.random(1, #availableServers)]
            visitedServers[chosenServer.id] = true
            
            print("Teleporting to server (" .. chosenServer.playing .. "/" .. chosenServer.maxPlayers .. ")")
            TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
            
            task.wait(10)
            isHopping = false
            serverHop() -- Retry if teleport fails after 10s
        else
            task.wait(3)
            isHopping = false
            serverHop()
        end
    else
        task.wait(2)
        isHopping = false
        serverHop()
    end
end

-------------------------------------------------------------------------------
-- 3. AUTO-RECONNECT (Bypasses Roblox error screens)
-------------------------------------------------------------------------------
GuiService.ErrorMessageChanged:Connect(function(errorMessage)
    warn("Roblox Error Detected: " .. tostring(errorMessage))
    task.wait(5)
    serverHop()
end)

pcall(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui", 5):WaitForChild("promptOverlay", 5)
    if promptOverlay then
        promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                task.wait(2)
                serverHop()
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 4. UTILITY FUNCTIONS (Scanning, Claiming, Tweening, Platform)
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
                        task.wait(3) -- Wait for bees to spawn
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
    part.Position = position - Vector3.new(0,
