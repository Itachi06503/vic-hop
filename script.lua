-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(5) 

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-------------------------------------------------------------------------------
-- 1. OVERNIGHT ANTI-AFK
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-------------------------------------------------------------------------------
-- 2. SIMPLE UI
-------------------------------------------------------------------------------
pcall(function()
    local hiddenGui = gethui and gethui() or CoreGui
    for _, v in pairs(hiddenGui:GetChildren()) do if v.Name == "VicDetectorUI" then v:Destroy() end end
    for _, v in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do if v.Name == "VicDetectorUI" then v:Destroy() end end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VicDetectorUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = gethui() end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 40)
MainFrame.Position = UDim2.new(0.5, -120, 0, 20) 
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true
MainFrame.Draggable = true

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Initializing..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true

-------------------------------------------------------------------------------
-- 3. STATE VARIABLES & BLACKLIST
-------------------------------------------------------------------------------
local atlasExecuted = false
local isHopping = false
local hopCountdown = 10 
local hopStartTime = 0 

local blacklistedServers = {} 
local currentTargetId = nil   
local failedAttempts = 0 
local lastFailTime = 0 

-------------------------------------------------------------------------------
-- 4. SAFER TELEPORT LOGIC (WITH HARD COOLDOWNS)
-------------------------------------------------------------------------------
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        if currentTargetId then blacklistedServers[currentTargetId] = true end
        
        if os.time() - lastFailTime > 2 then
            failedAttempts = failedAttempts + 1
            lastFailTime = os.time()
        end
        
        StatusLabel.Text = "Roblox TP Fail! 15s Cooldown..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        
        -- THE FIX: Force a 15-second hard yield before unlocking the scanner
        task.wait(15)
        isHopping = false
    end
end)

local function executeTeleport(targetId, pCountLabel)
    currentTargetId = targetId
    StatusLabel.Text = "Teleporting (" .. pCountLabel .. ")..."
    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, targetId, LocalPlayer)
    end)
    
    if not success then
        blacklistedServers[targetId] = true
        if os.time() - lastFailTime > 2 then
            failedAttempts = failedAttempts + 1
            lastFailTime = os.time()
        end
        
        StatusLabel.Text = "TP Error! 15s Cooldown..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        
        -- THE FIX: Force a 15-second hard yield here too
        task.wait(15)
        isHopping = false
        return
    end
end

-------------------------------------------------------------------------------
-- 5. THE BULLDOZER SCANNER
-------------------------------------------------------------------------------
local function performHop()
    if isHopping then return end
    isHopping = true
    hopStartTime = os.time() 
    
    if failedAttempts >= 3 then
        StatusLabel.Text = "Loop! Forcing Random Hop..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        failedAttempts = 0 
        
        pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
        
        task.spawn(function()
            task.wait(20)
            isHopping = false 
        end)
        return 
    end
    
    task.spawn(function()
        local cursor = ""
        local fallbackOne = nil
        local page = 1
        local maxPages = 50
        local rateLimitRetries = 0
        
        while page <= maxPages do
            StatusLabel.Text = "Digging Pg " .. page .. "..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            
            local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            url = url .. "&_=" .. tostring(math.random(10000, 99999))
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if success and result and result.data then
                rateLimitRetries = 0 
                local validServers = {}
                
                for _, srv in pairs(result.data) do
                    if srv.id ~= game.JobId and srv.playing and not blacklistedServers[srv.id] then
                        if srv.playing >= 2 and srv.playing <= 5 then
                            table.insert(validServers, srv)
                        elseif srv.playing == 1 and not fallbackOne then
                            fallbackOne = srv.id   
                        end
                    end
                end
                
                if #validServers > 0 then
                    local target = validServers[math.random(1, #validServers)]
                    executeTeleport(target.id, target.playing .. " players")
                    return 
                end
                
                if result.nextPageCursor then
                    cursor = result.nextPageCursor
                    page = page + 1
                    task.wait(0.5) 
                else
                    break 
                end
            else
                rateLimitRetries = rateLimitRetries + 1
                if rateLimitRetries > 3 then break end
                
                StatusLabel.Text = "Rate limited. Waiting 15s..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(15) 
            end
        end
        
        if fallbackOne then
            executeTeleport(fallbackOne, "1 player fallback")
        else
            StatusLabel.Text = "API Blocked. Emergency random hop!"
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 255)
            failedAttempts = failedAttempts + 1
            
            pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
            task.wait(20)
            isHopping = false 
        end
    end)
end

-------------------------------------------------------------------------------
-- 6. HARD-RECONNECT ERROR CRUSHER
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
            if prompt and prompt:FindFirstChild("promptOverlay") then
                local errorPrompt = prompt.promptOverlay:FindFirstChild("ErrorPrompt")
                if errorPrompt and errorPrompt.Visible then
                    GuiService:ClearError() 
                    
                    StatusLabel.Text = "DISCONNECTED! Forcing reconnect..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    
                    TeleportService:Teleport(PlaceId, LocalPlayer)
                    task.wait(10)
                end
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 7. VICIOUS DETECTOR
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
-- 8. MAIN TIMELINE LOOP & SMART CLOCK
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if isHopping then
            if os.time() - hopStartTime > 120 then
                isHopping = false
                failedAttempts = failedAttempts + 1
                StatusLabel.Text = "Watchdog Reset! Retrying hop..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
            continue 
        end 
        
        local viciousHere = isViciousAlive()

        if viciousHere then
            if not atlasExecuted then
                StatusLabel.Text = "Vicious Found! Loading Atlas..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
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
                StatusLabel.Text = "Vicious Dead! Collecting Loot..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 255)
                
                task.wait(5)
                performHop()
            else
                local clockTime = Lighting.ClockTime
                
                if clockTime >= 16 and clockTime < 18.2 then
                    StatusLabel.Text = "Dusk ("..string.format("%.1f", clockTime).."). Waiting for night..."
                    StatusLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
                else
                    if hopCountdown > 0 then
                        if clockTime > 6 and clockTime < 16 then
                            StatusLabel.Text = "Daytime. Fast-hopping..."
                            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                            hopCountdown = 0 
                        else
                            StatusLabel.Text = "No Vicious. Hopping in " .. hopCountdown .. "s"
                            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                            hopCountdown = hopCountdown - 1
                        end
                    else
                        performHop()
                    end
                end
            end
        end
    end
end)
