--[[
    ═══════════════════════════════════════════════════════════════
    SHITSAKEN - v10.0.7 (Rayfield Port + Shift Fix + Usage Guide + Duration)
    ═══════════════════════════════════════════════════════════════
    INCLUDED:
    #1 GetTargetMode → 4th button toggle đúng mode (không flip Default)
    #2 ab_requestState global → không silent error
    #3 Shift to Stop Aimbot (Heartbeat poll - chắc chắn hoạt động)
    #4 Usage Guide trong tab Aimbot (có mô tả Shift)
    #5 One Shot Button toggle aimbot
    #6 Disable Auto Block on invalid char
    #7 Duration → thời gian hiện hộp đỏ (M1 miss) + cửa sổ dò rectangle
    ═══════════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("[shitsaken] Loading v10.0.7 + Duration (Rayfield)...")
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════
local Settings = {
    AntiBlindness=false, AntiGlitch=false, AntiSubspaced=false, AntiNoliLaugh=false,
    MinionESP=false, ProjectileESP=false, AzureTrapESP=false,
    AutoBlock=false, AutoBlockButton=false, ABMode="Guest1337", AimPunch=false,
    FOVValue=120, LowGraphics=false, MaxZoom=false, FPSPing=false,
    NoclipCam=false, ForceChat=false, Disable007n7=false, ShowPrivacy=false,
    AutoBlockCustom=false, CustomABMode="Guest1337",
    CustomDiamondLength=8, CustomDiamondWidth=4, CustomDiamondOffset=3,
    CustomCircleRadius=5, ShowDiamond=false, ShowCircle=false, ZoneHeight=0.5,
    AutoBlockRectangle=false, RectangleABMode="Guest1337",
    RectangleDistance=3, RectangleMultiplier=1, RectangleTransparency=0.85, RectangleEdgeTransparency=0.2,
    Duration=0.25,
    RectangleEdgeColor="175,150,220", RectangleSuccessColor="120,255,120", RectangleColorSync=false,
    FakeName=false,
    HDTEnabled=false, HDTSpeed=40, HDTDelay=0.05, HDTDuration=0.6,
    AimbotEnabled=false, AimbotCharLock=true, AimbotCamLock=false,
    AimbotShiftStop=true, AimbotOneShotButton=false,
    AimbotDelay=0.3, AimbotMinDistance=15, AimbotLockDuration=0.8, AimbotPrediction=4,
    DisableAutoBlockOnInvalidChar=false,
}

local function GetRectEdgeColor()
    local s = Settings.RectangleEdgeColor or "175,150,220"
    local r, g, b = string.match(tostring(s), "(%d+),(%d+),(%d+)")
    return Color3.fromRGB(tonumber(r) or 175, tonumber(g) or 150, tonumber(b) or 220)
end
local function GetRectSuccessColor()
    if Settings.RectangleColorSync then return GetRectEdgeColor() end
    local s = Settings.RectangleSuccessColor or "120,255,120"
    local r, g, b = string.match(tostring(s), "(%d+),(%d+),(%d+)")
    return Color3.fromRGB(tonumber(r) or 120, tonumber(g) or 255, tonumber(b) or 120)
end

local Toggles, Sliders, Dropdowns = {}, {}, {}
local Inputs = {}
local PlayerDropdown = nil
local _suppressToggleCallback = false
local zoneStateMemory = { diamond=false, circle=false }

local function ExtractDropdownValue(v)
    if type(v) == "table" then
        return v[1] or v.Value or v.Option
    end
    return v
end

-- ═══════════════════════════════════════════════════════════════
-- KILLER STATE
-- ═══════════════════════════════════════════════════════════════
local KillerState = { isKiller = false }

local function IsLocalPlayerKiller()
    local char = LocalPlayer.Character
    if not char then return false end
    local p = Workspace:FindFirstChild("Players")
    local k = p and p:FindFirstChild("Killers")
    if not k then return false end
    local a = char
    while a do
        if a == k then return true end
        a = a.Parent
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════
local CONFIG_FOLDER = "TestHub"
local CONFIG_NAME = "default"
local function GetConfigPath() return CONFIG_FOLDER.."/"..CONFIG_NAME..".json" end

local function SaveConfig()
    if not (writefile and isfolder and makefolder) then
        warn("[shitsaken] File IO not available"); return false
    end
    pcall(function() if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end end)

    Settings.AutoBlockButton = Settings.AutoBlockButton or false
    Settings.ABMode = Settings.ABMode or "Guest1337"
    Settings.CustomABMode = Settings.CustomABMode or "Guest1337"
    Settings.RectangleABMode = Settings.RectangleABMode or "Guest1337"
    Settings.AutoBlock = Settings.AutoBlock or false
    Settings.AutoBlockCustom = Settings.AutoBlockCustom or false
    Settings.AutoBlockRectangle = Settings.AutoBlockRectangle or false
    Settings.Duration = Settings.Duration or 0.25
    Settings.HDTEnabled = Settings.HDTEnabled or false
    Settings.HDTSpeed = Settings.HDTSpeed or 40
    Settings.HDTDelay = Settings.HDTDelay or 0.05
    Settings.HDTDuration = Settings.HDTDuration or 0.6
    Settings.AimbotEnabled = Settings.AimbotEnabled or false
    if Settings.AimbotCharLock == nil then Settings.AimbotCharLock = true end
    Settings.AimbotCamLock = Settings.AimbotCamLock or false
    if Settings.AimbotShiftStop == nil then Settings.AimbotShiftStop = true end
    Settings.AimbotOneShotButton = Settings.AimbotOneShotButton or false
    Settings.AimbotDelay = Settings.AimbotDelay or 0.3
    Settings.AimbotMinDistance = Settings.AimbotMinDistance or 15
    Settings.AimbotLockDuration = Settings.AimbotLockDuration or 0.8
    Settings.AimbotPrediction = Settings.AimbotPrediction or 4
    Settings.DisableAutoBlockOnInvalidChar = Settings.DisableAutoBlockOnInvalidChar or false

    local ok, encoded = pcall(function() return HttpService:JSONEncode(Settings) end)
    if not ok then warn("[shitsaken] JSONEncode error:", encoded); return false end
    local written = pcall(function() writefile(GetConfigPath(), encoded) end)
    if not written then warn("[shitsaken] writefile error"); return false end
    print("[shitsaken] Saved | ABBtn="..tostring(Settings.AutoBlockButton).." | ABMode="..tostring(Settings.ABMode).." | Duration="..tostring(Settings.Duration))
    return true
end

local function ReadConfigFile()
    if not (isfile and readfile and isfile(GetConfigPath())) then return nil end
    local ok, d = pcall(function() return HttpService:JSONDecode(readfile(GetConfigPath())) end)
    if ok and type(d) == "table" then return d end
    return nil
end
local function DeleteConfigFile()
    if not (isfile and delfile) then return false end
    if isfile(GetConfigPath()) then pcall(function() delfile(GetConfigPath()) end); return true end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI BLINDNESS / GLITCH / SUBSPACED / NOLI
-- ═══════════════════════════════════════════════════════════════
local AntiBlindness = { running=false, conn=nil }
local function StartAntiBlindness()
    if AntiBlindness.running then return end
    AntiBlindness.running = true
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BlurEffect") then pcall(function() obj:Destroy() end) end
    end
    AntiBlindness.conn = Lighting.ChildAdded:Connect(function(obj)
        if AntiBlindness.running and obj:IsA("BlurEffect") then pcall(function() obj:Destroy() end) end
    end)
end
local function StopAntiBlindness()
    AntiBlindness.running = false
    if AntiBlindness.conn then AntiBlindness.conn:Disconnect(); AntiBlindness.conn = nil end
end

local AntiGlitch = { running=false, connections={} }
local function StartAntiGlitch()
    if AntiGlitch.running then return end
    AntiGlitch.running = true
    local TARGETS = { Glitched=true, Hallucination=true }
    local function isTarget(obj)
        if not obj or not TARGETS[obj.Name] then return false end
        local m = PlayerGui:FindFirstChild("MainUI")
        local tu = PlayerGui:FindFirstChild("TemporaryUI")
        if m then local sc = m:FindFirstChild("StatusContainer"); if sc and obj:IsDescendantOf(sc) then return true end end
        if tu and obj:IsDescendantOf(tu) then return true end
        return false
    end
    local function process(obj)
        if not obj or not obj.Parent then return end
        if isTarget(obj) then pcall(function() obj:Destroy() end)
        elseif obj:IsA("Frame") then
            local tu = PlayerGui:FindFirstChild("TemporaryUI")
            if tu then local f = tu:FindFirstChild("Frame"); if f and obj:IsDescendantOf(f) then pcall(function() obj:Destroy() end) end end
        end
    end
    local function watch(root)
        if not root then return end
        table.insert(AntiGlitch.connections, root.DescendantAdded:Connect(process))
        for _, o in ipairs(root:GetDescendants()) do process(o) end
    end
    watch(PlayerGui)
end
local function StopAntiGlitch()
    AntiGlitch.running = false
    for _, c in ipairs(AntiGlitch.connections) do pcall(function() c:Disconnect() end) end
    AntiGlitch.connections = {}
end

local AntiSubspaced = { running=false, connections={} }
local function StartAntiSubspaced()
    if AntiSubspaced.running then return end
    AntiSubspaced.running = true
    local LT = { SubspaceVFXBlur=true, SubspaceVFXColorCorrection=true, HealthDesaturation=true }
    local UT = { Subspaced=true }
    local function process(obj)
        if not obj or not obj.Parent then return end
        if LT[obj.Name] and obj:IsDescendantOf(Lighting) then pcall(function() obj:Destroy() end) end
        if UT[obj.Name] then
            local m = PlayerGui:FindFirstChild("MainUI")
            local tu = PlayerGui:FindFirstChild("TemporaryUI")
            if m then local sc = m:FindFirstChild("StatusContainer"); if sc and obj:IsDescendantOf(sc) then pcall(function() obj:Destroy() end) return end end
            if tu and obj:IsDescendantOf(tu) then pcall(function() obj:Destroy() end) end
        end
    end
    local function watch(root)
        if not root then return end
        table.insert(AntiSubspaced.connections, root.DescendantAdded:Connect(process))
        for _, o in ipairs(root:GetDescendants()) do process(o) end
    end
    watch(Lighting); watch(PlayerGui)
end
local function StopAntiSubspaced()
    AntiSubspaced.running = false
    for _, c in ipairs(AntiSubspaced.connections) do pcall(function() c:Disconnect() end) end
    AntiSubspaced.connections = {}
end

local AntiNoliLaugh = { running=false, connections={} }
local function StartAntiNoliLaugh()
    if AntiNoliLaugh.running then return end
    AntiNoliLaugh.running = true
    local function process(obj)
        if not obj or not obj.Parent then return end
        if obj.Name == "noliLaugh" then
            local cam = Workspace.CurrentCamera
            if cam and (obj:IsDescendantOf(cam) or obj:IsDescendantOf(Workspace)) then pcall(function() obj:Destroy() end) end
        end
    end
    local function watch(root)
        if not root then return end
        table.insert(AntiNoliLaugh.connections, root.DescendantAdded:Connect(process))
        for _, o in ipairs(root:GetDescendants()) do process(o) end
    end
    watch(Workspace.CurrentCamera)
    table.insert(AntiNoliLaugh.connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() watch(Workspace.CurrentCamera) end))
    local wc = Workspace:FindFirstChild("Camera"); if wc then watch(wc) end
    table.insert(AntiNoliLaugh.connections, Workspace.ChildAdded:Connect(function(o) if o.Name == "Camera" then watch(o) end end))
end
local function StopAntiNoliLaugh()
    AntiNoliLaugh.running = false
    for _, c in ipairs(AntiNoliLaugh.connections) do pcall(function() c:Disconnect() end) end
    AntiNoliLaugh.connections = {}
end

-- ═══════════════════════════════════════════════════════════════
-- MINION ESP
-- ═══════════════════════════════════════════════════════════════
local MinionESP = { running=false, connections={}, folder=nil }
local playerCharacters = setmetatable({}, {__mode="k"})
local playerCharSet = {}
local function registerPlayer(player)
    if player.Character then playerCharacters[player.Character] = player; playerCharSet[player.Character] = player end
    player.CharacterAdded:Connect(function(char)
        playerCharacters[char] = player; playerCharSet[char] = player
        task.wait(0.1)
        if MinionESP.folder then local it = MinionESP.folder:FindFirstChild(char:GetDebugId()); if it then it:Destroy() end end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do registerPlayer(p) end
Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(function(p) if p.Character then playerCharacters[p.Character] = nil; playerCharSet[p.Character] = nil end end)

local MINION_SKINS = {"primordial","betrayed","classic","crew leader","evil green skeleton","soccer legend","green guest","toy","16th night","pride","green envy","darkness","infernum","monochrome","illumina","bluesteel","everfrost","fleskhjerta","voidbound","timeless","toon","xx4ce0fspadesxx","ace","milestone zero","milestone i","milestone ii","milestone iii","milestone iv","milestone","guardian","hacklord","erlking","crazyblox","martyr","eye of the abyss","savior","scarletkidd","guide shedletsky","shedletsky","jack frost","eggs","champion","big 1x1x1x1","big 1x1"}

local function StartMinionESP()
    if MinionESP.running then return end
    MinionESP.running = true
    local folder = Instance.new("Folder"); folder.Name = "MinionESP_Highlights"; folder.Parent = CoreGui; MinionESP.folder = folder
    local BLOCKLIST = {"killer","kidd","1x1x1x1","c00lkidd","c00lkid","jane","doe","jane_doe","janedoe","lobby","ambient","decor","prop","dummy","statue","mannequin","display","preview","shop","corpse","dead","ragdoll","body","bone","npc","character"}
    local LOBBY_FOLDERS = {"lobby","menu","npc","ambient","decor","characters","preview","display","shop","spawn_area"}
    local MINION_FOLDERS = {"minion","enem","summon","spawned","mob","rotten"}
    local function nameHas(n, kws) local l = string.lower(n); for _, kw in ipairs(kws) do if string.find(l, kw, 1, true) then return true end end; return false end
    local function isSkinName(name) local l = string.lower(name); for _, s in ipairs(MINION_SKINS) do if l == s or string.find(l, s, 1, true) then return true end end; return false end
    local function inSkinAncestor(o) local c,d=o,0; while c and d<5 do if isSkinName(c.Name) then return true end; c,d=c.Parent,d+1 end; return false end
    local function inBlock(o) local c,d=o,0; while c and d<5 do if nameHas(c.Name,BLOCKLIST) then return true end; c,d=c.Parent,d+1 end; return false end
    local function inLobby(o) local c,d=o.Parent,0; while c and d<5 do if nameHas(c.Name,LOBBY_FOLDERS) then return true end; c,d=c.Parent,d+1 end; return false end
    local function inMinionF(o) local c,d=o.Parent,0; while c and d<5 do if nameHas(c.Name,MINION_FOLDERS) then return true end; c,d=c.Parent,d+1 end; return false end
    local function isRealPlayer(o)
        if playerCharacters[o] or playerCharSet[o] then return true end
        local ok, plr = pcall(function() return Players:GetPlayerFromCharacter(o) end)
        if ok and plr then return true end
        for char in pairs(playerCharSet) do
            if char and char.Parent then
                if o == char then return true end
                local ok2, isD = pcall(function() return o:IsDescendantOf(char) end)
                if ok2 and isD then return true end
            else playerCharSet[char] = nil end
        end
        local c, d = o, 0
        while c and d < 10 do if c:IsA("Player") then return true end; c, d = c.Parent, d+1 end
        return false
    end
    local function isMinion(o)
        if not o:IsA("Model") then return false end
        if isRealPlayer(o) then return false end
        local is1x = inSkinAncestor(o)
        if not is1x and inBlock(o) then return false end
        if inLobby(o) then return false end
        local inMinF = inMinionF(o)
        local hum = o:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return false end
        local root = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Torso") or o:FindFirstChild("UpperTorso") or o:FindFirstChild("Head")
        if not root then return false end
        local a, t = 0, 0
        for _, p in ipairs(o:GetChildren()) do if p:IsA("BasePart") then t = t+1; if p.Anchored then a = a+1 end end end
        if t > 0 and a == t then return false end
        if not inMinF and not is1x and root.Anchored then return false end
        return true
    end
    local function applyHL(model)
        if not model or not model:IsA("Model") or isRealPlayer(model) then return end
        local id = model:GetDebugId()
        if folder:FindFirstChild(id) then return end
        local h = Instance.new("Highlight")
        h.Name = id; h.Adornee = model
        h.FillTransparency = 0.5; h.FillColor = Color3.fromRGB(255,255,0)
        h.OutlineColor = Color3.fromRGB(255,255,0); h.OutlineTransparency = 0
        h.Parent = folder
        model.Destroying:Connect(function() if h then h:Destroy() end end)
        task.delay(0.3, function() if h and h.Parent and isRealPlayer(model) then h:Destroy() end end)
    end
    local function check(o) if MinionESP.running and isMinion(o) then applyHL(o) end end
    for _, o in ipairs(Workspace:GetDescendants()) do check(o) end
    table.insert(MinionESP.connections, Workspace.DescendantAdded:Connect(function(o) task.wait(0.1); check(o) end))
end
local function StopMinionESP()
    MinionESP.running = false
    for _, c in ipairs(MinionESP.connections) do pcall(function() c:Disconnect() end) end
    MinionESP.connections = {}
    if MinionESP.folder then pcall(function() MinionESP.folder:Destroy() end); MinionESP.folder = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- PROJECTILE ESP
-- ═══════════════════════════════════════════════════════════════
local ProjectileESP = { running=false, connections={}, folder=nil }
local function StartProjectileESP()
    if ProjectileESP.running then return end
    ProjectileESP.running = true
    local folder = Instance.new("Folder"); folder.Name = "ProjectileESP_Highlights"; folder.Parent = Workspace; ProjectileESP.folder = folder
    local COLOR = Color3.fromRGB(255,50,50)
    local ORIGINAL = { HumanoidRootProjectile=true }
    local LOBBY_KWS = {"lobby","spawn","menu","waitingroom","decor","ambient"}
    local tracked, hls = setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"})
    local function isPlayerChar(o)
        for _, p in ipairs(Players:GetPlayers()) do local ch = p.Character; if ch and o:IsDescendantOf(ch) then return true end end
        local m = o:FindFirstAncestorOfClass("Model"); if m and m:FindFirstChildOfClass("Humanoid") then return true end; return false
    end
    local function isInLobby(o)
        local c = o.Parent
        while c and c ~= Workspace do local n = c.Name:lower(); for _, kw in ipairs(LOBBY_KWS) do if n:find(kw) then return true end end; c = c.Parent end
        return false
    end
    local function applyHL(part)
        if not ProjectileESP.running or not part or not part.Parent or tracked[part] then return end
        local hl = Instance.new("Highlight")
        hl.Name = "ProjESPHL"; hl.Adornee = part
        hl.FillColor = COLOR; hl.FillTransparency = 0.35
        hl.OutlineColor = Color3.fromRGB(255,255,255); hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = folder
        tracked[part] = true; hls[part] = hl
        part.AncestryChanged:Connect(function(_, parent) if not parent then tracked[part]=nil; if hl and hl.Parent then hl:Destroy() end; hls[part]=nil end end)
    end
    local function eval(o)
        if not ProjectileESP.running or not o or not o.Parent or isPlayerChar(o) or isInLobby(o) then return end
        if ORIGINAL[o.Name] and o:IsA("BasePart") then local fn = o:GetFullName(); if fn:find("Map.Ingame",1,true) then applyHL(o) end end
    end
    table.insert(ProjectileESP.connections, Workspace.DescendantAdded:Connect(function(o)
        if not ProjectileESP.running then return end
        if o:IsA("BasePart") or o:IsA("Model") then eval(o) end
    end))
    task.spawn(function()
        local cnt = 0
        for _, o in ipairs(Workspace:GetDescendants()) do
            if not ProjectileESP.running then break end
            if o:IsA("BasePart") or o:IsA("Model") then eval(o); cnt=cnt+1; if cnt%250==0 then task.wait() end end
        end
    end)
end
local function StopProjectileESP()
    ProjectileESP.running = false
    for _, c in ipairs(ProjectileESP.connections) do pcall(function() c:Disconnect() end) end
    ProjectileESP.connections = {}
    if ProjectileESP.folder then pcall(function() ProjectileESP.folder:Destroy() end); ProjectileESP.folder = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- AZURE TRAP ESP
-- ═══════════════════════════════════════════════════════════════
local AzureTrapESP = { running=false, connections={}, folder=nil }
local function StartAzureTrapESP()
    if AzureTrapESP.running then return end
    AzureTrapESP.running = true
    local folder = Instance.new("Folder"); folder.Name = "AzureTrapESP_Folder"; folder.Parent = Workspace; AzureTrapESP.folder = folder
    local COLOR = Color3.fromRGB(160,32,240)
    local MAX, RETRY, LOOP = 6, 5, 0.3
    local AZURE = {["Flower_Base"]=true,["Flower_Bottom"]=true,["Flower_Root"]=true,["Flower_Tentacle"]=true,["Flower_Top"]=true,["Nectar"]=true,["Root1"]=true,["Root2"]=true,["Root3"]=true,["Root4"]=true,["Tendril_Middle"]=true,["Tentacle"]=true,["Tentacle42.001"]=true,["Tentacle_Base"]=true,["GroundBulb"]=true,["Vine"]=true}
    local LOBBY = {"lobby","spawn","menu","waitingroom","decor","ambient"}
    local hl, tr, rec = {}, {}, {}
    local cnt, blk, counted = {}, {}, {}
    local function isPlayerChar(o) for _, p in ipairs(Players:GetPlayers()) do local ch = p.Character; if ch and o:IsDescendantOf(ch) then return true end end; local m = o:FindFirstAncestorOfClass("Model"); return m and m:FindFirstChildOfClass("Humanoid") end
    local function isInLobby(o) local c = o.Parent; while c and c ~= Workspace do local n = c.Name:lower(); for _, kw in ipairs(LOBBY) do if n:find(kw) then return true end end; c = c.Parent end; return false end
    local function isAzure(p) return AZURE[p.Name] and not blk[p.Name] end
    local function clear(n) for p, h in pairs(hl) do if p.Name == n then if h and h.Parent then h:Destroy() end; hl[p]=nil; tr[p]=nil end end end
    local function inc(p) if counted[p] or not AZURE[p.Name] then return end; counted[p]=true; cnt[p.Name]=(cnt[p.Name] or 0)+1; if cnt[p.Name] > MAX and not blk[p.Name] then blk[p.Name]=true; clear(p.Name) end end
    local function dec(p) if not counted[p] then return end; counted[p]=nil; local n = p.Name; if not cnt[n] then return end; cnt[n]=math.max(0,cnt[n]-1); if cnt[n] <= MAX and blk[n] then blk[n]=nil end end
    local function cleanup(p) dec(p); tr[p]=nil; rec[p]=nil; if hl[p] then if hl[p].Parent then hl[p]:Destroy() end; hl[p]=nil end end
    local function create(p)
        if tr[p] then return end
        if hl[p] then tr[p]=true; return end
        local h = Instance.new("Highlight")
        h.Name="AzureTrapHL"; h.Adornee=p
        h.FillColor=COLOR; h.FillTransparency=0.75; h.OutlineColor=COLOR; h.OutlineTransparency=0
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=folder; hl[p]=h; tr[p]=true
    end
    local function handle(p)
        if not AzureTrapESP.running or not p:IsA("BasePart") then return end
        if tr[p] or isPlayerChar(p) or isInLobby(p) then return end
        if not isAzure(p) then return end
        if not p:GetAttribute("AzureESP_Hooked") then
            p:SetAttribute("AzureESP_Hooked", true)
            p.AncestryChanged:Connect(function(_, parent) if not parent then cleanup(p) end end)
        end
        create(p)
    end
    for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") and AZURE[o.Name] then counted[o]=true; cnt[o.Name]=(cnt[o.Name] or 0)+1 end end
    for n, c in pairs(cnt) do if c > MAX then blk[n]=true end end
    for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then handle(o) end end
    table.insert(AzureTrapESP.connections, Workspace.DescendantAdded:Connect(function(o) if not o:IsA("BasePart") then return end; inc(o); rec[o]=tick(); handle(o) end))
    task.spawn(function() while AzureTrapESP.running do task.wait(LOOP); local now = tick(); for p, t in pairs(rec) do if not p.Parent then rec[p]=nil elseif now - t > RETRY then rec[p]=nil elseif not tr[p] then handle(p) end end end end)
end
local function StopAzureTrapESP()
    AzureTrapESP.running = false
    for _, c in ipairs(AzureTrapESP.connections) do pcall(function() c:Disconnect() end) end
    AzureTrapESP.connections = {}
    if AzureTrapESP.folder then pcall(function() AzureTrapESP.folder:Destroy() end); AzureTrapESP.folder = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- FORCE CHAT / DISABLE 007n7 / SHOW PRIVACY / FAKE NAME
-- ═══════════════════════════════════════════════════════════════
local ForceChat = { running=false }
local function StartForceChat()
    if ForceChat.running then return end
    ForceChat.running = true
    task.spawn(function()
        while ForceChat.running do
            task.wait(0.5)
            pcall(function() local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration"); if cw then cw.Enabled = true end end)
        end
    end)
end
local function StopForceChat() ForceChat.running = false end

local Disable007n7 = { running=false, moved={} }
local function StartDisable007n7()
    if Disable007n7.running then return end
    Disable007n7.running = true; Disable007n7.moved = {}
    task.spawn(function()
        while Disable007n7.running do
            task.wait(0.5)
            local ingame = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
            if ingame then for _, v in ipairs(ingame:GetChildren()) do if v.Name:lower() == "007n7" and not Players:GetPlayerFromCharacter(v) then local orig = v.Parent; if pcall(function() v.Parent = Lighting end) then Disable007n7.moved[v] = orig end end end end
        end
    end)
end
local function StopDisable007n7()
    Disable007n7.running = false
    for obj, parent in pairs(Disable007n7.moved) do if obj and obj.Parent == Lighting and parent and parent.Parent then pcall(function() obj.Parent = parent end) end end
    table.clear(Disable007n7.moved)
end

local ShowPrivacy = { running=false }
local function StartShowPrivacy()
    if ShowPrivacy.running then return end
    ShowPrivacy.running = true
    task.spawn(function()
        while ShowPrivacy.running do
            task.wait(0.5)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local data = p:FindFirstChild("PlayerData")
                    local privacy = data and data:FindFirstChild("Privacy", true)
                    if privacy then for _, setting in ipairs(privacy:GetChildren()) do if setting:IsA("BoolValue") then pcall(function() setting.Value = false end) end end end
                end
            end
        end
    end)
end
local function StopShowPrivacy() ShowPrivacy.running = false end

local FakeNameState = { running=false, connections={} }
local function StartFakeName()
    if FakeNameState.running then return end
    FakeNameState.running = true; FakeNameState.connections = {}
    local CONFIG = { FakeName="PROTECTED", FakeDisplay="PROTECTED" }
    local RealName = LocalPlayer.Name; local RealDisplay = LocalPlayer.DisplayName
    local function SpoofText(obj)
        if not obj or not obj.Parent then return end
        local ok, txt = pcall(function() return obj.Text end); if not ok or type(txt) ~= "string" then return end
        if not txt:find(RealName, 1, true) and not txt:find(RealDisplay, 1, true) then return end
        local newText = txt:gsub(RealName, CONFIG.FakeName); newText = newText:gsub(RealDisplay, CONFIG.FakeDisplay)
        if newText ~= txt then pcall(function() obj.Text = newText end) end
    end
    local function MonitorObject(obj)
        if not obj then return end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            SpoofText(obj)
            table.insert(FakeNameState.connections, obj:GetPropertyChangedSignal("Text"):Connect(function() if FakeNameState.running then SpoofText(obj) end end))
        end
    end
    for _, v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do MonitorObject(v) end
    table.insert(FakeNameState.connections, LocalPlayer.PlayerGui.DescendantAdded:Connect(function(o) if FakeNameState.running then MonitorObject(o) end end))
    pcall(function()
        local CG = game:GetService("CoreGui")
        for _, v in ipairs(CG:GetDescendants()) do MonitorObject(v) end
        table.insert(FakeNameState.connections, CG.DescendantAdded:Connect(function(o) if FakeNameState.running then MonitorObject(o) end end))
    end)
    local function MonitorCharacter(char)
        if not char then return end
        local humanoid = char:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.DisplayName = CONFIG.FakeDisplay
            table.insert(FakeNameState.connections, humanoid:GetPropertyChangedSignal("DisplayName"):Connect(function()
                if FakeNameState.running and humanoid.DisplayName ~= CONFIG.FakeDisplay then humanoid.DisplayName = CONFIG.FakeDisplay end
            end))
        end
    end
    if LocalPlayer.Character then MonitorCharacter(LocalPlayer.Character) end
    table.insert(FakeNameState.connections, LocalPlayer.CharacterAdded:Connect(function(c) if FakeNameState.running then MonitorCharacter(c) end end))
end
local function StopFakeName()
    if not FakeNameState.running then return end
    FakeNameState.running = false
    for _, c in ipairs(FakeNameState.connections) do pcall(function() c:Disconnect() end) end
    FakeNameState.connections = {}
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO BLOCK CORE
-- ═══════════════════════════════════════════════════════════════
local AB = {
    running=false, connections={}, attrStates={}, attrDebounce=0,
    punchDebounce=0, generation=0,
    RemoteEvent=nil, KillersFolder=nil, LocalRoot=nil,
}
local StartAutoBlock, StopAutoBlock
local StartFourthButton, StopFourthButton
local FourthBlock = {
    instance=nil, applyTint=nil, running=false, connections={},
    cachedPos=nil, cachedSize=nil, sourceName=nil,
}

local abLastToggle = 0
local abPendingState = nil
local abPendingTask = nil
local abDebounce = 0.08

do
    local rs = ReplicatedStorage
    local modules = rs:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Network", true)
    local net2 = net and net:FindFirstChild("Network", true)
    AB.RemoteEvent = net2 and net2:FindFirstChild("RemoteEvent")
    if not AB.RemoteEvent then AB.RemoteEvent = rs:FindFirstChild("RemoteEvent", true) end
end

local function GetPing()
    local ping = 0.05
    pcall(function()
        local ns = Stats:FindFirstChild("Network")
        local ssi = ns and ns:FindFirstChild("ServerStatsItem")
        local dp = ssi and ssi:FindFirstChild("Data Ping")
        if dp then ping = dp:GetValue() / 1000 end
    end)
    return math.clamp(ping, 0.05, 0.35)
end

local BlockSounds = {
    ["rbxassetid://132298811847315"]=true,["rbxassetid://81114852524420"]=true,
    ["rbxassetid://123825742002486"]=true,["rbxassetid://116616310968045"]=true,
    ["rbxassetid://102808968188291"]=true,["rbxassetid://117828699507982"]=true,
    ["rbxassetid://125854302746190"]=true,["rbxassetid://18568553101"]=true,
    ["rbxassetid://95135835034592"]=true,["rbxassetid://135209101640984"]=true,
    ["rbxassetid://91165993312513"]=true,["rbxassetid://82772022662025"]=true,
}
local function isBlockSnd(sid)
    if not sid or sid == "" then return false end
    if BlockSounds[sid] then return true end
    local n = sid:match("rbxassetid://(%d+)") or sid:match("^(%d+)$")
    return n and BlockSounds["rbxassetid://"..n] or false
end

local function FireAbility(name)
    if AB.RemoteEvent then pcall(function() AB.RemoteEvent:FireServer("UseActorAbility", {name}) end) end
end
local function FireBlock() FireAbility("Block") end
local function FireClone() FireAbility("Clone") end

local function GetActiveMode()
    if Settings.AutoBlockRectangle then return "rectangle" end
    if Settings.AutoBlockCustom then return "custom" end
    return "default"
end

local LastActiveMode = "default"
local function GetTargetMode()
    if Settings.AutoBlockRectangle then LastActiveMode = "rectangle"; return "rectangle" end
    if Settings.AutoBlockCustom then LastActiveMode = "custom"; return "custom" end
    if Settings.AutoBlock then LastActiveMode = "default"; return "default" end
    return LastActiveMode or "default"
end

local function FireAbilityByMode()
    local mode = GetActiveMode()
    if mode == "rectangle" then
        if Settings.RectangleABMode == "007n7" then FireClone() else FireBlock() end
    elseif mode == "custom" then
        if Settings.CustomABMode == "007n7" then FireClone() else FireBlock() end
    else
        if Settings.ABMode == "007n7" then FireClone() else FireBlock() end
    end
end

local function GetNearestKiller()
    local folder = AB.KillersFolder
    if not folder or not folder.Parent then
        local p = Workspace:FindFirstChild("Players")
        folder = p and p:FindFirstChild("Killers")
    end
    local localRoot = AB.LocalRoot
    if not localRoot or not localRoot.Parent then
        local char = LocalPlayer.Character
        localRoot = char and char:FindFirstChild("HumanoidRootPart")
    end
    if not folder or not localRoot then return nil, nil end
    local nearest, model, minD = nil, nil, 30
    for _, k in pairs(folder:GetChildren()) do
        local kr = k:FindFirstChild("HumanoidRootPart")
        if kr then
            local d = (localRoot.Position - kr.Position).Magnitude
            if d < minD then minD = d; nearest = kr; model = k end
        end
    end
    return nearest, model
end

local function AimPunch()
    local kr, km = GetNearestKiller()
    if not (kr and AB.LocalRoot and km) then return end
    local kh = km:FindFirstChildOfClass("Humanoid")
    local start = tick(); local lastPos = kr.Position
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not AB.running or tick() - start > 0.6 or not AB.LocalRoot or not kr then conn:Disconnect(); return end
        local cur = AB.LocalRoot.Position; local tgt = kr.Position
        local vel = (tgt - lastPos) / math.max(dt, 0.001); lastPos = tgt
        local mdir = kh and kh.MoveDirection or Vector3.new()
        local ws = kh and kh.WalkSpeed or 16
        local lead = 0.24 + GetPing()
        local pred = tgt + mdir * ws * lead + Vector3.new(vel.X, 0, vel.Z) * 0.08
        AB.LocalRoot.CFrame = CFrame.lookAt(cur, Vector3.new(pred.X, cur.Y, pred.Z))
    end)
end

local OnBlockSuccess

local function MonitorBlockSuccess(char)
    if not char then return end
    local function check(v) if v:IsA("Sound") and isBlockSnd(v.SoundId) then OnBlockSuccess() end end
    for _, v in pairs(char:GetDescendants()) do check(v) end
    table.insert(AB.connections, char.DescendantAdded:Connect(check))
end

-- ═══════════════════════════════════════════════════════════════
-- HDT - HITBOX DRAG TECH
-- ═══════════════════════════════════════════════════════════════
local HDT = {
    enabled = false, speed = 40, delay = 0.05, duration = 0.6,
    debounce = false, lastDamage = 0,
}
local HDT_MOVE_BIND = "HDT_MoveOverride"
local HDT_BLOCK_ANIM_IDS = { ["72722244508749"]=true, ["96959123077498"]=true, ["95802026624883"]=true, ["140671644163156"]=true, ["100926346851492"]=true }
local HDT_WatcherConn, HDT_charConn, HDT_retryTask, HDT_CurrentAnimator = nil, nil, nil, nil

local function HDT_GetNearestKillerModel()
    local killersFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers")
    if not killersFolder then return nil end
    local char = LocalPlayer.Character; local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, math.huge
    for _, k in ipairs(killersFolder:GetChildren()) do
        if k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Parent then local d = (hrp.Position - myRoot.Position).Magnitude; if d < closestDist then closest, closestDist = k, d end end
        end
    end
    return closest
end

local function HDT_DashToKiller(killerModel)
    if HDT.debounce or not killerModel or not killerModel.Parent then return end
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    local targetHRP = killerModel:FindFirstChild("HumanoidRootPart") or killerModel.PrimaryPart
    if not targetHRP then return end
    local dist = (targetHRP.Position - hrp.Position).Magnitude
    if dist < 2.5 then return end
    HDT.debounce = true
    local oldWalk = humanoid.WalkSpeed; local oldAutoRotate = humanoid.AutoRotate
    humanoid.WalkSpeed = HDT.speed; humanoid.AutoRotate = true
    local startTime = tick()
    pcall(function() RunService:UnbindFromRenderStep(HDT_MOVE_BIND) end)
    RunService:BindToRenderStep(HDT_MOVE_BIND, Enum.RenderPriority.Last.Value + 1, function()
        if not HDT.debounce then pcall(function() RunService:UnbindFromRenderStep(HDT_MOVE_BIND) end); return end
        if not char.Parent or not killerModel.Parent or not humanoid.Parent then HDT.debounce = false; return end
        local t = killerModel:FindFirstChild("HumanoidRootPart"); if not t then HDT.debounce = false; return end
        local flat = Vector3.new(t.Position.X - hrp.Position.X, 0, t.Position.Z - hrp.Position.Z)
        if flat.Magnitude <= 2 then HDT.debounce = false; return end
        humanoid.WalkSpeed = HDT.speed; humanoid:Move(flat.Unit, false)
        if tick() - startTime > HDT.duration then HDT.debounce = false end
    end)
    local hbConn
    hbConn = RunService.Heartbeat:Connect(function() if not HDT.debounce then if hbConn then hbConn:Disconnect() end; return end; if humanoid and humanoid.Parent then humanoid.WalkSpeed = HDT.speed end end)
    task.delay(HDT.duration + 0.2, function() if HDT.debounce then HDT.debounce = false end end)
    task.spawn(function()
        while HDT.debounce do task.wait() end
        pcall(function() RunService:UnbindFromRenderStep(HDT_MOVE_BIND) end)
        if hbConn and hbConn.Connected then hbConn:Disconnect() end
        if humanoid and humanoid.Parent then pcall(function() humanoid:Move(Vector3.new(0,0,0), false); humanoid.WalkSpeed = oldWalk; humanoid.AutoRotate = oldAutoRotate end) end
    end)
end

local function HDT_OnAnimPlayed(track)
    if not HDT.enabled or HDT.debounce or KillerState.isKiller or tick() - HDT.lastDamage < 0.2 then return end
    local id; pcall(function() id = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
    if not id or not HDT_BLOCK_ANIM_IDS[id] then return end
    local nearest = HDT_GetNearestKillerModel(); if not nearest then return end
    if HDT.delay > 0 then task.delay(HDT.delay, function() if HDT.enabled and not HDT.debounce then HDT_DashToKiller(nearest) end end) else HDT_DashToKiller(nearest) end
end

local function HDT_TryAttach()
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator"); if not animator then return end
    if HDT_CurrentAnimator == animator and HDT_WatcherConn then return end
    if HDT_WatcherConn then pcall(function() HDT_WatcherConn:Disconnect() end); HDT_WatcherConn = nil end
    HDT_CurrentAnimator = animator
    HDT_WatcherConn = animator.AnimationPlayed:Connect(HDT_OnAnimPlayed)
end

local function HDT_StartWatcher()
    if not HDT.enabled then return end
    HDT_TryAttach()
    if not HDT_charConn then HDT_charConn = LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); if HDT.enabled then HDT_TryAttach() end end) end
    if not HDT_retryTask then HDT_retryTask = task.spawn(function() while HDT.enabled do if not HDT_WatcherConn then HDT_TryAttach() end; task.wait(1) end; HDT_retryTask = nil end) end
end

local function HDT_StopWatcher()
    HDT.enabled = false
    if HDT_WatcherConn then pcall(function() HDT_WatcherConn:Disconnect() end); HDT_WatcherConn = nil end
    if HDT_charConn then pcall(function() HDT_charConn:Disconnect() end); HDT_charConn = nil end
    if HDT_retryTask then pcall(task.cancel, HDT_retryTask); HDT_retryTask = nil end
    HDT_CurrentAnimator = nil; HDT.debounce = false
    pcall(function() RunService:UnbindFromRenderStep(HDT_MOVE_BIND) end)
end

local function HDT_TrackDamage(char)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local prev = humanoid.Health
        humanoid.HealthChanged:Connect(function(n) if n < prev then HDT.lastDamage = tick() end; prev = n end)
    end
end

if LocalPlayer.Character then HDT_TrackDamage(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(HDT_TrackDamage)

-- ═══════════════════════════════════════════════════════════════
-- AUTO BLOCK BUTTON (v10.0.7 - GetTargetMode)
-- ═══════════════════════════════════════════════════════════════
function StartFourthButton()
    if FourthBlock.running then return end
    FourthBlock.running = true
    FourthBlock.connections = {}
    do
        local m = PlayerGui:FindFirstChild("MainUI")
        if m then
            local c = m:FindFirstChild("AbilityContainer", true)
            if c then
                local old = c:FindFirstChild("FourthBlockAbility")
                if old then pcall(function() old:Destroy() end) end
            end
        end
    end
    if not FourthBlock.applyTint then
        FourthBlock.applyTint = function()
            local b = FourthBlock.instance
            if not b or not b.Parent then return end
            local targetMode = GetTargetMode()
            local active = false
            if targetMode == "rectangle" then active = Settings.AutoBlockRectangle
            elseif targetMode == "custom" then active = Settings.AutoBlockCustom
            else active = Settings.AutoBlock end
            local col = active and Color3.fromRGB(0,255,60) or Color3.fromRGB(255,0,0)
            if b:IsA("ImageButton") or b:IsA("ImageLabel") then b.ImageColor3 = col end
            for _, d in ipairs(b:GetDescendants()) do
                if d:IsA("ImageLabel") or d:IsA("ImageButton") then d.ImageColor3 = col
                elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundColor3 = col end
            end
        end
    end
    local toggleLastTick = 0
    local TOGGLE_COOLDOWN = 0.15
    local function Toggle()
        local now = tick()
        if now - toggleLastTick < TOGGLE_COOLDOWN then return end
        toggleLastTick = now
        local targetMode = GetTargetMode()
        local current = false
        if targetMode == "rectangle" then current = Settings.AutoBlockRectangle
        elseif targetMode == "custom" then current = Settings.AutoBlockCustom
        else current = Settings.AutoBlock end
        print("[shitsaken] 4th Button toggle "..targetMode.." | "..tostring(current).." -> "..tostring(not current))
        ab_requestState(not current, targetMode)
        task.defer(function() if FourthBlock.applyTint then FourthBlock.applyTint() end end)
    end
    table.insert(FourthBlock.connections, RunService.RenderStepped:Connect(function()
        if not FourthBlock.running then return end
        local b = FourthBlock.instance
        if b and b.Parent then
            local ok, p = pcall(function() return b.AbsolutePosition end)
            local ok2, s = pcall(function() return b.AbsoluteSize end)
            if ok and ok2 then FourthBlock.cachedPos = p; FourthBlock.cachedSize = s end
        else FourthBlock.cachedPos = nil; FourthBlock.cachedSize = nil end
    end))
    local function IsActuallyOnButton(pos)
        local btn = FourthBlock.instance
        if not btn or not btn.Parent then return false end
        local ok, objs = pcall(function() return UserInputService:GetGuiObjectsAtPosition(pos.X, pos.Y) end)
        if ok and objs and #objs > 0 then local top = objs[1]; return top == btn or top:IsDescendantOf(btn) end
        if not FourthBlock.cachedPos or not FourthBlock.cachedSize then return false end
        local p, s = FourthBlock.cachedPos, FourthBlock.cachedSize
        return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end
    local downPos, downTime = nil, 0
    table.insert(FourthBlock.connections, UserInputService.InputBegan:Connect(function(input)
        if not FourthBlock.running then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not IsActuallyOnButton(input.Position) then return end
        downPos = input.Position; downTime = tick()
    end))
    table.insert(FourthBlock.connections, UserInputService.InputEnded:Connect(function(input)
        if not FourthBlock.running then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not downPos then return end
        local held = tick() - downTime; downPos = nil
        if held > 0.5 then return end
        if not IsActuallyOnButton(input.Position) then return end
        Toggle()
    end))
    local function BindAll(root)
        if not root then return end
        local function tb(obj)
            if not obj then return end
            if obj:IsA("GuiButton") then
                pcall(function() obj.Active=true; obj.Selectable=true end)
                pcall(function() obj.MouseButton1Click:Connect(Toggle) end)
                pcall(function() obj.Activated:Connect(Toggle) end)
            end
        end
        tb(root)
        for _, d in ipairs(root:GetDescendants()) do if d:IsA("GuiObject") then tb(d) end end
    end
    task.spawn(function()
        while FourthBlock.running do
            task.wait(0.5)
            if not FourthBlock.running then break end
            local m = PlayerGui:FindFirstChild("MainUI")
            if m then
                local c = m:FindFirstChild("AbilityContainer", true)
                if c then
                    local blockBtn = c:FindFirstChild("Block")
                    local cloneBtn = c:FindFirstChild("Clone")
                    local targetMode = GetTargetMode()
                    local orig = nil
                    if targetMode == "rectangle" then orig = (Settings.RectangleABMode == "007n7") and cloneBtn or blockBtn
                    elseif targetMode == "custom" then orig = (Settings.CustomABMode == "007n7") and cloneBtn or blockBtn
                    else orig = (Settings.ABMode == "007n7") and cloneBtn or blockBtn end
                    local e = c:FindFirstChild("FourthBlockAbility")
                    local needsRecreate = false
                    if not e then needsRecreate = (orig ~= nil)
                    elseif not orig then needsRecreate = false
                    elseif FourthBlock.sourceName ~= orig.Name then needsRecreate = true
                    elseif FourthBlock.instance ~= e then
                        FourthBlock.instance = e; BindAll(e)
                        if FourthBlock.applyTint then FourthBlock.applyTint() end
                    end
                    if needsRecreate and orig then
                        if e then pcall(function() e:Destroy() end) end
                        local clone = orig:Clone()
                        clone.Name = "FourthBlockAbility"; clone.LayoutOrder = 4
                        if clone:IsA("GuiObject") then clone.ZIndex = 50 end
                        for _, d in ipairs(clone:GetDescendants()) do
                            if d:IsA("TextLabel") or d:IsA("TextButton") then local t = d.Text:lower(); if t:find("block") or t:find("clone") then d.Text=""; d.Visible=false end end
                            if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, 50); d.Active = true end
                        end
                        clone.Parent = c
                        FourthBlock.instance = clone; FourthBlock.sourceName = orig.Name
                        BindAll(clone)
                        if FourthBlock.applyTint then FourthBlock.applyTint() end
                    end
                end
            end
        end
    end)
end

function StopFourthButton()
    if not FourthBlock.running then return end
    FourthBlock.running = false
    for _, c in ipairs(FourthBlock.connections) do pcall(function() c:Disconnect() end) end
    FourthBlock.connections = {}
    if FourthBlock.instance and FourthBlock.instance.Parent then pcall(function() FourthBlock.instance:Destroy() end) end
    FourthBlock.instance = nil
    FourthBlock.cachedPos = nil; FourthBlock.cachedSize = nil; FourthBlock.sourceName = nil
end

-- ═══════════════════════════════════════════════════════════════
-- DISABLE AUTO BLOCK ON INVALID CHAR LOGIC
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    local disabledByFeature = false
    local savedMode = nil
    while true do
        task.wait(0.5)
        if not Settings.DisableAutoBlockOnInvalidChar then
            if disabledByFeature then
                if savedMode then pcall(ab_requestState, true, savedMode) end
                disabledByFeature = false; savedMode = nil
            end
            continue
        end
        local m = PlayerGui:FindFirstChild("MainUI")
        local c = m and m:FindFirstChild("AbilityContainer", true)
        if c then
            local hasBlock = c:FindFirstChild("Block") ~= nil
            local hasClone = c:FindFirstChild("Clone") ~= nil
            local isValid = hasBlock or hasClone
            if not isValid then
                if not disabledByFeature then
                    local targetMode = GetTargetMode()
                    local isOn = false
                    if targetMode == "rectangle" then isOn = Settings.AutoBlockRectangle
                    elseif targetMode == "custom" then isOn = Settings.AutoBlockCustom
                    else isOn = Settings.AutoBlock end
                    if isOn then
                        savedMode = targetMode
                        pcall(ab_requestState, false, targetMode)
                        disabledByFeature = true
                        print("[shitsaken] Invalid char → Auto Block disabled")
                    end
                end
            else
                if disabledByFeature then
                    if savedMode then pcall(ab_requestState, true, savedMode) end
                    disabledByFeature = false; savedMode = nil
                    print("[shitsaken] Valid char → Auto Block restored")
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ═══ AIMBOT ═══
-- ═══════════════════════════════════════════════════════════════
local Aimbot = {
    enabled = false, charLock = true, camLock = false,
    delay = 0.3, minDistance = 15, lockDuration = 0.8, prediction = 4,
    shiftHeld = false, active = false, lastTrigger = {},
    animator = nil, conn = nil, retryTask = nil, charConn = nil,
}

local AIMBOT_PUNCH_ANIMS = {
    "87259391926321","99100240941590","72685103823181","81905101227053",
    "113936304594883","140703210927645","136007065400978","129843313690921",
    "86709774283672","108807732150251","138040001965654","86096387000557",
    "119850211147676","131696603025265","119462383658044","116618003477002",
    "133491532453922","76649505662612","71190646367497",
}
local AIMBOT_PUNCH_SET = {}
for _, id in ipairs(AIMBOT_PUNCH_ANIMS) do AIMBOT_PUNCH_SET[id] = true end

-- ═══════════════════════════════════════════════════════════════
-- ═══ SHIFT CODE - Shift to Stop Aimbot (Heartbeat poll) ═══
-- ═══════════════════════════════════════════════════════════════
local function ForceStopAimbotLock()
    if Aimbot.active then
        Aimbot.active = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.AutoRotate = true end) end
        return true
    end
    return false
