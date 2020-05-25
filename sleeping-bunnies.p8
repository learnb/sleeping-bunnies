pico-8 cartridge // http://www.pico-8.com
version 23
__lua__
function _init()
  paused = true
  reset = false
  gameover = false
  io_lock_duration = 30*4
  io_lock_tick = io_lock_duration
  debug = 0
  init_menu()
end
function _update()
  if (io_lock_tick <= 0) then io_lock_tick = 0 else io_lock_tick = io_lock_tick - 1 end
  if reset then
    start_game()
  end
  if paused then
    update_menu()
  else
    if (btn(4,pad) and btn(5,pad)) then paused = not paused end
    if gameover then
      end_game()
    else
      update_sim()
    end
  end
end
function _draw()
  if paused then
    draw_menu()
  elseif (not gameover) then
    draw_sim()
  else
    draw_gameover()
  end
  print(debug, 3,3, 6)
end
function start_game()
  play_bg_music(isMusic)
  init_sim()
  pause = false
  reset = false
end
function end_game()
  -- select
  --local selected = 0
  if ( btnp(4, pad) and (io_lock_tick == 0) ) then
    reset = true
    gameover = false
  end
end
function draw_gameover()
  local _w = 64
  local _h = 64
  local _x = 64-(_w/2)
  local _y = 64-(_h/2)
  --
  rectfill(_x,_y, _x+_w,_y+_h, 1)
  print("game over", _x+1,_y+1, 6)
  print("score:", _x+1,_y+9, 6)
  print(ceil(score), _x+1,_y+16, 6)
  --
  if (io_lock_tick == 0) then
    print("press   to reset", _x+1,_y+58)
    spr(12, _x+22,_y+57)
  end
  --
  _x = 56
  spr(0, _x+1,_y+(8*3)+1, 0.5, 0.75)
  spr(16, _x,_y+(8*4))
  spr(16, _x,_y+(8*5))
  spr(16, _x,_y+(8*6))
  --
  if (rabbit.alive) then spr(26, _x+8,_y+(8*3)) else spr(27, _x+8,_y+(8*3)) end
  if (buns[1].alive) then spr(26, _x+8,_y+(8*4)) else spr(27, _x+8,_y+(8*4)) end
  if (buns[2].alive) then spr(26, _x+8,_y+(8*5)) else spr(27, _x+8,_y+(8*5)) end
  if (buns[3].alive) then spr(26, _x+8,_y+(8*6)) else spr(27, _x+8,_y+(8*6)) end
end
-->8
function init_sim()
  score = 0

  worldw = 128
  worldh = 128

  sniff_duration = 30*5
  sniff_cooldown = 30*15
  sniff_tick = sniff_duration
  sniff_lock = false

  reduce_rate = 0.01

  home = false

  -- rabbit
  rabbit = {}
  rabbit.x = 104
  rabbit.y = 102
  rabbit.hp = 100
  rabbit.alive = true
  rabbit.speed = 1
  rabbit.radius = 4
  rabbit.hidden = false
  rabbit.sniff = false

  rabbit.move_sprites = {4, 5, 6, 5}
  rabbit.move_tick = 0
  rabbit.move_frame = 1
  rabbit.move_step = 4

  rabbit.idle_sprites = {1,1,1,1, 2,2,2,2, 3,3,3,3, 2,2,18,2}
  rabbit.idle_tick = 0
  rabbit.idle_frame = 1
  rabbit.idle_step = 4
  rabbit.state = "idle"
  rabbit.flip = false

  -- bunnies
  bun1 = {}
  bun1.x = 104
  bun1.y = 100
  bun1.hp = 50
  bun1.alive = true
  bun1.radius = 8

  bun1.sprites = {16}
  bun1.tick = 0
  bun1.frame = 1
  bun1.step = 32

  bun1.idle_sprites = {17}
  bun1.idle_tick = 0
  bun1.idle_frame = 1
  bun1.idle_step = 16
  bun1.state = "idle"
  bun1.flip = false

  bun2 = {}
  bun2.x = 89
  bun2.y = 98
  bun2.hp = 50
  bun2.alive = true
  bun2.radius = 8

  bun2.sprites = {16}
  bun2.tick = 0
  bun2.frame = 1
  bun2.step = 32

  bun2.idle_sprites = {17}
  bun2.idle_tick = 0
  bun2.idle_frame = 1
  bun2.idle_step = 16
  bun2.state = "idle"
  bun2.flip = true

  bun3 = {}
  bun3.x = 96
  bun3.y = 104
  bun3.hp = 50
  bun3.alive = true
  bun3.radius = 8

  bun3.sprites = {16}
  bun3.tick = 0
  bun3.frame = 1
  bun3.step = 32

  bun3.idle_sprites = {17}
  bun3.idle_tick = 0
  bun3.idle_frame = 1
  bun3.idle_step = 16
  bun3.state = "idle"
  bun3.flip = false

  buns = {bun1, bun2, bun3}

  -- predators
  fox = {}
  fox.x = 80
  fox.y = 56
  fox.aradius = 32
  fox.cradius = 16

  fox.idle_tick = 0
  fox.idle_frame = 1
  fox.idle_step = 4
  fox.idle_sprites = {49,49,49,49, 49,49,49,49, 50,50,51,51, 50,50}

  fox.move_tick = 0
  fox.move_frame = 1
  fox.move_step = 4
  fox.move_sprites = {53, 54}
  fox.state = "idle"
  fox.anim_state = "idle"
  fox.flip = false

  -- food
  all_food = {}
  spawners = foodtiles()
  foreach(spawners, spawn_food)

  -- pathfinding tools
  path_init_heatmap()
  path_init_field()
