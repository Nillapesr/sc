
-- =========================================================
-- ✅ DISCORD WEBHOOK + USER COUNTER (JSONBin.io)
-- =========================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1552560930527911976/nv3ZGk8jrrSoTUNjFWt62QAx_WHPXdhDF_gEXyQmyZeZJrF-m1Cxm6UJx5bVh3cpMh8z"  -- GANTI
local JSONBIN_ID  = "6ab4baf0ffd5d160532942b0"                              -- GANTI (dari jsonbin.io)
local JSONBIN_KEY = "$2a$10$fqM416FqxYlN9IxodShsTe89/7se5TluSWtfdJo1xJgIPdt5ruJhi"                              -- GANTI (X-Master-Key)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- ===== Helper: ambil info executor =====
local function getExecutorName()
    local name = "Unknown"
    pcall(function() if identifyexecutor then name = identifyexecutor() end end)
    if name == "Unknown" then
        pcall(function() if getexecutorname then name = getexecutorname() end end)
    end
    return tostring(name)
end

local function getHWID()
    local id = "N/A"
    pcall(function()
        if gethwid then id = gethwid()
        elseif syn and syn.get_hwid then id = syn.get_hwid()
        elseif getrobloxhwid then id = getrobloxhwid() end
    end)
    return tostring(id)
end

local function getAvatarURL(userId)
    return string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png",
        userId
    )
end

-- ===== Load stats dari JSONBin =====
local function loadStats()
    local stats = { totalUsers = 0, seenUsers = {} }
    pcall(function()
        local res = request({
            Url = "https://api.jsonbin.io/v3/b/" .. JSONBIN_ID .. "/latest",
            Method = "GET",
            Headers = {
                ["X-Master-Key"] = JSONBIN_KEY,
                ["X-Bin-Meta"] = "false",
            },
        })
        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            if type(data) == "table" then
                stats.totalUsers = data.totalUsers or 0
                stats.seenUsers = data.seenUsers or {}
            end
        end
    end)
    return stats
end

-- ===== Save stats ke JSONBin =====
local function saveStats(stats)
    pcall(function()
        request({
            Url = "https://api.jsonbin.io/v3/b/" .. JSONBIN_ID,
            Method = "PUT",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Master-Key"] = JSONBIN_KEY,
            },
            Body = HttpService:JSONEncode({
                totalUsers = stats.totalUsers,
                seenUsers = stats.seenUsers,
            }),
        })
    end)
end

-- ===== Kirim webhook =====
local function sendWebhook(isFirstTime, activeCount, totalCount, executor, hwid)
    local player = Players.LocalPlayer
    local avatar = getAvatarURL(player.UserId)
    local now = os.time()

    local title = isFirstTime
        and "🆕 New User Executed Lychee Hub!"
        or  "🔁 Returning User Executed Lychee Hub!"
    local color = isFirstTime and 0x00FF88 or 0x00A2FF

    local payload = {
        username = "Lychee Hub Logger",
        embeds = {{
            title = title,
            description = "**Lychee Hub [ V1 ]** — Steal An Egg\nScript berhasil dijalankan.",
            color = color,
            thumbnail = { url = avatar },
            fields = {
                { name = "👤 Username",   value = string.format("`%s` (%s)", player.Name, player.DisplayName), inline = true },
                { name = "🆔 User ID",    value = "`" .. tostring(player.UserId) .. "`", inline = true },
                { name = "⚙️ Executor",   value = "`" .. executor .. "`", inline = true },
                { name = "🔑 HWID",       value = "`" .. string.sub(hwid, 1, 40) .. "...`", inline = false },
                { name = "🌐 Place ID",   value = "`" .. tostring(game.PlaceId) .. "`", inline = true },
                { name = "🕐 Time",       value = "<t:" .. now .. ":F> (<t:" .. now .. ":R>)", inline = true },
                { name = "📊 Active Users (Sekarang)", value = "**" .. tostring(activeCount) .. "** orang", inline = true },
                { name = "🏆 Total Users (All-time)",  value = "**" .. tostring(totalCount) .. "** orang", inline = true },
                { name = "🎮 Server Players", value = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), inline = true },
            },
            footer = {
                text = "Lychee Hub • " .. executor,
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    }

    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload),
        })
    end)
end

-- ===== MAIN: jalankan saat script load =====
task.spawn(function()
    local player = Players.LocalPlayer
    local uid = tostring(player.UserId)
    local executor = getExecutorName()
    local hwid = getHWID()

    -- Load stats global
    local stats = loadStats()

    -- Cek user pertama kali atau bukan
    local isFirstTime = not stats.seenUsers[uid]

    if isFirstTime then
        stats.totalUsers = stats.totalUsers + 1
        stats.seenUsers[uid] = os.time()
        saveStats(stats)
    else
        stats.seenUsers[uid] = os.time()
        saveStats(stats)
    end

    -- Active users = jumlah player di server (proxy sederhana)
    -- Kalau mau lebih akurat: simpan activeUsers ke bin juga, tapi resiko race condition
    local activeCount = #Players:GetPlayers()

    -- Kirim webhook
    sendWebhook(isFirstTime, activeCount, stats.totalUsers, executor, hwid)

    -- Log ke console
    print(string.format("[LycheeHub Logger] User: %s | First time: %s | Total: %d",
        player.Name, tostring(isFirstTime), stats.totalUsers))
end)

local ProxyLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"
))()
local Lib = ProxyLib.new()

local Window = Lib:CreateWindow({
    Title = "Lychee Hub [ V1 ]",
    Subtitle = "Steal An Egg",
    Size = Vector2.new(460, 320),
    MinSize = Vector2.new(420, 320),
    MaxSize = Vector2.new(900, 620),
    Theme = Color3.fromRGB(0, 200, 255),
    TypeUI = "Modern",
    Language = "English",
    Search = true,
    AutoSave = false, AutoLoad = false,
    DefaultFps = false, DefaultPing = false, DefaultProfile = true,
    BackgroundImage = { Id = "rbxassetid://136182100085563", Active = false },
    TitleConfig = {
        Gradient = true,
        Colors = { Color3.fromRGB(80, 180, 255), Color3.fromRGB(30, 90, 255) },
        Words = {
            { Text = "Lychee", Colors = { Color3.fromRGB(80, 200, 255), Color3.fromRGB(0, 120, 255) } },
            { Text = "Hub", Colors = { Color3.fromRGB(120, 220, 255), Color3.fromRGB(30, 90, 255) } },
        },
    },
    ConfigPanel = {
        Enabled = true, Acrylic = true, Theme = true, Fps = false,
        Ping = false, Profile = true, HideNotify = true, Language = true,
        BackgroundImage = true,
    },
    FloatButton = {
        Shape = "Circle", Color = "Translucent", Size = 50,
        Icon = "rbxassetid://102468802738090"
    },
    Acrylic = { Enabled = false, Opacity = 0 },
})

-- =========================================================
-- ==============  LycheeHUB ORIGINAL (UNCHANGED)  ==========
-- =========================================================
local e = game:GetService("Players")
local r = game:GetService("Workspace")
local y = game:GetService("RunService")
local u = game:GetService("TweenService")
local w = game:GetService("UserInputService")
local j = game:GetService("ReplicatedStorage")
local k = game:GetService("ProximityPromptService")
local a = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local o = e.LocalPlayer
local currentLang = "EN"
local executorCheckCaller = typeof(checkcaller) == "function" and checkcaller or function() return false end
local safeNewCClosure = typeof(newcclosure) == "function" and newcclosure or function(fn) return fn end
local V = game:GetService("ProximityPromptService")
pcall(function()
    V.PromptButtonHoldBegan:Connect(function(e)
        pcall(function()
            if typeof(fireproximityprompt) == "function" then fireproximityprompt(e) end
        end)
    end)
end)
local H = function() end
local t = function() end

local s = nil
pcall(function() s = require((j:WaitForChild("Client", 5)):WaitForChild("EggState", 5)) end)
if not s then pcall(function() s = require(j.Client.EggState) end) end
local p = nil
pcall(function() p = require(((j:WaitForChild("Shared", 5)):WaitForChild("Util", 5)):WaitForChild("AssetItems", 5)) end)
if not p then pcall(function() p = require(j.Shared.Util.AssetItems) end) end
local B = nil
pcall(function() B = require((j:WaitForChild("Shared", 5)):WaitForChild("Remotes", 5)) end)
if not B then pcall(function() B = require(j.Shared.Remotes) end) end

local function J(e, r)
    local y = (j:FindFirstChild("Packages") and j.Packages:FindFirstChild("Networking")) or j:FindFirstChild("Network") or j
    local u = y:FindFirstChild(e) or j:FindFirstChild(e)
    if u then return u end
    local w = y:FindFirstChild(e, true) or j:FindFirstChild(e, true)
    if w then return w end
    if r then
        local e = y:FindFirstChild(r) or j:FindFirstChild(r)
        if e then return e end
        local u = y:FindFirstChild(r, true) or j:FindFirstChild(r, true)
        if u then return u end
    end
    local k = string.match(e, "[^/]+$")
    if k then
        local e = y:FindFirstChild(k, true) or j:FindFirstChild(k, true)
        if e then return e end
    end
    return nil
end