end

RunService.Heartbeat:Connect(function()
    if not Aimbot.enabled then Aimbot.shiftHeld = false; return end
    local shouldBlock = false
    if Settings.AimbotShiftStop then
        shouldBlock = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
    end
    if shouldBlock ~= Aimbot.shiftHeld then
        Aimbot.shiftHeld = shouldBlock
        if shouldBlock then ForceStopAimbotLock() end
    end
    if Aimbot.shiftHeld and Aimbot.active then ForceStopAimbotLock() end
end)
-- ═══ END SHIFT CODE ═══

local function GetNearestKillerModelAimbot()
    local killersFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers")
    if not killersFolder then return nil, math.huge end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, math.huge end
    local closest, closestDist = nil, math.huge
    for _, k in ipairs(killersFolder:GetChildren()) do
        if k:IsA("Model") then
            local kr = k:FindFirstChild("HumanoidRootPart")
            if kr then
                local d = (kr.Position - myRoot.Position).Magnitude
                if d < closestDist then closest, closestDist = k, d end
            end
        end
    end
    return closest, closestDist
end

local function AimLockLoop(killer, myRoot, humanoid)
    local startTime = tick()
    while Aimbot.active do
        if not Aimbot.enabled then break end
        if Aimbot.shiftHeld then break end
        if KillerState.isKiller then break end
        if tick() - startTime > Aimbot.lockDuration then break end
        if not killer or not killer.Parent then break end
        local kr = killer:FindFirstChild("HumanoidRootPart"); if not kr then break end
        if not myRoot or not myRoot.Parent then break end
        local dist = (kr.Position - myRoot.Position).Magnitude
        if dist < Aimbot.minDistance then break end
        local predicted = kr.Position + (kr.CFrame.LookVector * Aimbot.prediction)
        if Aimbot.charLock then pcall(function() myRoot.CFrame = CFrame.lookAt(myRoot.Position, predicted) end) end
        if Aimbot.camLock then
            local cam = Workspace.CurrentCamera
            if cam then pcall(function() cam.CFrame = CFrame.lookAt(cam.CFrame.Position, predicted) end) end
        end
        task.wait()
    end
    Aimbot.active = false
    if humanoid then pcall(function() humanoid.AutoRotate = true end) end