end

function update_sim()
  local src = ent_tile(rabbit)
  gen_flow_field(src.x, src.y)
  -- game over check
  if (not rabbit.alive or ((not buns[1].alive) and (not buns[2].alive) and (not buns[3].alive))) then
    end_sim()
  end
  -- sniff ability
  if ((btnp(4, pad)) and (not sniff_lock)) then -- red btn
    if (not rabbit.sniff) then
      toggle_sniff_state()
    end
  end
  if (rabbit.sniff or sniff_lock) then
    sniff_tick = sniff_tick - 1
    if (sniff_tick <= 0) then
      if (sniff_lock) then -- end cooldown timer
        sniff_lock = false
        sniff_tick = sniff_duration
      else -- end sniff effect
        toggle_sniff_state()
      end
    end
  end
  -- feed bun
  if (btnp(5,pad)) then -- green btn
    for i=1,3 do
      if (buns[i].state == "feed") then
        rabbit_feed(buns[i])
      end
    end
  end

  -- update position
  -- -- user input 
  moved = false
  local dx = 0
  local dy = 0
  local t = {}
  t.x = rabbit.x
  t.y = rabbit.y
  if (btn(0,pad)) then -- btn left
    moved = true
    dx = -1
    rabbit.flip = false
  end
  if (btn(1,pad)) then -- btn right 
    moved = true
    dx = 1
    rabbit.flip = true
  end
  if (btn(2,pad)) then -- btn down
    moved = true
    dy = -1
  end
  if (btn(3,pad)) then -- btn up
    moved = true
    dy = 1
  end
  -- -- collision detection
  t.x = t.x + dx
  if (cmap(t)) then dx = 0 end -- check x-axis
  t.x = rabbit.x
  t.y = t.y + dy
  if (cmap(t)) then dy = 0 end -- check y-axis
  -- -- change position
  if (dx == 0 or dy == 0) then
    -- normal move
    rabbit.x = rabbit.x + dx
    rabbit.y = rabbit.y + dy
  else
    -- angle move
    rabbit.x = rabbit.x + (dx*sqrt(0.5))
    rabbit.y = rabbit.y + (dy*sqrt(0.5))
  end
  -- home detection
  if (rabbit.y > 88 and rabbit.x > 80) then
    home = true
  else
    home = false
  end
  -- food collision
  for i=1,#all_food do -- for each food
    if (all_food[i] != nil) then
      if (ent_dist(all_food[i], rabbit) < all_food[i].radius) then
        if (rabbit.hp <= 90) then
          -- eat food
          rabbit_consume(all_food[i])
        end
      end
    end
  end
  -- fox collision
  if (ent_dist(rabbit, fox) < rabbit.radius) then
    -- eaten by fox
    rabbit.alive = false
    --sfx(2)
  end
  
  -- update animation state
  if (moved and rabbit.state == "idle") then
    rabbit_change_anim_state("move")
    -- TODO REMOVE
    fox.anim_state = "move"
  elseif (not moved and rabbit.state == "move") then
    rabbit_change_anim_state("idle")
    -- TODO REMOVE
    fox.anim_state = "idle"
  end
  if (rabbit.state == "idle") then ent_anim_idle(rabbit) end
  if (rabbit.state == "move") then ent_anim_move(rabbit) end
  -- update hidden state
  if (rabbit.hidden) then
    if (not cgrass(rabbit) and not home) then
      -- exit hidden state
      rabbit_change_hidden_state(false)
    end
  else
    if (cgrass(rabbit) or home) then
      -- enter hidden state
      rabbit_change_hidden_state(true)
    end
  end
  -- update bunnies
  for i=1,3 do -- for each bun
    if (buns[i].alive) then
      -- update score
      score = score + 0.01
      -- update state
      if (ent_dist(rabbit, buns[i]) <= buns[i].radius) then
        buns[i].state = "feed"
      else
        buns[i].state = "idle"
      end
      -- reduce bun hp
      buns[i].hp = buns[i].hp - reduce_rate
      if (buns[i].hp <= 0) then -- bun dies
        buns[i].hp = 0
        buns[i].alive = false
      end
    end
  end
  
  -- update predators
  if (fox.state == "idle") then
    if (ent_dist(rabbit, fox) <= fox.aradius) then
      fox.state = "alert"
    end
    fox_move_patrol()
  elseif (fox.state == "alert") then
    if (ent_dist(rabbit, fox) > fox.aradius) then
      fox.state = "idle"
    elseif (not rabbit.hidden) then
      fox.target = {x=rabbit.x, y=rabbit.y}
      if (ent_dist(rabbit, fox) <= fox.cradius) then
        fox.state = "chase"
      end
    end
    fox_move_search()
  elseif (fox.state == "chase") then
    if (rabbit.hidden) then
      fox.state = "alert"
    end
    fox_move_chase()
  end
  if (fox.anim_state == "idle") then
    ent_anim_idle(fox)
  elseif (fox.anim_state == "move") then
    ent_anim_move(fox)
  end
