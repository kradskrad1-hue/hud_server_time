script_name("HUD Server Time")
script_author("")
script_version("2.0")

require "lib.moonloader"
local imgui = require "imgui"
local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

;(function()
local ml = package.loaded.moonloader
local font_flag = ml and ml.font_flag or { BOLD = 2 }

local CFG = {}
CFG.SERVER_UTC_PLUS = 3
CFG.MARGIN_BOTTOM = 48
CFG.FONT_SIZE = 22
CFG.ALARM_FONT_SIZE = 34
CFG.TIMER_HISTORY_MAX = 8
CFG.CLOCK_SECOND_ANIM_MS = 320
CFG.VK_F7 = 0x76
CFG.VK_F8 = 0x77
CFG.VK_F9 = 0x78
CFG.ALARM_POPUP_MS = 20000
CFG.ALARM_MSG = "Time's up!"
CFG.ALARM_TEXT_PAD = 16
CFG.ALARM_TEXT_WIDTH_EXTRA = 54
CFG.ALARM_FADE_IN_MS = 350
CFG.ALARM_FADE_OUT_MS = 500
CFG.ALARM_TEXT_COLOR = 0xFFFFF2CC
CFG.VK_LBUTTON = 0x01
CFG.VK_ESCAPE = 0x1B
CFG.CLOCK_SPIN_MS = 1200
CFG.TOOLBAR_BTN_W = 38
CFG.TOOLBAR_BTN_H = 24
CFG.TOOLBAR_GAP = 8
CFG.TOOLBAR_ABOVE = 10
CFG.MENU_COLOR_LABEL_SCALE = 1.35
CFG.MENU_TEXT_BUF_SIZE = 128
CFG.MENU_TIMER_BOTTOM_GAP = 2
CFG.MENU_IMGUI_FONT_BASE_SIZE = 14.0
CFG.MENU_BG_IMAGE_FILE = "hud_server_time_bg.png"
CFG.MENU_BG_IMAGE_TINT = 0xCCFFFFFF
CFG.MENU_STARS_COUNT = 36
CFG.MENU_STAR_MIN_SPEED = 260
CFG.MENU_STAR_MAX_SPEED = 520
CFG.MENU_STAR_MIN_LEN = 20
CFG.MENU_STAR_MAX_LEN = 62
CFG.MENU_STAR_MIN_ALPHA = 0xB0
CFG.MENU_STAR_MAX_ALPHA = 0xFF
CFG.MENU_STAR_LINE_THICK = 2.5
CFG.MENU_CLICK_SPARK_COUNT = 14
CFG.MENU_CLICK_SPARK_LIFE_MIN_MS = 220
CFG.MENU_CLICK_SPARK_LIFE_MAX_MS = 420
CFG.MENU_CLICK_SPARK_SPEED_MIN = 90
CFG.MENU_CLICK_SPARK_SPEED_MAX = 210
CFG.MENU_CLICK_SPARK_GRAVITY = 420
CFG.TIMER_FONT_OPTIONS = {
  "Verdana",
  "Arial",
  "Calibri",
  "Segoe UI",
  "Trebuchet MS",
  "Times New Roman",
  "Georgia",
  "Consolas",
  "Courier New",
  "Comic Sans MS",
  "Lucida Console",
  "Palatino Linotype",
}
CFG.TIMER_FONT_FILES = {
  ["Verdana"] = "verdana.ttf",
  ["Arial"] = "arial.ttf",
  ["Calibri"] = "calibri.ttf",
  ["Segoe UI"] = "segoeui.ttf",
  ["Trebuchet MS"] = "trebuc.ttf",
  ["Times New Roman"] = "times.ttf",
  ["Georgia"] = "georgia.ttf",
  ["Consolas"] = "consola.ttf",
  ["Courier New"] = "cour.ttf",
  ["Comic Sans MS"] = "comic.ttf",
  ["Lucida Console"] = "lucon.ttf",
  ["Palatino Linotype"] = "pala.ttf",
}
CFG.OUTLINE_COLOR_OPTIONS = {
  { key = "black", label = "Black", argb = 0xCC000000 },
  { key = "white", label = "White", argb = 0xCCFFFFFF },
  { key = "red", label = "Red", argb = 0xCCFF0000 },
  { key = "green", label = "Green", argb = 0xCC00FF00 },
  { key = "blue", label = "Blue", argb = 0xCC0000FF },
  { key = "yellow", label = "Yellow", argb = 0xCCFFFF00 },
  { key = "orange", label = "Orange", argb = 0xCCFFAA00 },
  { key = "cyan", label = "Cyan", argb = 0xCC00FFFF },
  { key = "magenta", label = "Magenta", argb = 0xCCFF00FF },
  { key = "gray", label = "Gray", argb = 0xCC808080 },
}
CFG.CREATOR_CONTACT_URL = "https://vk.com/ram.onovv"
CFG.MENU_TIMER_FONT_SIZE = math.max(8, math.floor(CFG.FONT_SIZE * 1.0))

local F = {}

local label_prefix = "AraDynastry"
local timer_visible = true

local alarm_fire_at = nil
local timers = {}
local timer_seq = 0
local timer_history = {}
local timer_repeat_enabled = imgui.ImBool(false)
local timer_repeat_minutes = imgui.ImInt(5)
local timer_label_input = imgui.ImBuffer("Timer", 48)
local timer_paused = false
local timer_pause_started_gt = nil
local time_format_mode = "24h"
local clock_second_last = -1
local clock_second_anim_gt = 0
local hk_prev = { f7 = false, f8 = false, f9 = false }
local alarm_popup_until = nil

local alarm_bounce = {
  inited = false,
  last_gt = nil,
  x = 0,
  y = 0,
  vx = 0,
  vy = 0,
}
local alarm_close_lmb_was = false

local color_mode = "shimmer_red_orange"

local font
local font_alarm
local font_tool
local font_menu_timer
local timer_font_cache = {}
local preview_font_cache = {}
local timer_font_name = "Verdana"
local outline_color_key = "black"
local outline_thickness = imgui.ImInt(1)
local outline_enabled = imgui.ImBool(true)
local hud_glow_enabled = imgui.ImBool(true)
local hud_glow_strength = imgui.ImInt(70)
local hud_shadow_enabled = imgui.ImBool(true)
local menu_timer_imgui_font = nil
local menu_imgui_fonts = {}
local menu_font_pending_name = nil
local menu_font_building = false
local popup_open_gt = {}

local clock_custom = false
local clock_x = 0
local clock_y = 0
local clock_edit_active = false
local clock_follow_cursor = false
local clock_spin_start_gt = nil
local clock_rotation_quarter = 0
local clock_edit_skip_until_gt = nil
local clock_lmb_was = false
local clock_drag_offset_x = 0
local clock_drag_offset_y = 0
local reopen_menu_after_clock_edit = false
local pending_begin_clock_edit = false
local menu_esc_was = false
local menuOpen = imgui.ImBool(false)
imgui.Process = false
local menuWindowSize = imgui.ImVec2(840, 560)
local menu_center_on_open = false
local menu_bg_texture = nil
local menu_bg_image_path = nil
local menu_bg_texture_failed = false
local menu_bg_retry_after_gt = 0
local menu_stars = {}
local menu_star_last_gt = nil
local menu_click_sparks = {}
local menu_click_spark_last_gt = nil
local menu_label_input = imgui.ImBuffer(label_prefix, CFG.MENU_TEXT_BUF_SIZE)
local menu_countdown_input = imgui.ImBuffer("00:00:00", 16)
local menu_countdown_error = false
local menu_timer_list_text = ""

function F.trim(s)
  if not s then
    return ""
  end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function F.unquote(s)
  s = F.trim(s)
  local n = #s
  if n >= 2 then
    local a, b = s:sub(1, 1), s:sub(n, n)
    if (a == '"' and b == '"') or (a == "'" and b == "'") then
      return s:sub(2, n - 1)
    end
  end
  return s
end

function F.only_six_digits(s)
  local d = (s or ""):gsub("%D", "")
  if #d > 6 then
    d = d:sub(1, 6)
  end
  return d
end

function F.clamp_time_digits_by_position(d)
  local max_by_pos = { 2, 4, 6, 9, 6, 9 }
  local out = {}
  for i = 1, #d do
    local ch = d:sub(i, i)
    local n = tonumber(ch) or 0
    local mx = max_by_pos[i] or 9
    if n > mx then
      n = mx
    elseif n < 0 then
      n = 0
    end
    out[#out + 1] = tostring(n)
  end
  return table.concat(out)
end

function F.format_hhmmss_mask(digits)
  local d = digits or ""
  if #d < 6 then
    d = d .. string.rep("0", 6 - #d)
  elseif #d > 6 then
    d = d:sub(1, 6)
  end
  return d:sub(1, 2) .. ":" .. d:sub(3, 4) .. ":" .. d:sub(5, 6)
end

function F.build_hud_text(clock)
  local prefix = label_prefix or ""
  if prefix ~= "" then
    local ok, decoded = pcall(function()
      return u8:decode(prefix)
    end)
    if ok and decoded and decoded ~= "" then
      prefix = decoded
    end
  end
  if prefix == "" then
    return clock
  end
  return prefix .. " " .. clock
end

local EMBEDDED_STATE = {
  label_prefix = "",
  clock_custom = false,
  clock_x = 0,
  clock_y = 0,
  color_mode = "shimmer_red_orange",
  timer_font_name = "Verdana",
  outline_color_key = "black",
  outline_thickness = 1,
  outline_enabled = false,
  time_format_mode = "24h",
  timer_repeat_enabled = true,
  timer_repeat_minutes = 5,
  timer_label = "Timer",
  hud_glow_enabled = true,
  hud_glow_strength = 70,
  hud_shadow_enabled = true,
}

function F.load_label_prefix()
  local data = F.trim(EMBEDDED_STATE.label_prefix or "")
  if data ~= "" then
    label_prefix = data
  end
end

function F.save_label_prefix()
  EMBEDDED_STATE.label_prefix = label_prefix or ""
end

function F.sync_menu_label_input_from_prefix()
  local max_len = CFG.MENU_TEXT_BUF_SIZE - 1
  local txt = label_prefix or ""
  if #txt > max_len then
    txt = txt:sub(1, max_len)
  end
  menu_label_input.v = txt
end

function F.rebuild_timer_fonts()
  font = renderCreateFont(timer_font_name, CFG.FONT_SIZE, font_flag.BOLD)
  font_menu_timer = renderCreateFont(timer_font_name, CFG.MENU_TIMER_FONT_SIZE, font_flag.BOLD)
  timer_font_cache = { [CFG.MENU_TIMER_FONT_SIZE] = font_menu_timer }
end

function F.get_timer_font_by_size(size)
  size = math.max(8, math.floor(size))
  local f = timer_font_cache[size]
  if not f then
    f = renderCreateFont(timer_font_name, size, font_flag.BOLD)
    timer_font_cache[size] = f
  end
  return f
end

function F.get_preview_font_by_name_size(name, size)
  local font_name = (name and name ~= "") and name or timer_font_name
  size = math.max(8, math.floor(size))
  local key = font_name .. "|" .. tostring(size)
  local f = preview_font_cache[key]
  if not f then
    local source = font_name
    local file_name = CFG.TIMER_FONT_FILES[font_name]
    if file_name and file_name ~= "" then
      local font_path = "C:\\Windows\\Fonts\\" .. file_name
      local probe = io.open(font_path, "rb")
      if probe then
        probe:close()
        source = font_path
      end
    end
    f = renderCreateFont(source, size, 0)
    preview_font_cache[key] = f
  end
  return f
end

function F.request_menu_imgui_font_rebuild(font_name)
  menu_font_pending_name = nil
  menu_timer_imgui_font = nil
end

function F.process_menu_imgui_font_rebuild()
  return
end

function F.script_dir_path()
  if thisScript and thisScript().path then
    local p = tostring(thisScript().path or "")
    local dir = p:match("^(.*)[/\\][^/\\]+$")
    if dir and dir ~= "" then
      return dir
    end
  end
  return nil
end

function F.file_exists(path)
  if not path or path == "" then
    return false
  end
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

function F.open_external_url(url)
  if not url or url == "" then
    return
  end
  os.execute('start "" "' .. url .. '"')
end

function F.load_clock_position()
  if not EMBEDDED_STATE.clock_custom then
    return
  end
  clock_x = tonumber(EMBEDDED_STATE.clock_x) or 0
  clock_y = tonumber(EMBEDDED_STATE.clock_y) or 0
  clock_custom = true
end

function F.save_clock_position()
  EMBEDDED_STATE.clock_custom = true
  EMBEDDED_STATE.clock_x = math.floor(clock_x or 0)
  EMBEDDED_STATE.clock_y = math.floor(clock_y or 0)
  clock_custom = true
end

function F.clear_clock_position_file()
  EMBEDDED_STATE.clock_custom = false
  clock_custom = false
end

function F.add_timer_history(text)
  if not text or text == "" then
    return
  end
  table.insert(timer_history, 1, text)
  while #timer_history > CFG.TIMER_HISTORY_MAX do
    table.remove(timer_history)
  end
end

function F.add_timer(duration_ms, label, repeat_ms, source)
  if not duration_ms or duration_ms <= 0 then
    return nil
  end
  timer_seq = timer_seq + 1
  local now_gt = getGameTimer()
  local item = {
    id = timer_seq,
    label = F.trim(label or ""),
    duration_ms = duration_ms,
    repeat_ms = repeat_ms or 0,
    fire_at = now_gt + duration_ms,
  }
  if item.label == "" then
    item.label = "Timer " .. tostring(item.id)
  end
  timers[#timers + 1] = item
  F.add_timer_history(string.format("Start: %s (%s)", item.label, F.format_hms_from_ms(duration_ms)))
  return item
end

function F.cancel_all_timers()
  timers = {}
  alarm_fire_at = nil
  timer_paused = false
  timer_pause_started_gt = nil
end

function F.pause_all_timers(gt)
  if timer_paused then
    return
  end
  timer_paused = true
  timer_pause_started_gt = gt or getGameTimer()
  F.add_timer_history("Pause timers")
end

function F.resume_all_timers(gt)
  if not timer_paused then
    return
  end
  local now_gt = gt or getGameTimer()
  local paused_delta = math.max(0, now_gt - (timer_pause_started_gt or now_gt))
  for i = 1, #timers do
    local tm = timers[i]
    tm.fire_at = tm.fire_at + paused_delta
  end
  timer_paused = false
  timer_pause_started_gt = nil
  F.add_timer_history("Resume timers")
end

function F.get_next_timer(gt)
  local best = nil
  for i = 1, #timers do
    local tm = timers[i]
    local left = tm.fire_at - gt
    if left >= 0 then
      if (not best) or tm.fire_at < best.fire_at then
        best = tm
      end
    end
  end
  return best
end

function F.update_timers_and_alarm(gt)
  if timer_paused then
    alarm_fire_at = nil
    return
  end
  local i = 1
  while i <= #timers do
    local tm = timers[i]
    if gt >= tm.fire_at then
      alarm_popup_until = gt + CFG.ALARM_POPUP_MS
      alarm_bounce.inited = false
      alarm_bounce.last_gt = nil
      sampAddChatMessage("{FF6666}[HUD Time]{FFFFFF} " .. tm.label .. " finished!", 0xFFFF6666)
      F.add_timer_history("Done: " .. tm.label)
      if tm.repeat_ms and tm.repeat_ms > 0 then
        tm.fire_at = gt + tm.repeat_ms
        F.add_timer_history(string.format("Repeat: %s (%s)", tm.label, F.format_hms_from_ms(tm.repeat_ms)))
        i = i + 1
      else
        table.remove(timers, i)
      end
    else
      i = i + 1
    end
  end
  local nxt = F.get_next_timer(gt)
  alarm_fire_at = nxt and nxt.fire_at or nil
end

function F.build_timer_list_text(gt)
  if #timers == 0 then
    return "Нет активных таймеров"
  end
  local out = {}
  for i = 1, #timers do
    local tm = timers[i]
    local left = tm.fire_at - gt
    if left < 0 then
      left = 0
    end
    local repeat_mark = (tm.repeat_ms and tm.repeat_ms > 0) and " [R]" or ""
    out[#out + 1] = string.format("%d) %s %s%s", i, tm.label, F.format_hms_from_game_timer_ms(left), repeat_mark)
    if #out >= 3 then
      break
    end
  end
  return table.concat(out, "\n")
end

function F.save_all_settings()
  EMBEDDED_STATE.color_mode = color_mode
  EMBEDDED_STATE.timer_font_name = timer_font_name
  EMBEDDED_STATE.outline_color_key = outline_color_key
  EMBEDDED_STATE.outline_thickness = outline_thickness.v or 1
  EMBEDDED_STATE.outline_enabled = outline_enabled.v and true or false
  EMBEDDED_STATE.time_format_mode = time_format_mode
  EMBEDDED_STATE.timer_repeat_enabled = timer_repeat_enabled.v and true or false
  EMBEDDED_STATE.timer_repeat_minutes = timer_repeat_minutes.v or 5
  EMBEDDED_STATE.label_prefix = label_prefix or ""
  EMBEDDED_STATE.timer_label = timer_label_input.v or "Timer"
  EMBEDDED_STATE.clock_custom = clock_custom and true or false
  EMBEDDED_STATE.clock_x = math.floor(clock_x or 0)
  EMBEDDED_STATE.clock_y = math.floor(clock_y or 0)
  EMBEDDED_STATE.hud_glow_enabled = hud_glow_enabled.v and true or false
  EMBEDDED_STATE.hud_glow_strength = math.max(0, math.min(100, hud_glow_strength.v or 0))
  EMBEDDED_STATE.hud_shadow_enabled = hud_shadow_enabled.v and true or false
end

function F.load_all_settings()
  if type(COLOR_GETTERS) == "table" and COLOR_GETTERS[EMBEDDED_STATE.color_mode] then
    color_mode = EMBEDDED_STATE.color_mode
  end
  if EMBEDDED_STATE.timer_font_name and EMBEDDED_STATE.timer_font_name ~= "" then
    timer_font_name = EMBEDDED_STATE.timer_font_name
  end
  if EMBEDDED_STATE.outline_color_key and EMBEDDED_STATE.outline_color_key ~= "" then
    outline_color_key = EMBEDDED_STATE.outline_color_key
  end
  outline_thickness.v = math.max(0, math.min(10, tonumber(EMBEDDED_STATE.outline_thickness) or 1))
  outline_enabled.v = EMBEDDED_STATE.outline_enabled and true or false
  if EMBEDDED_STATE.time_format_mode == "12h" or EMBEDDED_STATE.time_format_mode == "24h" then
    time_format_mode = EMBEDDED_STATE.time_format_mode
  end
  timer_repeat_enabled.v = EMBEDDED_STATE.timer_repeat_enabled and true or false
  timer_repeat_minutes.v = math.max(0, tonumber(EMBEDDED_STATE.timer_repeat_minutes) or 5)
  if EMBEDDED_STATE.label_prefix and EMBEDDED_STATE.label_prefix ~= "" then
    label_prefix = EMBEDDED_STATE.label_prefix
  end
  timer_label_input.v = EMBEDDED_STATE.timer_label or "Timer"
  hud_glow_enabled.v = EMBEDDED_STATE.hud_glow_enabled ~= false
  hud_glow_strength.v = math.max(0, math.min(100, tonumber(EMBEDDED_STATE.hud_glow_strength) or 70))
  hud_shadow_enabled.v = EMBEDDED_STATE.hud_shadow_enabled ~= false
end

function F.process_timer_hotkeys(gt)
  local f7 = (isKeyDown and isKeyDown(CFG.VK_F7)) or false
  local f8 = (isKeyDown and isKeyDown(CFG.VK_F8)) or false
  local f9 = (isKeyDown and isKeyDown(CFG.VK_F9)) or false
  if f7 and not hk_prev.f7 then
    local dur_ms = F.parse_alarm_duration_hms(menu_countdown_input.v or "")
    if dur_ms then
      local rep_ms = 0
      if timer_repeat_enabled.v then
        rep_ms = math.max(0, timer_repeat_minutes.v or 0) * 60000
      end
      F.add_timer(dur_ms, F.trim(timer_label_input.v or ""), rep_ms, "hotkey")
    end
  end
  if f8 and not hk_prev.f8 then
    if timer_paused then
      F.resume_all_timers(gt)
    else
      F.pause_all_timers(gt)
    end
  end
  if f9 and not hk_prev.f9 then
    F.cancel_all_timers()
  end
  hk_prev.f7 = f7
  hk_prev.f8 = f8
  hk_prev.f9 = f9
end

function F.format_clock_now(gt)
  local t = F.time_table_now()
  local h = t.hour
  if time_format_mode == "12h" then
    h = h % 12
    if h == 0 then
      h = 12
    end
  end
  local clock = string.format("%02d:%02d:%02d", h, t.min, t.sec)
  if t.sec ~= clock_second_last then
    clock_second_last = t.sec
    clock_second_anim_gt = gt
  end
  return F.build_hud_text(clock)
end

function F.draw_next_timer_overlay(gt, draw_x, draw_y, tw)
  local timer_gt = timer_paused and (timer_pause_started_gt or gt) or gt
  local next_timer = F.get_next_timer(timer_gt)
  if not next_timer then
    return
  end
  local remain_text = next_timer.label .. ":" .. F.format_hms_from_game_timer_ms(next_timer.fire_at - timer_gt)
  local rw = renderGetFontDrawTextLength(font, remain_text)
  local rh = math.floor(CFG.FONT_SIZE * 1.2)
  local rx = draw_x + math.floor((tw - rw) * 0.5)
  local ry = draw_y - rh - 6
  F.draw_outlined_render_text(font, remain_text, rx, ry, F.timer_color_argb(gt))
  if #timers > 1 then
    local extra = "+" .. tostring(#timers - 1) .. " timers"
    F.draw_outlined_render_text(font_tool, extra, rx, ry - 18, 0xFFE8E8E8)
  end
  if timer_paused then
    F.draw_outlined_render_text(font_tool, "[PAUSE]", rx, ry + rh + 2, 0xFFFFD36A)
  end
end

function F.animated_clock_color(gt)
  local base_col = F.timer_color_argb(gt)
  local pulse = 0
  if gt < (clock_second_anim_gt + CFG.CLOCK_SECOND_ANIM_MS) then
    pulse = 1.0 - (gt - clock_second_anim_gt) / CFG.CLOCK_SECOND_ANIM_MS
    if pulse < 0 then
      pulse = 0
    end
  end
  local a = math.floor(base_col / 0x1000000) % 0x100
  local r = math.floor(base_col / 0x10000) % 0x100
  local g = math.floor(base_col / 0x100) % 0x100
  local b = base_col % 0x100
  local k = 0.30 * pulse
  r = math.floor(r + (255 - r) * k)
  g = math.floor(g + (255 - g) * k)
  b = math.floor(b + (255 - b) * k)
  return a * 0x1000000 + r * 0x10000 + g * 0x100 + b
end

function F.popup_visible_count(key, total)
  local now_gt = getGameTimer()
  if not popup_open_gt[key] then
    popup_open_gt[key] = now_gt
  end
  local elapsed = now_gt - popup_open_gt[key]
  if elapsed < 0 then
    elapsed = 0
  end
  local reveal_step_ms = 35
  local visible = math.floor(elapsed / reveal_step_ms) + 1
  if visible < 1 then
    visible = 1
  elseif visible > total then
    visible = total
  end
  return visible
end

function F.default_clock_xy(sw, sh, tw)
  local x = math.floor((sw - tw) / 2)
  local y = sh - CFG.MARGIN_BOTTOM - CFG.FONT_SIZE
  return x, y
end

function F.clock_spin_offset(gt)
  if not clock_spin_start_gt then
    return 0, 0
  end
  local elapsed = gt - clock_spin_start_gt
  if elapsed >= CFG.CLOCK_SPIN_MS then
    clock_spin_start_gt = nil
    return 0, 0
  end
  local u = elapsed / CFG.CLOCK_SPIN_MS
  local ang = u * 2 * math.pi
  local r = 42 * (1 - u)
  return math.cos(ang) * r, math.sin(ang) * r
end

function F.clock_edit_end_cursor()
  if sampSetCursorMode then
    sampSetCursorMode(0)
  end
  clock_edit_active = false
  clock_follow_cursor = false
  clock_edit_skip_until_gt = nil
end

function F.set_menu_state(opened)
  menuOpen.v = opened
  imgui.Process = opened
  imgui.ShowCursor = opened
  imgui.LockPlayer = false
  if sampSetCursorMode and not clock_edit_active then
    if opened then
      sampSetCursorMode(2)
    else
      sampSetCursorMode(0)
    end
  end
  if opened then
    menu_star_last_gt = nil
    menu_stars = {}
    menu_click_spark_last_gt = nil
  else
    menu_click_sparks = {}
  end
end

function F.begin_clock_position_edit(reopen_menu_after)
  reopen_menu_after_clock_edit = reopen_menu_after and true or false
  F.set_menu_state(false)
  imgui.ShowCursor = true
  clock_edit_active = true
  clock_follow_cursor = false
  clock_edit_skip_until_gt = getGameTimer() + 450
  clock_lmb_was = isKeyDown and isKeyDown(CFG.VK_LBUTTON) or false
  clock_drag_offset_x = 0
  clock_drag_offset_y = 0
  if sampSetCursorMode then
    sampSetCursorMode(2)
  end
end

function F.maybe_reopen_menu_after_clock_edit()
  if reopen_menu_after_clock_edit then
    reopen_menu_after_clock_edit = false
    F.set_menu_state(true)
    menu_center_on_open = true
  end
end

function F.ensure_menu_bg_texture()
  if menu_bg_texture then
    return menu_bg_texture
  end
  local now_gt = getGameTimer and getGameTimer() or 0
  if menu_bg_texture_failed and now_gt < (menu_bg_retry_after_gt or 0) then
    return nil
  end
  if not imgui.CreateTextureFromFile then
    menu_bg_texture_failed = true
    menu_bg_retry_after_gt = now_gt + 5000
    return nil
  end
  local candidates = {}
  if CFG.MENU_BG_IMAGE_FILE and CFG.MENU_BG_IMAGE_FILE ~= "" then
    local dir = F.script_dir_path()
    if dir and dir ~= "" then
      candidates[#candidates + 1] = dir .. "\\" .. CFG.MENU_BG_IMAGE_FILE
    end
    local wd = getWorkingDirectory and getWorkingDirectory() or ""
    if wd ~= "" then
      candidates[#candidates + 1] = wd .. "\\moonloader\\" .. CFG.MENU_BG_IMAGE_FILE
      candidates[#candidates + 1] = wd .. "\\" .. CFG.MENU_BG_IMAGE_FILE
    end
  end
  menu_bg_image_path = nil
  for i = 1, #candidates do
    if F.file_exists(candidates[i]) then
      menu_bg_image_path = candidates[i]
      break
    end
  end
  if not menu_bg_image_path then
    menu_bg_texture_failed = true
    menu_bg_retry_after_gt = now_gt + 5000
    return nil
  end
  local ok, tex = pcall(imgui.CreateTextureFromFile, menu_bg_image_path)
  if ok and tex then
    menu_bg_texture = tex
    menu_bg_texture_failed = false
    menu_bg_retry_after_gt = 0
    return menu_bg_texture
  end
  menu_bg_texture_failed = true
  menu_bg_retry_after_gt = now_gt + 5000
  return nil
end

function F.random_menu_star(w, h)
  local sx = math.random() * math.max(1, w)
  local sy = (math.random() * math.max(1, h)) - math.max(32, h * 0.35)
  local speed = CFG.MENU_STAR_MIN_SPEED + math.random() * (CFG.MENU_STAR_MAX_SPEED - CFG.MENU_STAR_MIN_SPEED)
  local len = CFG.MENU_STAR_MIN_LEN + math.random() * (CFG.MENU_STAR_MAX_LEN - CFG.MENU_STAR_MIN_LEN)
  local alpha = math.floor(CFG.MENU_STAR_MIN_ALPHA + math.random() * (CFG.MENU_STAR_MAX_ALPHA - CFG.MENU_STAR_MIN_ALPHA))
  return {
    x = sx,
    y = sy,
    speed = speed,
    len = len,
    alpha = alpha,
  }
end

function F.reset_menu_starfield(w, h)
  menu_stars = {}
  for i = 1, CFG.MENU_STARS_COUNT do
    menu_stars[i] = F.random_menu_star(w, h)
  end
  menu_star_last_gt = getGameTimer()
end

function F.menu_star_color(alpha)
  local a = math.max(0, math.min(255, alpha or 255)) / 255.0
  return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.94, 0.98, 1.00, a))
end

function F.update_and_draw_menu_stars(draw_list, win_x, win_y, w, h, gt)
  if #menu_stars == 0 then
    F.reset_menu_starfield(w, h)
  end
  if not menu_star_last_gt then
    menu_star_last_gt = gt
  end
  local dt_ms = gt - menu_star_last_gt
  if dt_ms < 0 then
    dt_ms = 0
  elseif dt_ms > 50 then
    dt_ms = 50
  end
  local dt = dt_ms / 1000.0
  menu_star_last_gt = gt
  local dir_x = 1.0
  local dir_y = 0.58
  local dir_len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
  dir_x = dir_x / dir_len
  dir_y = dir_y / dir_len

  for i = 1, #menu_stars do
    local s = menu_stars[i]
    s.x = s.x + dir_x * s.speed * dt
    s.y = s.y + dir_y * s.speed * dt
    if s.x > w + s.len + 20 or s.y > h + s.len + 20 then
      menu_stars[i] = F.random_menu_star(w, h)
      s = menu_stars[i]
    end
    local hx = s.x
    local hy = s.y
    local tx = s.x - dir_x * s.len
    local ty = s.y - dir_y * s.len
    draw_list:AddLine(
      imgui.ImVec2(win_x + hx, win_y + hy),
      imgui.ImVec2(win_x + tx, win_y + ty),
      F.menu_star_color(s.alpha),
      CFG.MENU_STAR_LINE_THICK
    )
    if draw_list.AddCircleFilled then
      draw_list:AddCircleFilled(imgui.ImVec2(win_x + hx, win_y + hy), 1.6, F.menu_star_color(math.min(255, s.alpha + 24)), 8)
    end
  end
end

function F.spawn_menu_button_sparks(cx, cy)
  for _ = 1, CFG.MENU_CLICK_SPARK_COUNT do
    local ang = math.random() * math.pi * 2.0
    local speed = CFG.MENU_CLICK_SPARK_SPEED_MIN + math.random() * (CFG.MENU_CLICK_SPARK_SPEED_MAX - CFG.MENU_CLICK_SPARK_SPEED_MIN)
    local life_ms = CFG.MENU_CLICK_SPARK_LIFE_MIN_MS + math.random() * (CFG.MENU_CLICK_SPARK_LIFE_MAX_MS - CFG.MENU_CLICK_SPARK_LIFE_MIN_MS)
    menu_click_sparks[#menu_click_sparks + 1] = {
      x = cx,
      y = cy,
      vx = math.cos(ang) * speed,
      vy = math.sin(ang) * speed - 45,
      life_ms = life_ms,
      max_life_ms = life_ms,
    }
  end
end

function F.update_and_draw_button_sparks(draw_list, gt)
  if #menu_click_sparks == 0 then
    menu_click_spark_last_gt = gt
    return
  end
  if not menu_click_spark_last_gt then
    menu_click_spark_last_gt = gt
  end
  local dt_ms = gt - menu_click_spark_last_gt
  if dt_ms < 0 then
    dt_ms = 0
  elseif dt_ms > 50 then
    dt_ms = 50
  end
  menu_click_spark_last_gt = gt
  local dt = dt_ms / 1000.0

  for i = #menu_click_sparks, 1, -1 do
    local p = menu_click_sparks[i]
    p.life_ms = p.life_ms - dt_ms
    if p.life_ms <= 0 then
      table.remove(menu_click_sparks, i)
    else
      local px = p.x
      local py = p.y
      p.vy = p.vy + CFG.MENU_CLICK_SPARK_GRAVITY * dt
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      local a = math.max(0.0, math.min(1.0, p.life_ms / p.max_life_ms))
      local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.90, 0.96, 1.00, a))
      if draw_list.AddLine then
        draw_list:AddLine(imgui.ImVec2(px, py), imgui.ImVec2(p.x, p.y), col, 1.8)
      end
      if draw_list.AddCircleFilled then
        draw_list:AddCircleFilled(imgui.ImVec2(p.x, p.y), 1.2, col, 8)
      end
    end
  end
end

function F.menu_button(label, size, keep_external_colors)
  if not keep_external_colors then
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 14.0)
    imgui.PushStyleVar(imgui.StyleVar.FramePadding, imgui.ImVec2(12, 7))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.34, 0.42, 0.76, 0.72))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.45, 0.56, 0.90, 0.82))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.24, 0.32, 0.62, 0.92))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.95, 0.97, 1.00, 0.98))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.70, 0.78, 0.98, 0.65))
  end
  local clicked = imgui.Button(label, size)
  if not keep_external_colors then
    imgui.PopStyleColor(5)
    imgui.PopStyleVar(2)
  end
  if clicked and imgui.GetItemRectMin and imgui.GetItemRectMax then
    local rmin = imgui.GetItemRectMin()
    local rmax = imgui.GetItemRectMax()
    local cx = (rmin.x + rmax.x) * 0.5
    local cy = (rmin.y + rmax.y) * 0.5
    F.spawn_menu_button_sparks(cx, cy)
  end
  return clicked
