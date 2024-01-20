-- Copyright (c) 2023 tsl0922. All rights reserved.
-- SPDX-License-Identifier: GPL-2.0-only

local utils = require('mp.utils')

-- pre-defined file types
local file_types = {
    video = table.concat({ '*.mpeg4', '*.m4v', '*.mp4', '*.mp4v', '*.mpg4', '*.h264', '*.avc', '*.x264', '*.264',
        '*.hevc', '*.h265', '*.x265', '*.265', '*.m2ts', '*.m2t', '*.mts', '*.mtv', '*.ts', '*.tsv', '*.tsa', '*.tts',
        '*.mpeg', '*.mpg', '*.mpe', '*.mpeg2', '*.m1v', '*.m2v', '*.mp2v', '*.mkv', '*.mk3d', '*.wm', '*.wmv', '*.asf',
        '*.vob', '*.vro', '*.evob', '*.evo', '*.ogv', '*.ogm', '*.ogx', '*.webm', '*.avi', '*.vfw', '*.divx', '*.3iv',
        '*.xvid', '*.nut', '*.flic', '*.fli', '*.flc', '*.nsv', '*.gxf', '*.mxf', '*.dvr-ms', '*.dvr', '*.wtv', '*.dv',
        '*.hdv', '*.flv', '*.f4v', '*.qt', '*.mov', '*.hdmov', '*.rm', '*.rmvb', '*.3gpp', '*.3gp', '*.3gp2', '*.3g2',
        '*.yuv', '*.y4m' }, ';'),
    audio = table.concat({ '*.mp3', '*.m4a', '*.aac', '*.flac', '*.ac3', '*.a52', '*.eac3', '*.mpa', '*.m1a', '*.m2a',
        '*.mp1', '*.mp2', '*.oga', '*.ogg', '*.wav', '*.mlp', '*.dts', '*.dts-hd', '*.dtshd', '*.true-hd', '*.thd',
        '*.truehd', '*.thd+ac3', '*.tta', '*.pcm', '*.aiff', '*.aif', '*.aifc', '*.amr', '*.awb', '*.au', '*.snd',
        '*.lpcm', '*.ape', '*.wv', '*.shn', '*.adts', '*.adt', '*.opus', '*.spx', '*.mka', '*.weba', '*.wma', '*.f4a',
        '*.ra', '*.ram', '*.3ga', '*.3ga2', '*.ay', '*.gbs', '*.gym', '*.hes', '*.kss', '*.nsf', '*.nsfe', '*.sap',
        '*.spc', '*.vgm', '*.vgz', '*.m3u', '*.m3u8', '*.pls', '*.cue' }, ';'),
    image = table.concat({ '*.jpg', '*.bmp', '*.png', '*.gif', '*.webp' }, ';'),
    iso = table.concat({ '*.iso' }, ';'),
    subtitle = table.concat(
        { '*.srt', '*.ass', '*.idx', '*.sub', '*.sup', '*.ttxt', '*.txt', '*.ssa', '*.smi', '*.mks' }, ';'),
    playlist = table.concat({ '*.m3u', '*.m3u8', '*.pls', '*.cue' }, ';'),
}
local open_action = ''

-- open bluray iso or dir
local function open_bluray(path)
    mp.commandv('set', 'bluray-device', path)
    mp.commandv('loadfile', 'bd://')
end

-- open dvd iso or dir
local function open_dvd(path)
    mp.commandv('set', 'dvd-device', path)
    mp.commandv('loadfile', 'dvd://')
end

-- open a single file
local function open_file(path, append)
    local ext = path:match('^.+(%..+)$') or ''
    local function check_file_type(ext, type)
        return ext ~= '' and file_types[type]:find(ext)
    end

    -- play iso file directly
    if check_file_type(ext, 'iso') then
        local info = utils.file_info(path)
        if info and info.is_file then
            if info.size > 4.7 * 1000 * 1000 * 1000 then
                open_bluray(path)
            else
                open_dvd(path)
            end
            return
        end
    end

    if check_file_type(ext, 'subtitle') then
        mp.commandv('sub-add', path, 'auto')
    else
        mp.commandv('loadfile', path, append and 'append-play' or 'replace')
    end
