local ESX = exports.es_extended:getSharedObject()
local slingWeapon = nil
local isSlinged = false
local slingObj = nil
local skipNextAnimation = false
local position = nil
local smallPosition = nil
local isAdjusting = false
local isAdjustingSmall = false
local controlsUiVisible = false
local weaponObject = nil
local smallWeaponObject = nil
local positionsLoaded = false

local controls = {
    ["LEFT"] = "LEFT ARROW (left)",
    ["RIGHT"] = "RIGHT ARROW (right)",
    ["UP"] = "UP ARROW (up)",
    ["DOWN"] = "DOWN ARROW (down)",
    ["J"] = "J (forward)",
    ["L"] = "L (backward)",
    ["COMMA"] = ", (tilt +)",
    ["PERIOD"] = ". (tilt -)",
    ["SEMICOLON"] = "; (rotation +)",
    ["APOSTROPHE"] = "' (rotation -)",
    ["WHEEL_UP"] = "MOUSE WHEEL UP (yaw +)",
    ["WHEEL_DOWN"] = "MOUSE WHEEL DOWN (yaw -)",
    ["ENTER"] = "ENTER to SAVE and exit",
    ["ESC"] = "ESC to CANCEL adjustment"
}

local function getWeaponModelAndPosition(weapon)
    if Config.AttachableWeapons[weapon] then
        return Config.AttachableWeapons[weapon], position or Config.DefaultLargeWeaponPosition
    elseif Config.SmallAttachableWeapons[weapon] then
        return Config.SmallAttachableWeapons[weapon], smallPosition or Config.DefaultSmallWeaponPosition
    end
    return nil, nil
end

local function attachSlingWeapon(weapon)
    if slingObj then DeleteEntity(slingObj) slingObj = nil end
    local ped = PlayerPedId()
    local model, pos = getWeaponModelAndPosition(weapon)
    if not model or not pos then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local obj = CreateObject(GetHashKey(model), 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 24818), pos.x, pos.y, pos.z, pos.pitch, pos.roll, pos.yaw, false, false, false, false, 2, true)
    slingObj = obj
    weaponObject = obj
end

local function attachSmallSlingWeapon(weapon)
    if smallWeaponObject then DeleteEntity(smallWeaponObject) smallWeaponObject = nil end
    local ped = PlayerPedId()
    local model, pos = getWeaponModelAndPosition(weapon)
    if not model or not pos then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local obj = CreateObject(GetHashKey(model), 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 24818), pos.x, pos.y, pos.z, pos.pitch, pos.roll, pos.yaw, false, false, false, false, 2, true)
    smallWeaponObject = obj
end

local function detachSlingWeapon()
    if slingObj then DeleteEntity(slingObj) slingObj = nil end
    weaponObject = nil
end

local function detachSmallSlingWeapon()
    if smallWeaponObject then DeleteEntity(smallWeaponObject) smallWeaponObject = nil end
end

local function UpdateWeaponPosition()
    if weaponObject and DoesEntityExist(weaponObject) then
        local ped = PlayerPedId()
        AttachEntityToEntity(
            weaponObject,
            ped,
            GetPedBoneIndex(ped, 24818),
            position.x, position.y, position.z,
            position.pitch, position.roll, position.yaw,
            false, false, false, false, 2, true
        )
    end
end

local function UpdateSmallWeaponPosition()
    if smallWeaponObject and DoesEntityExist(smallWeaponObject) then
        local ped = PlayerPedId()
        AttachEntityToEntity(
            smallWeaponObject,
            ped,
            GetPedBoneIndex(ped, 24818),
            smallPosition.x, smallPosition.y, smallPosition.z,
            smallPosition.pitch, smallPosition.roll, smallPosition.yaw,
            false, false, false, false, 2, true
        )
    end
end

local function ShowControlsUI()
    if not controlsUiVisible then
        if isAdjusting then
            controlsUiVisible = true
            SendNUIMessage({
                action = "showControls",
                data = {
                    position = position or Config.DefaultLargeWeaponPosition,
                    controls = controls,
                    weaponType = "large"
                }
            })
        elseif isAdjustingSmall then
            controlsUiVisible = true
            SendNUIMessage({
                action = "showControls",
                data = {
                    position = smallPosition or Config.DefaultSmallWeaponPosition,
                    controls = controls,
                    weaponType = "small"
                }
            })
        end
    end
end

