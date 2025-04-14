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

local function calculateBonusSavingThrow() -- Calculate the player's bonus saving throw based on their occupation and traits and first aid skill
    local bonusSavingThrow = 0

    -- ---------------------- Saving Throw From Occupation ----------------------
    local occupation = player:getDescriptor():getProfession()
    if occupation == "doctor" then
        savbonusSavingThrowingThrow = bonusSavingThrow + 5
        -- print("Occupation: Doctor - Saving Throw: " .. bonusSavingThrow)
    end
    if occupation == "nurse" then
        bonusSavingThrow = bonusSavingThrow + 2
        -- print("Occupation: Nurse - Saving Throw: " .. bonusSavingThrow)
    end
    local relatedOccupations = {"policeofficer", "fireofficer", "parkranger", "veteran", "securityguard"}
    for _, relatedOccupation in ipairs(relatedOccupations) do
        if occupation == relatedOccupation then
            bonusSavingThrow = bonusSavingThrow + 1
            -- print("Occupation: " .. relatedOccupation .. " - Saving Throw: " .. bonusSavingThrow)
        end
    end

    -- ---------------------- Saving Throw From Traits ----------------------
    local relatedTraits = {"FirstAid", "FastHealer", "Resilient", "ThickSkinned", "Dextrous", "Strong", "Athletic", "Outdoorsman", "Lucky"}
    local traits = player:getTraits()
    maxSavingThrowFromTraits = 3
    savingThrowFromTraits = 0
    for i = 0, traits:size() - 1 do
        for _, relatedTrait in ipairs(relatedTraits) do
            if traits:get(i) == relatedTrait then
                savingThrowFromTraits = savingThrowFromTraits + 1
                -- print("Trait: " .. relatedTrait .. " adds 1 Saving Throw for a MAX of: " .. maxSavingThrowFromTraits)
            end
        end
    end
    if savingThrowFromTraits > maxSavingThrowFromTraits then
        bonusSavingThrow = bonusSavingThrow + maxSavingThrowFromTraits
        -- print("Saving Throw from Traits: " .. maxSavingThrowFromTraits .. " Total Bonus Saving Throw: " .. bonusSavingThrow)
    else
        bonusSavingThrow = bonusSavingThrow + savingThrowFromTraits
        -- print("Saving Throw from Traits: " .. savingThrowFromTraits .. " Total Bonus Saving Throw: " .. bonusSavingThrow)
    end

    -- ---------------------- Saving Throw From First Aid Skill ----------------------
    local firstAidLevel = player:getPerkLevel(Perks.Doctor)
    if firstAidLevel >= 6 then
        bonusSavingThrow = bonusSavingThrow + firstAidLevel - 5
        -- print("First Aid Level: " .. firstAidLevel .. " - Saving Throw: " .. bonusSavingThrow)
    end

    -- print("Final Saving Throw: " .. bonusSavingThrow)
    return bonusSavingThrow
end

local function calculateDifficultyClass()
    local difficultyClass = 16 -- Base DC for infection check 20% chance to save yourself by default at 0 minutes after bite

    infectionStartedTime = modData.ICdata.infectionStartedTime
    if infectionStartedTime == nil then
        return difficultyClass
    end

    local currentTime = getGameTime():getWorldAgeHours()
    local elapsedInfectionTimeMinutes = math.floor((currentTime - modData.ICdata.infectionStartedTime) * 60)

    if elapsedInfectionTimeMinutes > 60 then
        difficultyClass = 0 -- If you've been infected for longer than an hour, you're screwed and there is no possible way to save yourself, not even d20
    elseif elapsedInfectionTimeMinutes <= 60 then
        local bonusDifficultyPoints = math.ceil(elapsedInfectionTimeMinutes / 3) -- 1 point of DC for every 3 minutes of infection time
        difficultyClass = difficultyClass + bonusDifficultyPoints
    end

    return difficultyClass
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

    print("Current Bonus Saving Throw: " .. calculateBonusSavingThrow())
    print("Current Difficulty Class: " .. calculateDifficultyClass())
end

Events.EveryOneMinute.Add(CheckForInfection)
Events.EveryTenMinutes.Add(PrintStatus)

