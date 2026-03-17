local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- 1. Scan for Vicious Bee
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

-- 2. Server Hopping Logic
local function serverHop()
    local serversApi = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(serversApi)) end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                task.wait(5)
            end
        end
    else
        task.wait(2)
        serverHop()
    end
end

-- 3. Smooth Tween Function
local function tweenTo(targetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Calculate time based on distance so it doesn't move dangerously fast
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local tweenTime = distance / 45 -- Speed: 45 studs per second
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
end

-- 4. Create an invisible platform to stand on
local function createPlatform(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(10, 1, 10)
    part.Position = position - Vector3.new(0, 3.5, 0) -- Placed just under your feet
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = true
    part.Parent = Workspace
    return part
end

-- Main Execution Thread
task.spawn(function()
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    task.wait(3) 

    local viciousSpike = scanDataForVicious()
    
    if viciousSpike then
        -- Vicious Bee found! Calculate a safe hovering position (18 studs above it)
        local safeCFrame = (viciousSpike:IsA("Model") and viciousSpike:GetPivot() or viciousSpike.CFrame) + Vector3.new(0, 18, 0)
        
        -- Tween smoothly to the target to avoid anti-cheat
        tweenTo(safeCFrame)
        
        -- Create a floating platform so you don't fall into the stinger hitbox
        local platform = createPlatform(safeCFrame.Position)
        
        -- Wait for the Vicious Bee to die (Its model will be removed from Workspace)
        while viciousSpike and viciousSpike.Parent do
            task.wait(0.5)
            -- Keeps you locked in place just in case
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = safeCFrame
            end
        end
        
        -- It died! Clean up the platform and immediately hop to farm the next one
        platform:Destroy()
        task.wait(1) -- Brief pause to ensure token collection (stingers) finishes
        serverHop()
    else
        -- No Vicious Bee found, immediately server hop
        serverHop()
    end
end)
