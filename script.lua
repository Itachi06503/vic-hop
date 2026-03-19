-- Wait for the game to fully load
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(5) 

local TeleportService = game:GetService("TeleportService")
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
local hopCountdown = 30 
local forceHopTimer = false 

-------------------------------------------------------------------------------
-- 3. NATIVE HOPPER (NO HTTP / NO PROXY)
-------------------------------------------------------------------------------
local function performHop()
    if isHopping then return end
    isHopping = true
    StatusLabel.Text = "Triggering Native Hop..."
    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    
    -- This is the exact command executor buttons use to force a random matchmake
    -- No HTTP requests = No proxy failures.
    pcall(function()
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end)
    
    -- If it takes longer than 10 seconds to teleport, reset so it can try again
    task.spawn(function()
        task.wait(10)
        isHopping = false
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
        if atlasExecuted then continue end 
        if isHopping then continue end 
        
        -- Step 1: Check for Vicious
        if isViciousAlive() then
            StatusLabel.Text = "Vicious Found! Loading Atlas..."
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            atlasExecuted = true
            
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
            end)
            continue
        end
        
        -- Step 2: No Vicious? Run the countdown
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
            -- Step 3: Countdown hit 0, time to hop
            performHop()
        end
    end
end)