local K = J("RF/EggWorld/AskPlaceEgg", "AskPlaceEgg")
local c = J("RF/EggWorld/AskLiveSnapshot", "AskLiveSnapshot")
local v = J("RF/Homestead/AskState", "RF/Plots/AskState") or J("AskState")
local i = J("RF/EggWorld/AskFieldEggCarry", "AskFieldEggCarry")
local R = J("RF/EggWorld/AskFieldEggSnapshot", "AskFieldEggSnapshot") or J("Eggs: RequestAreaEggSnapshot", "RequestAreaEggSnapshot")
local g = J("RF/EggWorld/AskHatch", "AskHatch") or J("Eggs: RequestHatchEgg")
local Q = J("RF/EggWorld/AskFinishHatch", "AskFinishHatch") or J("Eggs: RequestCompleteHatchEgg")
local P = J("RE/GuardPatrol/ForestStrike", "ForestStrike") or (B and (B.GuardPatrol and B.GuardPatrol.ForestStrike))
local N = J("SpeedTollOffer", "RE/GuardPatrol/SpeedTollOffer") or (B and (B.GuardPatrol and B.GuardPatrol.SpeedTollOffer))
local U = J("RF/Treadmill/AskDoff", "AskDoff")
local l = J("RF/Treadmill/AskDon", "AskDon") or J("RF/Treadmill/AskMount", "AskMount")
local D = J("RF/Treadmill/AskTierRaise", "Treadmills: RequestUpgrade", "AskTierRaise")
local C = J("RF/Trailwear/AskPurchase", "Trailwear: RequestPurchase", "AskPurchase")
local q = J("RF/Trailwear/AskChoose", "Trailwear: RequestEquip", "AskChoose")
local n = J("RF/Trailwear/AskDoff", "Trailwear: RequestUnequip", "AskDoff")

H(string.format("[RemoteCheck] Carry:%s Snap:%s Place:%s Hatch:%s Finish:%s Strike:%s Toll:%s Doff:%s",
    tostring(i~=nil), tostring(R~=nil), tostring(K~=nil), tostring(g~=nil),
    tostring(Q~=nil), tostring(P~=nil), tostring(N~=nil), tostring(U~=nil)))