end

-- open callback
local function open_cb(...)
    for i, v in ipairs({ ... }) do
        local path = tostring(v)
        if open_action == 'add-sub' then
            mp.commandv('sub-add', path, 'auto')
        elseif open_action == 'add-video' then
            mp.commandv('video-add', path, 'auto')
        elseif open_action == 'add-audio' then
            mp.commandv('audio-add', path, 'auto')
        elseif open_action == 'add-playlist' then
            mp.commandv('loadfile', path, 'append')
        else
            open_file(path, i > 1)
        end
    end
end

-- open folder callback
local function open_folder_cb(path)
    if utils.file_info(utils.join_path(path, 'BDMV')) then
        open_bluray(path)
    elseif utils.file_info(utils.join_path(path, 'VIDEO_TS')) then
        open_dvd(path)
    else
        mp.commandv('loadfile', path)
    end
end

-- clipboard callback
local function clipboard_cb(clipboard)
    mp.commandv('loadfile', clipboard, 'append-play')
    mp.osd_message('clipboard: ' .. clipboard)
end

-- message replies
mp.register_script_message('dialog-open-multi-reply', open_cb)
mp.register_script_message('dialog-open-folder-reply', open_folder_cb)
mp.register_script_message('clipboard-get-reply', clipboard_cb)


-- add subtitle track
mp.register_script_message('add-sub', function()
    open_action = 'add-sub'
    mp.set_property_native('user-data/menu/dialog/filters', {
        { name = 'Subtitle Files',  spec = file_types['subtitle'] },
        { name = 'All Files (*.*)', spec = '*.*' },
    })
    mp.commandv('script-message-to', 'menu', 'dialog/open-multi', mp.get_script_name())
end)

-- add video track
mp.register_script_message('add-video', function()
    open_action = 'add-video'
    mp.set_property_native('user-data/menu/dialog/filters', {
        { name = 'Video Files',     spec = file_types['video'] },
        { name = 'All Files (*.*)', spec = '*.*' },
    })
    mp.commandv('script-message-to', 'menu', 'dialog/open-multi', mp.get_script_name())
end)

-- add audio track
mp.register_script_message('add-audio', function()
    open_action = 'add-audio'
    mp.set_property_native('user-data/menu/dialog/filters', {
        { name = 'Audio Files',     spec = file_types['audio'] },
        { name = 'All Files (*.*)', spec = '*.*' },
    })
    mp.commandv('script-message-to', 'menu', 'dialog/open-multi', mp.get_script_name())
end)

-- add to playlist
mp.register_script_message('add-playlist', function()
    open_action = 'add-playlist'
    mp.set_property_native('user-data/menu/dialog/filters', {
        { name = 'Video Files',     spec = file_types['video'] },
        { name = 'All Files (*.*)', spec = '*.*' },
    })
    mp.commandv('script-message-to', 'menu', 'dialog/open-multi', mp.get_script_name())
end)

-- open dialog
mp.register_script_message('open', function()
    open_action = ''
    mp.set_property_native('user-data/menu/dialog/filters', {
        { name = 'All Files (*.*)', spec = '*.*' },
        { name = 'Video Files',     spec = file_types['video'] },
        { name = 'Audio Files',     spec = file_types['audio'] },
        { name = 'Image Files',     spec = file_types['image'] },
        { name = 'ISO Image Files', spec = file_types['iso'] },
        { name = 'Subtitle Files',  spec = file_types['subtitle'] },
        { name = 'Playlist Files',  spec = file_types['playlist'] },
    })
    mp.commandv('script-message-to', 'menu', 'dialog/open-multi', mp.get_script_name())
end)

-- open folder dialog
mp.register_script_message('open-folder', function()
    mp.commandv('script-message-to', 'menu', 'dialog/open-folder', mp.get_script_name())
end)

-- open clipboard
mp.register_script_message('open-clipboard', function()
    mp.commandv('script-message-to', 'menu', 'clipboard/get', mp.get_script_name())
end)
