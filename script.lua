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
local scriptState = "SCANNING" -- Can be: SCANNING, FIGHTING, HOPPING
local fightStartTime = 0

-------------------------------------------------------------------------------
-- 1. ANTI-AFK (Prevents 20-minute idle kick)
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-------------------------------------------------------------------------------
-- 2. SMART SERVER HOPPING
-------------------------------------------------------------------------------
local isHopping = false
local function serverHop()
    scriptState = "HOPPING"
    if isHopping then return end
    isHopping = true
    
    print("Attempting to server hop...")
    
    -- Run the hop inside a spawn so if Roblox's API freezes, it doesn't break the script
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
                
                print("Teleporting to server (" .. chosenServer.playing .. "/" .. chosenServer.maxPlayers .. ")")
                TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
            else
                print("No safe servers found this attempt.")
            end
        end
        
        -- Unlock the hop variable after 10 seconds so it can try again if it failed
        task.wait(10)
        isHopping = false
    end)
end

-------------------------------------------------------------------------------
-- 3. BACKGROUND WATCHDOG (The 60-Second Failsafe)
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(60) do
        if scriptState == "HOPPING" or scriptState == "SCANNING" then
            print("Watchdog: 60 seconds passed with no combat. Forcing a server hop...")
            isHopping = false -- Force reset the lock
            serverHop()
        elseif scriptState == "FIGHTING" and (tick() - fightStartTime) > 180 then
            -- Failsafe if the fight takes longer than 3 minutes
            print("Watchdog: Fight took too long (3+ mins). Boss might be stuck. Hopping...")
            serverHop()
        end
    end
end)

-------------------------------------------------------------------------------
-- 4. AUTO-RECONNECT
-------------------------------------------------------------------------------
GuiService.ErrorMessageChanged:Connect(function()
    task.wait(5)
    isHopping = false
    serverHop()
end)

pcall(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui", 5):WaitForChild("promptOverlay", 5)
    if promptOverlay then
        promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
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
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    task.wait(3) 
    
    local viciousSpike = scanDataForVicious()
    
    if viciousSpike then
        print("Vicious Bee found! Attempting to claim hive...")
        
        if claimHiveAndWait() then
            scriptState = "FIGHTING"
            fightStartTime = tick()
            print("Hive claimed. Moving to Vicious Bee...")
            
            local targetPivot = viciousSpike:IsA("Model") and viciousSpike:GetPivot() or viciousSpike.CFrame
            local safeCFrame = targetPivot + Vector3.new(0, 30, 0) 
            
            tweenTo(safeCFrame)
            local platform = createPlatform(safeCFrame.Position)
            
            while viciousSpike and viciousSpike.Parent do
                task.wait(0.5)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = safeCFrame
                end
            end
            
            print("Vicious Bee defeated! Collecting stingers...")
            platform:Destroy()
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPivot + Vector3.new(0, 5, 0)
            end
            
            task.wait(2) 
            serverHop()
        else
            print("Failed to claim hive. Hopping...")
            serverHop()
        end
    else
        print("No Vicious Bee found. Hopping...")
        serverHop()
    end
end)