end

function F.utf8_char_list(s)
  local out = {}
  for ch in (s or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    out[#out + 1] = ch
  end
  return out
end

function F.clock_text_size(font_obj, text)
  local rot = clock_rotation_quarter % 4
  if rot == 0 or rot == 2 then
    return renderGetFontDrawTextLength(font_obj, text), math.floor(CFG.FONT_SIZE * 1.2)
  end
  local char_h = math.floor(CFG.FONT_SIZE * 1.8)
  local chars = F.utf8_char_list(text)
  local max_w = 0
  for i = 1, #chars do
    local ch = chars[i]
    local cw = renderGetFontDrawTextLength(font_obj, ch)
    if cw > max_w then
      max_w = cw
    end
  end
  return max_w, char_h * #chars
end

function F.argb_set_alpha(argb, alpha)
  alpha = math.max(0, math.min(255, math.floor(alpha + 0.5)))
  local rgb = argb % 0x1000000
  return alpha * 0x1000000 + rgb
end

function F.draw_hud_clock_glow(font_obj, text, x, y, color_argb)
  if not hud_glow_enabled.v then
    return
  end
  local st = math.max(0, math.min(100, hud_glow_strength.v or 0)) / 100.0
  if st <= 0.01 then
    return
  end
  local dirs = {
    { 2, 0 },
    { -2, 0 },
    { 0, 2 },
    { 0, -2 },
    { 3, 1 },
    { 3, -1 },
    { -3, 1 },
    { -3, -1 },
    { 1, 3 },
    { 1, -3 },
    { -1, 3 },
    { -1, -3 },
    { 4, 0 },
    { -4, 0 },
    { 0, 4 },
    { 0, -4 },
    { 3, 3 },
    { 3, -3 },
    { -3, 3 },
    { -3, -3 },
    { 5, 0 },
    { -5, 0 },
    { 0, 5 },
    { 0, -5 },
  }
  for i = 1, #dirs do
    local ox, oy = dirs[i][1], dirs[i][2]
    local dist = math.sqrt(ox * ox + oy * oy)
    local a = math.floor((118 - dist * 9) * st)
    if a > 10 then
      renderFontDrawText(font_obj, text, x + ox, y + oy, F.argb_set_alpha(color_argb, a))
    end
  end
  for i = 1, #dirs do
    local ox, oy = dirs[i][1], dirs[i][2]
    local dist = math.sqrt(ox * ox + oy * oy)
    local a = math.floor((42 - dist * 3) * st)
    if a > 6 then
      renderFontDrawText(font_obj, text, x + ox, y + oy, F.argb_set_alpha(0xFFFFFFFF, a))
    end
  end
end

function F.draw_hud_clock_shadow(font_obj, text, x, y)
  if not hud_shadow_enabled.v then
    return
  end
  local st = math.max(0, math.min(100, hud_glow_strength.v or 0)) / 100.0
  local a1 = math.floor((110 + 90 * st) * 0.85)
  local a2 = math.floor((110 + 90 * st) * 0.32)
  if a1 < 18 then
    return
  end
  renderFontDrawText(font_obj, text, x + 2, y + 2, F.argb_set_alpha(0xFF000000, a1))
  renderFontDrawText(font_obj, text, x + 3, y + 3, F.argb_set_alpha(0xFF000000, a2))
end

function F.draw_clock_text(font_obj, text, x, y, color_argb)
  local rot = clock_rotation_quarter % 4
  if rot == 0 then
    F.draw_hud_clock_glow(font_obj, text, x, y, color_argb)
    F.draw_hud_clock_shadow(font_obj, text, x, y)
    F.draw_outlined_render_text(font_obj, text, x, y, color_argb)
    return
  end
  if rot == 2 then
    F.draw_hud_clock_glow(font_obj, text, x, y, color_argb)
    F.draw_hud_clock_shadow(font_obj, text, x, y)
    F.draw_outlined_render_text(font_obj, text, x, y, color_argb)
    return
  end
  local seq = F.utf8_char_list(text)
  if rot == 3 then
    local rev = {}
    for i = #seq, 1, -1 do
      rev[#rev + 1] = seq[i]
    end
    seq = rev
  end
  local char_h = math.floor(CFG.FONT_SIZE * 1.8)
  for i = 1, #seq do
    local ch = seq[i]
    local cx = x
    local cy = y + (i - 1) * char_h
    F.draw_hud_clock_glow(font_obj, ch, cx, cy, color_argb)
    F.draw_hud_clock_shadow(font_obj, ch, cx, cy)
    F.draw_outlined_render_text(font_obj, ch, cx, cy, color_argb)
  end
end

F.parse_alarm_duration_hms = function(s)
  s = F.trim(s or "")
  if s == "" then
    return nil
  end
  local h, m, sec = s:match("^(%d+):(%d+):(%d+)$")
  if not h then
    return nil
  end
  h, m, sec = tonumber(h), tonumber(m), tonumber(sec)
  if m > 59 or sec > 59 then
    return nil
  end
  local total_sec = h * 3600 + m * 60 + sec
  if total_sec <= 0 then
    return nil
  end
  return total_sec * 1000
end

F.format_hms_from_ms = function(ms)
  local s = math.floor(ms / 1000)
  local h = math.floor(s / 3600)
  s = s % 3600
  local m = math.floor(s / 60)
  s = s % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

F.format_hms_from_game_timer_ms = function(ms)
  if not ms or ms < 0 then
    ms = 0
  end
  local s = math.floor(ms / 1000)
  local h = math.floor(s / 3600)
  s = s % 3600
  local m = math.floor(s / 60)
  s = s % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

function F.argb_from_rgb(r, g, b)
  r = math.max(0, math.min(255, math.floor(r + 0.5)))
  g = math.max(0, math.min(255, math.floor(g + 0.5)))
  b = math.max(0, math.min(255, math.floor(b + 0.5)))
  return 0xFF000000 + r * 65536 + g * 256 + b
end

function F.blend_rgb(a, b, w)
  w = math.max(0, math.min(1, w))
  return F.argb_from_rgb(a[1] + (b[1] - a[1]) * w, a[2] + (b[2] - a[2]) * w, a[3] + (b[3] - a[3]) * w)
end

local COLOR_GETTERS = {}

function F.add_solid(name, r, g, b)
  local c = F.argb_from_rgb(r, g, b)
  COLOR_GETTERS[name] = function()
    return c
  end
end

function F.add_shimmer(name, fn)
  COLOR_GETTERS[name] = fn
end

F.add_solid("white", 255, 255, 255)
F.add_solid("red", 255, 64, 64)
F.add_solid("green", 96, 255, 128)
F.add_solid("blue", 96, 170, 255)
F.add_solid("yellow", 255, 255, 96)
F.add_solid("orange", 255, 165, 64)
F.add_solid("cyan", 96, 235, 255)
F.add_solid("magenta", 255, 96, 255)
F.add_solid("pink", 255, 150, 200)
F.add_solid("purple", 176, 112, 255)
F.add_solid("lime", 200, 255, 80)
F.add_solid("gold", 255, 205, 96)
F.add_solid("silver", 205, 208, 220)
F.add_solid("navy", 64, 104, 200)
F.add_solid("gray", 168, 172, 180)
F.add_solid("black", 48, 48, 52)

F.add_shimmer("shimmer_red_orange", function(ms)
  local phase = ms / 650
  local w = (math.sin(phase) + 1) * 0.5
  local w2 = (math.sin(phase * 1.7 + 1.1) + 1) * 0.5
  return F.argb_from_rgb(255, 55 + w * 165, 8 + w2 * 55)
end)

F.add_shimmer("shimmer_rainbow", function(ms)
  local t = (ms / 1100) % 1 * 6
  local f = t - math.floor(t)
  local i = math.floor(t)
  local r, g, b = 0, 0, 0
  if i == 0 then
    r, g = 255, math.floor(255 * f)
  elseif i == 1 then
    r, g = math.floor(255 * (1 - f)), 255
  elseif i == 2 then
    g, b = 255, math.floor(255 * f)
  elseif i == 3 then
    g, b = math.floor(255 * (1 - f)), 255
  elseif i == 4 then
    b, r = 255, math.floor(255 * f)
  else
    b, r = math.floor(255 * (1 - f)), 255
  end
  return F.argb_from_rgb(r, g, b)
end)

F.add_shimmer("shimmer_fire", function(ms)
  local w = (math.sin(ms / 400) + 1) * 0.5
  local w2 = (math.sin(ms / 290 + 0.7) + 1) * 0.5
  return F.blend_rgb({ 255, 48, 0 }, { 255, 230, 80 }, 0.42 * w + 0.38 * w2)
end)

F.add_shimmer("shimmer_ocean", function(ms)
  local w = (math.sin(ms / 520) + 1) * 0.5
  return F.blend_rgb({ 32, 110, 200 }, { 140, 235, 255 }, w)
end)

F.add_shimmer("shimmer_ice", function(ms)
  local w = (math.sin(ms / 580 + 0.4) + 1) * 0.5
  local w2 = (math.sin(ms / 410 + 1.2) + 1) * 0.5
  return F.blend_rgb(F.blend_rgb({ 210, 245, 255 }, { 120, 200, 255 }, w), { 255, 255, 255 }, 0.25 * w2)
end)

F.add_shimmer("shimmer_violet", function(ms)
  local w = (math.sin(ms / 500) + 1) * 0.5
  return F.blend_rgb({ 160, 80, 255 }, { 255, 130, 210 }, w)
end)

F.add_shimmer("shimmer_gold", function(ms)
  local w = (math.sin(ms / 450) + 1) * 0.5
  return F.blend_rgb({ 255, 190, 70 }, { 255, 255, 210 }, w)
end)

F.add_shimmer("shimmer_sunset", function(ms)
  local w = (math.sin(ms / 480) + 1) * 0.5
  local w2 = (math.sin(ms / 360 + 0.9) + 1) * 0.5
  return F.blend_rgb(F.blend_rgb({ 255, 90, 70 }, { 255, 170, 210 }, w), { 255, 150, 80 }, 0.35 * w2)
end)

F.add_shimmer("duo_red_blue", function(ms)
  local w = (math.sin(ms / 600) + 1) * 0.5
  return F.blend_rgb({ 255, 64, 64 }, { 100, 120, 255 }, w)
end)

F.add_shimmer("duo_green_cyan", function(ms)
  local w = (math.sin(ms / 550) + 1) * 0.5
  return F.blend_rgb({ 80, 255, 140 }, { 80, 230, 255 }, w)
end)

F.add_shimmer("duo_orange_magenta", function(ms)
  local w = (math.sin(ms / 530) + 1) * 0.5
  return F.blend_rgb({ 255, 160, 64 }, { 255, 90, 230 }, w)
end)

F.add_shimmer("duo_yellow_purple", function(ms)
  local w = (math.sin(ms / 620) + 1) * 0.5
  return F.blend_rgb({ 255, 255, 100 }, { 180, 100, 255 }, w)
end)

F.add_shimmer("trio_rgb", function(ms)
  local r = 127 + 127 * math.sin(ms / 520)
  local g = 127 + 127 * math.sin(ms / 520 + 2.1)
  local b = 127 + 127 * math.sin(ms / 520 + 4.2)
  return F.argb_from_rgb(r, g, b)
end)

F.add_shimmer("trio_cmy", function(ms)
  local c = (math.sin(ms / 480) + 1) * 0.5
  local m = (math.sin(ms / 480 + 2.09) + 1) * 0.5
  local y = (math.sin(ms / 480 + 4.18) + 1) * 0.5
  local s = c + m + y
  if s < 1e-6 then
    s = 1
  end
  c, m, y = c / s, m / s, y / s
  local r = 255 * (1 - c) + 40 * y
  local g = 255 * (1 - m) + 40 * c
  local b = 255 * (1 - y) + 40 * m
  return F.argb_from_rgb(r, g, b)
end)

local COLOR_ALIASES = {
  rainbow = "shimmer_rainbow",
  fire = "shimmer_fire",
  ocean = "shimmer_ocean",
  ice = "shimmer_ice",
  violet = "shimmer_violet",
  gold_anim = "shimmer_gold",
  sunset = "shimmer_sunset",
  redorange = "shimmer_red_orange",
  default = "shimmer_red_orange",
  reset = "shimmer_red_orange",
}

local COLOR_MENU_OPTIONS = {
  { key = "white", label = "White" },
  { key = "red", label = "Red" },
  { key = "green", label = "Green" },
  { key = "blue", label = "Blue" },
  { key = "yellow", label = "Yellow" },
  { key = "orange", label = "Orange" },
  { key = "cyan", label = "Cyan" },
  { key = "magenta", label = "Magenta" },
  { key = "pink", label = "Pink" },
  { key = "purple", label = "Purple" },
  { key = "gold", label = "Gold" },
  { key = "silver", label = "Silver" },
  { key = "gray", label = "Gray" },
  { key = "black", label = "Black" },
  { key = "shimmer_red_orange", label = "Shimmer Red Orange" },
  { key = "shimmer_rainbow", label = "Shimmer Rainbow" },
  { key = "shimmer_fire", label = "Shimmer Fire" },
  { key = "shimmer_ocean", label = "Shimmer Ocean" },
  { key = "shimmer_ice", label = "Shimmer Ice" },
  { key = "shimmer_violet", label = "Shimmer Violet" },
  { key = "shimmer_gold", label = "Shimmer Gold" },
  { key = "shimmer_sunset", label = "Shimmer Sunset" },
  { key = "duo_red_blue", label = "Duo Red Blue" },
  { key = "duo_green_cyan", label = "Duo Green Cyan" },
  { key = "duo_orange_magenta", label = "Duo Orange Magenta" },
  { key = "duo_yellow_purple", label = "Duo Yellow Purple" },
  { key = "trio_rgb", label = "Trio RGB" },
  { key = "trio_cmy", label = "Trio CMY" },
}

function F.resolve_color_key(raw)
  local key = F.trim(raw):lower():gsub("%s+", "_")
  if key == "" then
    return nil
  end
  local aliased = COLOR_ALIASES[key]
  if aliased then
    key = aliased
  end
  if COLOR_GETTERS[key] then
    return key
  end
  return nil
end

F.timer_color_argb = function(ms)
  local fn = COLOR_GETTERS[color_mode]
  if not fn then
    color_mode = "shimmer_red_orange"
    fn = COLOR_GETTERS[color_mode]
  end
  return fn(ms)
end

function F.argb_to_imgui_color(argb)
  local a = math.floor(argb / 0x1000000) % 0x100
  local r = math.floor(argb / 0x10000) % 0x100
  local g = math.floor(argb / 0x100) % 0x100
  local b = argb % 0x100
  return imgui.ImVec4(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
end

function F.scale_rgb_vec4(c, mul, alpha)
  local r = math.min(1.0, c.x * mul)
  local g = math.min(1.0, c.y * mul)
  local b = math.min(1.0, c.z * mul)
  local a = alpha or c.w or 1.0
  return imgui.ImVec4(r, g, b, a)
end

function F.color_key_preview_vec4(key, gt)
  local fn = COLOR_GETTERS[key]
  if not fn then
    return imgui.ImVec4(0.30, 0.30, 0.30, 1.0)
  end
  local ok, argb = pcall(fn, gt or 0)
  if not ok or type(argb) ~= "number" then
    return imgui.ImVec4(0.30, 0.30, 0.30, 1.0)
  end
  local c = F.argb_to_imgui_color(argb)
  return imgui.ImVec4(c.x, c.y, c.z, 1.0)
end

F.draw_outlined_render_text = function(font_obj, text, x, y, color_argb)
  if not outline_enabled.v then
    renderFontDrawText(font_obj, text, x, y, color_argb)
    return
  end
  local outline = 0xCC000000
  for i = 1, #CFG.OUTLINE_COLOR_OPTIONS do
    local opt = CFG.OUTLINE_COLOR_OPTIONS[i]
    if opt.key == outline_color_key then
      outline = opt.argb
      break
    end
  end
  local t = outline_thickness and outline_thickness.v or 1
  if t < 0 then
    t = 0
  elseif t > 10 then
    t = 10
  end
  for d = 1, t do
    renderFontDrawText(font_obj, text, x - d, y, outline)
    renderFontDrawText(font_obj, text, x + d, y, outline)
    renderFontDrawText(font_obj, text, x, y - d, outline)
    renderFontDrawText(font_obj, text, x, y + d, outline)
    renderFontDrawText(font_obj, text, x - d, y - d, outline)
    renderFontDrawText(font_obj, text, x + d, y - d, outline)
    renderFontDrawText(font_obj, text, x - d, y + d, outline)
    renderFontDrawText(font_obj, text, x + d, y + d, outline)
  end
  renderFontDrawText(font_obj, text, x, y, color_argb)
end

function F.draw_outlined_imgui_text(x, y, scale, color_vec4, text)
  local outline = imgui.ImVec4(0, 0, 0, 1)
  imgui.SetWindowFontScale(scale)
  imgui.SetCursorPos(imgui.ImVec2(x - 2, y))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x + 2, y))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x, y - 2))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x, y + 2))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x - 1, y))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x + 1, y))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x, y - 1))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x, y + 1))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x - 1, y - 1))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x + 1, y - 1))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x - 1, y + 1))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x + 1, y + 1))
  imgui.TextColored(outline, text)
  imgui.SetCursorPos(imgui.ImVec2(x, y))
  imgui.TextColored(color_vec4, text)
  imgui.SetCursorPos(imgui.ImVec2(x + 1, y))
  imgui.TextColored(color_vec4, text)
  imgui.SetWindowFontScale(1.0)
