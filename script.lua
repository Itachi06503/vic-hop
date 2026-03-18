-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(10)

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local fetchReq = (request or http_request or (syn and syn.request))

-------------------------------------------------------------------------------
-- 1. SIMPLE DRAGGABLE UI
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
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end

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
StatusLabel.Text = "Starting up..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true

-------------------------------------------------------------------------------
-- 2. BASIC SERVER HOPPING
-------------------------------------------------------------------------------
local isHopping = false

local function randomServerHop()
    if isHopping then return end
    isHopping = true
    StatusLabel.Text = "Finding random server..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    task.spawn(function()
        -- Randomize Asc/Desc to mix up the results without needing pagination
        local sort = (math.random() > 0.5) and "Asc" or "Desc"
        local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=" .. sort .. "&limit=100"
        
        local success, result = pcall(function()
            if fetchReq then
                local res = fetchReq({Url = url, Method = "GET"})
                if res.StatusCode == 429 then return "RATELIMIT" end
                return HttpService:JSONDecode(res.Body)
            else
                return HttpService:JSONDecode(game:HttpGet(url))
            end
        end)
        
        if result == "RATELIMIT" then
            StatusLabel.Text = "Rate Limited. Waiting 15s..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(15)
            isHopping = false
            return
        end
        
        if success and type(result) == "table" and result.data then
            local validServers = {}
            for _, srv in ipairs(result.data) do
                if srv.playing and srv.playing < (srv.maxPlayers - 1) and srv.id ~= game.JobId then
                    table.insert(validServers, srv.id)
                end
            end
            
            if #validServers > 0 then
                local randomId = validServers[math.random(1, #validServers)]
                StatusLabel.Text = "Teleporting..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                
                TeleportService:TeleportToPlaceInstance(PlaceId, randomId, LocalPlayer)
                
                -- Wait 15 seconds for TP to happen. If it fails, reset hopping status.
                task.wait(15)
                isHopping = false 
            else
                StatusLabel.Text = "No open servers. Retrying..."
                task.wait(5)
                isHopping = false
            end
        else
            StatusLabel.Text = "API Error. Retrying..."
            task.wait(5)
            isHopping = false
        end
    end)
end

-------------------------------------------------------------------------------
-- 3. SIMPLE ERROR CLEARING
-------------------------------------------------------------------------------
-- If teleport fails, immediately allow hopping again
TeleportService.TeleportInitFailed:Connect(function()
    isHopping = false
end)

-- Auto-close Roblox error prompts
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local promptUI = CoreGui:FindFirstChild("RobloxPromptGui")
            if promptUI then
                local overlay = promptUI:FindFirstChild("promptOverlay")
                if overlay and overlay:FindFirstChild("ErrorPrompt") and overlay.ErrorPrompt.Visible then
                    GuiService:ClearError()
                    isHopping = false -- Reset hop status so it tries again
                end
            end
        end)
    end
end)

-------------------------------------------------------------------------------
-- 4. VICIOUS CHECK & MAIN LOOP
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

local atlasLoaded = false

task.spawn(function()
    while task.wait(3) do
        if isHopping then continue end
        
        if isViciousAlive() then
            if not atlasLoaded then
                StatusLabel.Text = "Vicious Found! Loading Atlas..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                atlasLoaded = true 
                
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
                end)
            else
                StatusLabel.Text = "Atlas Active. Fighting Vicious..."
            end
        else
            StatusLabel.Text = "No Vicious. Preparing to hop..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            task.wait(2) 
            
            if not isViciousAlive() and not isHopping then
                randomServerHop()
            end
        end
    end
end)
