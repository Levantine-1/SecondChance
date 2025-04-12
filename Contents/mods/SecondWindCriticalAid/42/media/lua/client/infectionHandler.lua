print("LEVANTINE MOD LOADED")
local player
local function LoadPlayerData()
	player = getPlayer()
	modData = player:getModData()
	modData.ICdata = modData.ICdata or {}
	modData.ICdata.infectionStartedTime = modData.ICdata.infectionStartedTime or nil
end
Events.OnGameStart.Add(LoadPlayerData)


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

local function PrintStatus()
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

