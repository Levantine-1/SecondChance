local player
local function LoadPlayerData()
	player = getPlayer()
	modData = player:getModData()
	modData.ICdata = modData.ICdata or {}
	modData.ICdata.infectionStartedTime = modData.ICdata.infectionStartedTime or nil
    modData.ICdata.infectionVector = modData.ICdata.infectionVector or nil
    modData.ICdata.failedSavingThrow = modData.ICdata.infectionCheck or false
end
Events.OnGameStart.Add(LoadPlayerData)


local function ResetInfectionData()
    if player then
        player = getPlayer() -- Reinitialize player variable
        modData.ICdata.infectionStartedTime = nil
        modData.ICdata.infectionVector = nil
        modData.ICdata.failedSavingThrow = false
        print("Infection data reset for new character.")
    end
end
Events.OnCreatePlayer.Add(ResetInfectionData) -- Reset infection data when a new character is created in the event of a respawn


local function calculateBonusSavingThrow() -- Calculate the player's bonus saving throw based on their occupation and traits and first aid skill
    local bonusSavingThrow = 0

    -- ---------------------- Saving Throw From Occupation ----------------------
    local occupation = player:getDescriptor():getProfession()
    if occupation == "doctor" then
        bonusSavingThrow = bonusSavingThrow + 5
        -- print("Occupation: Doctor - Saving Throw: " .. bonusSavingThrow)
    end
    if occupation == "nurse" then
        bonusSavingThrow = bonusSavingThrow + 3
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

    -- 2025-14-04 For now debuffs don't work because the traits are not well documented and I'm too lazy to figure it out right now
        -- -- ---------------------- Debuff From Traits ----------------------
        -- local relatedDebuffTraits = {"Emaciated", "SlowHealer", "ThinSkinned", "ProneToIllness"}
        -- local traits = player:getTraits()
        -- -- maxSavingThrowDebuffsFromTraits = 3 -- No limit to debuffs
        -- for i = 0, traits:size() - 1 do
        --     for _, relatedDebuffTrait in ipairs(relatedDebuffTraits) do
        --         if traits:get(i) == relatedDebuffTrait then
        --             savingThrowFromTraits = savingThrowFromTraits - 1
        --             -- print("Trait: " .. relatedTrait .. " subracts 1 saving throw)
        --         end
        --     end
        -- end

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


local advantagedRoll = false
local function checkDoesPlayerSurvive()
    currentDCcheck = calculateDifficultyClass()
    if currentDCcheck == 0 then
        return false -- Player has been infected for too long, no chance to save yourself
    end

    bonusSavingThrows = calculateBonusSavingThrow()

    local d20 = ZombRand(1, 20) -- Roll a d20

    local totalRoll = d20 + bonusSavingThrows

    if advantagedRoll and (totalRoll < currentDCcheck) then -- If the player has advantage and the first roll fails, roll again
        local d20Adv = ZombRand(1, 20) -- Roll a d20 with advantage
        totalRoll = d20Adv + bonusSavingThrows
    end

    print("Rolled a " .. d20 .. " + " .. bonusSavingThrows .. " = " .. totalRoll .. " vs DC: " .. currentDCcheck)

    if (totalRoll >= currentDCcheck) or (d20 == 20) then -- Player has succeeded the saving throw, or rolled a natural 20
        if d20 == 20 then
            local stats = player:getStats()
            stats:setFatigue(0.0)                   -- Resets fatigue
            stats:setEndurance(1.0)                 -- Resets endurance
        end
        return true -- Player has succeeded the saving throw
    else
        if d20 == 1 then
            player:setOnFire(true)
        end
        return false -- Player has failed the saving throw, but not a critical failure
    end
end


local function playerWillDie()
    print("Player has failed the infection check!")
    modData.ICdata.failedSavingThrow = true
end


local function playerWillSurvive()
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then
        print("Error: bodyDamage is nil in playerWillSurvive")
        return
    end

    -- Iterate over all body parts and remove infection
    local bodyParts = bodyDamage:getBodyParts()
    for i = 0, bodyParts:size() - 1 do
        local bodyPart = bodyParts:get(i)
        bodyPart:SetInfected(false) -- Remove infection from body part
    end

    -- Reset global infection state and related values
    bodyDamage:setInfected(false) -- Remove real infection status
    bodyDamage:setInfectionLevel(0.0) -- Reset infection level
    bodyDamage:setInfectionTime(-1.0) -- Reset infection time
    bodyDamage:setInfectionMortalityDuration(-1.0) -- Reset mortality duration
    bodyDamage:setIsFakeInfected(true) -- Make the player squrim

    -- Clear mod data
    modData.ICdata.infectionStartedTime = nil
    modData.ICdata.infectionVector = nil
    print("Player has survived the infection check!")
end


local function CheckForInfection()
    if not player:getBodyDamage():IsInfected() and modData.ICdata.infectionStartedTime ~= nil then
        print("Somehow the player is no longer infected, resetting infection start time")
        ResetInfectionData()
    end

    if modData.ICdata.failedSavingThrow == true then
        return -- Player has already failed the saving throw, no need to check again, they will die
    end

    if player:getBodyDamage():IsInfected() and modData.ICdata.infectionStartedTime == nil then -- player first becomes infected
        local currentTime = getGameTime():getWorldAgeHours()
        if checkUntreatedBiteWounds() then
            modData.ICdata.infectionVector = "bite"
            print("Player has been bitten!")
        end
        print("Player is infected! Infection began at: " .. currentTime)
        modData.ICdata.infectionStartedTime = currentTime
    end

    -- Monitor infection status every minute until player treats the infection
    if player:getBodyDamage():IsInfected() and modData.ICdata.infectionStartedTime ~= nil and modData.ICdata.infectionVector == "bite" then
        if checkUntreatedBiteWounds() then
            return -- player is still has untreated bite wounds, do nothing
        elseif checkUntreatedBiteWounds() == false then
            if checkDoesPlayerSurvive() then
                playerWillSurvive()
            else
                playerWillDie()
            end
        end
    end
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
    print("Failed Saving Throw Status: " .. tostring(modData.ICdata.failedSavingThrow))
end
-- Events.EveryTenMinutes.Add(PrintStatus) -- Uncomment this line to print status every 10 minutes for debugging


Events.EveryOneMinute.Add(CheckForInfection)