end

function draw_sim()
  -- background map layer
  rectfill(0,0, 127,127, 3)
  -- main map layer
  map(0,0, 0,0, 16,16, 0x80)
  -- bottom of entities
  for i=1,#all_food do -- for each food
    ent_draw(all_food[i])
  end
  for i=1,3 do -- for each bun
    if (buns[i].alive) then
      if (buns[i].state == "idle") then ent_draw_idle(buns[i])
      else ent_draw(buns[i]) end
    end
  end
  if (fox.anim_state == "idle") then ent_draw_idle(fox, false) end
  if (fox.anim_state == "move") then ent_draw_move(fox, false) end
  if (rabbit.sniff) then
    circ(fox.x+4, fox.y+4, fox.cradius, 8)
    circ(fox.x+4, fox.y+4, fox.aradius, 10)
  end
  if (rabbit.state == "idle") then ent_draw_idle(rabbit, false) end
  if (rabbit.state == "move") then ent_draw_move(rabbit, false) end
  -- tall grass map layer
  map(16,0, 0,0, 16,16, 0x40)
  -- top of entities
  if (rabbit.state == "idle") then ent_draw_idle(rabbit, true) end
  if (rabbit.state == "move") then ent_draw_move(rabbit, true) end
  -- status bar
  draw_ui()
  -- top of warren
  if (not home) then
    map(32,0, 0,0, 16,16, 0x80)
  end
  path_print_field()
end
function end_sim() -- trigger gameover
  play_bg_music(false)
  sfx(1)
  io_lock_tick = io_lock_duration
  gameover = true
end
-->8
function rabbit_feed(bun)
  if ( (rabbit.hp >= 10) and (bun.hp < 90) ) then
    sfx(0)
    -- reduce rabbit ep
    rabbit.hp = rabbit.hp - 10
    if (rabbit.hp < 0) then rabbit.hp = 0 end
    -- increase bun hp
    bun.hp = bun.hp + 5
    if (bun.hp > 100) then bun.hp = 100 end
  end
end
function rabbit_consume(fud)
  del(all_food, fud)
  rabbit.hp = rabbit.hp + 20
  if (rabbit.hp > 100) then rabbit.hp = 100 end
end
function spawn_food(obj)
  local f = {}
  if (obj != nil) then
    f = {}
    f.x = obj.x 
    f.y = obj.y 
    f.radius = 6
    f.frame = 1
    f.sprites = {35}
    add(all_food, f)
  end
end
function toggle_sniff_state()
  if (rabbit.sniff) then -- start cooldown timer
    rabbit.sniff = false
    sniff_tick = sniff_cooldown
    sniff_lock = true
  else -- start sniff effect
    rabbit.sniff = true
    sniff_tick = sniff_duration
  end
end
function rabbit_change_anim_state(_state)
  rabbit.state = _state
  rabbit.tick = 0
end
function rabbit_change_hidden_state(_state)
  rabbit.hidden = _state
  if (_state) then sfx(3)
  else sfx(4) end
end
function fox_move_patrol()
  --
end
function fox_move_search()
  --
end
function fox_move_chase()
  --
end
function cgrass(o)
  -- check "tall grass" tile collision
  local offset = 4
  local c = false
  local x1=(o.x+offset)/8
  local y1=(o.y+offset)/8
  local x2=((o.x-offset)+7)/8
  local y2=((o.y-offset)+7)/8
  x1 = x1+16
  x2 = x2+16
  local a=fget(mget(x1,y1),6) -- top left
  local b=fget(mget(x1,y2),6) -- bottom left
  local c=fget(mget(x2,y2),6) -- bottm right
  local d=fget(mget(x2,y1),6) -- top right
  c = a or b or c or d
  return c
end
function cmap(o)
  local ct=false
  local cb=false

  -- check map tile collision
  local x1=o.x/8
  local y1=o.y/8
  local x2=(o.x+7)/8
  local y2=(o.y+7)/8
  local a=fget(mget(x1,y1),0) -- top left
  local b=fget(mget(x1,y2),0) -- bottom left
  local c=fget(mget(x2,y2),0) -- bottm right
  local d=fget(mget(x2,y1),0) -- top right
  ct = a or b or c or d
  -- check world bounds collision
  cb = (o.x<0 or o.x+8>worldw or
        o.y<0 or o.y+8>worldh)

  return ct or cb
end
function foodtiles()
  local _list = {}
  for _y=0,15 do -- rows
    for _x=0,15 do -- cols
      if (fget(mget(_x,_y),1)) then
        add(_list, {x=_x*8, y=_y*8})
      end
    end
  end
  return _list
