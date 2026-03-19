-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(5) 

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-------------------------------------------------------------------------------
-- 1. SIMPLE UI
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
-- 2. STATE VARIABLES & BLACKLIST
-------------------------------------------------------------------------------
local atlasExecuted = false
local isHopping = false
local hopCountdown = 15 
local forceHopTimer = false 

local blacklistedServers = {} -- Stores broken server IDs
local currentTargetId = nil   -- The server we are currently trying to join

-------------------------------------------------------------------------------
-- 3. SAFER TELEPORT LOGIC + BLACKLISTING
-------------------------------------------------------------------------------
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        if currentTargetId then
            blacklistedServers[currentTargetId] = true -- Add broken server to blacklist
        end
        isHopping = false
        StatusLabel.Text = "Roblox TP Fail! Blacklisted & Retrying..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
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
        StatusLabel.Text = "TP Error! Blacklisting..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(3)
        isHopping = false
        return
    end
    
    -- Timeout Watchdog
    task.spawn(function()
        task.wait(40)
        if isHopping then
            blacklistedServers[targetId] = true -- Add to blacklist if it times out
            isHopping = false
            StatusLabel.Text = "TP Timed out. Blacklisted & Retrying..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end

-------------------------------------------------------------------------------
-- 4. THE BULLDOZER SCANNER
-------------------------------------------------------------------------------
local function performHop()
    if isHopping then return end
    isHopping = true
    
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
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end
            url = url .. "&_=" .. tostring(math.random(10000, 99999))
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if success and result and result.data then
                rateLimitRetries = 0 
                local validServers = {}
                
                for _, srv in pairs(result.data) do
                    -- ONLY check servers that are NOT blacklisted
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
                if rateLimitRetries > 5 then
                    break 
                end
                
                StatusLabel.Text = "Rate limited. Waiting 3s..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(3)
            end
        end
        
        if fallbackOne then
            executeTeleport(fallbackOne, "1 player fallback")
        else
            StatusLabel.Text = "Scan failed. Retrying in 5s..."
            task.wait(5)
            isHopping = false 
        end
    end)
end

-------------------------------------------------------------------------------
-- 5. ERROR POPUP CRUSHER (10 SEC OVERRIDE)
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
            if prompt and prompt:FindFirstChild("promptOverlay") then
                local errorPrompt = prompt.promptOverlay:FindFirstChild("ErrorPrompt")
                if errorPrompt and errorPrompt.Visible then
                    GuiService:ClearError() 
                    
                    StatusLabel.Text = "Error cleared! Hopping in 10s..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    
                    isHopping = false 
                    hopCountdown = 10
                    forceHopTimer = true 
                end
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 6. VICIOUS DETECTOR
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
-- 7. MAIN TIMELINE LOOP
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if isHopping then continue end 
        
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
                if hopCountdown > 0 then
                    if forceHopTimer then
                        StatusLabel.Text = "Error Recovery: Hop in " .. hopCountdown .. "s"
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    else
                        StatusLabel.Text = "No Vicious. Hopping in " .. hopCountdown .. "s"
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                    end
                    hopCountdown = hopCountdown - 1
                else
                    performHop()
                end
            end
        end
    end
end)
