local playerJob = nil

local animationsEnabled = true
local weaponAdjustDict = 'reaction@intimidation@1h'
local weaponAdjustAnim = 'intro'
local weaponAdjustTime = 1000 
local isDrawingWeapon = false

local weaponAttached = false
local smallWeaponAttached = false
local weaponEquipped = nil
local smallWeaponEquipped = nil
local attachedWeapons = {}

local animations = {
    small = {
        dict = 'reaction@intimidation@1h',
        anim = 'intro',
        duration = 2500,
        flag = 50 
    },
    large = {
        dict = 'reaction@intimidation@1h',
        anim = 'intro',
        duration = 2500,
        flag = 50
    },
    default = {
        dict = 'reaction@intimidation@1h',
        anim = 'intro',
        duration = 2500,
        flag = 50
    },
    holster = {
        dict = 'reaction@intimidation@1h',
        anim = 'outro',
        duration = 1200,
        flag = 50
    },
    police = {
        draw = {
            dict = "rcmjosh4",
            anim = "josh_leadout_cop2",
            duration = 1000,
            flag = 50
        },
        holster = {
            dict = "reaction@intimidation@cop@unarmed",
            anim = "intro",
            duration = 1000,
            flag = 50
        }
    }
}

local weaponDrawCooldown = false
local skipNextAnimation = false
local recentlyUsedQuickslot = false
local lastWeaponName = nil
local lastWeaponHash = nil

local meleeWeapons = {
    "WEAPON_KNIFE", "WEAPON_KNUCKLE", "WEAPON_NIGHTSTICK", "WEAPON_HAMMER", "WEAPON_BAT",
    "WEAPON_GOLFCLUB", "WEAPON_CROWBAR", "WEAPON_BOTTLE", "WEAPON_DAGGER", "WEAPON_HATCHET",
    "WEAPON_MACHETE", "WEAPON_FLASHLIGHT", "WEAPON_SWITCHBLADE", "WEAPON_POOLCUE", "WEAPON_WRENCH",
    "WEAPON_BATTLEAXE", "WEAPON_STONE_HATCHET", "WEAPON_UNARMED", "WEAPON_KATANA", "WEAPON_SLEDGEHAMMER",
    "WEAPON_KEYBOARD", "WEAPON_KRAMBIT", "WEAPON_SWORD", "WEAPON_RIFTEDGE", "WEAPON_DILDO", "WEAPON_CANDYCANE"
}

RegisterNetEvent('esx:setPlayerData', function(key, val)
    if key == 'job' then
        playerJob = val.name
    end
end)

Citizen.CreateThread(function()
    while playerJob == nil do
        if ESX and ESX.PlayerData and ESX.PlayerData.job then
            playerJob = ESX.PlayerData.job.name
        end
        Citizen.Wait(100)
    end
end)

local function IsMeleeWeapon(weaponName)
    for _, weapon in ipairs(meleeWeapons) do
        if weaponName == weapon then
            return true
        end
    end
    return false
end

local function IsSmallWeapon(weaponHash)
    for _, weapon in ipairs(Config.SmallAttachableWeapons) do
        if GetHashKey(weapon) == weaponHash then
            return true
        end
    end
    return false
end

local function IsLargeWeapon(weaponHash)
    for _, weapon in ipairs(Config.AttachableWeapons) do
        if GetHashKey(weapon) == weaponHash then
            return true
        end
    end
    return false
end

Citizen.CreateThread(function()
    for _, animData in pairs(animations) do
        if type(animData) == "table" and animData.dict then
            RequestAnimDict(animData.dict)
            while not HasAnimDictLoaded(animData.dict) do
                Citizen.Wait(10)
            end
        elseif type(animData) == "table" then
            for _, subAnim in pairs(animData) do
                if type(subAnim) == "table" and subAnim.dict then
                    RequestAnimDict(subAnim.dict)
                    while not HasAnimDictLoaded(subAnim.dict) do
                        Citizen.Wait(10)
                    end
                end
            end
        end
    end
end)

function DisableActionsWhileAnimating()
    Citizen.CreateThread(function()
        while isDrawingWeapon do
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            Citizen.Wait(0)
        end
    end)
end

