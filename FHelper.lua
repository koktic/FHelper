script_version("v1.05")
script_name("Family Helper")
local name = "[Family Helper] "
local color1 = "{B43DD9}" 
local color2 = "{FFFFFF}"
local tag = color1 .. name .. color2

local imgui = require 'mimgui'
local fa = require('fAwesome5')

local encoding = require 'encoding'
encoding.default = 'CP1251'
local new = imgui.new
local u8 = encoding.UTF8
local effil = require 'effil'
local ffi = require 'ffi'
local ev = require 'samp.events'
local new, str = imgui.new, ffi.string

if not doesFileExist(getWorkingDirectory().."/FamHelper/fAwesome5.ttf") then
	downloadUrlToFile("https://dl.dropboxusercontent.com/s/zgfq5juurf7yvru/fAwesome5.ttf", getWorkingDirectory().."/FamHelper/fonts/fAwesome5.ttf")
end 

local WinState = new.bool()
--ОБНОВА--
local enable_autoupdate = true
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring,u8:decode [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/koktic/FHelper/refs/heads/main/version.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/koktic/helper"
        end
    end
end
--INI--
local ini = require 'inicfg'
local settings = ini.load({
    main = {
	menu = 'fhelp',
        faminv = 'finv',
	famuninvite = 'fui',
        fammute = 'fm',
	famunmute = 'fum',
	fampoint = 'fp',
    },
	blacklist = {
	blacklist_nicks = '', -- строка с никами через запятую
    },
}, 'FamHelper.ini')
--ЛОКАЛ--
local menu = new.char[10](u8(settings.main.menu))
local faminv1 = new.char[10](u8(settings.main.faminv))
local famuninvite1 = new.char[10](u8(settings.main.famuninvite))
local fammute1 = new.char[10](u8(settings.main.fammute))
local famunmute1 = new.char[10](u8(settings.main.famunmute))
local fampoint1 = new.char[10](u8(settings.main.fampoint))

local add_nick = new.char[256]() -- поле для добавления нового ника

-- Функция для работы с черным списком
local blacklist_nicks = {}

-- Загружаем черный список из настроек
function loadBlacklist()
    blacklist_nicks = {}
    if settings.blacklist.blacklist_nicks and settings.blacklist.blacklist_nicks ~= '' then
        for nick in string.gmatch(settings.blacklist.blacklist_nicks, "([^,]+)") do
            nick = nick:match("^%s*(.-)%s*$") -- убираем пробелы
            if nick ~= '' then
                table.insert(blacklist_nicks, nick)
            end
        end
    end
end
-- Сохраняем черный список в настройки
function saveBlacklist()
    settings.blacklist.blacklist_nicks = table.concat(blacklist_nicks, ",")
    ini.save(settings, 'FamHelper.ini')
end
-- Добавляем ник в черный список
function addToBlacklist(nick)
    if nick and nick ~= '' then
        nick = nick:match("^%s*(.-)%s*$") -- убираем пробелы
        if nick ~= '' then
            -- Проверяем, нет ли уже такого ника
            for i, existing_nick in ipairs(blacklist_nicks) do
                if existing_nick:lower() == nick:lower() then
                    return false -- уже есть
                end
            end
            table.insert(blacklist_nicks, nick)
            saveBlacklist()
            return true
        end
    end
    return false
end
-- Удаляем ник из черного списка
function removeFromBlacklist(nick)
    for i, existing_nick in ipairs(blacklist_nicks) do
        if existing_nick:lower() == nick:lower() then
            table.remove(blacklist_nicks, i)
            saveBlacklist()
            return true
        end
    end
    return false
end
--ПОИСК В ЧАТЕ--
function ev.onServerMessage(color, text)
	for _, nick in ipairs(blacklist_nicks) do
		if text:find(u8:decode'^{......}%[Семья%](.*) '..nick..'%[%d+%]:') then
			sampAddChatMessage(tag..u8:decode'[МУТ] Найден ник в семейном чате: '..nick, -1)
			sampAddChatMessage('/fammute '..nick..' 180 Неадекват') 
			break
		end
	end
end
-- === UID BLACKLIST SYSTEM === --
local uid_blacklist = {}
local uid_config_path = 'BlackList.ini'
local uid_settings = nil

function loadUIDBlacklist()
    if not doesFileExist(uid_config_path) then
        local default = { blacklist = { uid = '' } }
        ini.save(ini.load(default, uid_config_path), uid_config_path)
    end
    uid_settings = ini.load(nil, uid_config_path)
    uid_blacklist = {}
    local uids = tostring(uid_settings.blacklist.uid or '')
    for uid in uids:gmatch('([^,]+)') do
        uid = tonumber(uid:match('^%s*(.-)%s*$'))
        if uid then
            uid_blacklist[uid] = true
        end
    end
end

function saveUIDBlacklist()
    local list = {}
    for uid in pairs(uid_blacklist) do
        table.insert(list, tostring(uid))
    end
    uid_settings.blacklist.uid = table.concat(list, ',')
    ini.save(uid_settings, uid_config_path)
end

function addUIDToBlacklist(uid)
    if not uid_blacklist[uid] then
        uid_blacklist[uid] = true
        saveUIDBlacklist()
        return true
    end
    return false
end

function removeUIDFromBlacklist(uid)
    if uid_blacklist[uid] then
        uid_blacklist[uid] = nil
        saveUIDBlacklist()
        return true
    end
    return false
end
--МЕНЮШКА--
imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromFileTTF('Arial.ttf', 14.0, nil, glyph_ranges) -- Стандартный шрифт
    icon = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/MiniHelper/fAwesome5.ttf', 17.0, config, iconRanges) -- подгружаем иконки для верхнего (стандартного) шрифта.
end)
--MAIN--
function inviteWithBlacklistCheck(id)
    if not id or not tonumber(id) then
        sampAddChatMessage(tag..u8:decode"Укажи ID игрока!", 0xFF0000)
        return
    end
    id = tonumber(id)
    -- Запрашиваем UID через /id
    sampSendChat("/id " .. id)
    lua_thread.create(function()
        local found_uid = nil
        local timeout = os.clock() + 5 -- 5 секунд на ожидание
        while os.clock() < timeout do
            wait(200)
            for i = 0, 29 do -- ищем в 30 строках чата
                local text = sampGetChatString(i)
                -- Пример строки: "Имя: ... [ID: 123] ... UID: 456789"
                if text and (text:find("ID:?%s*" .. id) or text:find("%["..id.."%]")) then
                    local uid = text:match("UID:?%s*(%d+)")
                    if uid then
                        found_uid = tonumber(uid)
                        break
                    end
                end
            end
            if found_uid then break end
        end
        if not found_uid then
            sampAddChatMessage(tag..u8:decode"UID не найден в чате! Возможно, сервер не выдал /id или формат отличается.", 0xFF0000)
            return
        end
        if uid_blacklist[found_uid] then
            sampAddChatMessage(tag..u8:decode("UID "..found_uid.." в черном списке! Приглашение отменено."), 0xFF0000)
            return
        end
        sampSendChat("/faminvite " .. id)
    end)