end

F.time_table_now = function()
  if CFG.SERVER_UTC_PLUS == false then
    return os.date("*t")
  end
  local n = tonumber(CFG.SERVER_UTC_PLUS) or 0
  return os.date("!*t", os.time() + math.floor(n * 3600 + 0.5))
end

function F.print_color_help()
  sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Usage: /taimercolor <name>  |  /taimercolor list", 0xFF88CCFF)
  sampAddChatMessage(
    "{AAAAAA}Solids:{FFFFFF} white, red, green, blue, yellow, orange, cyan, magenta, pink, purple, lime, gold, silver, navy, gray, black",
    0xFF88CCFF
  )
  sampAddChatMessage(
    "{AAAAAA}Shimmer:{FFFFFF} shimmer_red_orange, shimmer_rainbow, shimmer_fire, shimmer_ocean, shimmer_ice, shimmer_violet, shimmer_gold, shimmer_sunset",
    0xFF88CCFF
  )
  sampAddChatMessage(
    "{AAAAAA}Duo:{FFFFFF} duo_red_blue, duo_green_cyan, duo_orange_magenta, duo_yellow_purple  {AAAAAA}|{FFFFFF}  {AAAAAA}Trio:{FFFFFF} trio_rgb, trio_cmy",
    0xFF88CCFF
  )
  sampAddChatMessage("{AAAAAA}Aliases:{FFFFFF} rainbow, fire, ocean, ice, violet, sunset, default, reset", 0xFF88CCFF)