local function UpdateControlsUI()
    if controlsUiVisible then
        if isAdjusting then
            SendNUIMessage({
                action = "updatePosition",
                data = {
                    position = position or Config.DefaultLargeWeaponPosition
                }
            })
        elseif isAdjustingSmall then
            SendNUIMessage({
                action = "updatePosition",
                data = {
                    position = smallPosition or Config.DefaultSmallWeaponPosition
                }
            })
        end
    end
end

local function SaveCurrentPosition()
    if isAdjusting then
        isAdjusting = false
        controlsUiVisible = false
        SendNUIMessage({action = "hideControls"})
        TriggerServerEvent('f1f_sling:savePos', position)
        if weaponObject then DeleteEntity(weaponObject) weaponObject = nil end
        if slingObj then DeleteEntity(slingObj) slingObj = nil end
    elseif isAdjustingSmall then
        isAdjustingSmall = false
        controlsUiVisible = false
        SendNUIMessage({action = "hideControls"})
        TriggerServerEvent('f1f_sling:saveSmall', smallPosition)
        if smallWeaponObject then DeleteEntity(smallWeaponObject) smallWeaponObject = nil end
    end
end

local function CancelAdjustment()
    isAdjusting = false
    isAdjustingSmall = false
    controlsUiVisible = false
    SendNUIMessage({action = "hideControls"})
    TriggerServerEvent('f1f_sling:checkPos')
    if weaponObject then DeleteEntity(weaponObject) weaponObject = nil end
    if slingObj then DeleteEntity(slingObj) slingObj = nil end
    if smallWeaponObject then DeleteEntity(smallWeaponObject) smallWeaponObject = nil end
end

RegisterCommand('holster', function()
    if isSlinged then return end
    if not positionsLoaded then
        TriggerServerEvent('f1f_sling:checkPos')
        while not positionsLoaded do Wait(10) end
    end
    local ped = PlayerPedId()
    local weaponData = exports.ox_inventory:getCurrentWeapon()
    local weapon = weaponData and weaponData.hash or nil
    if weapon and weapon ~= `WEAPON_UNARMED` and (Config.AttachableWeapons[weapon] or Config.SmallAttachableWeapons[weapon]) then
        slingWeapon = weapon
        isSlinged = true
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        Wait(100)
        if Config.AttachableWeapons[weapon] then
            attachSlingWeapon(weapon)
        elseif Config.SmallAttachableWeapons[weapon] then
            attachSmallSlingWeapon(weapon)
        end
        skipNextAnimation = true 
        TriggerServerEvent('f1f_sling:syncSling', weapon, true)
    end
end, false)

RegisterCommand('unholster', function()
    if not isSlinged then return end
    local ped = PlayerPedId()
    detachSlingWeapon()
    detachSmallSlingWeapon()
    SetCurrentPedWeapon(ped, slingWeapon, true)
    TriggerServerEvent('f1f_sling:syncSling', slingWeapon, false)
    slingWeapon = nil
    isSlinged = false
end, false)

RegisterCommand('setpos', function()
    if isAdjusting then
        SaveCurrentPosition()
        return
    end
    if isAdjustingSmall then
        SaveCurrentPosition()
        return
    end
    local playerPed = PlayerPedId()
    local currentWpn = exports.ox_inventory:getCurrentWeapon()
    if not currentWpn then return end
    local weaponHash = currentWpn.hash
    if Config.AttachableWeapons[weaponHash] then
        isAdjusting = true
        position = position or Config.DefaultLargeWeaponPosition
        attachSlingWeapon(weaponHash)
        ShowControlsUI()
    elseif Config.SmallAttachableWeapons[weaponHash] then
        isAdjustingSmall = true
        smallPosition = smallPosition or Config.DefaultSmallWeaponPosition
        attachSmallSlingWeapon(weaponHash)
        ShowControlsUI()
    end
end, false)

RegisterNUICallback("updatePosition", function(data, cb)
    if isAdjusting and data and data.position then
        position = data.position
        UpdateWeaponPosition()
    elseif isAdjustingSmall and data and data.position then
        smallPosition = data.position
        UpdateSmallWeaponPosition()
    end
    cb("ok")
end)

RegisterNUICallback("savePosition", function(data, cb)
    SaveCurrentPosition()
    cb("ok")
end)

RegisterNUICallback("cancelPosition", function(data, cb)
    CancelAdjustment()
    cb("ok")
end)

