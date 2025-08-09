local ESX = exports.es_extended:getSharedObject()
local slingData = {}
local playerPositions = {}

RegisterNetEvent('f1f_sling:syncSling')
AddEventHandler('f1f_sling:syncSling', function(weapon, state)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if state then
        if xPlayer.hasWeapon(weapon) then
            slingData[src] = weapon
            TriggerClientEvent('f1f_sling:updateSling', src, weapon, true, src)
            TriggerClientEvent('f1f_sling:showSling', -1, src, weapon, true)
        end
    else
        slingData[src] = nil
        TriggerClientEvent('f1f_sling:updateSling', src, weapon, false, src)
        TriggerClientEvent('f1f_sling:showSling', -1, src, weapon, false)
    end
end)

RegisterNetEvent('f1f_sling:saveSmall')
AddEventHandler('f1f_sling:saveSmall', function(smallPosition)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.identifier then
        local encodedPosition = json.encode(smallPosition)
        MySQL.Async.execute('INSERT INTO sling_positions (identifier, small) VALUES (@identifier, @small) ON DUPLICATE KEY UPDATE small = @small', {
            ['@identifier'] = xPlayer.identifier,
            ['@small'] = encodedPosition
        }, function(rowsChanged)
            if rowsChanged > 0 then
                if not playerPositions[src] then playerPositions[src] = {} end
                playerPositions[src].small = smallPosition
            else
            end
        end)
    end
end)

RegisterNetEvent('f1f_sling:savePos')
AddEventHandler('f1f_sling:savePos', function(position)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.identifier then
        local encodedPosition = json.encode(position)
        MySQL.Async.execute('INSERT INTO sling_positions (identifier, large) VALUES (@identifier, @large) ON DUPLICATE KEY UPDATE large = @large', {
            ['@identifier'] = xPlayer.identifier,
            ['@large'] = encodedPosition
        }, function(rowsChanged)
            if rowsChanged > 0 then
                if not playerPositions[src] then playerPositions[src] = {} end
                playerPositions[src].large = position
            else
            end
        end)
    end
end)

RegisterNetEvent('f1f_sling:checkPos')
AddEventHandler('f1f_sling:checkPos', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.identifier then
        MySQL.Async.fetchAll('SELECT * FROM sling_positions WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(results)
            local positions = {}
            if results and #results > 0 then
                if results[1].large then
                    local decoded = json.decode(results[1].large)
                    if decoded then positions.large = decoded end
                end
                if results[1].small then
                    local decoded = json.decode(results[1].small)
                    if decoded then positions.small = decoded end
                end
            end
            TriggerClientEvent('f1f_sling:loadPos', src, positions)
        end)
    else
        TriggerClientEvent('f1f_sling:loadPos', src, {})
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    slingData[src] = nil
    playerPositions[src] = nil
    TriggerClientEvent('f1f_sling:showSling', -1, src, 0, false)
end)