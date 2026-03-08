-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Core/LearningEngine.lua
--   📁 Dossier : AI/Core/
--   Rôle : Moteur d'apprentissage automatique
--          S'améliore à chaque session sans intervention
-- ══════════════════════════════════════════════════════

local LearningEngine = {}

local HS   = game:GetService("HttpService")
local FILE = "NexusESP/ai_profile.json"
local MAX_MEM = 500

local profile = {
    version     = 1,
    sessions    = 0,
    aim = {
        avgError   = 5.0,
        bestSmooth = 10,
        hitRate    = 0.0,
        rewards    = 0,
        penalties  = 0,
    },
    movement = {
        avgSpeed  = 16,
        jumpFreq  = 0.1,
        strafeRate = 0.5,
    },
    enemies = {},
    history = {},
}

function LearningEngine.Init(deps)
    LearningEngine.Load()
    profile.sessions = profile.sessions + 1
    print("[AI/Learning] Session #"..profile.sessions.." ✓")
end

function LearningEngine.Save()
    pcall(function()
        if not isfolder("NexusESP") then makefolder("NexusESP") end
        writefile(FILE, HS:JSONEncode(profile))
    end)
end

function LearningEngine.Load()
    local ok, data = pcall(function()
        return HS:JSONDecode(readfile(FILE))
    end)
    if ok and data then
        for k, v in pairs(data) do
            if profile[k] ~= nil then profile[k] = v end
        end
        print("[AI/Learning] Profil chargé ✓")
    else
        print("[AI/Learning] Nouveau profil")
    end
end

function LearningEngine.Reward(action, mag)
    mag = mag or 1
    if action == "aim_hit" then
        profile.aim.rewards  = profile.aim.rewards + mag
        profile.aim.hitRate  = profile.aim.rewards / math.max(1, profile.aim.rewards + profile.aim.penalties)
        profile.aim.bestSmooth = math.max(1, profile.aim.bestSmooth - 0.1 * mag)
    end
    table.insert(profile.history, {action=action, value=mag, positive=true, time=os.clock()})
    if #profile.history > MAX_MEM then table.remove(profile.history, 1) end
end

function LearningEngine.Penalize(action, mag)
    mag = mag or 1
    if action == "aim_miss" then
        profile.aim.penalties = profile.aim.penalties + mag
        profile.aim.hitRate   = profile.aim.rewards / math.max(1, profile.aim.rewards + profile.aim.penalties)
        profile.aim.bestSmooth = math.min(30, profile.aim.bestSmooth + 0.2 * mag)
    end
    table.insert(profile.history, {action=action, value=mag, positive=false, time=os.clock()})
    if #profile.history > MAX_MEM then table.remove(profile.history, 1) end
end

function LearningEngine.UpdateEnemy(userId, data)
    local id = tostring(userId)
    if not profile.enemies[id] then
        profile.enemies[id] = {encounters=0, avgSpeed=16, movePattern="unknown", hitRate=0}
    end
    local ep = profile.enemies[id]
    ep.encounters = ep.encounters + 1
    if data.speed   then ep.avgSpeed    = ep.avgSpeed * 0.8 + data.speed * 0.2 end
    if data.pattern then ep.movePattern = data.pattern end
end

function LearningEngine.GetOptimalSmooth() return math.floor(profile.aim.bestSmooth) end
function LearningEngine.GetHitRate()       return profile.aim.hitRate end
function LearningEngine.GetEnemyProfile(userId) return profile.enemies[tostring(userId)] end
function LearningEngine.GetProfile()       return profile end

function LearningEngine.Reset()
    profile.aim     = {avgError=5, bestSmooth=10, hitRate=0, rewards=0, penalties=0}
    profile.enemies = {}
    profile.history = {}
    LearningEngine.Save()
end

return LearningEngine