RegisterNetEvent('f1f_sling:updateSling')
AddEventHandler('f1f_sling:updateSling', function(weapon, state, target)
    if target and target ~= GetPlayerServerId(PlayerId()) then return end
    if state then
        slingWeapon = weapon
        isSlinged = true
        if Config.AttachableWeapons[weapon] then
            attachSlingWeapon(weapon)
        elseif Config.SmallAttachableWeapons[weapon] then
            attachSmallSlingWeapon(weapon)
        end
    else
        local ped = PlayerPedId()
        slingWeapon = nil
        isSlinged = false
        detachSlingWeapon()
        detachSmallSlingWeapon()
        SetCurrentPedWeapon(ped, weapon or `WEAPON_UNARMED`, true)
    end
end)

RegisterNetEvent('f1f_sling:showSling')
AddEventHandler('f1f_sling:showSling', function(target, weapon, state)
    if target == GetPlayerServerId(PlayerId()) then return end
    if state then
        if Config.AttachableWeapons[weapon] then
            if not slingObj then
                local ped = GetPlayerPed(GetPlayerFromServerId(target))
                local model, pos = getWeaponModelAndPosition(weapon)
                if model and ped and ped ~= 0 and pos then
                    RequestModel(model)
                    while not HasModelLoaded(model) do Wait(10) end
                    local obj = CreateObject(GetHashKey(model), 0.0, 0.0, 0.0, true, true, false)
                    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 24818), pos.x, pos.y, pos.z, pos.pitch, pos.roll, pos.yaw, false, false, false, false, 2, true)
                    SetEntityCollision(obj, false, false)
                    SetEntityCompletelyDisableCollision(obj, false, false)
                    SetEntityAlpha(obj, 255, false)
                    slingObj = obj
                    weaponObject = obj
                end
            end
        elseif Config.SmallAttachableWeapons[weapon] then
            if not smallWeaponObject then
                local ped = GetPlayerPed(GetPlayerFromServerId(target))
                local model, pos = getWeaponModelAndPosition(weapon)
                if model and ped and ped ~= 0 and pos then
                    RequestModel(model)
                    while not HasModelLoaded(model) do Wait(10) end
                    local obj = CreateObject(GetHashKey(model), 0.0, 0.0, 0.0, true, true, false)
                    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 24818), pos.x, pos.y, pos.z, pos.pitch, pos.roll, pos.yaw, false, false, false, false, 2, true)
                    SetEntityCollision(obj, false, false)
                    SetEntityCompletelyDisableCollision(obj, false, false)
                    SetEntityAlpha(obj, 255, false)
                    smallWeaponObject = obj
                end
            end
        end
    else
        if slingObj then DeleteEntity(slingObj) slingObj = nil end
        weaponObject = nil
        if smallWeaponObject then DeleteEntity(smallWeaponObject) smallWeaponObject = nil end
    end
end)

RegisterNetEvent('f1f_sling:loadPos')
AddEventHandler('f1f_sling:loadPos', function(savedPositions)
    if savedPositions and type(savedPositions) == "table" then
        if savedPositions.large then
            position = savedPositions.large
        else
            position = Config.DefaultLargeWeaponPosition
        end
        if savedPositions.small then
            smallPosition = savedPositions.small
        else
            smallPosition = Config.DefaultSmallWeaponPosition
        end
    else
        position = Config.DefaultLargeWeaponPosition
        smallPosition = Config.DefaultSmallWeaponPosition
    end
    positionsLoaded = true
end)

exports('SetSkipNextAnimation', function(skip)
    skipNextAnimation = skip
end)

exports('GetSkipNextAnimation', function()
    return skipNextAnimation
end)