end

function F.print_color_list()
  sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Current: {FFFFAA}" .. color_mode, 0xFF88CCFF)
  F.print_color_help()
end

function F.cmd_taimer()
  timer_visible = not timer_visible
  local msg = timer_visible and "Timer visible." or "Timer hidden."
  sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} " .. msg, 0xFF88CCFF)
end

function F.cmd_taimenu()
  F.set_menu_state(not menuOpen.v)
  if menuOpen.v then
    menu_center_on_open = true
  end
end

function F.cmd_taimerm(arg)
  local raw = F.unquote(arg or "")
  if raw == "" then
    sampAddChatMessage(
      '{88CCFF}[HUD Time]{FFFFFF} Usage: {AAAAAA}/taimerm "text"{FFFFFF} or {AAAAAA}/taimerm word',
      0xFF88CCFF
    )
    return
  end
  label_prefix = raw
  F.sync_menu_label_input_from_prefix()
  F.save_label_prefix()
  F.save_all_settings()
  sampAddChatMessage('{88CCFF}[HUD Time]{FFFFFF} Label: {FFFFAA}' .. raw, 0xFF88CCFF)
end

function F.cmd_taimercolor(arg)
  local raw = F.trim(arg or "")
  local low = raw:lower()
  if raw == "" or low == "help" then
    F.print_color_help()
    return
  end
  if low == "list" then
    F.print_color_list()
    return
  end
  local key = F.resolve_color_key(raw)
  if not key then
    sampAddChatMessage("{88CCFF}[HUD Time]{FF6666} Unknown mode.{FFFFFF} Use /taimercolor list", 0xFF88CCFF)
    return
  end
  color_mode = key
  F.save_all_settings()
  sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Color mode: {FFFFAA}" .. key, 0xFF88CCFF)
