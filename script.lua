-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(10) -- Give the game 10 seconds to render monsters before we start scanning

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
-- 2. ROBUST HOPPING LOGIC (WITH RETRIES)
-------------------------------------------------------------------------------
local isHopping = false

local function serverHop()
    if isHopping then return end
    isHopping = true
    StatusLabel.Text = "No Vicious! Hopping..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    task.spawn(function()
        local chosenServer = nil
        local attempts = 0
        
        -- Try to fetch the API up to 3 times to bypass rate-limits
        while not chosenServer and attempts < 3 do
            attempts = attempts + 1
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
                    if server.playing and server.playing < (server.maxPlayers - 2) and server.id ~= game.JobId then
                        table.insert(availableServers, server)
                    end
                end
                
                if #availableServers > 0 then
                    chosenServer = availableServers[math.random(1, #availableServers)]
                    break
                end
            end
            
            if not chosenServer then
                StatusLabel.Text = "API Rate Limit. Retry " .. attempts .. "/3..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                task.wait(3) -- Wait 3 seconds before trying the API again
            end
        end
        
        -- If we successfully found a server, teleport. Otherwise, fallback.
        if chosenServer then
            StatusLabel.Text = "Teleporting..."
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
        else
            StatusLabel.Text = "API Failed. Random Hop..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(2)
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
        
        -- If 20 seconds pass and we are still here, the teleport failed! Unlock and retry.
        task.wait(20)
        if isHopping then
            StatusLabel.Text = "Teleport stalled. Retrying..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            isHopping = false
        end
    end)
end

-------------------------------------------------------------------------------
-- 3. BULLETPROOF ERROR & KICK CATCHERS (WITH COOLDOWNS)
-------------------------------------------------------------------------------
-- Catcher 1: Built-in Teleport Failure Event
TeleportService.TeleportInitFailed:Connect(function()
    StatusLabel.Text = "Teleport Blocked! Waiting 5s..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    task.wait(5) -- MUST wait 5 seconds to bypass Roblox spam filter
    isHopping = false
    serverHop()
end)

-- Catcher 2: GuiService Error Event
GuiService.ErrorMessageChanged:Connect(function()
    StatusLabel.Text = "Error detected! Waiting 5s..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    task.wait(5) -- MUST wait 5 seconds to clear the error state
    isHopping = false
    serverHop()
end)

-- Catcher 3: Physical Screen Prompt Scanner
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local promptUI = CoreGui:FindFirstChild("RobloxPromptGui")
            if promptUI then
                local overlay = promptUI:FindFirstChild("promptOverlay")
                if overlay and overlay:FindFirstChild("ErrorPrompt") and overlay.ErrorPrompt.Visible then
                    StatusLabel.Text = "Server Full Detected! Waiting 5s..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    task.wait(5)
                    isHopping = false
                    serverHop()
                end
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 4. VICIOUS BEE DETECTOR
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
-- 5. MAIN LOOP & ATLAS INJECTOR
-------------------------------------------------------------------------------
local atlasLoaded = false

task.spawn(function()
    while true do
        task.wait(3) -- Check every 3 seconds
        if isHopping then continue end
        
        if isViciousAlive() then
            if not atlasLoaded then
                StatusLabel.Text = "Vicious Found! Loading Atlas..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80) -- Green
                atlasLoaded = true 
                
                -- ========================================================
                -- ATLAS HUB INJECTOR
                -- ========================================================
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
                    end)
                end)
                -- ========================================================
                
            else
                StatusLabel.Text = "Atlas Active. Fighting Vicious..."
            end
        else
            StatusLabel.Text = "Verifying empty server..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80) -- Orange
            task.wait(5) -- Give it 5 seconds to double check
            
            if not isViciousAlive() then
                serverHop()
            end
        end
    end
end)
