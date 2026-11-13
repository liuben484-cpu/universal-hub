-- Universal Hub (Fluent-Custom)
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hund335/Fluent-Custom/main/Fluent.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Options = Fluent.Options

local connections = {}
local function track(c) table.insert(connections, c) return c end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local Window = Fluent:CreateWindow({
    Title = "Universal Hub",
    SubTitle = "Fluent-Custom",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- blur crashes many executors
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Aim = Window:AddTab({ Title = "Aim", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

---------------------------------------------------------------- Player
local Movement = Tabs.Player:AddSection("Movement")

Movement:AddToggle("SpeedEnabled", { Title = "Custom Walk Speed", Default = false })
Movement:AddSlider("WalkSpeed", {
    Title = "Walk Speed", Min = 16, Max = 200, Default = 16, Increment = 1, Suffix = " studs/s",
})

Movement:AddToggle("JumpEnabled", { Title = "Custom Jump Power", Default = false })
Movement:AddSlider("JumpPower", {
    Title = "Jump Power", Min = 50, Max = 300, Default = 50, Increment = 5,
})

local defaults = { WalkSpeed = 16, JumpPower = 50 }
local function applyStats()
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = Options.SpeedEnabled.Value and Options.WalkSpeed.Value or defaults.WalkSpeed
    hum.UseJumpPower = true
    hum.JumpPower = Options.JumpEnabled.Value and Options.JumpPower.Value or defaults.JumpPower
end
for _, id in ipairs({ "SpeedEnabled", "WalkSpeed", "JumpEnabled", "JumpPower" }) do
    Options[id]:OnChanged(applyStats)
end
-- some games reset WalkSpeed; reapply while enabled
track(RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if not hum then return end
    if Options.SpeedEnabled.Value and hum.WalkSpeed ~= Options.WalkSpeed.Value then
        hum.WalkSpeed = Options.WalkSpeed.Value
    end
end))
track(LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    applyStats()
end))

Movement:AddToggle("InfJump", { Title = "Infinite Jump", Default = false })
track(UserInputService.JumpRequest:Connect(function()
    if not Options.InfJump.Value then return end
    local hum = getHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

Movement:AddToggle("Noclip", { Title = "Noclip", Default = false })
track(RunService.Stepped:Connect(function()
    if not Options.Noclip.Value then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end))

-- Fly
local Fly = Tabs.Player:AddSection("Fly")
Fly:AddSlider("FlySpeed", { Title = "Fly Speed", Min = 10, Max = 300, Default = 60, Increment = 5, Suffix = " studs/s" })
Fly:AddKeybind("FlyKey", { Title = "Fly", Mode = "Toggle", Default = "F" })

local flyVel, flyGyro
local function stopFly()
    if flyVel then flyVel:Destroy() flyVel = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end
track(RunService.RenderStepped:Connect(function()
    local root, hum = getRoot(), getHumanoid()
    if not (Options.FlyKey:GetState() and root and hum) then
        if flyVel then stopFly() end
        return
    end
    if not flyVel or flyVel.Parent ~= root then
        stopFly()
        flyVel = Instance.new("BodyVelocity")
        flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyVel.Parent = root
        flyGyro = Instance.new("BodyGyro")
        flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyGyro.P = 9e4
        flyGyro.Parent = root
    end
    hum.PlatformStand = true
    local cam = Workspace.CurrentCamera
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
    flyVel.Velocity = dir.Magnitude > 0 and dir.Unit * Options.FlySpeed.Value or Vector3.zero
    flyGyro.CFrame = cam.CFrame
end))

---------------------------------------------------------------- Aim
local AimMain = Tabs.Aim:AddSection("Aimbot")
AimMain:AddToggle("AimEnabled", { Title = "Aimbot", Description = "Aims while the key is active", Default = false })
AimMain:AddKeybind("AimKey", { Title = "Aim Key", Mode = "Hold", Default = "MouseRight" })
AimMain:AddDropdown("AimPart", { Title = "Target Part", Values = { "Head", "HumanoidRootPart", "UpperTorso" }, Multi = false, Default = 1 })
AimMain:AddSlider("AimSmooth", {
    Title = "Smoothness", Description = "1 = instant snap, higher = slower",
    Min = 1, Max = 20, Default = 5, Increment = 0.5,
})
AimMain:AddSlider("AimMaxDist", { Title = "Max Distance", Min = 50, Max = 2000, Default = 500, Increment = 50, Suffix = " studs" })

local AimFilter = Tabs.Aim:AddSection("Filters")
AimFilter:AddToggle("AimTeamCheck", { Title = "Ignore Teammates", Default = true })
AimFilter:AddToggle("AimWallCheck", { Title = "Visible Only", Description = "Skip targets behind walls", Default = true })
AimFilter:AddToggle("AimSticky", { Title = "Sticky Target", Description = "Stay on one target while holding", Default = true })

local AimFov = Tabs.Aim:AddSection("FOV Circle")
AimFov:AddSlider("AimFovRadius", { Title = "FOV Radius", Min = 20, Max = 600, Default = 120, Increment = 5, Suffix = " px" })
AimFov:AddToggle("AimShowFov", { Title = "Show FOV Circle", Default = true })
AimFov:AddColorpicker("AimFovColor", { Title = "Circle Color", Default = Color3.fromRGB(255, 255, 255) })

local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Visible = false
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isValidTarget(plr, part)
    if plr == LocalPlayer or not part then return false end
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Options.AimTeamCheck.Value and plr.Team ~= nil and plr.Team == LocalPlayer.Team then return false end
    local cam = Workspace.CurrentCamera
    if (part.Position - cam.CFrame.Position).Magnitude > Options.AimMaxDist.Value then return false end
    if Options.AimWallCheck.Value then
        rayParams.FilterDescendantsInstances = { LocalPlayer.Character, plr.Character }
        local origin = cam.CFrame.Position
        if Workspace:Raycast(origin, part.Position - origin, rayParams) then return false end
    end
    return true
end

local function getAimPart(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild(Options.AimPart.Value)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
end

local function screenDistance(part)
    local cam = Workspace.CurrentCamera
    local pos, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen then return math.huge end
    return (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
end

local currentTarget
local function findTarget()
    local best, bestDist = nil, Options.AimFovRadius.Value
    for _, plr in ipairs(Players:GetPlayers()) do
        local part = getAimPart(plr)
        if isValidTarget(plr, part) then
            local d = screenDistance(part)
            if d < bestDist then best, bestDist = plr, d end
        end
    end
    return best
end

track(RunService.RenderStepped:Connect(function(dt)
    local cam = Workspace.CurrentCamera
    if fovCircle then
        fovCircle.Visible = Options.AimEnabled.Value and Options.AimShowFov.Value
        fovCircle.Radius = Options.AimFovRadius.Value
        fovCircle.Color = Options.AimFovColor.Value
        fovCircle.Position = UserInputService:GetMouseLocation()
    end

    if not (Options.AimEnabled.Value and Options.AimKey:GetState()) then
        currentTarget = nil
        return
    end

    if not (Options.AimSticky.Value and currentTarget and isValidTarget(currentTarget, getAimPart(currentTarget))) then
        currentTarget = findTarget()
    end
    local part = currentTarget and getAimPart(currentTarget)
    if not part then return end

    local goal = CFrame.lookAt(cam.CFrame.Position, part.Position)
    local alpha = math.clamp(dt * 60 / Options.AimSmooth.Value, 0, 1)
    cam.CFrame = cam.CFrame:Lerp(goal, alpha)
end))

---------------------------------------------------------------- Visuals
local Esp = Tabs.Visuals:AddSection("Player ESP")
Esp:AddToggle("EspEnabled", { Title = "ESP (Highlight)", Default = false })
Esp:AddColorpicker("EspColor", { Title = "ESP Color", Default = Color3.fromRGB(96, 205, 255) })
Esp:AddToggle("EspTeamCheck", { Title = "Hide Teammates", Default = false })

local highlights = {}
local function clearEsp()
    for _, h in pairs(highlights) do h:Destroy() end
    table.clear(highlights)
end
task.spawn(function()
    while not Fluent.Unloaded do
        if Options.EspEnabled.Value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local char = plr.Character
                    local hide = Options.EspTeamCheck.Value and plr.Team ~= nil and plr.Team == LocalPlayer.Team
                    local h = highlights[plr]
                    if char and not hide then
                        if not h or h.Parent ~= char then
                            if h then h:Destroy() end
                            h = Instance.new("Highlight")
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            h.FillTransparency = 0.6
                            h.Parent = char
                            highlights[plr] = h
                        end
                        h.FillColor = Options.EspColor.Value
                        h.OutlineColor = Options.EspColor.Value
                    elseif h then
                        h:Destroy()
                        highlights[plr] = nil
                    end
                end
            end
        elseif next(highlights) then
            clearEsp()
        end
        task.wait(0.25)
    end
    clearEsp()
end)
track(Players.PlayerRemoving:Connect(function(plr)
    if highlights[plr] then highlights[plr]:Destroy() highlights[plr] = nil end
end))

local World = Tabs.Visuals:AddSection("World")
World:AddSlider("FOV", { Title = "Field of View", Min = 30, Max = 120, Default = 70, Increment = 1, Suffix = "°" })
Options.FOV:OnChanged(function(v) Workspace.CurrentCamera.FieldOfView = v end)

---------------------------------------------------------------- Misc
local Tp = Tabs.Misc:AddSection("Teleport")
local function playerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(t, p.Name) end
    end
    return t
end
local TpTarget = Tp:AddDropdown("TpTarget", { Title = "Target Player", Values = playerNames(), Multi = false })
Tp:AddButton({ Title = "Refresh List", Callback = function() TpTarget:SetValues(playerNames()) end })
Tp:AddButton({
    Title = "Teleport to Player",
    Callback = function()
        local target = Players:FindFirstChild(Options.TpTarget.Value or "")
        local tRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local root = getRoot()
        if tRoot and root then
            root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
        else
            Fluent:Notify({ Title = "Teleport", Content = "Target not found.", Duration = 3 })
        end
    end,
})

local Util = Tabs.Misc:AddSection("Utility")
Util:AddToggle("AntiAfk", { Title = "Anti AFK", Default = true })
local VirtualUser = game:GetService("VirtualUser")
track(LocalPlayer.Idled:Connect(function()
    if not Options.AntiAfk.Value then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))
Util:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        Window:Dialog({
            Title = "Rejoin",
            Content = "Rejoin this server?",
            Buttons = {
                { Title = "Yes", Callback = function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end },
                { Title = "No" },
            },
        })
    end,
})

---------------------------------------------------------------- Cleanup
task.spawn(function()
    repeat task.wait(1) until Fluent.Unloaded
    for _, c in ipairs(connections) do c:Disconnect() end
    stopFly()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = defaults.WalkSpeed
        hum.JumpPower = defaults.JumpPower
    end
end)

---------------------------------------------------------------- Settings
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "TpTarget" })
InterfaceManager:SetFolder("UniversalHub")
SaveManager:SetFolder("UniversalHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({ Title = "Universal Hub", Content = "Loaded. LeftCtrl = hide/show.", Duration = 5 })
SaveManager:LoadAutoloadConfig()
