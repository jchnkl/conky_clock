--[[
  A conky clock by Jochen Keil (2013)
  based upon Alison Pitt's Air Clock (2009)

  This clock is designed to resemble the swiss railway clock:

  https://en.wikipedia.org/wiki/Swiss_railway_clock
  https://upload.wikimedia.org/wikipedia/de/7/7c/Minutensprunguhr_animiert.gif

  From the wikipedia article:
  [..]
  The second hand is driven by an electrical motor independent of the
  master clock. It requires only about 58.5 seconds to circle the face, then the
  hand pauses briefly at the top of the clock. It starts a new rotation as soon
  as it receives the next minute impulse from the master clock
  [..]

  This clock also rotates smoothly without "ticks".
  It will also stop on top for a configureable delay (look out for the global delay value)

  The main drawback is resource usage. For smooth circulation, conky needs to be
  updated every 0.1 second. Therefore I strongly recommend to run this in
  a seperate conky process.
  Additionally, if the update_interval is larger than 1 the seconds hand is not
  drawn. Hence, to save battery set update_interval_on_battery to 30 or so.
--]]

require 'cairo'
require 'socket'

-- how long to pause the seconds hand
delay = 2

-- r, g, b, a
background_color = { 1, 1, 1, 1 }

surface_bg = nil
surface_hours_hand = nil
surface_minutes_hand = nil
surface_seconds_hand = nil

function init(window)
  surface_bg = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                          window.width, window.height)
  surface_hours_hand = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                  window.width, window.height)
  surface_minutes_hand = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                    window.width, window.height)
  surface_seconds_hand = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                    window.width, window.height)

  draw_seconds_hand(window.width / 2, window.height / 2,
                    math.min(window.width, window.height) / 2)

  draw_marks(window.width / 2, window.height / 2,
             math.min(window.width, window.height) / 2)
end

function conky_shutdown()
  cairo_surface_destroy(surface_bg)
  cairo_surface_destroy(surface_hours_hand)
  cairo_surface_destroy(surface_minutes_hand)
  cairo_surface_destroy(surface_seconds_hand)
end

function draw_marks(xc, yc, clock_r)
  local cr = cairo_create(surface_bg)

  local minutes_len = clock_r * 0.075
  local minutes_thick = clock_r * 0.025
  local minutes_color = { 0.0, 0, 0, 1.0 }

  local hours_len = clock_r * 0.245
  local hours_thick = clock_r * 0.069
  local hours_color = { 0.0, 0, 0, 1.0 }
  local steps = 360/60

  local r,g,b,a = unpack(background_color)
  cairo_set_source_rgba(cr, r, g, b, a)
  cairo_arc(cr, xc, yc, clock_r, 0, 2 * math.pi)
  cairo_fill(cr)

  for deg = steps, 360, steps do
    local len = minutes_len
    local thick = minutes_thick
    local r,g,b,a = unpack(minutes_color)

    if deg % (360/12) == 0 then
      len = hours_len
      thick = hours_thick
      r,g,b,a = unpack(hours_color)
    end

    xbegin = xc + (clock_r - len) * math.sin(deg / (180/math.pi))
    ybegin = yc - (clock_r - len) * math.cos(deg / (180/math.pi))

    xend = xc + clock_r * math.sin(deg / (180/math.pi))
    yend = yc - clock_r * math.cos(deg / (180/math.pi))

    cairo_move_to(cr,xbegin,ybegin)
    cairo_line_to(cr,xend,yend)

    cairo_set_line_cap(cr,CAIRO_LINE_CAP_BUTT)
    cairo_set_line_width(cr,thick)
    cairo_set_source_rgba(cr,r,g,b,a)
    cairo_stroke(cr)
  end

  cairo_destroy(cr)
end

function draw_hours(xc, yc, clock_r, hours_arc)
  local hours_cr = cairo_create(surface_hours_hand)

  local xbegin=xc+(clock_r * -0.24)*math.sin(hours_arc)
  local ybegin=yc-(clock_r * -0.24)*math.cos(hours_arc)
  local xend=xc+(clock_r * 0.672)*math.sin(hours_arc)
  local yend=yc-(clock_r * 0.672)*math.cos(hours_arc)

  cairo_set_operator(hours_cr, CAIRO_OPERATOR_CLEAR)
  cairo_paint(hours_cr)
  cairo_set_operator(hours_cr, CAIRO_OPERATOR_SOURCE);

  cairo_move_to(hours_cr,xbegin,ybegin)
  cairo_line_to(hours_cr,xend,yend)

  cairo_set_line_width(hours_cr,clock_r * 0.11)
  cairo_stroke(hours_cr)

  cairo_destroy(hours_cr)