AddEventHandler('ox_inventory:currentWeapon', function(data)
    if not isSlinged or not slingWeapon then return end
    local ped = PlayerPedId()
    local current = data and data.hash or nil

    if current == slingWeapon then
        if Config.AttachableWeapons[slingWeapon] then
            if slingObj then
                DeleteEntity(slingObj)
                slingObj = nil
                weaponObject = nil
            end
        elseif Config.SmallAttachableWeapons[slingWeapon] then
            if smallWeaponObject then
                DeleteEntity(smallWeaponObject)
                smallWeaponObject = nil
            end
        end
    elseif (not current or current == `WEAPON_UNARMED`) then
        if isSlinged then
            if Config.AttachableWeapons[slingWeapon] and not slingObj then
                attachSlingWeapon(slingWeapon)
                skipNextAnimation = true
            elseif Config.SmallAttachableWeapons[slingWeapon] and not smallWeaponObject then
                attachSmallSlingWeapon(slingWeapon)
                skipNextAnimation = true
            end
        end
    end

    if skipNextAnimation then
        skipNextAnimation = false
        if exports.f1f_sling then
            exports.f1f_sling:SetSkipNextAnimation(true)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if isAdjusting and weaponObject and DoesEntityExist(weaponObject) then
            if IsControlJustPressed(0, 18) then
                SaveCurrentPosition()
                Citizen.Wait(200)
            end
            if IsControlJustPressed(0, 322) then
                CancelAdjustment()
                Citizen.Wait(200)
            end
            if IsControlPressed(0, 172) then
                position.x = position.x - 0.005
                UpdateWeaponPosition()
            elseif IsControlPressed(0, 173) then
                position.x = position.x + 0.005
                UpdateWeaponPosition()
            end
            if IsControlPressed(0, 83) then
                position.y = position.y + 0.005
                UpdateWeaponPosition()
            elseif IsControlPressed(0, 84) then
                position.y = position.y - 0.005
                UpdateWeaponPosition()
            end
            if IsControlPressed(0, 174) then
                position.z = position.z + 0.005
                UpdateWeaponPosition()
            elseif IsControlPressed(0, 175) then
                position.z = position.z - 0.005
                UpdateWeaponPosition()
            end
            if IsControlPressed(0, 82) then
                position.pitch = position.pitch + 2.0
                UpdateWeaponPosition()
            elseif IsControlPressed(0, 81) then
                position.pitch = position.pitch - 2.0
                UpdateWeaponPosition()
            end
            if IsControlPressed(0, 39) then
                position.roll = position.roll + 2.0
                UpdateWeaponPosition()
            elseif IsControlPressed(0, 40) then
                position.roll = position.roll - 2.0
                UpdateWeaponPosition()
            end
            if IsControlJustPressed(0, 15) then
                position.yaw = position.yaw + 2.0
                UpdateWeaponPosition()
            elseif IsControlJustPressed(0, 14) then
                position.yaw = position.yaw - 2.0
                UpdateWeaponPosition()
            end
            ShowControlsUI()
            UpdateControlsUI()
        elseif isAdjustingSmall and smallWeaponObject and DoesEntityExist(smallWeaponObject) then
            if IsControlJustPressed(0, 18) then
                SaveCurrentPosition()
                Citizen.Wait(200)
            end
            if IsControlJustPressed(0, 322) then
                CancelAdjustment()
                Citizen.Wait(200)
            end
            if IsControlPressed(0, 172) then
                smallPosition.x = smallPosition.x - 0.005
                UpdateSmallWeaponPosition()
            elseif IsControlPressed(0, 173) then
                smallPosition.x = smallPosition.x + 0.005
                UpdateSmallWeaponPosition()
            end
            if IsControlPressed(0, 83) then
                smallPosition.y = smallPosition.y + 0.005
                UpdateSmallWeaponPosition()
            elseif IsControlPressed(0, 84) then
                smallPosition.y = smallPosition.y - 0.005
                UpdateSmallWeaponPosition()
            end
            if IsControlPressed(0, 174) then
                smallPosition.z = smallPosition.z + 0.005
                UpdateSmallWeaponPosition()
            elseif IsControlPressed(0, 175) then
                smallPosition.z = smallPosition.z - 0.005
                UpdateSmallWeaponPosition()
            end
            if IsControlPressed(0, 82) then
                smallPosition.pitch = smallPosition.pitch + 2.0
                UpdateSmallWeaponPosition()
            elseif IsControlPressed(0, 81) then
                smallPosition.pitch = smallPosition.pitch - 2.0
                UpdateSmallWeaponPosition()
            end
            if IsControlPressed(0, 39) then
                smallPosition.roll = smallPosition.roll + 2.0
                UpdateSmallWeaponPosition()
            elseif IsControlPressed(0, 40) then
                smallPosition.roll = smallPosition.roll - 2.0
                UpdateSmallWeaponPosition()
            end
            if IsControlJustPressed(0, 15) then
                smallPosition.yaw = smallPosition.yaw + 2.0
                UpdateSmallWeaponPosition()
            elseif IsControlJustPressed(0, 14) then
                smallPosition.yaw = smallPosition.yaw - 2.0
                UpdateSmallWeaponPosition()
            end
            ShowControlsUI()
            UpdateControlsUI()
        elseif controlsUiVisible then
            controlsUiVisible = false
            SendNUIMessage({action = "hideControls"})
        end
        Wait(0)
    end
end)