end

local function OnAimbotPunchDetected(track, animId)
    if not Aimbot.enabled or Aimbot.shiftHeld or Aimbot.active or KillerState.isKiller then return end
    local now = tick()
    if Aimbot.lastTrigger[animId] and now - Aimbot.lastTrigger[animId] < 0.5 then return end
    Aimbot.lastTrigger[animId] = now
    task.delay(Aimbot.delay, function()
        if not Aimbot.enabled or Aimbot.shiftHeld or Aimbot.active or KillerState.isKiller then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local humanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myRoot or not humanoid then return end
        local killer, dist = GetNearestKillerModelAimbot()
        if not killer then return end
        if dist < Aimbot.minDistance then return end
        Aimbot.active = true
        pcall(function() humanoid.AutoRotate = false end)
        AimLockLoop(killer, myRoot, humanoid)
    end)
end

local function AimbotAttachAnimator()
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator"); if not animator then return end
    if Aimbot.animator == animator and Aimbot.conn then return end
    if Aimbot.conn then pcall(function() Aimbot.conn:Disconnect() end); Aimbot.conn = nil end
    Aimbot.animator = animator
    Aimbot.conn = animator.AnimationPlayed:Connect(function(track)
        local ok, id = pcall(function() return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
        if ok and id and AIMBOT_PUNCH_SET[id] then OnAimbotPunchDetected(track, id) end
    end)
end

local function AimbotStart()
    Aimbot.enabled = true
    Aimbot.lastTrigger = {}
    AimbotAttachAnimator()
    if not Aimbot.charConn then
        Aimbot.charConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5); if Aimbot.enabled then AimbotAttachAnimator() end
        end)
    end
    if not Aimbot.retryTask then
        Aimbot.retryTask = task.spawn(function()
            while Aimbot.enabled do
                if not Aimbot.conn then AimbotAttachAnimator() end
                task.wait(1)
            end
            Aimbot.retryTask = nil
        end)
    end
