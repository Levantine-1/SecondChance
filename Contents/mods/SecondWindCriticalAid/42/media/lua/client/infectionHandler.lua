print("LEVANTINE MOD LOADED")
local player
local function LoadPlayerData()
	player = getPlayer()
	modData = player:getModData()
	modData.ICdata = modData.ICdata or {}
	modData.ICdata.infectionStartedTime = modData.ICdata.infectionStartedTime or nil
end
Events.OnGameStart.Add(LoadPlayerData)

local function ResetInfectionData()
    if player then
        player = getPlayer() -- Reinitialize player variable
        modData.ICdata.infectionStartedTime = nil
        print("Infection data reset for new character.")
    end
end
Events.OnCreatePlayer.Add(ResetInfectionData) -- Reset infection data when a new character is created in the event of a respawn


local function CheckForInfection()
    if player:getBodyDamage():IsInfected() and modData.ICdata.infectionStartedTime ~= nil then
        return -- happy (or rather unhappy) path, possible race condition if in debug mode and rapidly set and unset infected
    
    elseif player:getBodyDamage():IsInfected() and modData.ICdata.infectionStartedTime == nil then
        local currentTime = getGameTime():getWorldAgeHours()
        print("Player is infected! Infection began at: " .. currentTime)
        modData.ICdata.infectionStartedTime = currentTime

    elseif not player:getBodyDamage():IsInfected() and modData.ICdata.infectionStartedTime ~= nil then
        print("Somehow the player is no longer infected, resetting infection start time")
        modData.ICdata.infectionStartedTime = nil
    end
end

local function checkUntreatedBiteWounds() -- check if player has untreated bite wounds
    local bodyDamage = player:getBodyDamage()
    local bodyParts = bodyDamage:getBodyParts()
    for i = 0, bodyParts:size() - 1 do
        local bodyPart = bodyParts:get(i)
        -- print("Checking body part: " .. BodyPartType.getDisplayName(bodyPart:getType()))
        -- Check for infected wounds that are not disinfected. Poutices won't help here, only modern medicine will do
        if bodyPart:bitten() and bodyPart:getAlcoholLevel() < 1 then
            -- print("Untreated bite wound found on body part: " .. BodyPartType.getDisplayName(bodyPart:getType()))
            return true
        end
    end
    return false -- no untreated bite wounds found
end
Events.EveryOneMinute.Add(checkUntreatedBiteWounds)

local function PrintStatus() -- Purely for debug purposes, will be removed in the future
    print("Infection Start Time: " .. tostring(modData.ICdata.infectionStartedTime))
    local currentTime = getGameTime():getWorldAgeHours()
    print("Current Time: " .. currentTime)
    if modData.ICdata.infectionStartedTime ~= nil then
        local bodyDamage = player:getBodyDamage()
        if bodyDamage:IsInfected() then
            local elapsedInfectionTime = (currentTime - modData.ICdata.infectionStartedTime) * 60
            print("Time Since Infection: " .. math.floor(elapsedInfectionTime) .. " minutes")
        end
    end

    if checkUntreatedBiteWounds() then
        print("Player has untreated bite wound(s)!")
    end
end

local function DidPlayerSurvive(infected)
    if infected == false then
        print("You'll be fine")
    else
        print("You dead son")
    end
end
    

Events.EveryOneMinute.Add(CheckForInfection)
Events.EveryTenMinutes.Add(PrintStatus)

