-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(15)

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Attempt to find the correct HTTP request function for your executor
local fetchReq = nil
pcall(function() fetchReq = request or http_request or (http and http.request) or (syn and syn.request) end)

-------------------------------------------------------------------------------
-- 1. DRAGGABLE STATUS UI
-------------------------------------------------------------------------------
pcall(function()
    local hiddenGui = gethui and gethui() or CoreGui
    for _, v in pairs(hiddenGui:GetChildren()) do if v.Name == "VicDetectorUI" then v:Destroy() end end
    for _, v in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do if v.Name == "VicDetectorUI" then v:Destroy() end end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VicDetectorUI"
ScreenGui.ResetOnSpawn = false

local successUI = pcall(function() ScreenGui.Parent = gethui() end)
if not successUI then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end

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
StatusLabel.Text = "Scanning for Vicious..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true

-------------------------------------------------------------------------------
-- 2. GLOBAL COOLDOWN, STATE & CACHE
-------------------------------------------------------------------------------
local isHopping = false
local globalCooldown = 0 
local badServers = {} 
local lastAttemptedServer = nil
local savedCursor = "" 

-- THE SECRET STASH: This will store extra servers to use when we get rate-limited
local backupServerCache = {} 

badServers[game.JobId] = true 

local function setCooldown(seconds, message)
    globalCooldown = os.time() + seconds
    isHopping = false
    StatusLabel.Text = message
    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
end

-------------------------------------------------------------------------------
-- 3. THE CACHE-BASED HOPPING LOGIC
-------------------------------------------------------------------------------
local function serverHop()
    if isHopping then return end
    isHopping = true
    StatusLabel.Text = "Fetching Servers..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    task.spawn(function()
        local availableServers = {}
        local serversApi = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100"
        
        if savedCursor and savedCursor ~= "" then
            serversApi = serversApi .. "&cursor=" .. savedCursor
        else
            serversApi = serversApi .. "&_b=" .. tostring(os.time())
        end
        
        local success, result = pcall(function() 
            if fetchReq then
                local response = fetchReq({Url = serversApi, Method = "GET"})
                if response.StatusCode == 429 then return "RATELIMIT" end
                return HttpService:JSONDecode(response.Body)
            else
                return HttpService:JSONDecode(game:HttpGet(serversApi)) 
            end
        end)
        
        -- IF WE ARE RATE LIMITED: Use the Backup Cache instead of Blind Hopping!
        if result == "RATELIMIT" or not success then
            if #backupServerCache > 0 then
                StatusLabel.Text = "API Blocked! Using Cache (" .. #backupServerCache .. " left)"
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 255) -- Cyan for Cache hop
                task.wait(2)
                
                -- Pull a random server from our stash and remove it so we don't reuse it
                local cacheIndex = math.random(1, #backupServerCache)
                local cacheServerId = table.remove(backupServerCache, cacheIndex)
                lastAttemptedServer = cacheServerId
                
                pcall(function() TeleportService:TeleportCancel() end)
                TeleportService:TeleportToPlaceInstance(PlaceId, cacheServerId, LocalPlayer)
                
                task.wait(20)
                if isHopping then
                    badServers[lastAttemptedServer] = true
                    setCooldown(10, "Cache Hop stalled! Retrying...")
                end
                return
            else
                -- If we somehow run out of cached servers AND are rate limited, we must wait to avoid a kick.
                setCooldown(30, "Cache Empty & Blocked! Waiting 30s...")
                return
            end
        end
        
        -- IF API IS WORKING: Save the servers to our Stash!
        if type(result) == "table" and result.data then
            savedCursor = result.nextPageCursor or "" 
            
            for _, server in ipairs(result.data) do
                if server.playing and server.playing >= 1 and server.playing < (server.maxPlayers - 2) and not badServers[server.id] then
                    table.insert(availableServers, server)
                    
                    -- Add to our secret stash for later (keep stash under 500 to avoid memory lag)
                    if #backupServerCache < 500 then
                        table.insert(backupServerCache, server.id)
                    end
                end
            end
        end
        
        if #availableServers > 0 then
            local chosenServer = availableServers[math.random(1, #availableServers)]
            lastAttemptedServer = chosenServer.id
            
            StatusLabel.Text = "Teleporting..."
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            
            pcall(function() TeleportService:TeleportCancel() end)
            task.wait(1)
            
            TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
            
            task.wait(20)
            if isHopping then
                badServers[lastAttemptedServer] = true
                setCooldown(10, "Teleport stalled! Blacklisting...")
            end
        else
            setCooldown(5, "Page empty! Next page...")
        end
    end)
end

-------------------------------------------------------------------------------
-- 4. CLEAN ERROR CATCHERS
-------------------------------------------------------------------------------
TeleportService.TeleportInitFailed:Connect(function()
    if lastAttemptedServer then badServers[lastAttemptedServer] = true end
    setCooldown(10, "Teleport Blocked! Blacklisted.")
end)

GuiService.ErrorMessageChanged:Connect(function()
    if lastAttemptedServer then badServers[lastAttemptedServer] = true end
    pcall(function() GuiService:ClearError() end) 
    setCooldown(10, "Error Cleared! Blacklisted.")
end)

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local promptUI = CoreGui:FindFirstChild("RobloxPromptGui")
            if promptUI then
                local overlay = promptUI:FindFirstChild("promptOverlay")
                if overlay and overlay:FindFirstChild("ErrorPrompt") and overlay.ErrorPrompt.Visible then
                    if lastAttemptedServer then badServers[lastAttemptedServer] = true end
                    pcall(function() GuiService:ClearError() end)
                    overlay.ErrorPrompt.Visible = false 
                    setCooldown(10, "Prompt Killed! Blacklisted.")
                end
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 5. VICIOUS BEE DETECTOR
-------------------------------------------------------------------------------
local function isViciousAlive()
    local targetFolders = {Workspace:FindFirstChild("Particles"), Workspace:FindFirstChild("Monsters")}
    for _, folder in ipairs(targetFolders) do
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
-- 6. MAIN LOOP & ATLAS INJECTOR
-------------------------------------------------------------------------------
local atlasLoaded = false

task.spawn(function()
    while true do
        task.wait(2) 
        
        if os.time() < globalCooldown then
            StatusLabel.Text = "Cooldown: " .. (globalCooldown - os.time()) .. "s"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            continue
        end
        
        if isHopping then continue end
        
        if isViciousAlive() then
            if not atlasLoaded then
                StatusLabel.Text = "Vicious Found! Loading Atlas..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                atlasLoaded = true 
                
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
                    end)
                end)
            else
                StatusLabel.Text = "Atlas Active. Fighting Vicious..."
            end
        else
            StatusLabel.Text = "Verifying empty server..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            task.wait(5) 
            
            if not isViciousAlive() and not isHopping and os.time() >= globalCooldown then
                serverHop()
            end
        end
    end
end)