local f = { ["Light Dark"]=1300, ["LightDark"]=1300, ["Titan Temple"]=1100, ["Cherry Blossom"]=1000, ["Cosmic"]=900, ["Prehistoric"]=800, ["Abyss Ocean"]=700, ["Volcano"]=600, ["Snow"]=500, ["Jungle"]
local M = {"Light Dark","Titan Temple","Cherry Blossom","Cosmic","Prehistoric","Abyss Ocean","Volcano","Snow","Jungle","Desert","Lake","Forest"}
local I = { ["Light Dark"]=420, ["LightDark"]=420, ["Titan Temple"]=380, ["Cherry Blossom"]=330, ["Cosmic"]=280, ["Prehistoric"]=240, ["Abyss Ocean"]=200, ["Volcano"]=180, ["Snow"]=160, ["Jungle"]
local L = -360
local E = 525
local b = 620
local A = 130
local S = CFrame.new(4773.7587890625, 70.392112731934, -315.73501586914)
local Z = "LycheeHub_FlightSpeed.txt"
local z = "LycheeHub_EggSelectConfig.json"
local d = { ["Light Dark"]=Color3.fromRGB(168,85,247), ["Titan Temple"]=Color3.fromRGB(245,158,11), ["Cherry Blossom"]=Color3.fromRGB(236,72,153), ["Cosmic"]=Color3.fromRGB(6,182,212), ["Prehisto
local X = {"Divine","Eternal","Secret","Cosmic","Mythic","Legendary","Epic","Rare","Uncommon","Common"}
local G = { ["Divine"]=Color3.fromRGB(244,63,94), ["Eternal"]=Color3.fromRGB(217,70,239), ["Secret"]=Color3.fromRGB(249,115,22), ["Cosmic"]=Color3.fromRGB(6,182,212), ["Mythic"]=Color3.fromRGB(13
local F = { ["Divine"]=6, ["Eternal"]=5, ["Secret"]=4, ["Cosmic"]=3, ["Mythic"]=2, ["Legendary"]=1, ["Epic"]=0.5, ["Rare"]=0.3, ["Uncommon"]=0.1, ["Common"]=0 }
local h
local function O()
    local e = 600
    pcall(function()
        local r = false
        if isfile then r = isfile(Z)
        elseif readfile then local e, y = pcall(readfile, Z); r = e and (y ~= nil) end
        if r and readfile then
            local r = readfile(Z)
            local u = tonumber(r)
            if u and (u >= 100 and u <= 1000) then e = math.floor(u) end
        end
    end)
    return e
end
local function Y(e)
    pcall(function()
        if writefile then
            local y = math.clamp(math.floor(tonumber(e) or 600), 100, 1000)
            writefile(Z, tostring(y))
        end
    end)
end
local function T()
    local e = nil
    pcall(function()
        local r = false
        if isfile then r = isfile(z)
        elseif readfile then local e, y = pcall(readfile, z); r = e and (y ~= nil) end
        if r and (readfile and a) then
            local r = readfile(z)
            if r and r ~= "" then
                local u = a:JSONDecode(r)
                if type(u) == "table" then e = u end
            end
        end
    end)
    local r = { ["Light Dark"]=true, ["Titan Temple"]=true, ["Cherry Blossom"]=true, ["Cosmic"]=false, ["Prehistoric"]=false, ["Abyss Ocean"]=false, ["Volcano"]=false, ["Snow"]=false, ["Jungle"]
    local y = { ["Divine"]=true, ["Eternal"]=true, ["Secret"]=true, ["Cosmic"]=true, ["Mythic"]=true, ["Legendary"]=true, ["Epic"]=true, ["Rare"]=true, ["Uncommon"]=true, ["Common"]=true }
    if type(e) ~= "table" then
        e = { ["selectedZones"]=r, ["selectedRarities"]=y, ["alwaysCollectSecretPlus"]=false, ["minRarityTier"]=2, ["autoTreadmill"]=false, ["autoUpgradeTreadmill"]=false, ["autoBuyTrails"]=false
    else
        if type(e.selectedZones) ~= "table" then e.selectedZones = r end
        if type(e.selectedRarities) ~= "table" then e.selectedRarities = y
        else
            for r, w in ipairs(X) do
                if e.selectedRarities[w] == nil then e.selectedRarities[w] = (y[w] == true) end
            end
        end
        if e.alwaysCollectSecretPlus == nil then e.alwaysCollectSecretPlus = true end
        if e.minRarityTier == nil then e.minRarityTier = 2 end
        if e.autoTreadmill == nil then e.autoTreadmill = true end
        if e.autoUpgradeTreadmill == nil then e.autoUpgradeTreadmill = true end
        if e.autoBuyTrails == nil then e.autoBuyTrails = true end
        if e.hideNotEnoughMoney == nil then e.hideNotEnoughMoney = true end
        if e.performanceMode == nil then e.performanceMode = false end
        if e.disable3D == nil then e.disable3D = false end
        if e.antiAFK == nil then e.antiAFK = false end
        if e.language and ((e.language == "EN" or e.language == "TH")) then currentLang = e.language end
    end
    return e
end
local function x()
    pcall(function()
        if writefile and (a and h) then
            local r = { ["selectedZones"]=h.selectedZones or {}, ["selectedRarities"]=h.selectedRarities or {}, ["alwaysCollectSecretPlus"]=(h.alwaysCollectSecretPlus ~= false), ["minRarityTier"]
            local y = a:JSONEncode(r)
            writefile(z, y)
        end
    end)
end
local W = T()
h = { 
    ["godmode"]=true, ["autoGlide"]=true, ["autoHatch"]=false, ["autoPlaceEvery5"]=false, 
    ["batchStealCount"]=0, ["isBatchPlacing"]=false, ["isHatching"]=false, ["autoFarmLoop"]=false, 
    ["pureTweenFarm"]=false, ["glidingToTarget"]=false, ["securingEgg"]=false, ["glideSpeed"]=O(), 
    ["selectedZones"]=W.selectedZones, ["selectedRarities"]=W.selectedRarities, 
    ["alwaysCollectSecretPlus"]=W.alwaysCollectSecretPlus, ["minRarityTier"]=W.minRarityTier, 
    ["autoTreadmill"]=false, ["autoUpgradeTreadmill"]=false, ["autoBuyTrails"]=false, 
    ["hideNotEnoughMoney"]=false, ["performanceMode"]=false, ["disable3D"]=false, ["antiAFK"]=false, 
    ["onTreadmill"]=false, ["lastTreadmillMount"]=0, ["laneZ"]=-360, ["swapped"]=false, 
    ["teleporting"]=false, ["isReturning"]=false, ["delivering"]=false, ["holdingEggForGuard"]=false, 
    ["currentTargetModel"]=nil, ["targetPosition"]=nil, ["stateTime"]=os.clock(), ["statusText"]="Ready", 
    ["bestEggInfo"]="Scanning...", ["gui"]=nil, ["alive"]=true, ["plot"]=nil, ["pen"]=nil, 
    ["origin"]=nil, ["tread"]=nil, ["autoKillScramble"]=false, ["scrambleTarget"]=nil, 
    ["scrambleUID"]=nil, ["isAttackingScramble"]=false, ["scrambleFlyLock"]=false, 
    ["scrambleZoneIdx"]=1, ["scrambleHits"]={}, ["scrambleMaxHP"]={},
    ["scrambleHpFilter"] = { ["3"] = true, ["5"] = true, ["6"] = true, ["10"] = true },
    -- ✅ NEW FLAGS untuk fitur baru
    ["autoStealBigSize"] = false,
    ["stealAutoTreadmill"] = false,
}

-- =========================================================
-- ✅ SCHEDULED PAUSE (HANYA AUTO STEAL + KILL SCRAMBLE + BIG SIZE)
--    Stop saat menit berakhiran 4 & detik >= 13
--    Resume saat menit berganti ke 5
-- =========================================================
h.scheduledPause = false
h.pauseReason = nil
h._pausedFarmMode = "NONE"  -- "TWEEN" / "WARP" / "NONE"
h._pausedScramble = false
h._pausedBigSize = false
h._pausedToggles = {
    tween = false,
    warp = false,
    scramble = false,
    bigSize = false,
}

local function timeToString()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

-- ✅ Cek apakah sekarang waktunya pause (menit berakhiran 4 & detik >= 13)
local function shouldPauseNow()
    local t = os.date("*t")
    local isPauseMinute = (t.min % 10 == 4)  -- 04, 14, 24, 34, 44, 54
    return isPauseMinute and (t.sec >= 13)
end

-- ✅ Cek apakah sudah waktunya resume (menit berakhiran 5)
local function shouldResumeNow()
    local t = os.date("*t")
    return (t.min % 10 == 5)  -- 05, 15, 25, 35, 45, 55
end

-- ✅ Pause: Auto Steal + Scramble + Big Size
local function pauseStealAndScramble()
    if h.scheduledPause then return end
    h.scheduledPause = true
    h.pauseReason = "Pause @ " .. timeToString()

    print(string.format("[ScheduledPause] ⏸️ PAUSE @ %s — Stop Auto Steal + Scramble + Big Size", timeToString()))

    -- Simpan state toggle (untuk UI sync)
    h._pausedToggles.tween     = h.pureTweenFarm
    h._pausedToggles.warp      = h.autoFarmLoop
    h._pausedToggles.scramble  = h.autoKillScramble
    h._pausedToggles.bigSize   = h.autoStealBigSize
    h._pausedFarmMode          = Y4  -- "TWEEN" / "WARP" / "NONE"
    h._pausedScramble          = h.autoKillScramble
    h._pausedBigSize           = h.autoStealBigSize

    -- ✅ Stop farm mode (Tween & Warp) via T4
    Y4 = "NONE"
    h.pureTweenFarm = false
    h.autoFarmLoop = false

    -- ✅ Stop scramble
    h.autoKillScramble = false
    h.scrambleTarget = nil
    h.scrambleUID = nil
    h.scrambleFlyLock = false
    h.scrambleHits = {}
    h.scrambleMaxHP = {}

    -- ✅ Stop big size
    h.autoStealBigSize = false

    -- ✅ Cancel aktivitas steal yang sedang berjalan
    h.teleporting = false
    h.glidingToTarget = false
    h.securingEgg = false
    h.isReturning = false
    h.delivering = false
    h.holdingEggForGuard = false
    -- ⚠️ JANGAN cancel isBatchPlacing, onTreadmill, isHatching — biar fitur lain tetap jalan

    h.statusText = "⏸️ PAUSE (Steal + Scramble + BigSize) — Tunggu menit berganti..."
end

-- ✅ Resume: Auto Steal + Scramble + Big Size
local function resumeStealAndScramble()
    if not h.scheduledPause then return end

    print(string.format("[ScheduledPause] ▶️ RESUME @ %s — Restore Auto Steal + Scramble + Big Size", timeToString()))

    h.scheduledPause = false
    h.pauseReason = nil

    -- ✅ Restore scramble
    h.autoKillScramble = h._pausedScramble or false

    -- ✅ Restore big size
    h.autoStealBigSize = h._pausedBigSize or false

    -- ✅ Restore farm mode (TWEEN / WARP) via T4
    local prevMode = h._pausedFarmMode
    if prevMode == "TWEEN" or prevMode == "WARP" then
        pcall(function() if T4 then T4(prevMode) end end)
    end

    h._pausedFarmMode = "NONE"
    h._pausedScramble = false
    h._pausedBigSize = false
    h._pausedToggles = { tween = false, warp = false, scramble = false, bigSize = false }

    h.statusText = "▶️ RESUMED — Fitur kembali aktif"
end

-- ✅ Watcher loop: cek waktu tiap 0.5 detik
task.spawn(function()
    while h.alive do
        pcall(function()
            if not h.scheduledPause then
                if shouldPauseNow() then
                    pauseStealAndScramble()
                end
            else
                if shouldResumeNow() then
                    resumeStealAndScramble()
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- =========================================================
-- ✅ CAPTURE ORIGINAL HUMANOID VALUES (anti-flag WalkSpeed)
-- =========================================================
h._origWalkSpeed = nil
h._origJumpPower = nil
h._origJumpHeight = nil
h._origUseJumpPower = nil

local function captureOriginalHumanoid(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if h._origWalkSpeed == nil then
        h._origWalkSpeed = hum.WalkSpeed
        h._origJumpPower = hum.JumpPower
        h._origJumpHeight = hum.JumpHeight
        h._origUseJumpPower = hum.UseJumpPower
    end
end

local function releaseRigidWelds(char)
    char = char or o.Character
    if not char then return end
    for _, dd in ipairs(char:GetDescendants()) do
        if dd:IsA("WeldConstraint") and dd.Name:sub(1, 15) == "RigidJointWeld_" then
            pcall(function() dd:Destroy() end)
        end
    end
end

local function restoreNormalHumanoid(char)
    char = char or o.Character
    if not char then return end
    pcall(releaseRigidWelds, char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        hum.AutoRotate = true
        if hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    if h._origWalkSpeed ~= nil then
        pcall(function() hum.WalkSpeed = h._origWalkSpeed end)
    end
    if h._origUseJumpPower ~= nil then
        pcall(function() hum.UseJumpPower = h._origUseJumpPower end)
    end
    if h._origUseJumpPower and h._origJumpPower ~= nil then
        pcall(function() hum.JumpPower = h._origJumpPower end)
    elseif h._origJumpHeight ~= nil then
        pcall(function() hum.JumpHeight = h._origJumpHeight end)
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function() hrp.Anchored = false end)
    end
end

captureOriginalHumanoid(o.Character)

local m, e4, r4, y4, u4, w4, j4, k4, a4, o4, V4, H4, t4, s4, p4, B4, J4, K4, c4, v4, i4, R4, g4, Q4, P4, N4, U4, l4, D4, C4, q4, n4, f4, M4, I4, L4, E4, b4, A4, S4, Z4, z4, d4
local X4 = {}
local G4 = 0
local F4 = nil
local h4
local O4 = 0
local Y4 = "NONE"
local T4
local x4 = nil
local W4 = nil

pcall(function()
    local e = game:GetService("Lighting")
    e:GetPropertyChangedSignal("ClockTime"):Connect(function() X4 = {}; G4 = 0 end)
end)
pcall(function()
    local function e(e)
        if e:IsA("RemoteEvent") then
            local y = string.lower(e.Name)
            if string.find(y, "reset") or string.find(y, "night") or string.find(y, "spawn") or string.find(y, "countdown") then
                pcall(function()
                    e.OnClientEvent:Connect(function() X4 = {}; G4 = 0 end)
                end)
            end
        end
    end
    for y, u in ipairs(j:GetDescendants()) do e(u) end
    j.DescendantAdded:Connect(e)
end)

m = function(e)
    if not e or not e:IsA("Tool") then return false end
    local r = string.lower(e.Name)
    if string.find(r, "sword") or string.find(r, "radar") or string.find(r, "basket") or string.find(r, "punch") then return false end
    if e:GetAttribute("EggUid") or e:GetAttribute("UID") or string.find(r, "egg") or e:GetAttribute("Category") or e:GetAttribute("ItemType") == "Egg" then return true end
    return false
end
e4 = function()
    local e = o.Character
    if e then
        for e, y in ipairs(e:GetChildren()) do
            if m(y) then
                local e = y:GetAttribute("UID") or y:GetAttribute("EggUid")
                return y, e or y.Name
            end
        end
    end
    return nil, nil
end
r4 = function()
    local e = o:FindFirstChild("Backpack")
    if e then
        for e, y in ipairs(e:GetChildren()) do
            if m(y) then
                local e = y:GetAttribute("UID") or y:GetAttribute("EggUid")
                return y, e or y.Name
            end
        end
    end
    return nil, nil
end
y4 = function()
    local e = 0
    local r = o:FindFirstChild("Backpack")
    if r then for r, y in ipairs(r:GetChildren()) do if m(y) then e = e + 1 end end end
    local y = o.Character
    if y then for r, y in ipairs(y:GetChildren()) do if m(y) then e = e + 1 end end end
    return e
end
u4 = function(e)
    if not e and not ((h.pureTweenFarm or h.autoFarmLoop or h.teleporting or h.stealAutoTreadmill or h.autoStealBigSize)) then return end
    local r = o.Character
    local y = r and r:FindFirstChildOfClass("Humanoid")
    local u = o:FindFirstChild("Backpack")
    if y then pcall(function() y:UnequipTools() end) end
    if r and u then
        for e, r in ipairs(r:GetChildren()) do
            if r:IsA("Tool") then pcall(function() r.Parent = u end) end
        end
    end
end
w4 = function(e)
    if ((h.pureTweenFarm or h.autoFarmLoop or h.stealAutoTreadmill or h.autoStealBigSize)) and not h.holdingEggForGuard then
        local e = e4()
        if e then pcall(u4) end
        return false
    end
    local r, y = e4()
    if r then
        if e then if y == e or not y then return true end
        else return true end
    end
    local u = o.Character
    local w = u and u:FindFirstChild("HumanoidRootPart")
    if w and w.Position.X <= (E + 15) then return false end
    if s and s.ReadFieldEggs then
        local r, y = pcall(s.ReadFieldEggs)
        if r and (y and y.Records) then
            for r, y in ipairs(y.Records) do
                if ((y.State == "Carried" or y.State == 2)) and ((y.CarrierUserId == o.UserId or y.Carrier == o.UserId)) then
                    if e then if y.Uid == e then return true end
                    else return true end
                end
            end
        end
    end
    return false
end
j4 = function(e)
    local r, y = e4()
    if r then if not e or y == e or not y then return true end end
    local u = o:FindFirstChild("Backpack")
    if u then
        for r, y in ipairs(u:GetChildren()) do
            if m(y) then
                local r = y:GetAttribute("UID") or y:GetAttribute("EggUid")
                if not e or r == e or y.Name == tostring(e) then return true end
            end
        end
    end
    if e and (s and s.ReadFieldEggs) then
        local r, y = pcall(s.ReadFieldEggs)
        if r and (y and y.Records) then
            for r, y in ipairs(y.Records) do
                if y.Uid == e then
                    if (y.State == "Carried" or y.State == 2) then
                        local e = y.CarrierUserId or y.Carrier
                        if e == o.UserId then return true end
                    end
                end
            end
        end
    end
    return false
end
local m4 = false
local function ek()
    if m4 then return end
    local e = R or j:FindFirstChild("RF/EggWorld/AskFieldEggSnapshot", true) or j:FindFirstChild("AskFieldEggSnapshot", true) or j:FindFirstChild("Eggs: RequestAreaEggSnapshot", true)
    if not e or not e:IsA("RemoteFunction") then return end
    m4 = true
    task.spawn(function()
        local r, y = pcall(function() return e:InvokeServer() end)
        if r and type(y) == "table" then
            local e = {}
            local r = y.Records or y
            if type(r) == "table" then
                for r, y in pairs(r) do
                    if type(y) == "table" then
                        if not y.Uid and type(r) == "string" then y.Uid = r end
                        table.insert(e, y)
                    end
                end
            end
            if #e > 0 then F4 = e; G4 = os.clock() end
        end
        m4 = false
    end)
end
task.spawn(function()
    while true do task.wait(1.5); pcall(ek) end
end)

h4 = function(e)
    local y = os.clock()
    if e or (y - G4 >= 1.5) or not F4 then ek() end
    local u = ((F4 and #F4 > 0)) and F4 or nil
    local w = nil
    if s and s.ReadFieldEggs then
        local e, r = pcall(s.ReadFieldEggs)
        if e and type(r) == "table" then
            local e = {}
            local y = r.Records or r
            if type(y) == "table" then
                for r, y in pairs(y) do
                    if type(y) == "table" then
                        if not y.Uid and type(r) == "string" then y.Uid = r end
                        table.insert(e, y)
                    end
                end
            end
            if #e > 0 then w = e end
        end
    end
    local j = {}
    local k = {}
    if u then
        for e, r in ipairs(u) do
            if r.Uid then k[r.Uid] = true; table.insert(j, r) end
        end
    end
    if w then
        for e, r in ipairs(w) do
            if r.Uid and not k[r.Uid] then k[r.Uid] = true; table.insert(j, r) end
        end
    end
    local a = r:FindFirstChild("AreaEggSlotsClient")
    if a then
        for e, r in ipairs(a:GetChildren()) do
            local y = r.Name
            if y and y ~= "" then
                local e = r:GetPivot()
                local u = e.Position
                if u.X >= 530 and not string.find(tostring(y), "FirstArea") then
                    if not k[y] then
                        k[y] = true
                        local u = r:GetAttribute("Category") or r:GetAttribute("AssetCategory") or r.Name
                        local w = r:GetAttribute("AreaId") or r:GetAttribute("Area")
                        local a = r:GetAttribute("Rarity") or r:GetAttribute("RarityTier")
                        local V = r:GetAttribute("RarityRank") or r:GetAttribute("Rank")
                        local H = r:GetAttribute("Income") or r:GetAttribute("EarningRate")
                        local t = r:GetAttribute("Scale") or r:GetAttribute("AssetScale") or 1
                        local s = r:GetAttribute("Mutations") or r:GetAttribute("Mutation")
                        table.insert(j, { ["Uid"]=y, ["AssetCategory"]=u, ["AreaId"]=w, ["Rarity"]=a, ["Rank"]=V, ["Income"]=H, ["BoundsCFrame"]=e, ["BottomCFrame"]=e, ["CFrame"]=e, ["State"]="
                    else
                        for u, w in ipairs(j) do
                            if w.Uid == y then
                                w.PhysicalModel = r
                                if not w.BoundsCFrame then w.BoundsCFrame = e end
                                if not w.AreaId or w.AreaId == "" or w.AreaId == "Unknown" then w.AreaId = r:GetAttribute("AreaId") or r:GetAttribute("Area") end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return j
end

k4 = function(e)
    if not e then return false, "NoUid" end
    local y = h4(false)
    if y and #y > 0 then
        for r, y in ipairs(y) do
            if y.Uid == e then
                if (y.State == "Carried" or y.State == 2) then
                    local e = y.CarrierUserId or y.Carrier
                    if e and e == o.UserId then return true, "CarriedBySelf"
                    else return false, "CarriedByOther" end
                end
                if (y.State == "Slot" or y.State == "Dropped" or y.State == "GuardCarried" or y.State == 1) then return true, "Available" end
                local e = y.CarrierUserId or y.Carrier
                if e then
                    if e == o.UserId then return true, "CarriedBySelf"
                    else return false, "CarriedByOther" end
                end
                return true, "Available"
            end
        end
    end
    local u = r:FindFirstChild("AreaEggSlotsClient")
    if u then
        for r, y in ipairs(u:GetChildren()) do
            if y.Name == tostring(e) or y:GetAttribute("UID") == e or y:GetAttribute("Uid") == e then return true, "Available" end
        end
        return true, "Unchecked"
    end
end

a4 = function()
    local e, r = e4()
    if not r then local e, y = r4(); r = y end
    if not r then return false end
    if s and s.ReadFieldEggs then
        local e, u = pcall(s.ReadFieldEggs)
        if e and (u and u.Records) then
            for e, u in ipairs(u.Records) do
                if u.Uid == r then
                    local e = tostring(u.AreaId or "")
                    if e == "Lake" or string.find(string.lower(e), "lake") ~= nil then return true end
                end
            end
        end
    end
    if string.find(string.lower(tostring(r)), "lake") ~= nil then return true end
    return false
end

o4 = function()
    local e, r = e4()
    if not r then local e, y = r4(); r = y end
    if not r then return h.glideSpeed or 350 end
    if s and s.ReadFieldEggs then
        local e, u = pcall(s.ReadFieldEggs)
        if e and (u and u.Records) then
            for e, u in ipairs(u.Records) do
                if u.Uid == r and u.AreaId then return I[u.AreaId] or h.glideSpeed or 350 end
            end
        end
    end
    return h.glideSpeed or 350
end

V4 = function(e, y)
    y = y or 8
    local u = Instance.new("Part")
    u.Name = "SafetyFloorPad_AntiVoid"
    u.Size = Vector3.new(28, 1.5, 28)
    u.Position = e - Vector3.new(0, 3.2, 0)
    u.Anchored = true
    u.Transparency = 1
    u.CanCollide = true
    u.Parent = r
    task.delay(y, function() pcall(function() u:Destroy() end) end)
    return u
end

H4 = function(e)
    if P and e then
        pcall(function()
            local r = o.Character
            local y = r and r:FindFirstChild("HumanoidRootPart")
            local u = y and (y.CFrame * CFrame.new(0, 0, -3)) or CFrame.new()
            if P:IsA("RemoteFunction") then
                P:InvokeServer({ ["EggUid"]=e, ["GuardCFrame"]=u })
            else
                P:FireServer({ ["EggUid"]=e, ["GuardCFrame"]=u })
            end
        end)
    end
end

if typeof(hookmetamethod) == "function" and not _G._DesyncAntiRagdollHooked then
    _G._DesyncAntiRagdollHooked = true
    local oldIdx
    oldIdx = hookmetamethod(game, "__newindex", safeNewCClosure(function(r, y2, u2)
        if not executorCheckCaller() and typeof(r) == "Instance" then
            local farmActive = h and (
                h.pureTweenFarm or h.autoFarmLoop or h.teleporting or
                h.glidingToTarget or h.isReturning or h.securingEgg or
                h.delivering or h.holdingEggForGuard or h.onTreadmill or
                h.stealAutoTreadmill or h.autoStealBigSize
            )
            if farmActive then
                if r:IsA("Motor6D") and (y2 == "Enabled" and u2 == false) then return nil end
                if r:IsA("Humanoid") then
                    if y2 == "PlatformStand" and u2 == true then return nil end
                    if y2 == "Sit" and u2 == true then return nil end
                end
            end
        end
        return oldIdx(r, y2, u2)
    end))
end

S4 = function(e)
    e = e or o.Character
    if not e then return end
    local r = e:FindFirstChild("HumanoidRootPart")
    local y = e:FindFirstChild("Torso") or e:FindFirstChild("UpperTorso") or r
    if not y then return end

    local farmActive = h and (
        h.pureTweenFarm or h.autoFarmLoop or h.teleporting or
        h.glidingToTarget or h.isReturning or h.securingEgg or
        h.delivering or h.holdingEggForGuard or h.onTreadmill or
        h.autoKillScramble or h.stealAutoTreadmill or h.autoStealBigSize
    )

    if farmActive then
        for _, inst in ipairs(e:GetDescendants()) do
            if inst:IsA("BallSocketConstraint")
               or inst:IsA("HingeConstraint")
               or inst:IsA("NoCollisionConstraint") then
                pcall(function() inst:Destroy() end)
            end
        end
    end

    for _, m2 in ipairs(e:GetDescendants()) do
        if m2:IsA("Motor6D") and m2.Part0 and m2.Part1 then
            if farmActive then
                m2.Enabled = true
                local weldName = "RigidJointWeld_" .. m2.Name
                local existing = m2.Part1:FindFirstChild(weldName)
                if not existing then
                    local weld = Instance.new("WeldConstraint")
                    weld.Name = weldName
                    weld.Part0 = m2.Part0
                    weld.Part1 = m2.Part1
                    weld.Parent = m2.Part1
                end
            else
                m2.Enabled = true
                local weldName = "RigidJointWeld_" .. m2.Name
                local existing = m2.Part1:FindFirstChild(weldName)
                if existing then
                    pcall(function() existing:Destroy() end)
                end
            end
        end
    end

    if not farmActive then
        releaseRigidWelds(e)
    end
end

Z4 = function(e)
    if h and h.onTreadmill then return end
    e = e or o.Character
    if not e then return end

    local farmActive = h and (
        h.pureTweenFarm or h.autoFarmLoop or h.teleporting or
        h.glidingToTarget or h.isReturning or h.securingEgg or
        h.delivering or h.holdingEggForGuard
    )

    local r = e:FindFirstChildOfClass("Humanoid")
    if r then
        if farmActive then
            pcall(function()
                r:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                r:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                r:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                r:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                r:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                if r.PlatformStand then r.PlatformStand = false end