end

local function AimbotStop()
    Aimbot.enabled = false; Aimbot.active = false
    if Aimbot.conn then pcall(function() Aimbot.conn:Disconnect() end); Aimbot.conn = nil end
    if Aimbot.charConn then pcall(function() Aimbot.charConn:Disconnect() end); Aimbot.charConn = nil end
    if Aimbot.retryTask then pcall(task.cancel, Aimbot.retryTask); Aimbot.retryTask = nil end
    Aimbot.animator = nil
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.AutoRotate = true end) end
end

-- ═══════════════════════════════════════════════════════════════
-- CUSTOM ZONE
-- ═══════════════════════════════════════════════════════════════
local CustomZone = { running=false, connections={}, folder=nil, killerZones={} }
local PLAYER_RADIUS = 1.5

local function GetKillerGroundCF(kr)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {kr.Parent, LocalPlayer.Character}
    params.IgnoreWater = true
    local ray = Workspace:Raycast(kr.Position, Vector3.new(0, -30, 0), params)
    local groundY = ray and (kr.Position.Y - ray.Distance) or (kr.Position.Y - 3)
    return CFrame.new(kr.Position.X, groundY + (Settings.ZoneHeight or 0.5), kr.Position.Z) * kr.CFrame.Rotation
end

local function BuildZone(killer)
    local model = Instance.new("Model"); model.Name = "ABCustomZone_"..killer.Name; model.Parent = CustomZone.folder
    local edges = {}
    for i = 1, 4 do
        local p = Instance.new("Part")
        p.Name="Edge"..i; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
        p.CastShadow=false; p.Material=Enum.Material.Neon
        p.Color=Color3.fromRGB(255,0,0); p.Transparency=0.3
        p.Size=Vector3.new(0.35,0.08,1); p.CFrame=CFrame.new(0,-5000,0)
        p.Parent = model; edges[i] = p
    end
    local circle = Instance.new("Part")
    circle.Shape=Enum.PartType.Cylinder; circle.Name="Circle"
    circle.Anchored=true; circle.CanCollide=false; circle.CanQuery=false; circle.CanTouch=false
    circle.CastShadow=false; circle.Material=Enum.Material.Neon
    circle.Color=Color3.fromRGB(255,0,0); circle.Transparency=0.65
    circle.Size=Vector3.new(0.08,10,10); circle.CFrame=CFrame.new(0,-5000,0)
    circle.Parent = model
    return { model=model, edges=edges, circle=circle, killer=killer }
