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
-- 2. STATE VARIABLES
-------------------------------------------------------------------------------
local atlasExecuted = false
local isHopping = false
local hopCountdown = 15 
local forceHopTimer = false 

-------------------------------------------------------------------------------
-- 3. THE "SMALLEST SERVER" HOPPER
-------------------------------------------------------------------------------
local function performHop()
    if isHopping then return end
    isHopping = true
    StatusLabel.Text = "Hunting smallest server..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    task.spawn(function()
        local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100&_=" .. tostring(math.random(10000, 99999))
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            local minPlayers = math.huge
            local smallestServers = {}

            for _, srv in pairs(result.data) do
                if srv.playing and srv.playing >= 1 and srv.id ~= game.JobId then
                    if srv.playing < minPlayers then
                        minPlayers = srv.playing
                    end
                end
            end

            if minPlayers ~= math.huge then
                for _, srv in pairs(result.data) do
                    if srv.playing == minPlayers and srv.id ~= game.JobId then
                        table.insert(smallestServers, srv.id)
                    end
                end
            end
            
            if #smallestServers > 0 then
                local targetId = smallestServers[math.random(1, #smallestServers)]
                StatusLabel.Text = "Found " .. tostring(minPlayers) .. " player server!"
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                
                TeleportService:TeleportToPlaceInstance(PlaceId, targetId, LocalPlayer)
            else
                StatusLabel.Text = "No good servers. Retrying..."
                task.wait(5)
                isHopping = false 
            end
        else
            StatusLabel.Text = "HTTP Failed. Retrying..."
            task.wait(5)
            isHopping = false 
        end
    end)
end

-------------------------------------------------------------------------------
-- 4. ERROR POPUP CRUSHER (10 SEC OVERRIDE)
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
-- 5. VICIOUS DETECTOR
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
-- 6. MAIN TIMELINE LOOP
-------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if isHopping then continue end 
        
        local viciousHere = isViciousAlive()

        if viciousHere then
            -- Vicious is alive! Have we loaded Atlas yet?
            if not atlasExecuted then
                StatusLabel.Text = "Vicious Found! Loading Atlas..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                atlasExecuted = true
                
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
                end)
            else
                -- Atlas is loaded, we are fighting it. Update UI to show we're waiting.
                StatusLabel.Text = "Killing Vicious..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        else
            -- Vicious is NOT here. 
            if atlasExecuted then
                -- If we previously loaded Atlas, it means Vicious just died!
                StatusLabel.Text = "Vicious Dead! Collecting Loot..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 255)
                
                -- Wait 5 seconds to ensure Atlas picks up the stingers/loot
                task.wait(5)
                performHop()
            else
                -- Normal hunting sequence (no Vicious yet)
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
