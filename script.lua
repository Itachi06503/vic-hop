-- Blacklist table to remember which servers we've already tried
local visitedServers = {}

-- 3. Upgraded Server Hopping Logic
local function serverHop()
    print("Finding a safe server to hop to...")
    
    -- Changed sortOrder to Desc (Descending) so it looks at populated servers with space, not entirely dead ones
    local serversApi = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    
    local success, result = pcall(function() 
        return HttpService:JSONDecode(game:HttpGet(serversApi)) 
    end)
    
    if success and result and result.data then
        local availableServers = {}
        
        for _, server in ipairs(result.data) do
            -- BUFFER: Ensure there are at least 2 empty slots so we don't hit the "Full" error
            -- Also check that we aren't in it, and we haven't visited it yet
            if server.playing <= (server.maxPlayers - 2) and server.id ~= game.JobId and not visitedServers[server.id] then
                table.insert(availableServers, server)
            end
        end
        
        if #availableServers > 0 then
            -- Pick a random server from the safe list
            local chosenServer = availableServers[math.random(1, #availableServers)]
            
            -- Add it to our blacklist so we don't try it again
            visitedServers[chosenServer.id] = true
            
            print("Teleporting to server with " .. chosenServer.playing .. "/" .. chosenServer.maxPlayers .. " players.")
            TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
            
            -- Wait 10 seconds. If the teleport fails, the script will loop and try a new server.
            task.wait(10)
            serverHop()
        else
            print("No suitable servers in this batch. Retrying in 3 seconds...")
            task.wait(3)
            serverHop()
        end
    else
        task.wait(2)
        serverHop()
    end
end
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- 1. Scan for Vicious Bee FIRST
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

-- 2. Secure Hive Claiming Logic
local function claimHiveAndWait()
    local honeycombs = Workspace:WaitForChild("Honeycombs", 5)
    if not honeycombs then return false end
    
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        
        if owner and owner.Value == nil then
            local pad = hive:FindFirstChild("SpawnPos")
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if pad and root then
                -- Teleport to the empty hive
                root.CFrame = pad.CFrame
                
                -- Wait until the game successfully registers you as the owner
                local timeout = tick() + 5 -- 5 second timeout so it doesn't get stuck
                while tick() < timeout do
                    if owner.Value == LocalPlayer then
                        -- Hive claimed! Wait 3 seconds for bees to fully spawn out of the honeycomb
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

-- 3. Server Hopping Logic
local function serverHop()
    print("Hopping servers...")
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

-- 4. Smooth Tween Function
local function tweenTo(targetCFrame)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local tweenTime = distance / 45 
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.5) -- Give bees a tiny moment to catch up after traveling
end

-- 5. Create floating platform
local function createPlatform(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(15, 1, 15) -- Made it slightly wider too
    part.Position = position - Vector3.new(0, 3.5, 0)
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = true
    part.Parent = Workspace
    return part
end

-- Main Execution Thread
task.spawn(function()
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    task.wait(3) -- Let map load
    
    -- Step 1: Scan for Vicious Bee immediately
    local viciousSpike = scanDataForVicious()
    
    if viciousSpike then
        print("Vicious Bee found! Claiming hive...")
        
        -- Step 2: Claim hive and wait for bees to spawn
        local claimed = claimHiveAndWait()
        
        if claimed then
            -- Step 3: Calculate safe height (Increased to 30 studs to avoid damage)
            local targetPivot = viciousSpike:IsA("Model") and viciousSpike:GetPivot() or viciousSpike.CFrame
            local safeCFrame = targetPivot + Vector3.new(0, 30, 0)
            
            -- Step 4: Tween to the boss so bees follow, then create platform
            tweenTo(safeCFrame)
            local platform = createPlatform(safeCFrame.Position)
            
            -- Keep character exactly in place and wait for it to die
            while viciousSpike and viciousSpike.Parent do
                task.wait(0.5)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = safeCFrame
                end
            end
            
            -- Vicious Bee died!
            platform:Destroy()
            
            -- Drop down slightly to grab the Stingers, wait 2 seconds, then hop!
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPivot + Vector3.new(0, 5, 0)
            end
            task.wait(2) 
            serverHop()
        else
            -- If it failed to claim a hive for some reason, just hop to avoid getting stuck
            serverHop()
        end
    else
        -- No Vicious Bee found, immediately hop
        serverHop()
    end
end)
