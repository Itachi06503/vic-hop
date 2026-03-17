-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(10) -- Give the game 10 seconds to render monsters before we start scanning

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Attempt to find the correct HTTP request function for your executor
local fetchReq = nil
pcall(function() fetchReq = request or http_request or (http and http.request) or (syn and syn.request) end)

-------------------------------------------------------------------------------
-- 1. DRAGGABLE STATUS UI
-------------------------------------------------------------------------------
pcall(function()
    local hiddenGui = gethui and gethui() or game:GetService("CoreGui")
    for _, v in pairs(hiddenGui:GetChildren()) do if v.Name == "VicDetectorUI" then v:Destroy() end end
    for _, v in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do if v.Name == "VicDetectorUI" then v:Destroy() end end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VicDetectorUI"
ScreenGui.ResetOnSpawn = false

local successUI = pcall(function() ScreenGui.Parent = gethui() end)
if not successUI then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 40)
MainFrame.Position = UDim2.new(0.5, -110, 0, 20) 
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
-- 2. ROBUST HOPPING LOGIC
-------------------------------------------------------------------------------
local isHopping = false

local function serverHop()
    if isHopping then return end
    isHopping = true
    StatusLabel.Text = "No Vicious! Hopping..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
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
                if server.playing and server.playing < (server.maxPlayers - 1) and server.id ~= game.JobId then
                    table.insert(availableServers, server)
                end
            end
            
            if #availableServers > 0 then
                local chosenServer = availableServers[math.random(1, #availableServers)]
                StatusLabel.Text = "Teleporting..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1)
                TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer.id, LocalPlayer)
                return 
            end
        end
        
        StatusLabel.Text = "API Failed. Random Hop..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(1)
        TeleportService:Teleport(PlaceId, LocalPlayer)
        
        task.wait(15)
        isHopping = false
    end)
end

-------------------------------------------------------------------------------
-- 3. VICIOUS BEE DETECTOR
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
-- 4. ANTI-STUCK (DISCONNECT CATCHER)
-------------------------------------------------------------------------------
GuiService.ErrorMessageChanged:Connect(function()
    StatusLabel.Text = "Error detected! Forcing hop..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    task.wait(3)
    isHopping = false
    serverHop()
end)

-------------------------------------------------------------------------------
-- 5. MAIN LOOP
-------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(3) -- Check every 3 seconds
        if isHopping then continue end
        
        if isViciousAlive() then
            StatusLabel.Text = "Vicious Found! Staying..."
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80) -- Green
        else
            StatusLabel.Text = "Verifying empty server..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80) -- Orange
            task.wait(5) -- Give it 5 seconds to double check (prevents hopping during lag spikes)
            
            if not isViciousAlive() then
                serverHop()
            end
        end
    end
end)