end

function F.cmd_tai(arg)
  local raw = F.trim(arg or "")
  if raw == "" then
    sampAddChatMessage(
      "{88CCFF}[HUD Time]{FFFFFF} Usage: {AAAAAA}/tai HH:MM:SS{FFFFFF} (countdown)  |  {AAAAAA}/tai off{FFFFFF} cancel",
      0xFF88CCFF
    )
    return
  end
  local low = raw:lower()
  if low == "off" or low == "cancel" or low == "stop" then
    F.cancel_all_timers()
    alarm_popup_until = nil
    alarm_bounce.inited = false
    alarm_bounce.last_gt = nil
    sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Timers cancelled.", 0xFF88CCFF)
    return
  end
  local dur_ms = F.parse_alarm_duration_hms(raw)
  if not dur_ms then
    sampAddChatMessage(
      "{88CCFF}[HUD Time]{FF6666} Invalid time.{FFFFFF} Use {AAAAAA}HH:MM:SS{FFFFFF} (e.g. {FFFFAA}00:15:30{FFFFFF}; minutes and seconds 00-59).",
      0xFF88CCFF
    )
    return
  end
  alarm_popup_until = nil
  alarm_bounce.inited = false
  alarm_bounce.last_gt = nil
  F.add_timer(dur_ms, "Timer", 0, "chat")
  sampAddChatMessage(
    "{88CCFF}[HUD Time]{FFFFFF} Timer started for {FFFFAA}" .. F.format_hms_from_ms(dur_ms) .. "{FFFFFF} from now.",
    0xFF88CCFF
  )
end

function F.cmd_taipos()
  if clock_edit_active then
    F.save_clock_position()
    F.clock_edit_end_cursor()
    clock_lmb_was = isKeyDown and isKeyDown(CFG.VK_LBUTTON) or false
    F.maybe_reopen_menu_after_clock_edit()
    sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Clock position saved.", 0xFF88CCFF)
    return
  end
  F.begin_clock_position_edit(false)
  sampAddChatMessage(
    "{88CCFF}[HUD Time]{FFFFFF} Move clock with mouse. {AAAAAA}LMB{FFFFFF} place. {FFFFAA}V{FFFFFF} save  {FFFFAA}R{FFFFFF} rotate 90 deg  {FFFFAA}X{FFFFFF} cancel/reset. {AAAAAA}/taipos{FFFFFF} save.",
    0xFF88CCFF
  )
end

function F.bootstrap_main()
  if not isSampLoaded() or not isSampfuncsLoaded() then
    return
  end
  F.load_label_prefix()
  F.load_all_settings()
  F.sync_menu_label_input_from_prefix()
  F.load_clock_position()
  while not isSampAvailable() do
    wait(100)
  end

  F.rebuild_timer_fonts()
  F.request_menu_imgui_font_rebuild(timer_font_name)
  font_alarm = renderCreateFont("Verdana", CFG.ALARM_FONT_SIZE, font_flag.BOLD)
  font_tool = renderCreateFont("Arial", 17, font_flag.BOLD)

  sampRegisterChatCommand("taimer", F.cmd_taimer)
  sampRegisterChatCommand("taimenu", F.cmd_taimenu)
  sampRegisterChatCommand("taimerm", F.cmd_taimerm)
  sampRegisterChatCommand("taimercolor", F.cmd_taimercolor)
  sampRegisterChatCommand("tai", F.cmd_tai)
  sampRegisterChatCommand("taipos", F.cmd_taipos)

  wait(-1)
end

function main()
  F.bootstrap_main()
end

function onScriptTerminate()
  if clock_edit_active then
    F.clock_edit_end_cursor()
  end
  if clock_custom then
    F.save_clock_position()
  end
  F.save_all_settings()
  if menu_bg_texture and imgui.ReleaseTexture then
    pcall(imgui.ReleaseTexture, menu_bg_texture)
    menu_bg_texture = nil
  end
end

