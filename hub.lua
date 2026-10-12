-- ROCKET HUB v3 — Build A Boat + Grace + Settings
-- Інжектор: Solara

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- СТАН
-- ============================================================
local State = {
    Speed = 16,
    Jump = 50,
    Gravity = 196.2,
    FlySpeed = 120,
    FOV = 70,

    Fly = false,
    Noclip = false,
    InfJump = false,
    ESP = false,
    Tracers = false,
    Fullbright = false,
    GravityOff = false,
    ClickTP = false,
    AntiAFK = true,

    DoorsAutoHide = false,
    DoorsHighlights = false,
    DoorsRushAlarm = false,

    BHSkyPreset = "Default",

    KSCameraLock = false,

    ArEsp = false,
    ArTracers = false,

    RvEsp = false,
    RvTracers = false,
    RvCamLock = false,
    RvTeamCheck = true,

    MmEsp = false,
    MmTracers = false,
    MmRoleEsp = true,

    BaEsp = false,
    BaTracers = false,
    BaAutoCollect = false,

    GrEsp = false,
    GrTracers = false,
    GrFullbright = false,
}

-- ============================================================
-- НАЛАШТУВАННЯ (зберігаються в пам'яті, поки скрипт активний)
-- ============================================================
local Settings = {
    NotifSound = true,
    NotifVolume = 0.5,
    NotifDuration = 4,           -- секунди
    SoundSuccess = "rbxassetid://4590662766",
    SoundError   = "rbxassetid://5159527953",
    SoundInfo    = "rbxassetid://4590662766",
    SoundWarn    = "rbxassetid://5159527953",
}

-- ============================================================
-- УТИЛІТИ
-- ============================================================
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function applyHumanoid()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = State.Speed
        hum.UseJumpPower = true
        hum.JumpPower = State.Jump
    end
end
applyHumanoid()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyHumanoid()
end)

-- ============================================================
-- СИСТЕМА СПОВІЩЕНЬ
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "ROCKET_Notifs"
notifGui.ResetOnSpawn = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifGui.Parent = CoreGui

local notifHolder = Instance.new("Frame")
notifHolder.Size = UDim2.new(0, 320, 1, -40)
notifHolder.Position = UDim2.new(1, -340, 0, 20)
notifHolder.BackgroundTransparency = 1
notifHolder.Parent = notifGui

local notifLayout = Instance.new("UIListLayout", notifHolder)
notifLayout.Padding = UDim.new(0, 8)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local notifColors = {
    success = Color3.fromRGB(30, 150, 90),
    error = Color3.fromRGB(180, 40, 60),
    warn = Color3.fromRGB(200, 150, 30),
    info = Color3.fromRGB(50, 100, 180),
}
local notifIcons = {
    success = "✅", error = "❌", warn = "⚠️", info = "ℹ️",
}

local function playNotifSound(id)
    if not Settings.NotifSound then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = Settings.NotifVolume
    s.Parent = SoundService
    s:Play()
    game:GetService("Debris"):AddItem(s, 3)
end

local function Notify(title, text, ntype)
    ntype = ntype or "info"
    local color = notifColors[ntype] or notifColors.info
    local icon = notifIcons[ntype] or "ℹ️"

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Position = UDim2.new(1, 60, 0, 0)
    card.Parent = notifHolder
    local cc = Instance.new("UICorner", card) cc.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Parent = card
    local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(0, 8)

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 30, 1, 0)
    iconL.Position = UDim2.new(0, 8, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 20
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = color
    iconL.Parent = card

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -50, 0, 22)
    titleL.Position = UDim2.new(0, 42, 0, 6)
    titleL.BackgroundTransparency = 1
    titleL.Text = "ROCKET • " .. tostring(title)
    titleL.TextColor3 = Color3.fromRGB(240, 235, 255)
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.Parent = card

    local textL = Instance.new("TextLabel")
    textL.Size = UDim2.new(1, -50, 0, 22)
    textL.Position = UDim2.new(0, 42, 0, 28)
    textL.BackgroundTransparency = 1
    textL.Text = tostring(text)
    textL.TextColor3 = Color3.fromRGB(180, 180, 200)
    textL.Font = Enum.Font.Gotham
    textL.TextSize = 11
    textL.TextXAlignment = Enum.TextXAlignment.Left
    textL.TextWrapped = true
    textL.Parent = card

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0,
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    if ntype == "success" then
        playNotifSound(Settings.SoundSuccess)
    elseif ntype == "error" then
        playNotifSound(Settings.SoundError)
    elseif ntype == "warn" then
        playNotifSound(Settings.SoundWarn)
    else
        playNotifSound(Settings.SoundInfo)
    end

    task.delay(Settings.NotifDuration, function()
        local t = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 60, 0, 0),
        })
        t:Play()
        TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
        t.Completed:Wait()
        card:Destroy()
    end)