function PlayWeaponAnimation(weapon)
    if not weapon or weaponDrawCooldown then return end
    if skipNextAnimation or recentlyUsedQuickslot then
        skipNextAnimation = false
        recentlyUsedQuickslot = false
        return
    end
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then return end
    local weaponName = string.upper(weapon.name)
    if IsMeleeWeapon(weaponName) then return end
    local animData = animations.default
    if playerJob == "police" or playerJob == "sheriff" then
        animData = animations.police.draw
    end
    if not HasAnimDictLoaded(animData.dict) then
        RequestAnimDict(animData.dict)
        while not HasAnimDictLoaded(animData.dict) do Citizen.Wait(10) end
    end
    isDrawingWeapon = true
    DisableActionsWhileAnimating()
    TaskPlayAnim(playerPed, animData.dict, animData.anim, 8.0, -8.0, animData.duration, animData.flag, 0, false, false, false)
    TriggerServerEvent("f1f_sling:syncAnimation", animData.dict, animData.anim, animData.duration, animData.flag)
    weaponDrawCooldown = true
    Citizen.SetTimeout(animData.duration, function()
        ClearPedTasks(playerPed)
        weaponDrawCooldown = false
        isDrawingWeapon = false
    end)
end

function PlayHolsterAnimation(callback)
    local playerPed = PlayerPedId()
    local animData = animations.holster
    if playerJob == "police" or playerJob == "sheriff" then
        animData = animations.police.holster
    end
    if not HasAnimDictLoaded(animData.dict) then
        RequestAnimDict(animData.dict)
        while not HasAnimDictLoaded(animData.dict) do Citizen.Wait(10) end
    end
    isDrawingWeapon = true
    DisableActionsWhileAnimating()
    TaskPlayAnim(playerPed, animData.dict, animData.anim, 8.0, -8.0, animData.duration, animData.flag, 0, false, false, false)
    TriggerServerEvent("f1f_sling:syncAnimation", animData.dict, animData.anim, animData.duration, animData.flag)
    Citizen.SetTimeout(animData.duration, function()
        ClearPedTasks(playerPed)
        isDrawingWeapon = false
        if callback then callback() end
    end)
end

RegisterNetEvent('f1f_sling:playNetworkedAnim')
AddEventHandler('f1f_sling:playNetworkedAnim', function(playerId, dict, anim, duration, flag)
    local playerPed = GetPlayerPed(GetPlayerFromServerId(playerId))
    
    if playerPed ~= PlayerPedId() and DoesEntityExist(playerPed) then
        if not HasAnimDictLoaded(dict) then
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(10)
            end
        end
        
        TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, duration, flag, 0, false, false, false)
        
        Citizen.SetTimeout(duration, function()
            if DoesEntityExist(playerPed) then
                ClearPedTasks(playerPed)
            end
        end)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if skipNextAnimation then
            if IsControlJustPressed(0, 157) or IsControlJustPressed(0, 158) or 
               IsControlJustPressed(0, 160) or IsControlJustPressed(0, 161) or 
               IsControlJustPressed(0, 162) then
                quickslotKeysPressed = true
                quickslotTimer = GetGameTimer() + 3000 
            end
        end
        
        if quickslotKeysPressed and GetGameTimer() > quickslotTimer then
            quickslotKeysPressed = false
        end
    end
end)

AddEventHandler('ox_inventory:currentWeapon', function(weapon)
    if not weapon then
        if lastWeaponName or lastWeaponHash then
            PlayHolsterAnimation(function()
                lastWeaponName = nil
                lastWeaponHash = nil
            end)
        else
            lastWeaponName = nil
            lastWeaponHash = nil
        end
        return 
    end

    local weaponName = weapon.name
    local weaponHash = GetHashKey(weaponName)

    if quickslotKeysPressed then
        quickslotKeysPressed = false
        lastWeaponName = weaponName
        lastWeaponHash = weaponHash
        return
    end
    local skipAnim = exports.f1f_sling:GetSkipNextAnimation()
    local skipAnim = exports.f1f_sling:GetSkipNextAnimation()
    if skipAnim then
        exports.f1f_sling:SetSkipNextAnimation(false)
        return
    end
    if lastWeaponName == weaponName or lastWeaponHash == weaponHash then
        lastWeaponName = weaponName
        lastWeaponHash = weaponHash
        return
    end
    exports.f1f_sling:PlayWeaponAnimation(weapon)
    lastWeaponName = weaponName
    lastWeaponHash = weaponHash
end)

exports('SetSkipNextAnimation', function(skip)
    skipNextAnimation = skip
end)

exports('PlayWeaponAnimation', PlayWeaponAnimation)

exports('GetSkipNextAnimation', function()
    return skipNextAnimation
end)