end

local function IsPlayerInDiamond(myPos, killerCF, killerPos)
    if not Settings.ShowDiamond then return false end
    local fwd = killerCF.LookVector; local right = killerCF.RightVector
    local flatFwd = Vector3.new(fwd.X, 0, fwd.Z); local flatRight = Vector3.new(right.X, 0, right.Z)
    if flatFwd.Magnitude < 0.01 or flatRight.Magnitude < 0.01 then return false end
    flatFwd = flatFwd.Unit; flatRight = flatRight.Unit
    local toPlayer = Vector3.new(myPos.X - killerPos.X, 0, myPos.Z - killerPos.Z)
    local distFwd = toPlayer:Dot(flatFwd); local distRight = toPlayer:Dot(flatRight)
    local centerDist = Settings.CustomDiamondOffset + Settings.CustomDiamondLength / 2
    local dF = distFwd - centerDist
    local halfW = Settings.CustomDiamondWidth / 2 + PLAYER_RADIUS
    local halfL = Settings.CustomDiamondLength / 2 + PLAYER_RADIUS
    return math.abs(distRight) / halfW + math.abs(dF) / halfL <= 1
end

local function IsPlayerInCircle(myPos, killerPos)
    if not Settings.ShowCircle then return false end
    local dx = myPos.X - killerPos.X; local dz = myPos.Z - killerPos.Z
    local effectiveR = Settings.CustomCircleRadius + PLAYER_RADIUS
    return dx*dx + dz*dz <= effectiveR * effectiveR