end

local function safe(label, fn)
    local ok, err = pcall(fn)
    if ok then
        Notify(label, "Успішно активовано", "success")
    else
        Notify(label, "Помилка: " .. tostring(err), "error")
    end
end

-- ============================================================
-- FLY
-- ============================================================
local bv, bg, flyVel = nil, nil, Vector3.zero
local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    flyVel = Vector3.zero
end
local function startFly()
    local hrp = getHRP() if not hrp then return end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4
    bg.Parent = hrp
    RunService.RenderStepped:Connect(function(dt)
        if not State.Fly or not bv then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        local target = move * State.FlySpeed
        flyVel = flyVel:Lerp(target, math.min(dt*8, 1))
        bv.Velocity = flyVel
    end)
end

-- ============================================================
-- NOCLIP / INF JUMP / GRAVITY / FOV
-- ============================================================
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    if State.GravityOff then
        workspace.Gravity = 0
    else
        workspace.Gravity = State.Gravity
    end
end)

RunService.RenderStepped:Connect(function()
    if Camera.FieldOfView ~= State.FOV then
        Camera.FieldOfView = State.FOV
    end
end)

-- ============================================================
-- ESP + TRACERS
-- ============================================================
local espList = {}
local tracerList = {}
local function createESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 1.5 box.Color = Color3.fromRGB(255,80,80) box.Filled = false box.Visible = false
    local nm = Drawing.new("Text")
    nm.Size = 13 nm.Color = Color3.fromRGB(255,255,255) nm.Center = true nm.Outline = true nm.Visible = false
    espList[player] = {box=box, name=nm}

    local line = Drawing.new("Line")
    line.Thickness = 1.5 line.Color = Color3.fromRGB(0,200,255) line.Transparency = 0.8 line.Visible = false
    tracerList[player] = line

    RunService.RenderStepped:Connect(function()
        local d = espList[player]
        local l = tracerList[player]
        local char = player.Character
        local enabled = State.ESP or State.ArEsp or State.RvEsp or State.MmEsp or State.BaEsp or State.GrEsp
        local tracerOn = State.Tracers or State.ArTracers or State.RvTracers or State.MmTracers or State.BaTracers or State.GrTracers

        if not d then return end
        if not char or (not enabled and not tracerOn) then
            if d.box then d.box.Visible = false end
            if d.name then d.name.Visible = false end
            if l then l.Visible = false end
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then
            d.box.Visible=false d.name.Visible=false if l then l.Visible=false end
            return
        end
        local pos, on = Camera:WorldToViewportPoint(hrp.Position)
        local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
        if on then
            if enabled then
                local h = math.abs(pos.Y - hp.Y)*2
                local w = h/2
                d.box.Size = Vector2.new(w,h)
                d.box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                d.box.Visible = true

                local labelText = player.Name
                if State.MmRoleEsp then
                    local role = "Innocent"
                    if player.Backpack then
                        for _, tool in ipairs(player.Backpack:GetChildren()) do
                            if tool.Name:lower():find("knife") then role = "Murderer" end
                            if tool.Name:lower():find("gun") then role = "Sheriff" end
                        end
                    end
                    if char then
                        for _, tool in ipairs(char:GetChildren()) do
                            if tool:IsA("Tool") then
                                if tool.Name:lower():find("knife") then role = "Murderer" end
                                if tool.Name:lower():find("gun") then role = "Sheriff" end
                            end
                        end
                    end
                    labelText = player.Name .. " [" .. role .. "]"
                end

                d.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 16)
                d.name.Text = labelText
                d.name.Visible = true
            else
                d.box.Visible = false
                d.name.Visible = false
            end
            if tracerOn and l then
                l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                l.To = Vector2.new(pos.X, pos.Y)
                l.Visible = true
            elseif l then
                l.Visible = false
            end
        else
            d.box.Visible=false d.name.Visible=false if l then l.Visible=false end
        end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- ============================================================
-- FULLBRIGHT
-- ============================================================
RunService.Heartbeat:Connect(function()
    if State.Fullbright then
        Lighting.Brightness = 4
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
        Lighting.FogEnd = 1e6
    end
end)

-- ============================================================
-- ANTI-AFK
-- ============================================================
LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

-- ============================================================
-- CLICK TELEPORT
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if State.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local hrp = getHRP()
        if not hrp then return end
        local mouse = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then
            hrp.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0))
        end
    end
