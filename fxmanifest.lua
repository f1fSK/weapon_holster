fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'f1f'

client_scripts {
    '@ox_lib/init.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

shared_scripts {
    '@es_extended/imports.lua',
    'shared/config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'ox_inventory',
    'oxmysql',
    'ox_lib'
}