function onD3DPresent()
  if not font or not font_alarm or not font_tool then
    return
  end
  if isSampLoaded() and not isSampAvailable() then
    return
  end

  local gt = getGameTimer()
  local sw, sh = getScreenResolution()
  F.process_menu_imgui_font_rebuild()

  if pending_begin_clock_edit then
    pending_begin_clock_edit = false
    F.begin_clock_position_edit(true)
    local t0 = F.time_table_now()
    local text0 = F.build_hud_text(string.format("%02d:%02d:%02d", t0.hour, t0.min, t0.sec))
    local tw0, _ = F.clock_text_size(font, text0)
    clock_x, clock_y = F.default_clock_xy(sw, sh, tw0)
    clock_custom = true
    clock_follow_cursor = false
    timer_visible = true
  end

  if clock_edit_active and sampSetCursorMode then
    sampSetCursorMode(2)
  end

  if menuOpen.v then
    local esc_down = (isKeyDown and isKeyDown(CFG.VK_ESCAPE)) or false
    if esc_down and not menu_esc_was then
      F.set_menu_state(false)
    end
    menu_esc_was = esc_down
  else
    menu_esc_was = false
  end

  F.process_timer_hotkeys(gt)
  F.update_timers_and_alarm(gt)

  if alarm_popup_until then
    if gt >= alarm_popup_until then
      alarm_popup_until = nil
      alarm_bounce.inited = false
      alarm_bounce.last_gt = nil
      alarm_close_lmb_was = false
    else
      local msg = CFG.ALARM_MSG
      local twa = renderGetFontDrawTextLength(font_alarm, msg)
      local content_w = math.ceil(twa) + CFG.ALARM_TEXT_WIDTH_EXTRA
      local text_h = math.ceil(CFG.ALARM_FONT_SIZE * 1.55) + 14
      local box_w = content_w + CFG.ALARM_TEXT_PAD * 2
      local box_h = text_h + CFG.ALARM_TEXT_PAD * 2
      local box_x = math.floor((sw - box_w) * 0.5)
      local box_y = math.floor((sh - box_h) * 0.5)
      local close_size = 22
      local close_x = box_x + box_w - close_size - 6
      local close_y = box_y + 6

      local elapsed = CFG.ALARM_POPUP_MS - (alarm_popup_until - gt)
      local remain = alarm_popup_until - gt
      local alpha_mul = 1.0
      if elapsed < CFG.ALARM_FADE_IN_MS then
        alpha_mul = elapsed / CFG.ALARM_FADE_IN_MS
      elseif remain < CFG.ALARM_FADE_OUT_MS then
        alpha_mul = remain / CFG.ALARM_FADE_OUT_MS
      end
      if alpha_mul < 0 then
        alpha_mul = 0
      elseif alpha_mul > 1 then
        alpha_mul = 1
      end
      local fade_a = math.floor(255 * alpha_mul + 0.5)
      local bg_a = math.floor(fade_a * 0.55 + 0.5)
      local bg_col = bg_a * 0x1000000 + 0x00242836
      if renderDrawBox then
        renderDrawBox(box_x, box_y, box_w, box_h, bg_col)
      end

      local pulse = (math.sin(gt / 150) + 1) * 0.5
      local border_a = math.floor((150 + 85 * pulse) * alpha_mul + 0.5)
      local border_col = border_a * 0x1000000 + 0x00FFC44D
      local border_w = 1.0 + pulse * 2.0
      if renderDrawLine then
        renderDrawLine(box_x, box_y, box_x + box_w, box_y, border_w, border_col)
        renderDrawLine(box_x, box_y + box_h, box_x + box_w, box_y + box_h, border_w, border_col)
        renderDrawLine(box_x, box_y, box_x, box_y + box_h, border_w, border_col)
        renderDrawLine(box_x + box_w, box_y, box_x + box_w, box_y + box_h, border_w, border_col)
      end
      if renderDrawBox then
        renderDrawBox(close_x, close_y, close_size, close_size, bg_col)
      end
      if renderDrawLine then
        renderDrawLine(close_x + 5, close_y + 5, close_x + close_size - 5, close_y + close_size - 5, 1.6, 0xFFFFFFFF)
        renderDrawLine(close_x + close_size - 5, close_y + 5, close_x + 5, close_y + close_size - 5, 1.6, 0xFFFFFFFF)
      end

      local text_x = box_x + CFG.ALARM_TEXT_PAD + math.floor((content_w - twa) * 0.5)
      local text_y = box_y + CFG.ALARM_TEXT_PAD + math.floor((text_h - CFG.ALARM_FONT_SIZE * 1.38) * 0.5)
      local ta = math.floor(255 * alpha_mul + 0.5)
      local shimmer = (math.sin(gt / 180) + 1) * 0.5
      local tr = 255
      local tg = math.floor(140 + (235 - 140) * shimmer + 0.5)
      local tb = math.floor(40 + (120 - 40) * shimmer + 0.5)
      local text_col = ta * 0x1000000 + tr * 0x10000 + tg * 0x100 + tb
      local out_col = math.floor(ta * 0.88) * 0x1000000 + 0x00000000
      renderFontDrawText(font_alarm, msg, text_x - 2, text_y, out_col)
      renderFontDrawText(font_alarm, msg, text_x + 2, text_y, out_col)
      renderFontDrawText(font_alarm, msg, text_x, text_y - 2, out_col)
      renderFontDrawText(font_alarm, msg, text_x, text_y + 2, out_col)
      renderFontDrawText(font_alarm, msg, text_x, text_y, text_col)

      if getCursorPos then
        local mx, my = getCursorPos()
        local down = (isKeyDown and isKeyDown(CFG.VK_LBUTTON)) or false
        if down and not alarm_close_lmb_was then
          if mx >= close_x and mx <= close_x + close_size and my >= close_y and my <= close_y + close_size then
            alarm_popup_until = nil
            alarm_bounce.inited = false
            alarm_bounce.last_gt = nil
          end
        end
        alarm_close_lmb_was = down
      else
        alarm_close_lmb_was = false
      end
    end
  else
    alarm_close_lmb_was = false
  end

  local show_clock = timer_visible or clock_edit_active
  if not show_clock then
    return
  end
  if menuOpen.v and not clock_edit_active then
    return
  end

  local text = F.format_clock_now(gt)
  local tw, th = F.clock_text_size(font, text)

  local base_x
  local base_y
  if clock_edit_active and clock_follow_cursor and getCursorPos then
    local mx, my = getCursorPos()
    base_x = math.floor(mx - clock_drag_offset_x)
    base_y = math.floor(my - clock_drag_offset_y)
    local min_y = CFG.TOOLBAR_BTN_H + CFG.TOOLBAR_ABOVE + 4
    base_x = math.max(0, math.min(base_x, sw - tw - 1))
    base_y = math.max(min_y, math.min(base_y, sh - th - 2))
    clock_x, clock_y = base_x, base_y
  elseif clock_edit_active and not clock_follow_cursor then
    base_x = math.max(0, math.min(clock_x, sw - tw - 1))
    base_y = math.max(0, math.min(clock_y, sh - th - 2))
    clock_x, clock_y = base_x, base_y
  elseif clock_custom then
    base_x = math.max(0, math.min(clock_x, sw - tw - 1))
    base_y = math.max(0, math.min(clock_y, sh - th - 2))
    clock_x, clock_y = base_x, base_y
  else
    base_x, base_y = F.default_clock_xy(sw, sh, tw)
  end

  local ox, oy = F.clock_spin_offset(gt)
  local draw_x = base_x + ox
  local draw_y = base_y + oy

  local drag_pad = 12
  if clock_edit_active and renderDrawBox then
    renderDrawBox(draw_x - drag_pad, draw_y - drag_pad, tw + drag_pad * 2, th + drag_pad * 2, 0x00000000)
  end

  local bar_w = 3 * CFG.TOOLBAR_BTN_W + 2 * CFG.TOOLBAR_GAP
  local bar_x = draw_x + math.floor((tw - bar_w) / 2)
  bar_x = math.max(0, math.min(bar_x, sw - bar_w - 1))
  local bar_y = draw_y - CFG.TOOLBAR_ABOVE - CFG.TOOLBAR_BTN_H
  if bar_y < 2 then
    bar_y = 2
  end

  if clock_edit_active and getCursorPos then
    local mx, my = getCursorPos()
    local down = (isKeyDown and isKeyDown(CFG.VK_LBUTTON)) or false
    local allow_click = not clock_edit_skip_until_gt or gt >= clock_edit_skip_until_gt
    if allow_click and down and not clock_lmb_was then
      local hit_toolbar = false
      if my >= bar_y and my <= bar_y + CFG.TOOLBAR_BTN_H and mx >= bar_x and mx <= bar_x + bar_w then
        for i = 0, 2 do
          local bx = bar_x + i * (CFG.TOOLBAR_BTN_W + CFG.TOOLBAR_GAP)
          if mx >= bx and mx <= bx + CFG.TOOLBAR_BTN_W then
            hit_toolbar = true
            if i == 0 then
              F.save_clock_position()
              F.clock_edit_end_cursor()
              F.maybe_reopen_menu_after_clock_edit()
              sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Clock position saved.", 0xFF88CCFF)
            elseif i == 1 then
              clock_rotation_quarter = (clock_rotation_quarter + 1) % 4
            else
              F.clear_clock_position_file()
              F.clock_edit_end_cursor()
              F.maybe_reopen_menu_after_clock_edit()
              sampAddChatMessage("{88CCFF}[HUD Time]{FFFFFF} Clock reset to default position.", 0xFF88CCFF)
            end
            break
          end
        end
      end
      if not hit_toolbar then
        if mx >= draw_x - drag_pad and mx <= draw_x + tw + drag_pad and my >= draw_y - drag_pad and my <= draw_y + th + drag_pad then
          clock_follow_cursor = true
          clock_drag_offset_x = mx - draw_x
          clock_drag_offset_y = my - draw_y
        else
          clock_follow_cursor = false
        end
      end
    end
    if not down then
      clock_follow_cursor = false
    end
    clock_lmb_was = down
  elseif not clock_edit_active then
    clock_lmb_was = false
  else
    clock_lmb_was = (isKeyDown and isKeyDown(CFG.VK_LBUTTON)) or false
  end

  if clock_edit_active then
    local labels = { "V", "R", "X" }
    for i = 0, 2 do
      local bx = bar_x + i * (CFG.TOOLBAR_BTN_W + CFG.TOOLBAR_GAP)
      if renderDrawBox then
        renderDrawBox(bx, bar_y, CFG.TOOLBAR_BTN_W, CFG.TOOLBAR_BTN_H, 0xCC202028)
      end
      local lab = labels[i + 1]
      local lw = renderGetFontDrawTextLength(font_tool, lab)
      local ly = bar_y + math.floor((CFG.TOOLBAR_BTN_H - 17) / 2)
      renderFontDrawText(font_tool, lab, bx + math.floor((CFG.TOOLBAR_BTN_W - lw) / 2), ly, 0xFFFFFFFF)
    end
  end

  F.draw_next_timer_overlay(gt, draw_x, draw_y, tw)
  F.draw_clock_text(font, text, draw_x, draw_y, F.animated_clock_color(gt))
end