end)

-- ============================================================
-- DOORS
-- ============================================================
local Cache = {furniture={}, doors={}, items={}, lastRefresh=0, rushActive=false, lastRush=0}

local function refreshCache()
    local now = tick()
    if now - Cache.lastRefresh < 1 then return end
    Cache.lastRefresh = now
    Cache.furniture, Cache.doors, Cache.items = {}, {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("wardrobe") or n:find("locker") or n:find("bed") or n:find("drawer") or n:find("closet") or n:find("hide") then
                table.insert(Cache.furniture, obj)
            elseif n:find("door") then
                table.insert(Cache.doors, obj)
            elseif n:find("key") or n:find("coin") or n:find("gold") or n:find("crucifix") or n:find("lighter") or n:find("lockpick") then
                table.insert(Cache.items, obj)
            end
        end
    end
end

local hideConn
local function toggleDoorsAutoHide(on)
    State.DoorsAutoHide = on
    if on then
        hideConn = RunService.Heartbeat:Connect(function()
            if not State.DoorsAutoHide then return end
            local hrp = getHRP()
            if not hrp then return end
            refreshCache()
            local nearest, dist = nil, 10
            for _, obj in ipairs(Cache.furniture) do
                local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if base then
                    local d = (base.Position - hrp.Position).Magnitude
                    if d < dist then nearest, dist = base, d end
                end
            end
            if nearest then
                hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,2,0))
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        end)
    else
        if hideConn then hideConn:Disconnect() hideConn = nil end
    end
end

local doorHL, itemHL = {}, {}
local function toggleDoorsHighlights(on)
    State.DoorsHighlights = on
    for _, h in pairs(doorHL) do h:Destroy() end doorHL = {}
    for _, h in pairs(itemHL) do h:Destroy() end itemHL = {}
    if not on then return end
    refreshCache()
    for _, obj in ipairs(Cache.doors) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj:IsA("Model") and obj or obj.Parent
        hl.FillColor = Color3.fromRGB(255,100,100)
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.FillTransparency = 0.5
        hl.Parent = obj
        table.insert(doorHL, hl)
    end
    for _, obj in ipairs(Cache.items) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj
        hl.FillColor = Color3.fromRGB(255,220,80)
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.FillTransparency = 0.3
        hl.Parent = obj
        table.insert(itemHL, hl)
    end
end

RunService.Heartbeat:Connect(function()
    if not State.DoorsRushAlarm then return end
    local now = tick()
    if now - Cache.lastRush < 1 then return end
    Cache.lastRush = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("rush") or n:find("ambush") then
                if not Cache.rushActive then
                    Cache.rushActive = true
                    Notify("Rush Alarm", "Rush/Ambush виявлено!", "warn")
                end
                return
            end
        end
    end
    Cache.rushActive = false
end)

-- ============================================================
-- BROOKHAVEN SKY
-- ============================================================
local bhPresets = {
    Default = {ClockTime=14, Brightness=2, Ambient=Color3.fromRGB(70,70,70), OutdoorAmbient=Color3.fromRGB(128,128,128), FogEnd=500, FogColor=Color3.fromRGB(200,200,200)},
    Night = {ClockTime=0, Brightness=0.5, Ambient=Color3.fromRGB(20,20,30), OutdoorAmbient=Color3.fromRGB(30,30,50), FogEnd=300, FogColor=Color3.fromRGB(15,15,30)},
    Sunset = {ClockTime=18, Brightness=2, Ambient=Color3.fromRGB(120,80,60), OutdoorAmbient=Color3.fromRGB(180,120,90), FogEnd=800, FogColor=Color3.fromRGB(255,140,80)},
    BloodMoon = {ClockTime=0, Brightness=0.4, Ambient=Color3.fromRGB(80,10,10), OutdoorAmbient=Color3.fromRGB(120,20,20), FogEnd=250, FogColor=Color3.fromRGB(80,0,0)},
    Cyberpunk = {ClockTime=0, Brightness=1, Ambient=Color3.fromRGB(40,0,80), OutdoorAmbient=Color3.fromRGB(80,0,160), FogEnd=400, FogColor=Color3.fromRGB(120,0,200)},
    Toxic = {ClockTime=13, Brightness=1.5, Ambient=Color3.fromRGB(60,120,30), OutdoorAmbient=Color3.fromRGB(120,200,60), FogEnd=350, FogColor=Color3.fromRGB(80,180,40)},
}
local function applyBHPreset(name)
    local p = bhPresets[name]
    if not p then return end
    State.BHSkyPreset = name
    Lighting.ClockTime = p.ClockTime
    Lighting.Brightness = p.Brightness
    Lighting.Ambient = p.Ambient
    Lighting.OutdoorAmbient = p.OutdoorAmbient
    Lighting.FogEnd = p.FogEnd
    Lighting.FogColor = p.FogColor