end

local function IsPlayerInCustomZone(killer)
    if not killer or not killer.Parent then return false end
    local kr = killer:FindFirstChild("HumanoidRootPart")
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not kr or not myRoot then return false end
    return IsPlayerInDiamond(myRoot.Position, kr.CFrame, kr.Position) or IsPlayerInCircle(myRoot.Position, kr.Position)
end

local function UpdateZone(zone, kr, myRoot)
    if not zone or not zone.model or not zone.model.Parent then return end
    if not kr or not kr.Parent then return end
    if KillerState.isKiller then
        for _, e in ipairs(zone.edges) do if e and e.Parent then e.Transparency = 1 end end
        if zone.circle and zone.circle.Parent then zone.circle.Transparency = 1 end
        return
    end
    local baseCF = GetKillerGroundCF(kr)
    local offset = Settings.CustomDiamondOffset
    local L = Settings.CustomDiamondLength; local W = Settings.CustomDiamondWidth
    local wA = baseCF:PointToWorldSpace(Vector3.new(0, 0, -offset))
    local wB = baseCF:PointToWorldSpace(Vector3.new(0, 0, -(offset + L)))
    local wC = baseCF:PointToWorldSpace(Vector3.new(-W/2, 0, -(offset + L/2)))
    local wD = baseCF:PointToWorldSpace(Vector3.new(W/2, 0, -(offset + L/2)))
    local edgeSpecs = { {wA,wC}, {wA,wD}, {wB,wC}, {wB,wD} }
    for i, spec in ipairs(edgeSpecs) do
        local p1, p2 = spec[1], spec[2]
        local mid = (p1 + p2) / 2; local diff = p2 - p1
        local length = diff.Magnitude
        if length > 0.01 then
            local edge = zone.edges[i]
            if edge then
                edge.Size = Vector3.new(0.35, 0.08, length)
                edge.CFrame = CFrame.lookAt(mid, mid + diff.Unit)
                edge.Transparency = Settings.ShowDiamond and 0.3 or 1
            end
        end
    end
    if zone.circle then
        local cCenter = Vector3.new(baseCF.Position.X, baseCF.Position.Y + 0.04, baseCF.Position.Z)
        zone.circle.Size = Vector3.new(0.08, Settings.CustomCircleRadius*2, Settings.CustomCircleRadius*2)
        zone.circle.CFrame = CFrame.new(cCenter) * CFrame.Angles(0, 0, math.rad(90))
        zone.circle.Transparency = Settings.ShowCircle and 0.65 or 1
    end
    local inDiamond = myRoot and IsPlayerInDiamond(myRoot.Position, kr.CFrame, kr.Position) or false
    local inCircle = myRoot and IsPlayerInCircle(myRoot.Position, kr.Position) or false
    local diamondColor = inDiamond and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    local circleColor = inCircle and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    for _, e in ipairs(zone.edges) do if e and e.Parent then e.Color = diamondColor end end
    if zone.circle and zone.circle.Parent then zone.circle.Color = circleColor end