end
function ent_dist(a, b)
  local x1=a.x+4
  local x2=b.x+4
  local y1=a.y+4
  local y2=b.y+4
  return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
function ent_tile(ent)
  local cel = {}
  cel.x = flr((ent.x+4)/8) + 1
  cel.y = flr((ent.y+4)/8) + 1
  return cel
end
-->8
function init_menu()
  reset = true
  isMusic = false
  pad = 0
  menu = {}
  menu.selected = 1
  menu.count = 2
end
function update_menu()
  local gp = detect_gamepad()
  if gp != -1 then
    pad = gp
  end
  if (btnp(2,pad)) then input_menu('up') end -- menu up
  if (btnp(3,pad)) then input_menu('down') end -- menu down
  if (btnp(4,pad)) then input_menu('act') end -- menu action
end
function draw_menu()
  -- bg
  color(1)
  rectfill(0,0,128,128)
  -- text
  print('game config', 42, 3, 13)
  print('gamepad:  '..tostr(pad), 3, 12, 13)
  print('music:    '..tostr(isMusic), 3, 21, 13)
  print('resume', 3, 30, 13)
  -- highlight selected
  if menu.selected == 1 then -- toggle music
    rect(1, 19, 26, 27, 14)
  end
  if menu.selected == 2 then -- resume
    rect(1, 28, 27, 36, 14)
  end
  -- gamepad icons
  draw_gamepad(52,60)
  -- reset color
  color(0)
end
function input_menu(cmd)
  if cmd == 'up' then
    menu.selected = menu.selected+1
    if menu.selected > menu.count then
      menu.selected = 1
    end
  end
  if cmd == 'down' then
    menu.selected = menu.selected-1
    if menu.selected < 1 then
      menu.selected = menu.count
    end
  end
  if cmd == 'act' then
    if menu.selected == 1 then -- toggle music
      isMusic = not isMusic
      play_bg_music(isMusic)
    end
    if menu.selected == 2 then -- resume
      paused = false
    end
  end
end
-->8
function ent_draw_idle(ent, hidden)
  if (hidden) then
    spr(ent.idle_sprites[ent.idle_frame], ent.x, ent.y, 1, 0.6, ent.flip)
  else
    spr(ent.idle_sprites[ent.idle_frame], ent.x, ent.y, 1, 1, ent.flip)
  end
end
function ent_anim_idle(ent)
  ent.idle_tick = (ent.idle_tick+1) % ent.idle_step
  if (ent.idle_tick == 0) ent.idle_frame = ent.idle_frame % #ent.idle_sprites+1
end
function ent_draw_move(ent, hidden)
  if (hidden) then
    spr(ent.move_sprites[ent.move_frame], ent.x, ent.y, 1, 0.6, ent.flip)
  else
    spr(ent.move_sprites[ent.move_frame], ent.x, ent.y, 1, 1, ent.flip)
  end
end
function ent_anim_move(ent)
  ent.move_tick = (ent.move_tick+1) % ent.move_step
  if (ent.move_tick == 0) ent.move_frame = ent.move_frame % #ent.move_sprites+1
end
function ent_draw(ent)
  spr(ent.sprites[ent.frame], ent.x, ent.y, 1, 1, ent.flip)
end
function ent_draw_aoe(ent)
  circ(ent.x+4, ent.y+4, ent.cradius, 8)
  circ(ent.x+4, ent.y+4, ent.aradius, 10)
end
function ent_anim(ent)
  ent.tick = (ent.tick+1) % ent.step
  if (ent.tick == 0) ent.frame = ent.frame % #ent.sprites+1
end
-->8
function detect_gamepad()
  for p=0,8 do
    for b=0,6 do
      if btn(b,p) then
        return p
      end
    end
  end
  return -1
end
function draw_gamepad(x,y)
  local s_offset = 0
  local s_indx = 39
  rectfill(x,y,x+23,y+7, 13)
  --rect(x,y,x+23,y+7, 4)
  if (btn(2,pad)) then -- up
    s_offset = 1
  end
  if (btn(1,pad)) then -- right
    s_offset = 2
  end
  if (btn(3,pad)) then -- down
    s_offset = 3
  end
  if (btn(0,pad)) then -- left
    s_offset = 4
  end
  if (btn(2,pad) and btn(1,pad)) then -- up & right
    s_offset = 5
  end
  if (btn(3,pad) and btn(1,pad)) then -- down & right 
    s_offset = 6
  end
  if (btn(3,pad) and btn(0,pad)) then -- down & left
    s_offset = 7
  end
  if (btn(2,pad) and btn(0,pad)) then -- up & left
    s_offset = 8
  end
  spr(s_indx+s_offset, x, y)
  if (btn(4,pad)) then spr(13, x+8, y)
  else spr(12, x+8, y) end
  if (btn(5,pad)) then spr(15, x+16, y)
  else spr(14, x+16, y) end
end
function play_bg_music(on)
  if on then
    music(0)
  else
    music(-1, 300)
  end
end