end

-- ============================================================
-- CAMERA LOCK
-- ============================================================
local ksTarget = nil
local function ksFindEnemy(teamCheck)
    local closest, dist = nil, math.huge
    local myHRP = getHRP() if not myHRP then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 then
                local isEnemy = true
                if teamCheck and p.Team ~= nil and LocalPlayer.Team ~= nil then
                    isEnemy = (p.Team ~= LocalPlayer.Team)
                end
                if isEnemy then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < dist then closest, dist = p.Character, d end
                end
            end
        end
    end
    return closest
end
RunService.RenderStepped:Connect(function()
    local active = State.KSCameraLock or State.RvCamLock
    if not active then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
        if not ksTarget or not ksTarget.Parent then
            ksTarget = ksFindEnemy(State.RvTeamCheck and State.RvCamLock)
        end
        if ksTarget then
            local head = ksTarget:FindFirstChild("Head") or ksTarget:FindFirstChild("HumanoidRootPart")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end)

-- ============================================================
-- TP до гравця (MM2)
-- ============================================================
local function tpToPlayer(nameQuery)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():find(nameQuery:lower()) then
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = getHRP()
                if hrp and myHRP then
                    myHRP.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                    Notify("TP", "Переміщено до " .. p.Name, "success")
                    return
                end
            end
        end
    end
    Notify("TP", "Гравця не знайдено: " .. nameQuery, "error")
end

-- ============================================================
-- BUILD A BOAT: AUTO COLLECT + ESP TREASURE
-- ============================================================
local function baAutoCollect()
    if not State.BaAutoCollect then return end
    RunService.Heartbeat:Connect(function()
        if not State.BaAutoCollect then return end
        local hrp = getHRP()
        if not hrp then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Parent and obj.Parent.Name:lower():find("treasure") then
                if (obj.Position - hrp.Position).Magnitude < 50 then
                    pcall(function()
                        obj.CFrame = hrp.CFrame
                    end)
                end
            end
        end
    end)
end

-- ============================================================
-- GRACE: HIGHLIGHT ENTITIES + ESP
-- ============================================================
local graceHL = {}
local function toggleGraceHighlight(on)
    for _, h in pairs(graceHL) do h:Destroy() end
    graceHL = {}
    if not on then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("grace") or n:find("entity") or n:find("monster") or n:find("door") then
                local hl = Instance.new("Highlight")
                hl.Adornee = obj
                hl.FillColor = Color3.fromRGB(255, 80, 200)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.Parent = obj
                table.insert(graceHL, hl)
            end
        end
    end
end

-- ============================================================
-- SERVER HOP
-- ============================================================
local function serverHop()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then Notify("Server Hop", "Помилка запиту", "error") return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 then Notify("Server Hop", "Помилка розбору JSON", "error") return end
    for _, srv in ipairs(data.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            Notify("Server Hop", "Перехід на новий сервер...", "info")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
            return
        end
    end
    Notify("Server Hop", "Вільних серверів не знайдено", "warn")
end

-- ============================================================
-- GUI
-- ============================================================
local old = CoreGui:FindFirstChild("ROCKET_HUB")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ROCKET_HUB"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 620, 0, 500)
main.Position = UDim2.new(0, 40, 0, 60)
main.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local mc = Instance.new("UICorner", main) mc.CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(120, 90, 220)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(35, 25, 60)
title.BorderSizePixel = 0
title.Text = "🚀 ROCKET HUB  •  v3"
title.TextColor3 = Color3.fromRGB(230, 220, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = main
local tc = Instance.new("UICorner", title) tc.CornerRadius = UDim.new(0, 12)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 60)
closeBtn.Text = "—"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = title
local cbc = Instance.new("UICorner", closeBtn) cbc.CornerRadius = UDim.new(0, 6)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -46)
sidebar.Position = UDim2.new(0, 8, 0, 42)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
sidebar.BorderSizePixel = 0
sidebar.Parent = main
local sbc = Instance.new("UICorner", sidebar) sbc.CornerRadius = UDim.new(0, 8)

local sidebarScroll = Instance.new("ScrollingFrame")
sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
sidebarScroll.BackgroundTransparency = 1
sidebarScroll.BorderSizePixel = 0
sidebarScroll.ScrollBarThickness = 3
sidebarScroll.ScrollBarImageColor3 = Color3.fromRGB(150,100,220)
sidebarScroll.CanvasSize = UDim2.new(0,0,0,0)
sidebarScroll.Parent = sidebar