end

local function StartCustomZoneVisuals()
    if CustomZone.running then return end
    CustomZone.running = true
    CustomZone.connections = {}; CustomZone.killerZones = {}
    CustomZone.folder = Instance.new("Folder"); CustomZone.folder.Name = "ABCustomZoneVisuals"; CustomZone.folder.Parent = Workspace
    table.insert(CustomZone.connections, RunService.RenderStepped:Connect(function()
        if not CustomZone.running then return end
        if KillerState.isKiller then return end
        local killersFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers")
        if not killersFolder then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        for _, killer in ipairs(killersFolder:GetChildren()) do
            if killer:IsA("Model") then
                local kr = killer:FindFirstChild("HumanoidRootPart")
                if kr then
                    local zone = CustomZone.killerZones[killer]
                    if not zone or not zone.model or not zone.model.Parent then
                        if zone and zone.model then pcall(function() zone.model:Destroy() end) end
                        zone = BuildZone(killer); CustomZone.killerZones[killer] = zone
                    end
                    UpdateZone(zone, kr, myRoot)
                end
            end
        end
        for killer, zone in pairs(CustomZone.killerZones) do
            if not killer.Parent or not killer:IsDescendantOf(Workspace) then
                if zone.model then pcall(function() zone.model:Destroy() end) end
                CustomZone.killerZones[killer] = nil
            end
        end
    end))
