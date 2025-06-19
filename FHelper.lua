script_version("v1.01")
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
        faminv = '',
        unfaminv = '',
    },
	blacklist = {
		blacklist_nicks = '', -- строка с никами через запятую
    },
}, 'FamHelper.ini')
--ЛОКАЛ--
local menu = new.char[10](u8(settings.main.menu))
local faminv = new.char[256](u8(settings.main.faminv))
local unfaminv = new.char[256](u8(settings.main.unfaminv))

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
function main()
    while not isSampAvailable() do wait(0) end
	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
	sampAddChatMessage(tag..u8:decode"Открыть меню скрипта /" ..settings.main.menu,-1)
    sampAddChatMessage(tag..u8:decode"Успешно загружен!",-1)
	sampRegisterChatCommand(settings.main.menu, function() WinState[0] = not WinState[0] end)
	
	-- Загружаем черный список
	loadBlacklist()
	
	while not isSampAvailable() do
       wait(0)
    end
	if not doesDirectoryExist(getWorkingDirectory()..'\\FamHelper') then
        createDirectory(getWorkingDirectory()..'\\FamHelper')
    end
end
--MIMGUI--
imgui.OnFrame(function() return WinState[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(329, 409), imgui.Cond.Always)
    imgui.Begin('##Windows', WinState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
	imgui.SameLine()

    if imgui.BeginTabBar('Tabs') then -- задаём начало вкладок
    if imgui.BeginTabItem('Команды') then -- первая вкладка
		if imgui.InputTextWithHint('Команда скрипта', '1', menu, 12) then end
		if imgui.Button('Сохранить настройки', imgui.ImVec2(137, 30)) then
            settings.main.menu = (str(menu))
            ini.save(settings, 'FamHelper.ini')
            thisScript():reload()
        end
        imgui.EndTabItem() -- конец вкладки
    end
    if imgui.BeginTabItem('АвтоМут') then -- вторая вкладка
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
                sampAddChatMessage(tag..u8:decode'Ник '..nick..' добавлен в черный список', -1)
            else
                sampAddChatMessage(tag..u8:decode'Ник '..nick..' уже есть в черном списке или пустой', -1)
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
                        sampAddChatMessage(tag..u8:decode'Ник '..nick..' удален из черного списка', -1)
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