local sbLay = Instance.new("UIListLayout", sidebarScroll)
sbLay.Padding = UDim.new(0, 4)
sbLay.SortOrder = Enum.SortOrder.LayoutOrder
sbLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
sbLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sbLay.AbsoluteContentSize.Y + 10)
end)

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -154, 1, -46)
content.Position = UDim2.new(0, 146, 0, 42)
content.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
content.BorderSizePixel = 0
content.Parent = main
local ccc = Instance.new("UICorner", content) ccc.CornerRadius = UDim.new(0, 8)

local pages = {}

local function newPage(name, isSettings)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 220)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content
    local lay = Instance.new("UIListLayout", page)
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
    end)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = isSettings and Color3.fromRGB(60, 40, 90) or Color3.fromRGB(30, 32, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(210, 205, 230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.LayoutOrder = #pages
    btn.Parent = sidebarScroll
    local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(50,45,75)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if not pages[name] or not pages[name].page.Visible then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = isSettings and Color3.fromRGB(60,40,90) or Color3.fromRGB(30,32,45)
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            p.page.Visible = false
            TweenService:Create(p.btn, TweenInfo.new(0.2), {
                BackgroundColor3 = p.isSettings and Color3.fromRGB(60,40,90) or Color3.fromRGB(30,32,45)
            }):Play()
        end
        page.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(120,80,200)}):Play()
    end)

    pages[name] = {page=page, btn=btn, isSettings=isSettings}
    return page
end

local function makeLabel(parent, text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(180, 160, 230)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeButton(parent, text, cb, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 30)
    b.BackgroundColor3 = color or Color3.fromRGB(35, 38, 50)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 225, 245)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.Parent = parent
    local bc = Instance.new("UICorner", b) bc.CornerRadius = UDim.new(0, 6)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(60,55,85)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=color or Color3.fromRGB(35,38,50)}):Play()
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function makeToggle(parent, text, default, cb)
    local b = makeButton(parent, text .. ": " .. (default and "ON" or "OFF"), nil)
    local on = default
    local function upd()
        b.Text = text .. ": " .. (on and "ON" or "OFF")
        TweenService:Create(b, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Color3.fromRGB(40, 130, 80) or Color3.fromRGB(35, 38, 50)
        }):Play()
    end
    upd()
    b.MouseButton1Click:Connect(function()
        on = not on
        upd()
        safe(text, function() cb(on) end)
    end)
    return b
end

local function makeSlider(parent, label, min, max, default, cb)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -10, 0, 46)
    cont.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    cont.Parent = parent
    local c = Instance.new("UICorner", cont) c.CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 215, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(55, 58, 75)
    bar.BorderSizePixel = 0
    bar.Parent = cont
    local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 100, 220)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner", fill) fc.CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = label .. ": " .. val
        cb(val)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function makeTextBox(parent, default, placeholder, cb)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1, -10, 0, 30)
    t.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    t.Text = default or ""
    t.PlaceholderText = placeholder or ""
    t.TextColor3 = Color3.fromRGB(220, 215, 240)
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.Parent = parent
    local c = Instance.new("UICorner", t) c.CornerRadius = UDim.new(0, 6)
    if cb then
        t.FocusLost:Connect(function() cb(t.Text) end)
    end
    return t
end

-- ============================================================
-- СТОРІНКА: DOORS
-- ============================================================
local pDoors = newPage("Doors")
makeLabel(pDoors, "— Doors —")
makeSlider(pDoors, "Speed", 16, 60, 22, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pDoors, "Jump", 50, 200, 60, function(v) State.Jump = v applyHumanoid() end)
makeToggle(pDoors, "Inf Jump", false, function(on) State.InfJump = on end)
makeToggle(pDoors, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pDoors, "Auto Hide (шкафи)", false, toggleDoorsAutoHide)
makeToggle(pDoors, "Highlight Doors/Items", false, toggleDoorsHighlights)
makeToggle(pDoors, "Rush Alarm", false, function(on) State.DoorsRushAlarm = on end)
makeToggle(pDoors, "Fullbright", false, function(on) State.Fullbright = on end)
makeButton(pDoors, "TP вгору на 100 studs", function()
    safe("TP вгору", function()
        local hrp = getHRP() if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0,100,0) end
    end)