end

function main()
    while not isSampAvailable() do wait(0) end
	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
	sampAddChatMessage(tag..u8:decode"Открыть меню скрипта /" ..settings.main.menu,-1)
    sampAddChatMessage(tag..u8:decode"Успешно загружен!",-1)
	sampRegisterChatCommand(settings.main.menu, function() WinState[0] = not WinState[0] end)
	 _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    -- Заменяем регистрацию команды инвайта на функцию с проверкой ЧС
    sampRegisterChatCommand(settings.main.faminv, function(param)
        local id = tonumber(param)
        if id then
            inviteWithBlacklistCheck(id)
        else
            sampAddChatMessage(tag..u8:decode"Укажи ID!", 0xFF0000)
        end
    end)
    sampRegisterChatCommand(settings.main.fammute, fammute)
    sampRegisterChatCommand(settings.main.famunmute, famunmute)
    sampRegisterChatCommand(settings.main.famuninvite, famuninvite)
    sampRegisterChatCommand(settings.main.fampoint, fampoint)
	loadBlacklist()
    loadUIDBlacklist() -- <== Загрузка UID черного списка
    -- Команды для UID черного списка
    sampRegisterChatCommand('addbl', function(param)
        local uid = tonumber(param and param:match('%d+'))
        if uid then
            if addUIDToBlacklist(uid) then
                sampAddChatMessage(string.format(tag..u8:decode'UID %d добавлен в черный список', uid), 0x00FF00)
            else
                sampAddChatMessage(string.format(tag..u8:decode'UID %d уже в черном списке', uid), 0xFF0000)
            end
        else
            sampAddChatMessage(tag..u8:decode'Использование: /addbl [UID]', 0xFF0000)
        end
    end)
    sampRegisterChatCommand('removebl', function(param)
        local uid = tonumber(param and param:match('%d+'))
        if uid then
            if removeUIDFromBlacklist(uid) then
                sampAddChatMessage(string.format(tag..u8:decode'UID %d удален из черного списка', uid), 0x00FF00)
            else
                sampAddChatMessage(string.format(tag..u8:decode'UID %d не найден в черном списке', uid), 0xFF0000)
            end
        else
            sampAddChatMessage(tag..u8:decode'Использование: /removebl [UID]', 0xFF0000)
        end
    end)
    sampRegisterChatCommand('checkbl', function()
        local count = 0
        for _ in pairs(uid_blacklist) do count = count + 1 end
        if count > 0 then
            sampAddChatMessage(tag..u8:decode(string.format('Черный список (%d UID):', count)), 0xFFFF00)
            for uid in pairs(uid_blacklist) do
                sampAddChatMessage(tag..u8:decode(string.format('- %d', uid)), 0xFFFF00)
            end
        else
            sampAddChatMessage(tag..u8:decode'Черный список пуст', 0xFFFF00)
        end
    end)
	while not isSampAvailable() do
       wait(0)
    end
	if not doesDirectoryExist(getWorkingDirectory()..'\\FamHelper') then
        createDirectory(getWorkingDirectory()..'\\FamHelper')
    end