end

function draw_minutes(xc, yc, clock_r, mins_arc)
  local mins_cr = cairo_create(surface_minutes_hand)

  local xbegin=xc+(clock_r * -0.25)*math.sin(mins_arc)
  local ybegin=yc-(clock_r * -0.25)*math.cos(mins_arc)
  local xend=xc+(clock_r * 0.94)*math.sin(mins_arc)
  local yend=yc-(clock_r * 0.94)*math.cos(mins_arc)

  cairo_set_operator(mins_cr, CAIRO_OPERATOR_CLEAR)
  cairo_paint(mins_cr)
  cairo_set_operator(mins_cr, CAIRO_OPERATOR_SOURCE);

  cairo_move_to(mins_cr,xbegin,ybegin)
  cairo_line_to(mins_cr,xend,yend)

  cairo_set_line_width(mins_cr,clock_r * 0.08)
  cairo_stroke(mins_cr)

  cairo_destroy(mins_cr)
end

function draw_seconds_hand(xc, yc, clock_r)
  local secs_cr = cairo_create(surface_seconds_hand)

  local xbegin=xc
  local ybegin=yc-(clock_r * -0.34)
  local xend=xc
  local yend=yc-(clock_r * 0.65)

  cairo_set_source_rgba(secs_cr,1.0,0.0,0.0,1.0)

  cairo_move_to(secs_cr,xbegin,ybegin)
  cairo_line_to(secs_cr,xend,yend)

  cairo_set_line_width(secs_cr,clock_r * 0.025)
  cairo_stroke(secs_cr)

  cairo_arc(secs_cr, xend, yend, clock_r * 0.105, 0, 2 * math.pi)
  cairo_fill(secs_cr)

  cairo_destroy(secs_cr)
end

function conky_clock()
  if conky_window == nil then
    return
  elseif conky_window.width == 0 or conky_window.height == 0 then
    return
  end

  local first_run = surface_bg == nil
  if first_run then init(conky_window) end

  local w = conky_window.width
  local h = conky_window.height

  local cs = cairo_xlib_surface_create(conky_window.display,
                                       conky_window.drawable,
                                       conky_window.visual,
                                       w, h)

  local cr = cairo_create(cs)

  -- Settings

  local update_interval = conky_info["update_interval"]

  local clock_r = math.min(w,h) / 2

  local xc=w/2
  local yc=h/2

  local secs=os.date("%S")

  if tonumber(secs) == 0 or first_run then
    local mins=os.date("%M")
    local mins_arc=(2*math.pi/60)*mins
    draw_minutes(xc, yc, clock_r, mins_arc)

    local hours=os.date("%I")
    local hours_arc=(2*math.pi/12)*hours+mins_arc/12
    draw_hours(xc, yc, clock_r, hours_arc)
  end

  cairo_set_source_surface(cr, surface_bg, 0, 0)
  cairo_paint(cr)

  cairo_set_source_surface(cr, surface_hours_hand, 0, 0)
  cairo_paint(cr)

  cairo_set_source_surface(cr, surface_minutes_hand, 0, 0)
  cairo_paint(cr)

  if not (update_interval > 1) then
    local fac = 1 / update_interval
    local secs_arc = 2 * math.pi *
      (((secs + socket.gettime() - os.date("%s")) * fac) / ((60 - delay) * fac))

    if (secs_arc >= 0 or secs_arc <= (2 * math.pi) * (delay/60))
      and tonumber(secs) >= (60 - delay) then
      secs_arc = 0
    end

    cairo_translate(cr, xc, yc)
    cairo_rotate(cr, secs_arc)
    cairo_translate(cr, -xc, -yc)
    cairo_set_source_surface(cr, surface_seconds_hand, 0, 0)
    cairo_paint(cr)
  end

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end