end)
makeButton(pDoors, "TP до найдальших дверей", function()
    safe("TP до дверей", function()
        refreshCache()
        local hrp = getHRP() if not hrp then return end
        local best, dist = nil, 0
        for _, obj in ipairs(Cache.doors) do
            local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
            if base then
                local d = (base.Position - hrp.Position).Magnitude
                if d > dist then best, dist = base, d end
            end
        end
        if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0,4,0)) end
    end)
end)
makeButton(pDoors, "Rejoin", function()
    Notify("Rejoin", "Перезахід...", "info")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- ============================================================
-- СТОРІНКА: BROOKHAVEN
-- ============================================================
local pBH = newPage("Brookhaven")
makeLabel(pBH, "— Небо —")
makeButton(pBH, "☀️ Default", function() safe("Sky", function() applyBHPreset("Default") end) end)
makeButton(pBH, "🌙 Night", function() safe("Sky", function() applyBHPreset("Night") end) end)
makeButton(pBH, "🌅 Sunset", function() safe("Sky", function() applyBHPreset("Sunset") end) end)
makeButton(pBH, "🩸 Blood Moon", function() safe("Sky", function() applyBHPreset("BloodMoon") end) end)
makeButton(pBH, "🌌 Cyberpunk", function() safe("Sky", function() applyBHPreset("Cyberpunk") end) end)
makeButton(pBH, "☢️ Toxic", function() safe("Sky", function() applyBHPreset("Toxic") end) end)
makeLabel(pBH, "— Персонаж —")
makeSlider(pBH, "Speed", 16, 300, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pBH, "Jump", 50, 400, State.Jump, function(v) State.Jump = v applyHumanoid() end)
makeToggle(pBH, "Fly", false, function(on)
    State.Fly = on
    if on then startFly() else stopFly() end
end)
makeSlider(pBH, "Fly Speed", 50, 500, 120, function(v) State.FlySpeed = v end)
makeToggle(pBH, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pBH, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pBH, "Fullbright", false, function(on) State.Fullbright = on end)
makeButton(pBH, "Rejoin", function()
    Notify("Rejoin", "Перезахід...", "info")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- ============================================================
-- СТОРІНКА: KILLSTREAK
-- ============================================================
local pKS = newPage("Killstreak")
makeLabel(pKS, "— Killstreak (safe) —")
makeToggle(pKS, "ESP", false, function(on) State.ESP = on end)
makeToggle(pKS, "Tracers", false, function(on) State.Tracers = on end)
makeToggle(pKS, "Fullbright", false, function(on) State.Fullbright = on end)
makeToggle(pKS, "Camera Lock (Q)", false, function(on) State.KSCameraLock = on end)
makeSlider(pKS, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeButton(pKS, "Server Hop", serverHop)

-- ============================================================
-- СТОРІНКА: ARSENAL
-- ============================================================
local pAr = newPage("Arsenal")
makeLabel(pAr, "— Arsenal —")
makeToggle(pAr, "ESP Players", false, function(on) State.ArEsp = on end)
makeToggle(pAr, "Tracers", false, function(on) State.ArTracers = on end)
makeToggle(pAr, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pAr, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)

-- ============================================================
-- СТОРІНКА: RIVALS
-- ============================================================
local pRv = newPage("RIVALS")
makeLabel(pRv, "— RIVALS (safe) —")
makeToggle(pRv, "ESP Players", false, function(on) State.RvEsp = on end)
makeToggle(pRv, "Tracers", false, function(on) State.RvTracers = on end)
makeToggle(pRv, "Team Check", true, function(on) State.RvTeamCheck = on end)
makeToggle(pRv, "Camera Lock (Q)", false, function(on) State.RvCamLock = on end)
makeToggle(pRv, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pRv, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeButton(pRv, "Server Hop", serverHop)

-- ============================================================
-- СТОРІНКА: MM2
-- ============================================================
local pMm = newPage("MM2")
makeLabel(pMm, "— Murder Mystery 2 —")
makeToggle(pMm, "ESP Players", false, function(on) State.MmEsp = on end)
makeToggle(pMm, "Role ESP (Knife/Gun)", true, function(on) State.MmRoleEsp = on end)
makeToggle(pMm, "Tracers", false, function(on) State.MmTracers = on end)
makeToggle(pMm, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pMm, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeLabel(pMm, "— TP до гравця —")
makeTextBox(pMm, "", "введи ім'я гравця")
makeButton(pMm, "TP до гравця", function()
    local name = ""
    for _, child in ipairs(pMm:GetChildren()) do
        if child:IsA("TextBox") then name = child.Text end
    end
    if name == "" then
        Notify("TP", "Введи ім'я гравця", "warn")
        return
    end
    tpToPlayer(name)
end)
makeButton(pMm, "TP до випадкового", function()
    safe("TP випадковий", function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then table.insert(list, hrp) end
            end
        end
        local hrp = getHRP()
        if hrp and #list > 0 then
            hrp.CFrame = list[math.random(1, #list)].CFrame + Vector3.new(0,2,0)
            Notify("TP", "Переміщено до випадкового гравця", "success")
        end
    end)
end)
makeButton(pMm, "Server Hop", serverHop)

-- ============================================================
-- СТОРІНКА: BUILD A BOAT
-- ============================================================
local pBa = newPage("Build A Boat")
makeLabel(pBa, "— Build A Boat For Treasure —")
makeToggle(pBa, "ESP Players", false, function(on) State.BaEsp = on end)
makeToggle(pBa, "Tracers", false, function(on) State.BaTracers = on end)
makeToggle(pBa, "Auto Collect Treasure", false, function(on)
    State.BaAutoCollect = on
    if on then baAutoCollect() end
end)
makeToggle(pBa, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pBa, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeButton(pBa, "Server Hop", serverHop)
makeButton(pBa, "Rejoin", function()
    Notify("Rejoin", "Перезахід...", "info")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- ============================================================
-- СТОРІНКА: GRACE
-- ============================================================
local pGr = newPage("Grace")
makeLabel(pGr, "— Grace —")
makeToggle(pGr, "ESP Players", false, function(on) State.GrEsp = on end)
makeToggle(pGr, "Tracers", false, function(on) State.GrTracers = on end)
makeToggle(pGr, "Highlight Entities/Doors", false, function(on) toggleGraceHighlight(on) end)
makeToggle(pGr, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pGr, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeSlider(pGr, "Speed", 16, 60, 20, function(v) State.Speed = v applyHumanoid() end)
makeToggle(pGr, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pGr, "Inf Jump", false, function(on) State.InfJump = on end)
makeButton(pGr, "Server Hop", serverHop)

-- ============================================================
-- СТОРІНКА: BLOX FRUITS
-- ============================================================
local pBF = newPage("Blox Fruits")
makeLabel(pBF, "— Blox Fruits (у розробці) —")
makeToggle(pBF, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pBF, "Fly", false, function(on)
    State.Fly = on
    if on then startFly() else stopFly() end
end)
makeSlider(pBF, "Speed", 16, 300, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeToggle(pBF, "Noclip", false, function(on) State.Noclip = on end)

-- ============================================================
-- СТОРІНКА: OTHER
-- ============================================================
local pOther = newPage("Other")
makeLabel(pOther, "— Загальні функції —")
makeSlider(pOther, "Speed", 16, 500, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pOther, "Jump", 50, 500, State.Jump, function(v) State.Jump = v applyHumanoid() end)
makeSlider(pOther, "Gravity", 0, 500, State.Gravity, function(v) State.Gravity = v end)
makeSlider(pOther, "Fly Speed", 50, 800, State.FlySpeed, function(v) State.FlySpeed = v end)
makeSlider(pOther, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)

makeToggle(pOther, "Fly (WASD)", false, function(on)
    State.Fly = on
    if on then startFly() else stopFly() end
end)
makeToggle(pOther, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pOther, "Infinite Jump", false, function(on) State.InfJump = on end)
makeToggle(pOther, "Gravity OFF (0)", false, function(on) State.GravityOff = on end)
makeToggle(pOther, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pOther, "Tracers", false, function(on) State.Tracers = on end)
makeToggle(pOther, "Fullbright", false, function(on) State.Fullbright = on end)
makeToggle(pOther, "Click TP", false, function(on) State.ClickTP = on end)
makeToggle(pOther, "Anti-AFK", true, function(on) State.AntiAFK = on end)

makeLabel(pOther, "— Утиліти —")
makeButton(pOther, "Reset Character", function()
    safe("Reset", function()
        local hum = getHum() if hum then hum.Health = 0 end
    end)
end)
makeButton(pOther, "Rejoin", function()
    Notify("Rejoin", "Перезахід...", "info")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
makeButton(pOther, "Server Hop", serverHop)
makeButton(pOther, "Unload ROCKET HUB", function()
    stopFly()
    State.ESP = false State.Tracers = false State.RvEsp = false State.MmEsp = false State.BaEsp = false State.GrEsp = false
    for _, d in pairs(espList) do
        d.box:Remove() d.name:Remove()
    end
    for _, l in pairs(tracerList) do l:Remove() end
    for _, h in pairs(doorHL) do h:Destroy() end
    for _, h in pairs(itemHL) do h:Destroy() end
    for _, h in pairs(graceHL) do h:Destroy() end
    Notify("ROCKET", "Скрипт вивантажено", "success")
    task.wait(0.3)
    gui:Destroy()
    notifGui:Destroy()
end, Color3.fromRGB(90, 30, 40))

-- ============================================================
-- СТОРІНКА: SETTINGS
-- ============================================================
local pSet = newPage("⚙ Settings", true)

makeLabel(pSet, "— Сповіщення —")

makeToggle(pSet, "Звук сповіщень", Settings.NotifSound, function(on)
    Settings.NotifSound = on
end)

makeSlider(pSet, "Гучність (%)", 0, 100, math.floor(Settings.NotifVolume*100), function(v)
    Settings.NotifVolume = v / 100
end)

makeSlider(pSet, "Тривалість (сек)", 1, 15, Settings.NotifDuration, function(v)
    Settings.NotifDuration = v
end)

makeLabel(pSet, "— Звукові ID —")
makeLabel(pSet, "Встав rbxassetid або просто число", Color3.fromRGB(180,180,180))

makeLabel(pSet, "Success Sound ID:", Color3.fromRGB(120,200,140))
makeTextBox(pSet, Settings.SoundSuccess, "rbxassetid://...", function(text)
    if text and text ~= "" then
        Settings.SoundSuccess = text
        Notify("Settings", "Success звук оновлено", "success")
    end
end)

makeLabel(pSet, "Error Sound ID:", Color3.fromRGB(220,120,120))
makeTextBox(pSet, Settings.SoundError, "rbxassetid://...", function(text)
    if text and text ~= "" then
        Settings.SoundError = text
        Notify("Settings", "Error звук оновлено", "success")
    end
end)

makeLabel(pSet, "Info Sound ID:", Color3.fromRGB(120,160,220))
makeTextBox(pSet, Settings.SoundInfo, "rbxassetid://...", function(text)
    if text and text ~= "" then
        Settings.SoundInfo = text
        Notify("Settings", "Info звук оновлено", "success")
    end
end)

makeLabel(pSet, "Warn Sound ID:", Color3.fromRGB(220,200,120))
makeTextBox(pSet, Settings.SoundWarn, "rbxassetid://...", function(text)
    if text and text ~= "" then
        Settings.SoundWarn = text
        Notify("Settings", "Warn звук оновлено", "success")
    end
end)

makeLabel(pSet, "— Тестування —")
makeButton(pSet, "Тест: Success", function() Notify("Тест", "Це успіх!", "success") end)
makeButton(pSet, "Тест: Error", function() Notify("Тест", "Це помилка!", "error") end)
makeButton(pSet, "Тест: Warn", function() Notify("Тест", "Це попередження!", "warn") end)
makeButton(pSet, "Тест: Info", function() Notify("Тест", "Це інформація", "info") end)

makeLabel(pSet, "— Скидання —")
makeButton(pSet, "Скинути налаштування", function()
    Settings.NotifSound = true
    Settings.NotifVolume = 0.5
    Settings.NotifDuration = 4
    Settings.SoundSuccess = "rbxassetid://4590662766"
    Settings.SoundError   = "rbxassetid://5159527953"
    Settings.SoundInfo    = "rbxassetid://4590662766"
    Settings.SoundWarn    = "rbxassetid://5159527953"
    Notify("Settings", "Налаштування скинуто. Перезапусти скрипт.", "warn")
end, Color3.fromRGB(80, 40, 40))

-- ============================================================
-- ДЕФОЛТНА СТОРІНКА
-- ============================================================
for n, p in pairs(pages) do
    p.page.Visible = (n == "Other")
    p.btn.BackgroundColor3 = (n == "Other") and Color3.fromRGB(120,80,200) or (p.isSettings and Color3.fromRGB(60,40,90) or Color3.fromRGB(30,32,45))
end

-- Сворачивание
local opened = true
closeBtn.MouseButton1Click:Connect(function()
    opened = not opened
    if opened then
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size=UDim2.new(0,620,0,500)}):Play()
        sidebar.Visible = true content.Visible = true
        closeBtn.Text = "—"
    else
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size=UDim2.new(0,620,0,36)}):Play()
        sidebar.Visible = false content.Visible = false
        closeBtn.Text = "+"
    end
end)

Notify("ROCKET HUB v3", "Завантажено! Плейсів: 10 + Settings", "success")
print("[ROCKET HUB v3] Loaded — Doors, Brookhaven, Killstreak, Arsenal, RIVALS, MM2, Build A Boat, Grace, Blox Fruits, Other, Settings")
