local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local visitedServers = {}

-- [[ SCRIPT STATE TRACKER ]] --
local scriptState = "SCANNING"
local fightStartTime = 0

-------------------------------------------------------------------------------
-- 0. ON-SCREEN CONSOLE UI
-------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VicHopConsole"
-- Attempt to hide it in CoreGui, fallback to PlayerGui if executor restricts it
if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 200)
MainFrame.Position = UDim2.new(0, 15, 0, 15) -- Top left corner
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = " 🐝 Vic Hop Console"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.BorderSizePixel = 0

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, 0, 1, -25)
Scroll.Position = UDim2.new(0, 0, 0, 25)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local logCount = 0
local function Log(msg, level)
    level = level or "INFO"
    local color = Color3.fromRGB(220, 220, 220) -- Default white
    
    if level == "ERROR" then color = Color3.fromRGB(255, 80, 80)
    elseif level == "WARN" then color = Color3.fromRGB(255, 200, 80)
    elseif level == "SUCCESS" then color = Color3.fromRGB(80, 255, 80) end

    local txt = Instance.new("TextLabel", Scroll)
    txt.Size = UDim2.new(1, -5, 0, 16)
    txt.BackgroundTransparency = 1
    txt.Text = " [" .. level .. "] " .. tostring(msg)
    txt.TextColor3 = color
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.Code
    txt.TextSize = 12
    txt.TextWrapped = true
    txt.AutomaticSize = Enum.AutomaticSize.Y
    
    logCount = logCount + 1
    txt.LayoutOrder = logCount

    -- Auto-scroll to bottom
    task.delay(0.05, function()
        Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
    end)
end

Log("Vic Hop script initialized.", "INFO")

-------------------------------------------------------------------------------
-- 1. ANTI-AFK
-------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    Log("Anti-AFK: Prevented idle disconnect.", "WARN")
end)

-------------------------------------------------------------------------------
-- 2. SMART SERVER HOPPING
-------------------------------------------------------------------------------
local isHopping = false
local function serverHop()
    scriptState = "HOPPING"
    if isHopping then return end
    isHopping = true
    
    Log("Searching for a new server...", "INFO")
    
    task.spawn(function()
        local serversApi = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local success, result = pcall(function() 
            return HttpService:JSONDecode(game:HttpGet(serversApi)) 
        end)
        
        if success and result and result.data then
            local availableServers = {}
            for _, server in ipairs(result.data) do
                if server.playing <= (server.maxPlayers - 2) and server.id ~= game.JobId and not visitedServers[server.id] then
                    table.insert(availableServers, server)
                end
            end
            
            if #availableServers > 0 then
                local chosenServer = availableServers[math.random(1, #availableServers)]
                visitedServers[chosenServer.id] = true
                
                Log("Teleporting -> Player Count: " .. chosenServer.playing .. "/" .. chosenServer