function F.draw_menu_settings_section(ws)
  imgui.SetCursorPos(imgui.ImVec2(12, 34))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text("Индикатор времени:")
  imgui.SetWindowFontScale(1.0)
  imgui.SameLine()
  imgui.SetCursorPosX(math.max(420, ws.x - 290))
  if F.menu_button("Формат: " .. time_format_mode, imgui.ImVec2(120, 24)) then
    if time_format_mode == "24h" then
      time_format_mode = "12h"
    else
      time_format_mode = "24h"
    end
    F.save_all_settings()
  end
  imgui.SameLine()
  imgui.TextColored(imgui.ImVec4(0.8, 0.9, 1.0, 1.0), "F7 старт  F8 пауза  F9 стоп")

  local color_label = "Выбор цвета -"
  local color_btn_y = 66
  local color_btn_h = 28
  local label_size = imgui.CalcTextSize(color_label)
  local label_h = label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local label_y = color_btn_y + math.max(0, math.floor((color_btn_h - label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(color_label)
  imgui.SetWindowFontScale(1.0)
  local label_w = label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + label_w + 10, color_btn_y))
  if F.menu_button(color_mode, imgui.ImVec2(220, color_btn_h)) then
    imgui.OpenPopup("taimer_color_popup")
    popup_open_gt["taimer_color_popup"] = getGameTimer()
  end
  if imgui.BeginPopup("taimer_color_popup") then
    local gt_ui = getGameTimer()
    local visible_count = F.popup_visible_count("taimer_color_popup", #COLOR_MENU_OPTIONS)
    for i = 1, visible_count do
      local opt = COLOR_MENU_OPTIONS[i]
      if COLOR_GETTERS[opt.key] then
        local btn_text = opt.label .. "##" .. opt.key
        local base_col = F.color_key_preview_vec4(opt.key, gt_ui)
        imgui.PushStyleColor(imgui.Col.Button, F.scale_rgb_vec4(base_col, 0.80, 0.85))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, F.scale_rgb_vec4(base_col, 1.00, 0.94))
        imgui.PushStyleColor(imgui.Col.ButtonActive, F.scale_rgb_vec4(base_col, 1.15, 0.98))
        if F.menu_button(btn_text, imgui.ImVec2(220, 0), true) then
          color_mode = opt.key
          F.save_all_settings()
          imgui.CloseCurrentPopup()
        end
        imgui.PopStyleColor(3)
      end
    end
    imgui.EndPopup()
  else
    popup_open_gt["taimer_color_popup"] = nil
  end

  local text_label = "Изменение текста -"
  local text_row_y = 104
  local text_box_h = 30
  local text_label_size = imgui.CalcTextSize(text_label)
  local text_label_h = text_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local text_label_y = text_row_y + math.max(0, math.floor((text_box_h - text_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, text_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(text_label)
  imgui.SetWindowFontScale(1.0)

  local text_label_w = text_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + text_label_w + 10, text_row_y))
  imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.45, 0.45, 0.45, 0.55))
  imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.45, 0.45, 0.55))
  imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.50, 0.50, 0.50, 0.65))
  imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.55, 0.55, 0.55, 0.75))
  local text_preview = F.trim(label_prefix or "")
  if text_preview == "" then
    text_preview = "(пусто)"
  end
  F.menu_button(text_preview .. "##taimer_text_preview", imgui.ImVec2(280, 30))
  imgui.PopStyleColor(4)
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  if F.menu_button("Редактировать##open_label_editor", imgui.ImVec2(200, 30)) then
    menu_label_input.v = label_prefix or ""
    imgui.OpenPopup("Редактор текста##label_popup")
  end
  if imgui.BeginPopupModal("Редактор текста##label_popup", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
    imgui.Text("Введите новый текст индикатора:")
    imgui.PushItemWidth(360)
    imgui.InputText("##label_popup_input", menu_label_input)
    imgui.PopItemWidth()
    if F.menu_button("Сохранить##label_popup_save", imgui.ImVec2(170, 0)) then
      label_prefix = F.trim(menu_label_input.v or "")
      F.save_label_prefix()
      F.save_all_settings()
      imgui.CloseCurrentPopup()
    end
    imgui.SameLine()
    if F.menu_button("Отмена##label_popup_cancel", imgui.ImVec2(170, 0)) then
      imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
  end

  local font_label = "Шрифт -"
  local font_row_y = 142
  local font_btn_h = 28
  local font_label_size = imgui.CalcTextSize(font_label)
  local font_label_h = font_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local font_label_y = font_row_y + math.max(0, math.floor((font_btn_h - font_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, font_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(font_label)
  imgui.SetWindowFontScale(1.0)
  local font_label_w = font_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + font_label_w + 10, font_row_y))
  if F.menu_button("Font: " .. timer_font_name, imgui.ImVec2(220, font_btn_h)) then
    imgui.OpenPopup("taimer_font_popup")
    popup_open_gt["taimer_font_popup"] = getGameTimer()
  end
  if imgui.BeginPopup("taimer_font_popup") then
    local visible_count = F.popup_visible_count("taimer_font_popup", #CFG.TIMER_FONT_OPTIONS)
    for i = 1, visible_count do
      local fname = CFG.TIMER_FONT_OPTIONS[i]
      local btn_pos = imgui.GetCursorScreenPos and imgui.GetCursorScreenPos() or nil
      if F.menu_button(fname .. "##font_" .. tostring(i), imgui.ImVec2(220, 0)) then
        timer_font_name = fname
        F.rebuild_timer_fonts()
        F.request_menu_imgui_font_rebuild(timer_font_name)
        F.save_all_settings()
        imgui.CloseCurrentPopup()
      end
      if btn_pos then
        local preview_font = F.get_preview_font_by_name_size(fname, 13)
        local sample = "Abc 12:34"
        local sw = renderGetFontDrawTextLength(preview_font, sample)
        local sx = math.floor(btn_pos.x + 220 - sw - 8)
        local sy = math.floor(btn_pos.y + 4)
        F.draw_outlined_render_text(preview_font, sample, sx, sy, 0xFFD7E8FF)
      end
    end
    imgui.EndPopup()
  else
    popup_open_gt["taimer_font_popup"] = nil
  end

  local outline_label = "Обводка -"
  local outline_row_y = 180
  local outline_btn_h = 28
  local outline_label_size = imgui.CalcTextSize(outline_label)
  local outline_label_h = outline_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local outline_label_y = outline_row_y + math.max(0, math.floor((outline_btn_h - outline_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, outline_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(outline_label)
  imgui.SetWindowFontScale(1.0)
  local outline_label_w = outline_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + outline_label_w + 10, outline_row_y))
  if F.menu_button(outline_color_key, imgui.ImVec2(220, outline_btn_h)) then
    imgui.OpenPopup("taimer_outline_popup")
    popup_open_gt["taimer_outline_popup"] = getGameTimer()
  end
  if imgui.BeginPopup("taimer_outline_popup") then
    local visible_count = F.popup_visible_count("taimer_outline_popup", #CFG.OUTLINE_COLOR_OPTIONS)
    for i = 1, visible_count do
      local opt = CFG.OUTLINE_COLOR_OPTIONS[i]
      local base_col = F.argb_to_imgui_color(opt.argb)
      imgui.PushStyleColor(imgui.Col.Button, F.scale_rgb_vec4(base_col, 0.85, 0.86))
      imgui.PushStyleColor(imgui.Col.ButtonHovered, F.scale_rgb_vec4(base_col, 1.00, 0.94))
      imgui.PushStyleColor(imgui.Col.ButtonActive, F.scale_rgb_vec4(base_col, 1.15, 0.98))
      if F.menu_button(opt.label .. "##outline_" .. opt.key, imgui.ImVec2(220, 0), true) then
        outline_color_key = opt.key
        F.save_all_settings()
        imgui.CloseCurrentPopup()
      end
      imgui.PopStyleColor(3)
    end
    imgui.EndPopup()
  else
    popup_open_gt["taimer_outline_popup"] = nil
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  imgui.PushItemWidth(170)
  if imgui.SliderInt("Толщина обводки##outline_thickness", outline_thickness, 0, 10) then
    F.save_all_settings()
  end
  imgui.PopItemWidth()
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  imgui.Checkbox("Обводка##outline_enabled", outline_enabled)
  if imgui.IsItemDeactivatedAfterEdit and imgui.IsItemDeactivatedAfterEdit() then
    F.save_all_settings()
  end

  local glow_label = "Тень / свечение -"
  local glow_row_y = 218
  local glow_btn_h = 28
  local glow_label_size = imgui.CalcTextSize(glow_label)
  local glow_label_h = glow_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local glow_label_y = glow_row_y + math.max(0, math.floor((glow_btn_h - glow_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, glow_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(glow_label)
  imgui.SetWindowFontScale(1.0)
  local glow_label_w = glow_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + glow_label_w + 10, glow_row_y))
  imgui.Checkbox("Свечение##hud_glow", hud_glow_enabled)
  if imgui.IsItemDeactivatedAfterEdit and imgui.IsItemDeactivatedAfterEdit() then
    F.save_all_settings()
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  imgui.Checkbox("Тень##hud_shadow", hud_shadow_enabled)
  if imgui.IsItemDeactivatedAfterEdit and imgui.IsItemDeactivatedAfterEdit() then
    F.save_all_settings()
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  imgui.PushItemWidth(220)
  if imgui.SliderInt("Сила##hud_glow_strength", hud_glow_strength, 0, 100) then
    F.save_all_settings()
  end
  imgui.PopItemWidth()

  local pos_label = "Выбор местоположения -"
  local pos_row_y = 258
  local pos_btn_h = 28
  local pos_label_size = imgui.CalcTextSize(pos_label)
  local pos_label_h = pos_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local pos_label_y = pos_row_y + math.max(0, math.floor((pos_btn_h - pos_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, pos_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(pos_label)
  imgui.SetWindowFontScale(1.0)
  local pos_label_w = pos_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + pos_label_w + 10, pos_row_y))
  if F.menu_button("Изменить##position_edit", imgui.ImVec2(220, pos_btn_h)) then
    pending_begin_clock_edit = true
    F.set_menu_state(false)
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  if F.menu_button("Сброс##position_reset", imgui.ImVec2(120, pos_btn_h)) then
    local t_reset = F.time_table_now()
    local text_reset = F.build_hud_text(string.format("%02d:%02d:%02d", t_reset.hour, t_reset.min, t_reset.sec))
    local tw_reset, _ = F.clock_text_size(font, text_reset)
    local sw_reset, sh_reset = getScreenResolution()
    clock_x, clock_y = F.default_clock_xy(sw_reset, sh_reset, tw_reset)
    clock_custom = false
    F.clear_clock_position_file()
    F.save_all_settings()
  end
  local reset_label = "Восстановление параметров -"
  local reset_row_y = 296
  local reset_btn_h = 28
  local reset_label_size = imgui.CalcTextSize(reset_label)
  local reset_label_h = reset_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local reset_label_y = reset_row_y + math.max(0, math.floor((reset_btn_h - reset_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, reset_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(reset_label)
  imgui.SetWindowFontScale(1.0)
  local reset_label_w = reset_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  imgui.SetCursorPos(imgui.ImVec2(12 + reset_label_w + 10, reset_row_y))
  if F.menu_button("Восстановить##reset_all_settings", imgui.ImVec2(180, reset_btn_h)) then
    color_mode = "white"
    outline_enabled.v = false
    outline_thickness.v = 1
    hud_glow_enabled.v = true
    hud_glow_strength.v = 70
    hud_shadow_enabled.v = true
    time_format_mode = "24h"
    timer_repeat_enabled.v = false
    timer_repeat_minutes.v = 5
    timer_label_input.v = "Timer"
    F.cancel_all_timers()
    local t_reset = F.time_table_now()
    local text_reset = F.build_hud_text(string.format("%02d:%02d:%02d", t_reset.hour, t_reset.min, t_reset.sec))
    local tw_reset, _ = F.clock_text_size(font, text_reset)
    local sw_reset, sh_reset = getScreenResolution()
    clock_x, clock_y = F.default_clock_xy(sw_reset, sh_reset, tw_reset)
    clock_custom = false
    F.clear_clock_position_file()
    F.save_all_settings()
  end
end

function F.draw_menu_timer_and_history_section(ws)
  local gt_menu = getGameTimer()
  local t_menu = F.time_table_now()
  local menu_h = t_menu.hour
  if time_format_mode == "12h" then
    menu_h = menu_h % 12
    if menu_h == 0 then
      menu_h = 12
    end
  end
  local clock_menu = string.format("%02d:%02d:%02d", menu_h, t_menu.min, t_menu.sec)
  local text_menu = F.build_hud_text(clock_menu)
  local menu_scale = math.max(0.6, CFG.MENU_TIMER_FONT_SIZE / CFG.FONT_SIZE)
  local text_size = imgui.CalcTextSize(text_menu)
  local scaled_h = text_size.y * menu_scale
  local tx = 6
  imgui.SetCursorPos(imgui.ImVec2(12, 336))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text("Таймер:")
  imgui.SetWindowFontScale(1.0)

  local time_label = "Время -"
  local time_row_y = 370
  local time_btn_h = 28
  local time_label_size = imgui.CalcTextSize(time_label)
  local time_label_h = time_label_size.y * CFG.MENU_COLOR_LABEL_SCALE
  local time_label_y = time_row_y + math.max(0, math.floor((time_btn_h - time_label_h) * 0.5))
  imgui.SetCursorPos(imgui.ImVec2(12, time_label_y))
  imgui.SetWindowFontScale(CFG.MENU_COLOR_LABEL_SCALE)
  imgui.Text(time_label)
  imgui.SetWindowFontScale(1.0)
  local time_label_w = time_label_size.x * CFG.MENU_COLOR_LABEL_SCALE
  local time_input_x = 12 + time_label_w + 10
  local time_input_y = time_row_y
  local masked_digits = F.only_six_digits(menu_countdown_input.v or "")
  masked_digits = F.clamp_time_digits_by_position(masked_digits)
  local masked_text = F.format_hhmmss_mask(masked_digits)
  if menu_countdown_input.v ~= masked_text then
    menu_countdown_input.v = masked_text
  end
  imgui.SetCursorPos(imgui.ImVec2(time_input_x, time_input_y))
  imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.45, 0.45, 0.55))
  imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.50, 0.50, 0.50, 0.65))
  imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.55, 0.55, 0.55, 0.75))
  F.menu_button(masked_text .. "##menu_countdown_preview", imgui.ImVec2(180, 28))
  imgui.PopStyleColor(3)
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 8)
  if F.menu_button("Запустить##menu_countdown_start", imgui.ImVec2(120, time_btn_h)) then
    local digits = F.only_six_digits(menu_countdown_input.v or "")
    if #digits == 6 then
      local raw = F.format_hhmmss_mask(digits)
      local dur_ms = F.parse_alarm_duration_hms(raw)
      if dur_ms then
        local rep_ms = 0
        if timer_repeat_enabled.v then
          rep_ms = math.max(0, timer_repeat_minutes.v or 0) * 60000
        end
        alarm_popup_until = nil
        alarm_bounce.inited = false
        alarm_bounce.last_gt = nil
        F.add_timer(dur_ms, F.trim(timer_label_input.v or ""), rep_ms, "menu")
        menu_countdown_error = false
        F.save_all_settings()
      else
        menu_countdown_error = true
      end
    else
      menu_countdown_error = true
    end
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 6)
  local pause_text = timer_paused and "Продолжить" or "Пауза"
  if F.menu_button(pause_text .. "##menu_pause_resume", imgui.ImVec2(120, time_btn_h)) then
    if timer_paused then
      F.resume_all_timers(getGameTimer())
    else
      F.pause_all_timers(getGameTimer())
    end
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 6)
  if F.menu_button("Стоп все##menu_stop_all", imgui.ImVec2(100, time_btn_h)) then
    F.cancel_all_timers()
  end
  imgui.SameLine()
  imgui.SetCursorPosX(imgui.GetCursorPosX() + 6)
  if F.menu_button("Редактировать##open_time_editor", imgui.ImVec2(120, time_btn_h)) then
    local d = F.only_six_digits(menu_countdown_input.v or "")
    d = F.clamp_time_digits_by_position(d)
    menu_countdown_input.v = F.format_hhmmss_mask(d)
    imgui.OpenPopup("Редактор таймера##time_popup")
  end
  if imgui.BeginPopupModal("Редактор таймера##time_popup", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
    imgui.Text("Введите время HH:MM:SS")
    imgui.PushItemWidth(220)
    imgui.InputText("##time_popup_input", menu_countdown_input)
    local pd = F.only_six_digits(menu_countdown_input.v or "")
    pd = F.clamp_time_digits_by_position(pd)
    menu_countdown_input.v = F.format_hhmmss_mask(pd)
    imgui.PopItemWidth()
    if F.menu_button("Сохранить##time_popup_save", imgui.ImVec2(110, 0)) then
      local d = F.only_six_digits(menu_countdown_input.v or "")
      d = F.clamp_time_digits_by_position(d)
      menu_countdown_input.v = F.format_hhmmss_mask(d)
      F.save_all_settings()
      imgui.CloseCurrentPopup()
    end
    imgui.SameLine()
    if F.menu_button("Отмена##time_popup_cancel", imgui.ImVec2(110, 0)) then
      imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
  end

  imgui.SetCursorPos(imgui.ImVec2(12, time_row_y + 38))
  imgui.Text("Название -")
  imgui.SameLine()
  imgui.PushItemWidth(180)
  if imgui.InputText("##timer_label_input", timer_label_input) then
    F.save_all_settings()
  end
  imgui.PopItemWidth()
  imgui.SameLine()
  if imgui.Checkbox("Повтор##timer_repeat_enabled", timer_repeat_enabled) then
    F.save_all_settings()
  end
  imgui.SameLine()
  imgui.PushItemWidth(70)
  if imgui.InputInt("мин##timer_repeat_minutes", timer_repeat_minutes) then
    if timer_repeat_minutes.v < 0 then
      timer_repeat_minutes.v = 0
    end
    F.save_all_settings()
  end
  imgui.PopItemWidth()
  if timer_repeat_minutes.v < 0 then
    timer_repeat_minutes.v = 0
  end

  local gt_now = getGameTimer()
  local gt_show = timer_paused and (timer_pause_started_gt or gt_now) or gt_now
  menu_timer_list_text = F.build_timer_list_text(gt_show)
  imgui.SetCursorPos(imgui.ImVec2(12, time_row_y + 98))
  imgui.Text("Активные таймеры:")
  imgui.SetCursorPos(imgui.ImVec2(12, time_row_y + 118))
  imgui.TextColored(imgui.ImVec4(0.92, 0.96, 1.00, 1.00), menu_timer_list_text)

  if menu_countdown_error then
    imgui.SetCursorPos(imgui.ImVec2(time_input_x, time_input_y + time_btn_h + 4))
    imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), "Формат: HH:MM:SS")
  end
  local ty = math.max(0, ws.y - scaled_h - CFG.MENU_TIMER_BOTTOM_GAP)
  F.draw_outlined_imgui_text(tx, ty, menu_scale, F.argb_to_imgui_color(F.timer_color_argb(gt_menu)), text_menu)