end
local function StopCustomZoneVisuals()
    if not CustomZone.running then return end
    CustomZone.running = false
    for _, c in ipairs(CustomZone.connections) do pcall(function() c:Disconnect() end) end
    CustomZone.connections = {}
    for _, zone in pairs(CustomZone.killerZones) do if zone.model then pcall(function() zone.model:Destroy() end) end end
    CustomZone.killerZones = {}
    if CustomZone.folder then pcall(function() CustomZone.folder:Destroy() end); CustomZone.folder = nil end
end
local function UpdateCustomZoneVisibility()
    local shouldShow = Settings.ShowDiamond or Settings.ShowCircle
    if shouldShow and not CustomZone.running then StartCustomZoneVisuals()
    elseif not shouldShow and CustomZone.running then StopCustomZoneVisuals() end
end

-- ═══════════════════════════════════════════════════════════════
-- RECTANGLE
-- ═══════════════════════════════════════════════════════════════
local Rectangle = { folder=nil, invisibleTrackers={}, visibleFlashes={}, invisibleLoop=nil, flashLoop=nil }
local RECT_EDGE_THICK = 0.1
local RECT_INVIS_DURATION = 0.25
local RECT_FLASH_HIT_DURATION = 0.4

local function EnsureRectangleFolder()
    if not Rectangle.folder or not Rectangle.folder.Parent then
        local f = Instance.new("Folder"); f.Name = "RectangleBoxVisuals"; f.Parent = Workspace; Rectangle.folder = f
    end
end
local function CalcRectCenterCF(kr)
    local pos = kr.Position; local look = kr.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
    flat = flat.Unit
    local dist = Settings.RectangleDistance or 3
    return CFrame.lookAt(pos + flat * dist, pos + flat * dist + flat)
end
local function GetRectSize()
    local baseW, baseH, baseL = 4, 4, 6
    local m = Settings.RectangleMultiplier or 1
    return Vector3.new(baseW * m, baseH * m, baseL * m)
end
local function IsPlayerInRect(myPos, centerCF, size)
    local halfW = size.X / 2 + PLAYER_RADIUS
    local halfL = size.Z / 2 + PLAYER_RADIUS
    local halfH = size.Y / 2 + PLAYER_RADIUS
    local lp = centerCF:PointToObjectSpace(myPos)
    return math.abs(lp.X) <= halfW and math.abs(lp.Z) <= halfL and math.abs(lp.Y) <= halfH