-->8
function draw_ui()
  -- bg
  --rectfill(0,120, 127,127, 13)
  rectfill(0,120, 64,127, 13)
  -- rabbit hidden state
  spr(0, 2,121, 0.5,0.75)
  if (rabbit.hidden) then spr(64, 0,119) end
  -- detection state
  if (fox.state == "idle") then
    spr(23, 6,120)
  elseif (fox.state == "alert") then
    spr(24, 6,120)
  elseif (fox.state == "chase") then
    spr(25, 6,120)
  end
  -- rabbit energy bar
  print("ep", 16,121, 1)
  rectfill(25,122, 37,125, 1)
  rect(25,122, 37,125, 5)
  if (rabbit.hp > 0) then
    rectfill(26,123, (26+(rabbit.hp/10)),124, 3)
  end
  -- sniff ability
  local sp = 0
  print("sp", 41,121, 1)
  rectfill(50,122, 62,125, 1)
  rect(50,122, 62,125, 5)
  if (not sniff_lock) then -- duration
    sp = 10*(sniff_tick/sniff_duration)
    rectfill(51,123, 51+(sp),124, 12)
  elseif (sniff_lock) then -- cooldown
    sp = 10*(sniff_tick/sniff_cooldown)
    rectfill(51+(sp),124, 51,123, 8)
  end
  -- gamepad 67 76
  --draw_gamepad(66, 120)
  -- separators
  line(14,120, 14,127, 6)
  line(39,120, 39,127, 6)
  line(64,120, 64,127, 6)
  --line(91,120, 91,127, 6)
  -- bun health
  for i=1,3 do -- for each bun
    if (buns[i].alive) then
      local _x = buns[i].x + 1
      local _y = buns[i].y + 2
      local _w = (buns[i].hp / 100) * 6
      line(_x,_y, _x+5,_y, 8)
      line(_x,_y, _x+(_w),_y, 12)
    end
  end

end
-->8
-- pathfinding: flow field fun
function vec_mag(_vec)
  return sqrt((_vec.x)^2 + (_vec.y)^2)
end
function vec_dist(a, b)
  local x1=a.x
  local x2=b.x
  local y1=a.y
  local y2=b.y
  return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
function vec_norm(_vec)
  local m = vec_mag(_vec)
  return {x=(_vec.x/m), y=(_vec.y/m)}
