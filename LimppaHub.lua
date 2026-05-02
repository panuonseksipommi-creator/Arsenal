local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local aimbotEnabled = false
local usePredictionAimbot = true
local autoPredictionEnabled = true
local espEnabled = true
local highlightEnabled = false
local wallCheck = true
local teamCheck = true
local aimSmoothness = 0.18
local aimFOV = 720
local autoPredMultiplier = 0.0016

local targetCache = nil
local espObjects = {}

-- FOV Circle
local fovAim = Drawing.new("Circle")
fovAim.Thickness = 2
fovAim.Color = Color3.fromRGB(0, 255, 140)
fovAim.Transparency = 0.65
fovAim.Filled = false
fovAim.Visible = false

-- ==================== ESP ====================
local function createESP(plr)
    if espObjects[plr] then return end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Color3.fromRGB(0, 255, 140)
    box.Transparency = 1
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Text = plr.Name
    name.Size = 15
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Outline = true
    name.Center = true
    name.Visible = false

    espObjects[plr] = {box = box, name = name}
end

local function updateESP()
    if not espEnabled then
        for _, v in pairs(espObjects) do
            v.box.Visible = false
            v.name.Visible = false
        end
        return
    end

    for plr, drawings in pairs(espObjects) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
            if teamCheck and plr.Team == LocalPlayer.Team then
                drawings.box.Visible = false
                drawings.name.Visible = false
                continue
            end

            local root = plr.Character.HumanoidRootPart
            local head = plr.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,2,0))
                local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))

                local height = bottom.Y - top.Y
                local width = height * 0.6

                drawings.box.Size = Vector2.new(width, height)
                drawings.box.Position = Vector2.new(top.X - width/2, top.Y)
                drawings.box.Visible = true

                drawings.name.Position = Vector2.new(top.X, top.Y - 18)
                drawings.name.Visible = true
            else
                drawings.box.Visible = false
                drawings.name.Visible = false
            end
        else
            drawings.box.Visible = false
            drawings.name.Visible = false
        end
    end
end

-- Highlight ESP
local function updateHighlight()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local highlight = plr.Character:FindFirstChild("Highlight")
            if highlightEnabled then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "Highlight"
                    highlight.FillColor = Color3.fromRGB(0, 255, 140)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = plr.Character
                end
                if teamCheck and plr.Team == LocalPlayer.Team then
                    highlight.Enabled = false
                else
                    highlight.Enabled = true
                end
            elseif highlight then
                highlight:Destroy()
            end
        end
    end
end

-- Create ESP for existing players
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then createESP(plr) end
end
Players.PlayerAdded:Connect(createESP)

-- ==================== RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Limppa Hub | Arsenal",
    LoadingTitle = "Limppa Hub",
    LoadingSubtitle = "by ZenLimppa",
    ConfigurationSaving = {
        Enabled = false,
    },
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Aimbot Section
MainTab:CreateSection("Aimbot")

MainTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        aimbotEnabled = Value
    end,
})

MainTab:CreateToggle({
    Name = "Prediction",
    CurrentValue = true,
    Flag = "PredictionToggle",
    Callback = function(Value)
        usePredictionAimbot = Value
    end,
})

-- Aimbot Settings
MainTab:CreateSection("Aimbot Settings")

MainTab:CreateSlider({
    Name = "Aimbot Strength",
    Range = {0.05, 0.85},
    Increment = 0.01,
    CurrentValue = aimSmoothness,
    Flag = "SmoothnessSlider",
    Callback = function(Value)
        aimSmoothness = Value
    end,
})

MainTab:CreateSlider({
    Name = "Aim FOV",
    Range = {200, 1500},
    Increment = 10,
    CurrentValue = aimFOV,
    Flag = "FOVSlider",
    Callback = function(Value)
        aimFOV = Value
        fovAim.Radius = Value
    end,
})

-- Prediction Settings
MainTab:CreateSection("Prediction")

MainTab:CreateSlider({
    Name = "Prediction Multiplier",
    Range = {0.0008, 0.003},
    Increment = 0.0001,
    CurrentValue = autoPredMultiplier,
    Flag = "PredMultiplier",
    Callback = function(Value)
        autoPredMultiplier = Value
    end,
})

-- Visuals Section
MainTab:CreateSection("Visuals")

MainTab:CreateToggle({
    Name = "Drawing ESP",
    CurrentValue = true,
    Flag = "ESPToggle",
    Callback = function(Value)
        espEnabled = Value
    end,
})

MainTab:CreateToggle({
    Name = "Highlight ESP",
    CurrentValue = false,
    Flag = "HighlightToggle",
    Callback = function(Value)
        highlightEnabled = Value
    end,
})

-- Settings Section
MainTab:CreateSection("Settings")

MainTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(Value)
        wallCheck = Value
    end,
})

MainTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        teamCheck = Value
    end,
})

-- ==================== FUNCTIONS ====================
local function isEnemy(plr)
    if not teamCheck then return true end
    if not plr.Team or not LocalPlayer.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end

local function isVisible(part)
    if not wallCheck then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return res and res.Instance:IsDescendantOf(part.Parent)
end

local function getPrediction(part, root)
    if not usePredictionAimbot then return 0 end
    local dist = (Camera.CFrame.Position - part.Position).Magnitude
    if autoPredictionEnabled and root then
        return dist * autoPredMultiplier + (root.Velocity.Magnitude * 0.0001)
    end
    return 0
end

local function updateTargetCache()
    local closest, minDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isEnemy(plr) then
            local char = plr.Character
            local part = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
            local root = char:FindFirstChild("HumanoidRootPart")

            if part and isVisible(part) then
                local vp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(vp.X, vp.Y) - center).Magnitude
                    if dist < minDist and dist < aimFOV then
                        minDist = dist
                        closest = {Part = part, Root = root}
                    end
                end
            end
        end
    end
    targetCache = closest
end

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    if aimbotEnabled and targetCache then
        local pos = targetCache.Part.Position
        local pred = getPrediction(targetCache.Part, targetCache.Root)
        if targetCache.Root then 
            pos += targetCache.Root.Velocity * pred 
        end

        local targetCF = CFrame.lookAt(Camera.CFrame.Position, pos)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, aimSmoothness)
    end

    fovAim.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovAim.Visible = aimbotEnabled
    fovAim.Radius = aimFOV

    updateESP()
    updateHighlight()
end)

RunService.Heartbeat:Connect(updateTargetCache)

Rayfield:Notify({
    Title = "Limppa Hub",
    Content = "Successfully loaded by ZenLimppa",
    Duration = 6,
    Image = 4483362458,
})
