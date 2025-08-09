RegisterServerEvent('f1f_sling:syncAnimation')
AddEventHandler('f1f_sling:syncAnimation', function(dict, anim, duration, flag)
    local source = source
    local playerId = source
    TriggerClientEvent('f1f_sling:playNetworkedAnim', -1, playerId, dict, anim, duration, flag)
end)

local playerAnimationPrefs = {}

RegisterServerEvent('f1f_sling:saveAnimPref')
AddEventHandler('f1f_sling:saveAnimPref', function(enabled)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        local identifier = xPlayer.identifier
        playerAnimationPrefs[identifier] = enabled
    end
end)

RegisterServerEvent('f1f_sling:requestAnimPref')
AddEventHandler('f1f_sling:requestAnimPref', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        local identifier = xPlayer.identifier
        local enabled = playerAnimationPrefs[identifier]
        
        if enabled ~= nil then
            TriggerClientEvent('f1f_sling:loadAnimPref', source, enabled)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
    end
end)