end
function graph_cardinal_neighbors(_node)
  local _list = {}
  local _celx = _node.celx
  local _cely = _node.cely
  -- top
  if (_cely-1 >= 1) then
    add(_list, {celx=_celx, cely=_cely-1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- right
  if (_celx+1 <= 16) then
    add(_list, {celx=_celx+1, cely=_cely})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- bottom
  if (_cely+1 <= 16) then
    add(_list, {celx=_celx, cely=_cely+1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- left
  if (_celx-1 >= 1) then
    add(_list, {celx=_celx-1, cely=_cely})
  else
    add(_list, {celx=nil, cely=nil})
  end
  return _list
end
function graph_ordered_neighbors(_node)
  local _list = {}
  local _celx = _node.celx
  local _cely = _node.cely
  -- top
  if (_cely-1 >= 1) then
    add(_list, {celx=_celx, cely=_cely-1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- top right
  if ((_cely-1 >= 1) and (_celx+1 <= 16)) then
    add(_list, {celx=_celx+1, cely=_cely-1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- right
  if (_celx+1 <= 16) then
    add(_list, {celx=_celx+1, cely=_cely})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- bottom right
  if ((_cely+1 <= 16) and (_celx+1 <= 16)) then
    add(_list, {celx=_celx+1, cely=_cely+1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- bottom
  if (_cely+1 <= 16) then
    add(_list, {celx=_celx, cely=_cely+1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- bottom left
  if ((_cely+1 <= 16) and (_celx-1 >= 1)) then
    add(_list, {celx=_celx-1, cely=_cely+1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- left
  if (_celx-1 >= 1) then
    add(_list, {celx=_celx-1, cely=_cely})
  else
    add(_list, {celx=nil, cely=nil})
  end
  -- top left
  if ((_cely-1 >= 1) and (_celx-1 >= 1)) then
    add(_list, {celx=_celx-1, cely=_cely-1})
  else
    add(_list, {celx=nil, cely=nil})
  end
  return _list
end
function graph_get_neighbors(_node)
  local _list = {}
  local _celx = _node.celx
  local _cely = _node.cely
  -- top
  if (_cely-1 >= 1) then
    add(_list, {celx=_celx, cely=_cely-1})
  end
  -- top right
  if ((_cely-1 >= 1) and (_celx+1 <= 16)) then
    add(_list, {celx=_celx+1, cely=_cely-1})
  end
  -- right
  if (_celx+1 <= 16) then
    add(_list, {celx=_celx+1, cely=_cely})
  end
  -- bottom right
  if ((_cely+1 <= 16) and (_celx+1 <= 16)) then
    add(_list, {celx=_celx+1, cely=_cely+1})
  end
  -- bottom
  if (_cely+1 <= 16) then
    add(_list, {celx=_celx, cely=_cely+1})
  end
  -- bottom left
  if ((_cely+1 <= 16) and (_celx-1 >= 1)) then
    add(_list, {celx=_celx-1, cely=_cely+1})
  end
  -- left
  if (_celx-1 >= 1) then
    add(_list, {celx=_celx-1, cely=_cely})
  end
  -- top left
  if ((_cely-1 >= 1) and (_celx-1 >= 1)) then
    add(_list, {celx=_celx-1, cely=_cely-1})
  end
  return _list
end
function graph_bfs(_node)
  local dirty = {}
  for i=1,16 do
    dirty[i] = {}
    for j=1,16 do
      dirty[i][j] = true
    end
  end
  local _queue = {}
  local _depth = 0
  _node.depth = _depth + 1
  add(_queue, _node) -- enqueue source
  dirty[_node.celx][_node.cely] = false -- mark visited
  path_heatmap[_node.celx][_node.cely] = _depth -- set distance value
  while (#_queue >= 1) do
    -- dequeue next node
    local _n = _queue[1]
    del(_queue, _n)
    -- increase depth when first node of deeper layer found
    if (_n.depth > _depth) then
      _depth = _depth + 1
    end
    -- process all neighbors
    local nbs = graph_get_neighbors(_n)
    if (#nbs > debug) then debug = #nbs end
    for i=1,#nbs do
      local n = nbs[i]
      -- if not visited
      if (dirty[n.celx][n.cely]) then
        -- if passable
        if (path_heatmap[n.celx][n.cely] != 256) then
          -- enqueue node
          n.depth = _depth + 1
          add(_queue, n)
          -- mark as visited
          dirty[n.celx][n.cely] = false
          -- set distance value
          path_heatmap[n.celx][n.cely] = _depth
        end
      end
    end
  end
end
function graph_vector()
  for i=1,16 do
    for j=1,16 do
      local _c = path_heatmap[i][j]
      local _cneighbors = graph_cardinal_neighbors({celx=i, cely=j})
      local _top = {}
      if (_cneighbors[1].celx != nil) then
        _top = path_heatmap[_cneighbors[1].celx][_cneighbors[1].cely]
      else
        _top = _c
      end
      local _right = {}
      if (_cneighbors[2].celx != nil) then
        _right = path_heatmap[_cneighbors[2].celx][_cneighbors[2].cely]
      else
        _right = _c
      end
      local _bottom = {}
      if (_cneighbors[3].celx != nil) then
        _bottom = path_heatmap[_cneighbors[3].celx][_cneighbors[3].cely]
      else
        _bottom = _c
      end
      local _left = {}
      if (_cneighbors[4].celx != nil) then
        _left = path_heatmap[_cneighbors[4].celx][_cneighbors[4].cely]
      else
        _left = _c
      end

      --local _x = _left - _right -- left - right
      --local _y = _top - _bottom -- up - down
      local _x = 0
      local _y = 0
      if (_left < _right) then 
        _x = -1
      elseif (_right < _left) then
        _x = 1
      end
      if (_top < _bottom) then 
        _y = -1
      elseif (_bottom < _top) then
        _y = 1
      end
      path_field[i][j] = vec_norm({x=_x, y=_y})
    end
  end
end
function path_init_heatmap()
  path_heatmap = {}
  for i=1,16 do
    path_heatmap[i] = {}
    for j=1,16 do
      if (fget(mget(i-1,j-1), 0)) then -- collision tile
        path_heatmap[i][j] = 256
      else
        path_heatmap[i][j] = 9
      end
    end
  end
end
function path_print_heatmap()
  for i=1,16 do
    for j=1,16 do
      print(path_heatmap[i][j], (i-1)*8, (j-1)*8)
    end
  end
end
function path_print_field()
  for i=1,16 do
    for j=1,16 do
      local _x = ((i-1)*8)+4
      local _y = ((j-1)*8)+4
      local _vec = path_field[i][j]
      local c = 6
      if (_vec.x > 1 or _vec.y > 1) then 
        c = 8 
      else
        line(_x, _y, _x+_vec.x, _y+_vec.y, c)
      end
    end
  end
end
function path_init_field()
  path_field = {}
  for i=1,16 do
    path_field[i] = {}
    for j=1,16 do
        path_field[i][j] = {x=0, y=0}
    end
  end 
end
-- flow field
function gen_flow_field(_celx, _cely)
  -- build heatmap
  graph_bfs({celx=_celx, cely=_cely})
  -- build vector field
  graph_vector()
end
-- navigate

__gfx__
f67f00000067f00000000000000000000067f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f67f0000067f00000067700000677000067f00000067700077777000000550000006600000055000000550000005500000055000000550000005500000055000
77770000777700007777f70077777000777700007777f7005757f70000055000000660000005500000055000000550000058850000566500005bb50000566500
5757000057570000575700005757000057570000575700007e7776070555555005555550055556600555555006655550058888500566665005bbbb5005666650
7e7777007e7777007e7777007e7777007e7777007e777700777777700555555005555550055556600555555006655550058888500566665005bbbb5005666650
7777667077776670777766707777667077776670777777770767777000055000000550000005500000066000000550000058850000566500005bb50000566500
0767677f076767770767677707676777076767770767667000767677000550000005500000055000000660000005500000055000000550000005500000055000
76767770767677707676777076767770767677700767677000000067000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000006770000000000000070000000000007777700000055000000ff000000ee000000000b000000000000da900000dd000000dd000009ad000
00000000000000007777f70000000000000f7000000000005757f7000056650000f99f0000e88e0000000bb00000000000ddaa9000dddd0000dddd0009aadd00
000f7000000000007777000000000000007f7000000000007e777607056766500f9799f00e8788e000000b00088088000dd55aa00ddd5dd00dd5ddd00aa55dd0
007f7000007ff0007e777700007ff0000e5777700000000077777770056666500f9999f00e8888e00b00bb00008880000ddd5dd00dd55aa00aa55dd00dd5ddd0
0e5777700777777077776670077777700777776700000000076777700056650000f99f0000e88e000bb0b0000008000000dddd0000ddaa9009aadd0000dddd00
077776770f7e7677076767770f7e767700777670000000000767067700055000000ff000000ee00000bbb00000888000000dd000000da900009ad000000dd000
007767700f776770767677700f776770077077700000000000000067000000000000000000000000000b00000880880000000000000000000000000000000000
00bb000000350000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3590003b3590000b9900000b9b0000000000000000000000000000000dd00000a99a00000dd000000dd000000dd000000da900000dd000000dd000009ad000
b359500039599950b9940000093b900000000000000000000000000000daad0000aaaa0000dddaa000dddd000aaddd0000ddaa9000dddd0000dddd0009aadd00
b599590095599550094990000b9990000000000000000000000000000da99ad00dd55dd00ddd5a900dddddd009a5ddd00dd55aa00ddd5dd00dd5ddd00aa55dd0
095999905999559500994000009999000000000000000000000000000da99ad00dddddd00ddd5a900dd55dd009a5ddd00ddd5dd00dd55aa00aa55dd00dd5ddd0
0009959505559995000099000000990000000000000000000000000000daad0000dddd0000dddaa000aaaa000aaddd0000dddd0000ddaa9009aadd0000dddd00
00005995000599590000049000000990000000000000000000000000000dd000000dd000000dd00000a99a00000dd000000dd000000da900009ad000000dd000
00000059000055590000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00690070006900000069000000690000006900000069000000690000000000000000000000000000000000000000000000000000000000000000000000000000
09990090099900000999000009990000099900000999000009990000000000000000000000000000000000000000000000000000000000000000000000000000
f9990090f9990000f9990000f9990000f9990000f9990000f9990000000000000000000000000000000000000000000000000000000000000000000000000000
07999900077990000779900007799070079999970799999707999997000000000000000000000000000000000000000000000000000000000000000000000000
09999900099999000999790009999900099999000999990009999900000000000000000000000000000000000000000000000000000000000000000000000000
09d9d90009d99d9009d9999009d9999009d9d9000d99d900d9000d90000000000000000000000000000000000000000000000000000000000000000000000000
09d9d90009d7999009d9d99009d9d99009d9d90000d99000900000d9000000000000000000000000000000000000000000000000000000000000000000000000
0000000005b5b5b5005050503333333300000000000000004444444444444444555555555555555555555555ccccdccd33333333dddccccc3333333cc3333333
00000000055b5b5055b5b5b5333333330000000000000000444444d444444444511511111511115111511115cccd3dd333333333333ddccc3333333cc3333333
000000005b5b5b50b55b5b553333333300000000000000004444444444144444511111111111111111111115cccd33333333333333333dcc3333333cc3333333
00505050535353505b5b5b503333333300000000000000004444144444444444511444141444144441444155cdd333333333333333333dcc3333333cc3333333
05b5b5b555b5b5b55353535033333333000000000000000044444441144444445114444444444444444d4115d3333333333333333333dccc3333333cc3333333
055b5b50b55b5b5500000000333333330000000000000000444444111144d4445114d44d4444441444444115d3333333333d33333333dccc3333333cc3333333
5b5b5b505b5b5b50000000003333333300000000000000004444411551144444551144444144444d4d444115cd3333333ddcdd3333333ddc3333333cc3333333
53535350535353500000000033333333000000000000000044441155551144445114444444d4444444441115d3333333dcccccdd3333333dcccccccccccccccc
333333333333a33300aaaa000000000000000000000000004444115555114444511144445555555544441115333333ddccccccccd3333333cccccccccccccccc
3333333333333333aaeeeeaa0e55050000000000000000004444411551144144551444d4575555554144415533333dcccccccccccd3333333333333cc3333333
3333333373333333afe99efa5bbb5b500000000000000000444444111144444451144144555555d5d44441153333dcccccccccccccd333333333333cc3333333
3333333333333333aaeeeeaa05bbbe50000000000000000044414441144444445114444455555555444441153333dcccccccccccccd333333333333cc3333333
33333333333a339305affa5005bebbb50000000000000000444444444444444451144444555555554414411533333dcccccccccccd3333333333333cc3333333
333333333333333353aaaa350ebbbbe000000000000000004444444444d444445111444d555557554d44111533333dcccccccccccd3333333333333cc3333333
333333333933373305333550005bb50000000000000000004444d444444444445514441455d5555544444155333333dcccccccccd33333333333333cc3333333
33333333333333330055350000054400000000000000000044444444444444445114444455555555444441153333333dccccccccd33333333333333cc3333333
bbbbbbbb0000000000000000000000000000000000000000000000004444444451144444444d444444441115dd333333dcccccdd3333333d0000000000000000
bbbbbbbb00000000000000000000000000000000000000000000000044144444511144414414444144d44115ccdd33333ddccd3333333ddc0000000000000000
bb3bbbbb000000000000000000000000000000000000000000000000444d444451144d4444444444d4444115ccccd333333dd333333ddccc0000000000000000
b3bbbbbb00000000000000000000000000000000000000000000000044444441511444444444444444444115ccdd33333333333333dccccc0000000000000000
b33bbbbb000000000000000000000000000000000000000000000000d4444444511444414144441444144155cd33333333333333333dcccc0000000000000000
b33b333b00000000000000000000000000000000000000000000000044444444511111111111111111111115ccdd3333333333333ddccccc0000000000000000
bb3333bb00000000000000000000000000000000000000000000000044444444551111515111151115111115ccccddd333333333dccccccc0000000000000000
bbb33bbb00000000000000000000000000000000000000000000000044444444555555555555555555555555cccccccd33333333dccccccc0000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444400c77b0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444444440cc77bb0000d0000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444ccc77bbb00c7b000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444777777770e777f00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444777777770087a000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444444448887799900090000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444444440887799000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444444440087790000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404040004080808080808080808080808081408000808080818080818000000200000000004080808080808080000040404000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
605050506050505060505050605050507d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
506050605060506050605060506050607d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505060505050605050506050505060507d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050505050505050505050505050507d7d7d7d7d7d7d7d7d7d7d4040407d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050505059505050505050505050507d7d7d7d7d7d7d527d7d404141427d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050505950505050505050505050527d7d7d527d7d7d7d404141427d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050505059505050505050505050507d7d7d7d7d527d7d7d4242427d7d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050505059505050505050505050507d7d7d7d7d7d7d7d7d7d7d7d7d537d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050505059595950505050505050507d7d7d7d7d7d7d7d537d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505060505050505050505050505050507d7d7d7d7d7d7d7d7d7d7d7d404040407d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050505050505050505050505050507d7d7d7d7d7d7d7d7d7d7d40414141417d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5959595950505050505050595959585a7d7d7d7d7d7d7d7d7d7d407d7d7d41417d7d7d7d7d7d7d7d7d7d7d5252527d7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050505950605050505059484949575a7d7d7d7d7d7d7d7d7d7d7d7d7d7d42427d7d7d7d7d7d7d7d7d7d5250515050510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050505959505050505059584669475a7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d5251505150500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050505050505050505056575a59585a7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d5250505150510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5959595959595959596869696a59686a7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d7d52525250505051500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ff000000000000000000007c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000c050170501705017050180501405019050140501a050280501c050140501d0501e050140501f0502105016050220500c05025050250502605027050270502805029050290501c0502a0502a0502b050
000e0000000000000000000000002e0502c0502c0502b0502a0500000028050000002705000000260502505024050000002305023050000002205022050000002205021050000002105021050210502005020050
000600002f7502f7502f7502f7502f7502f7502f7502f7502f7502f7502f7502f7502f7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e7502e750
010800000767413675076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001367407675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000e1261312615126171260e1061300615006170060e0061300615006170060e0061300615006170060e0061300615006170060e0061300615006170060e0061300615006170060e006130061500617006
000800001375206752087520a7520c7520f752107521375216752097520b7520c7520f75211752157520c7520d75210752127520b7520e7520f752117521375214752187520f752127521475216752197521c752
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000003010130100301003010130101301003010030100311003110031100311003110031100311013110132101321023210333104331043310534107341093410c3510f35113351183611f361283613a371
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e0000105501155015550175501c5501f5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000e5400e5400e5400e54010540105401054010540135401354013540135401354013540155401554117540175411554015541135401354115540155411354213542135421354013531135150030000300
001000000e5400e5400e5400e54010540105401054010540135401354013540135401354013540155401554117540175411a5401a541175401754115540155411754017540175401754017540175400000000000
001000001c5401c5401c5401c5401a5401a5401754017540155401554015540155401554015540135401354115540155411754017541155401554113540135411054210542105421054010531105150000000000
001000000e5400e5400e5400e54010540105401054010540135401354013540135401354013540155401554013540135401354013540135401354013540135401354113531135150050000000000000000000000
001000001f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a532
001000001f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f5321f532215322153221532215321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a5321a532
001000001c5321c5321c5321c5321a5321a5321a5321a532175321753217532175321553215532155321553213532135321353213532135321353213532135321353213532135320000200002000020000200000
001000000775007750077500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 14574f10
00 15574311
00 14574312
00 16574313
00 14424344
00 15424344
00 14424344
02 16424344