end

function faminv(id)
    sampSendChat("/faminvite " .. id)
end

function fammute(id)
	sampSendChat("/fammute " .. id)
end

function famunmute(id)
    sampSendChat("/famunmute " .. id)
end

function famuninvite(id)
    sampSendChat("/famuninvite " .. id)
end

function fampoint()
    sampSendChat("/fampoint")
end
--MIMGUI--
imgui.OnFrame(function() return WinState[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(329, 409), imgui.Cond.Always)
    imgui.Begin('##Windows', WinState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
    imgui.SameLine()

    if imgui.BeginTabBar('Tabs') then -- задаём начало вкладок
        if imgui.BeginTabItem('Команды') then -- первая вкладка
            imgui.Text('Здесь можно ввести сокращения команд')
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('Команда скрипта', '1', menu, 10) then end
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('Команда для инвайта', '2', faminv1, 10) then end
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('Команда для увольнения', '3', famuninvite1, 10) then end
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('Команда для мута', '4', fammute1, 10) then end
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('Команда для размута', '5', famunmute1, 10) then end
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('Чекпоинт для семьи', '6', fampoint1, 10) then end
            if imgui.Button('Сохранить изменения', imgui.ImVec2(137, 30)) then
                settings.main.menu = (str(menu))
                settings.main.faminv = (str(faminv1))
                settings.main.famuninvite = (str(famuninvite1))
                settings.main.fammute = (str(fammute1))
                settings.main.famunmute = (str(famunmute1))
                settings.main.fampoint = (str(fampoint1))
                ini.save(settings, 'FamHelper.ini')
                thisScript():reload()
            end
            imgui.EndTabItem() -- конец вкладки
        end
        if imgui.BeginTabItem('АвтоМут (ники)') then -- вторая вкладка: автомута по никам
            imgui.Text('Черный список ников')
            imgui.Separator()
            -- Поле ввода для добавления ника
            imgui.SetNextItemWidth(200)
            if imgui.InputTextWithHint('##add_nick', 'Введите ник', add_nick, 256) then end
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_PLUS .. ' Добавить', imgui.ImVec2(80, 20)) then
                local nick = str(add_nick)
                if addToBlacklist(nick) then
                    add_nick[0] = 0 -- очищаем поле
                    sampAddChatMessage(string.format(tag..u8:decode'Ник %s добавлен в черный список', nick), -1)
                else
                    sampAddChatMessage(string.format(tag..u8:decode'Ник %s уже есть в черном списке или пустой', nick), -1)
                end
            end
            imgui.Separator()
            imgui.Text('Список ников в черном списке:')
            -- Отображаем список ников
            if #blacklist_nicks == 0 then
                imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), 'Список пуст')
            else
                for i, nick in ipairs(blacklist_nicks) do
                    imgui.Text(nick)
                    imgui.SameLine()
                    imgui.SetCursorPosX(imgui.GetCursorPosX() + 150)
                    if imgui.Button(fa.ICON_FA_MINUS .. '##remove_'..i, imgui.ImVec2(20, 20)) then
                        if removeFromBlacklist(nick) then
                            sampAddChatMessage(string.format(tag..u8:decode'Ник %s удален из черного списка', nick), -1)
                        end
                    end
                end
            end
            imgui.EndTabItem() -- конец вкладки
        end
        if imgui.BeginTabItem('ЧС UID') then -- третья вкладка: UID blacklist
            imgui.Text('Черный список UID')
            imgui.Separator()
            -- Поле для добавления UID
            if not add_uid then add_uid = imgui.new.char[32]() end
            imgui.SetNextItemWidth(120)
            if imgui.InputTextWithHint('##add_uid', 'Введите UID', add_uid, 32) then end
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_PLUS .. ' Добавить UID', imgui.ImVec2(110, 20)) then
                local uid = tonumber(str(add_uid))
                if uid and addUIDToBlacklist(uid) then
                    add_uid[0] = 0
                    sampAddChatMessage(string.format(tag..u8:decode'UID %d добавлен в черный список', uid), 0x00FF00)
                else
                    sampAddChatMessage(tag..u8:decode'UID уже есть в черном списке или невалидный', 0xFF0000)
                end
            end
            imgui.Separator()
            imgui.Text('Список UID в черном списке:')
            local count = 0
            for _ in pairs(uid_blacklist) do count = count + 1 end
            if count == 0 then
                imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), 'Список пуст')
            else
                local i = 0
                for uid in pairs(uid_blacklist) do
                    i = i + 1
                    imgui.Text(tostring(uid))
                    imgui.SameLine()
                    imgui.SetCursorPosX(imgui.GetCursorPosX() + 150)
                    if imgui.Button(fa.ICON_FA_MINUS .. '##remove_uid_'..i, imgui.ImVec2(20, 20)) then
                        if removeUIDFromBlacklist(uid) then
                            sampAddChatMessage(string.format(tag..u8:decode'UID %d удален из черного списка', uid), 0x00FF00)
                        end
                    end
                end
            end
            imgui.EndTabItem() -- конец вкладки
        end
        imgui.EndTabBar() -- конец всех вкладок
    end
