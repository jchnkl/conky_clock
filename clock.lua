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
background_color = (1, 1, 1, 1)

surface_bg = nil

function init(window)
  surface_bg = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                          window.width, window.height)
  local cr = cairo_create(surface_bg)
  draw_marks(cr, window.width / 2, window.height / 2,
             math.min(window.width, window.height) / 2)
  cairo_destroy(cr)
end

function conky_shutdown()
  cairo_surface_destroy(surface_bg)
end

function draw_marks(cr, xc, yc, clock_r)
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
end

function conky_clock()
  if conky_window == nil then
    return
  elseif conky_window.width == 0 or conky_window.height == 0 then
    return
  end

  if surface_bg == nil then init(conky_window) end

  local w = conky_window.width
  local h = conky_window.height

  local cs = cairo_xlib_surface_create(conky_window.display,
                                       conky_window.drawable,
                                       conky_window.visual,
                                       w, h)

  local cr = cairo_create(cs)

  cairo_set_source_surface(cr, surface_bg, 0, 0)
  cairo_paint(cr)

  -- Settings

  local update_interval = conky_info["update_interval"]
  local draw_seconds = not (update_interval > 1)

  local clock_r = math.min(w,h) / 2

  local xc=w/2
  local yc=h/2

  -- Grab time

  local hours=os.date("%I")
  local mins=os.date("%M")
  local secs=os.date("%S")

  local fac = 1 / update_interval
  local secs_arc = 2 * math.pi *
  (((secs + socket.gettime() - os.date("%s")) * fac) / ((60 - delay) * fac))

  if (secs_arc >= 0 or secs_arc <= (2 * math.pi) * (delay/60))
    and tonumber(secs) >= (60 - delay) then
    secs_arc = 0
  end

  mins_arc=(2*math.pi/60)*mins
  hours_arc=(2*math.pi/12)*hours+mins_arc/12

  -- Draw hour hand

  xbegin=xc+(clock_r * -0.24)*math.sin(hours_arc)
  ybegin=yc-(clock_r * -0.24)*math.cos(hours_arc)
  xend=xc+(clock_r * 0.672)*math.sin(hours_arc)
  yend=yc-(clock_r * 0.672)*math.cos(hours_arc)

  cairo_move_to(cr,xbegin,ybegin)
  cairo_line_to(cr,xend,yend)

  cairo_set_line_cap(cr,CAIRO_LINE_CAP_BUTT)
  cairo_set_line_width(cr,clock_r * 0.11)
  cairo_set_source_rgba(cr,0.0,0,0,1.0)
  cairo_stroke(cr)

  -- Draw minute hand

  xbegin=xc+(clock_r * -0.25)*math.sin(mins_arc)
  ybegin=yc-(clock_r * -0.25)*math.cos(mins_arc)
  xend=xc+(clock_r * 0.94)*math.sin(mins_arc)
  yend=yc-(clock_r * 0.94)*math.cos(mins_arc)

  cairo_move_to(cr,xbegin,ybegin)
  cairo_line_to(cr,xend,yend)

  cairo_set_line_width(cr,clock_r * 0.08)
  cairo_stroke(cr)

  -- Draw seconds hand

  if draw_seconds then
    cairo_set_source_rgba(cr,1.0,0.0,0.0,1.0)

    xbegin=xc+(clock_r * -0.34)*math.sin(secs_arc)
    ybegin=yc-(clock_r * -0.34)*math.cos(secs_arc)
    xend=xc+(clock_r * 0.65)*math.sin(secs_arc)
    yend=yc-(clock_r * 0.65)*math.cos(secs_arc)

    cairo_move_to(cr,xbegin,ybegin)
    cairo_line_to(cr,xend,yend)

    cairo_set_line_width(cr,clock_r * 0.025)
    cairo_stroke(cr)

    cairo_arc(cr, xend, yend, clock_r * 0.105, 0, 2 * math.pi)
    cairo_fill(cr)

    cairo_stroke(cr)
  end

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end