end

function F.draw_menu_contact_section(ws)
  local info_text = "Нашли ошибку/баг/имеется предложение? Свяжитесь с создателем"
  local link_text = CFG.CREATOR_CONTACT_URL
  local info_size = imgui.CalcTextSize(info_text)
  local link_size = imgui.CalcTextSize(link_text)
  local margin = 12
  local info_x = math.max(12, ws.x - info_size.x - margin)
  local info_y = math.max(0, ws.y - link_size.y - info_size.y - 10)
  imgui.SetCursorPos(imgui.ImVec2(info_x, info_y))
  imgui.Text(info_text)
  local link_x = math.max(12, ws.x - link_size.x - margin)
  local link_y = info_y + info_size.y + 2
  imgui.SetCursorPos(imgui.ImVec2(link_x, link_y))
  imgui.TextColored(imgui.ImVec4(0.45, 0.65, 1.00, 1.00), link_text)
  local link_hovered = imgui.IsItemHovered and imgui.IsItemHovered() or false
  if link_hovered then
    imgui.SetCursorPos(imgui.ImVec2(link_x, link_y))
    imgui.TextColored(imgui.ImVec4(0.55, 0.75, 1.00, 1.00), link_text)
  end
  if imgui.IsItemClicked and imgui.IsItemClicked(0) then
    F.open_external_url(CFG.CREATOR_CONTACT_URL)
  end
end

function imgui.OnDrawFrame()
  if not menuOpen.v then
    return
  end

  imgui.Process = true
  imgui.ShowCursor = true
  imgui.LockPlayer = false

  imgui.SwitchContext()
  imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.10, 0.06, 0.20, 0.54)
  imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.38, 0.22, 0.96, 0.66)
  imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.50, 0.34, 1.00, 0.82)
  imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.56, 0.40, 1.00, 0.90)
  imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.24, 0.14, 0.52, 0.50)
  imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.34, 0.22, 0.72, 0.66)
  imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.42, 0.30, 0.86, 0.76)
  imgui.GetStyle().Colors[imgui.Col.PopupBg] = imgui.ImVec4(0.11, 0.08, 0.24, 0.74)
  imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(0.62, 0.50, 1.00, 0.56)
  imgui.GetStyle().Colors[imgui.Col.Text] = imgui.ImVec4(0.92, 0.92, 1.00, 0.96)

  local io = imgui.GetIO()
  local centerX = io.DisplaySize.x * 0.5
  local centerY = io.DisplaySize.y * 0.5

  if menu_center_on_open then
    imgui.SetNextWindowPos(imgui.ImVec2(centerX, centerY), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    menu_center_on_open = false
  end
  imgui.SetNextWindowSize(menuWindowSize, imgui.Cond.FirstUseEver)
  imgui.Begin("taimer menu", menuOpen, imgui.WindowFlags.NoCollapse)
  local wp = imgui.GetWindowPos()
  local ws = imgui.GetWindowSize()
  local bg_texture = F.ensure_menu_bg_texture()
  local draw_list = imgui.GetWindowDrawList and imgui.GetWindowDrawList() or nil

  if draw_list and bg_texture and draw_list.AddImage then
    pcall(
      function()
        draw_list:AddImage(
          bg_texture,
          imgui.ImVec2(wp.x, wp.y),
          imgui.ImVec2(wp.x + ws.x, wp.y + ws.y),
          imgui.ImVec2(0, 0),
          imgui.ImVec2(1, 1),
          CFG.MENU_BG_IMAGE_TINT
        )
      end
    )
  end


  local gt_menu_fx = getGameTimer()
  if draw_list and draw_list.AddLine and ws.x > 8 and ws.y > 8 then
    if draw_list.PushClipRect and draw_list.PopClipRect then
      draw_list:PushClipRect(
        imgui.ImVec2(wp.x, wp.y),
        imgui.ImVec2(wp.x + ws.x, wp.y + ws.y),
        true
      )
      F.update_and_draw_menu_stars(draw_list, wp.x, wp.y, ws.x, ws.y, gt_menu_fx)
      draw_list:PopClipRect()
    else
      F.update_and_draw_menu_stars(draw_list, wp.x, wp.y, ws.x, ws.y, gt_menu_fx)
    end
  end

  F.draw_menu_settings_section(ws)
  F.draw_menu_timer_and_history_section(ws)
  F.draw_menu_contact_section(ws)

  if draw_list and draw_list.AddLine then
    if draw_list.PushClipRect and draw_list.PopClipRect then
      draw_list:PushClipRect(
        imgui.ImVec2(wp.x, wp.y),
        imgui.ImVec2(wp.x + ws.x, wp.y + ws.y),
        true
      )
      F.update_and_draw_button_sparks(draw_list, gt_menu_fx)
      draw_list:PopClipRect()
    else
      F.update_and_draw_button_sparks(draw_list, gt_menu_fx)
    end
  end

  imgui.End()

  if not menuOpen.v then
    imgui.Process = false
    imgui.ShowCursor = false
    imgui.LockPlayer = false
  end
end

end)()