end)







--ФУНКЦИИ--
function theme()
    imgui.SwitchContext()
    local ImVec4 = imgui.ImVec4

    -- Параметры отступов
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)

    -- Размеры элементов
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10

    -- Границы
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1

    -- Закругления
    imgui.GetStyle().WindowRounding = 10
    imgui.GetStyle().ChildRounding = 10
    imgui.GetStyle().FrameRounding = 10
    imgui.GetStyle().PopupRounding = 10
    imgui.GetStyle().ScrollbarRounding = 10
    imgui.GetStyle().GrabRounding = 10
    imgui.GetStyle().TabRounding = 10

    -- Цветовая схема
    imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00) -- Белый текст
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00) -- Серый текст
	imgui.GetStyle().Colors[imgui.Col.WindowBg]				  = imgui.ImVec4(0.10, 0.05, 0.20, 0.40) -- 70% прозрачности
	imgui.GetStyle().Colors[imgui.Col.ChildBg]				  = imgui.ImVec4(0.15, 0.10, 0.25, 0.30) -- 50% прозрачности
	imgui.GetStyle().Colors[imgui.Col.PopupBg] 				  = imgui.ImVec4(0.12, 0.05, 0.30, 0.50) -- 60% прозрачности
    imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.25, 0.25, 0.30, 0.30) -- Границы
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.20, 0.20, 0.30, 1.00) -- Фон фреймов
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.30, 0.30, 0.40, 1.00) -- Ховер фреймов
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.35, 0.35, 0.45, 1.00) -- Активный фрейм
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.10, 0.10, 0.20, 1.00) -- Заголовок окна
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.15, 0.15, 0.30, 0.70) -- Активный заголовок окна
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.10, 0.10, 0.15, 0.50) -- Фон меню
    imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.25, 0.25, 0.35, 0.76) -- Кнопки
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.30, 0.41, 0.99, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.30, 0.41, 0.99, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.35, 0.35, 0.45, 1.00) -- Ховер кнопок
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.40, 0.40, 0.50, 1.00) -- Активная кнопка
    imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.20, 0.20, 0.30, 1.00) -- Заголовки секций
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.30, 0.30, 0.40, 1.00) -- Ховер заголовков
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.35, 0.35, 0.45, 1.00) -- Активный заголовок
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.10, 0.10, 0.15, 1.00) -- Фон скроллбара
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.25, 0.25, 0.35, 1.00) -- Ползунок скроллбара
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.20, 0.20, 0.30, 1.00) -- Вкладки
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.30, 0.30, 0.40, 1.00) -- Ховер вкладок
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.35, 0.35, 0.45, 1.00) -- Активная вкладка
end

imgui.OnInitialize(function()
    theme()
end)
