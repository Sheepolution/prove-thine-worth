-----------------------------
-----------------------------
---------BASE CODE-----------
-----------------------------

-----------------------------
--RECT
-----------------------------
function Rect_new(self, x, y, width, height)
	self.type = "Rect"
	self.x = x or 0
	self.y = y or self.x
	self.width = width or 0
	self.height = height or self.width
	return self
end

function Rect_draw(self)
	if self.color then color(self.color) end
	rect(self.x, self.y, self.width, self.height)
end

function Rect_set(self, x, y, width, height)
	self.x = x or self.x
	self.y = y or self.y
	self.width = width or self.width
	self.height = height or self.height
end

function Rect_get(self)
	return self.x, self.y, self.width, self.height
end

function Rect_clone(self, r)
	self.x = r.x
	self.y = r.y
	self.width = r.width
	self.height = r.height
end

--If rect overlaps with rect or point
function Rect_overlaps(self, r)
	return  self.x + self.width > r.x and
			self.x < r.x + (r.width or 0) and
			self.y + self.height > r.y and
			self.y < r.y + (r.height or 0)
end

function Rect_overlapsX(self, r)
	return  self.x + self.width > r.x and
			self.x < r.x + (r.width or 0)
end

function Rect_overlapsY(self, r)
	return  self.y + self.height > r.y and
			self.y < r.y + (r.height or 0)
end

function Rect_top(self, val)
	if val then self.y = val end
	return self.y
end

function Rect_bottom(self, val)
	if val then self.y = val - self.height end
	return self.y + self.height
end

function Rect_centerX(self, val)
	if val then self.x = val - self.width / 2 end
	return self.x + self.width / 2
end

function Rect_centerY(self, val)
	if val then self.y = val - self.height / 2 end
	return self.y + self.height / 2
end

function Rect_distance(self, r)
	return sqrt(abs(self.x - r.x)^2 + abs(self.y - r.y)^2)
end

function Rect_distanceCenter(self, r)
	return sqrt(abs(self.x + self.width/2 - r.x + r.width/2)^2  + abs(self.y + self.height/2 - r.y + r.height/2))
end

function Rect_distanceY(self, r)
	return abs(self.y - r.y)
end

function Rect_distanceCenterX(self, r)
	return abs((self.x + self.width/2) - (r.x + r.width/2))
end

function Rect_distanceCenterY(self, r)
	return abs((self.y + self.height/2) - (r.y + r.height/2))
end



-----------------------------
--Spr
-----------------------------
function Spr_new(self, x, y, img)
	Rect_new(self, x, y, 8)
	self.type = "Spr"
	self.__save = {}
	self.dead = nil
	self.img = img
	self.imgWidth = 1
	self.imgHeight = 1

	-- self.flip = {x = nil, y = nil}
	self.flip_x = nil
	self.flip_y = nil
	self.offset_x = 0
	self.offset_y = 0

	self.visible = true

	self.frame = 1
	self.frameTimer = 1
	self.frameTimerDir = 1
	self.anim = nil
	-- self.anims = {}
	self.animEnded = nil

	return self
end


function Spr_update(self)
	Spr_simplify(self)
	Spr_animate(self)
end


function Spr_draw(self)
	if self.visible and not self.dead then
		blit(self.img  + (self.anim and self["anim__" .. self.anim][self.frame] * self.imgWidth - 1 or 0), self.x + self.offset_x, self.y + self.offset_y, self.imgWidth, self.imgHeight, self.flip_x, self.flip_y)
	end
end

function Spr_animate(self)
	if self.anim then
		local ani = self["anim__" .. self.anim]
		if not (ani.mode == "once" and self.animEnded) then
			self.frameTimer = self.frameTimer + 1 / self["anim__" .. self.anim].speed
			if self.frameTimer >= #ani + 1 or self.frameTimer <= 0 then
				if self.mode == "pingpong" then
					self.frameTimerDir = -self.frameTimerDir
					self.frameTimer = self.frameTimerDir > 0 and 2 or self.frameTimer - #ani
				elseif ani.mode == "once" then
					self.frameTimer = #ani
				else
					self.frameTimer = self.frameTimer - #ani
				end
				self.animEnded = true
			end
			self.frame = flr(self.frameTimer)
		end
	end
end

function Spr_addAnim(self, name, t, speed, mode)
	local a = {} 
	self["anim__" .. name] = a
	a.speed = speed or 1
	a.mode = mode or "loop"
	for i=1,#t do
		a[i] = t[i]
	end
end

function Spr_setAnim(self, anim, force)
	if  self.anim ~= anim or force then
		self.frame = 1
		self.frameTimer = 1
		self.frameTimerDir = 1
		self.anim = anim
		self.animEnded = nil
	end
end

function Spr_simplify(self)
	if self.type == "Eye" then
		return Eye_simplify(self)
	else
		return Spr_simplify_real(self)
	end
end

function Spr_simplify_real(self)
	--I check if it's out of screen, then I save the important variables, and remove everything else
	if Spr_canSimplify(self) then
		puts(self.__save,{"x","y","width","height","type","__save"})
		local new = {}
		for i,k in pairs(self.__save) do
			new[k] = self[k]
		end
		new.simplified = true
		local t = data(new.type)
		local i = find(t, self)
		del(t, i)
		put(t, new)
	end
end

function Spr_renew(self)
	if not Spr_canSimplify(self) then
		local old = {}
		for i,k in ipairs(self.__save) do
			if k ~= "__save" then
				old[k] = self[k]
			end
		end
		self.simplified = nil
		data(self.type, true)(self, self.x, self.y)
		for k,v in pairs(old) do
			self[k] = old[k]
		end
		return true
	end
	return nil
end

function Spr_canSimplify(self)
	if self.type == "Plr" then
		return nil
	elseif self.type == "Torch" then
		return Torch_canSimplify(self)
	elseif self.type == "Bat" then
		return Bat_canSimplify(self)
	elseif self.type == "Spider" then
		return Spd_canSimplify(self)
	elseif self.type == "Spear" then
		return Spear_canSimplify(self)
	elseif self.type == "Lava" then
		return Lava_canSimplify(self)
	elseif self.type == "Bolt" then
		return nil
	elseif self.type == "Wzrd" then
		return nil
	elseif self.type == "Crown" then
		return nil
	elseif self.type == "Stairs" then
		return nil
	elseif self.type == "Platform" then
		return nil
	else
		return Spr_canSimplify_real(self)
	end
end

function Spr_canSimplify_real(self)
	return not Rect_overlaps(self, {x = cam_x, y = cam_y, width = cam_width, height = cam_height})
end


-----------------------------
--Ent
-----------------------------
function Ent_new(self, x, y, img)
	Spr_new(self, x, y, img)
	self.type = "Ent"
	self.velocity_x = 0
	self.velocity_y = 0
	self.last = Rect_new({}, x, y)
	self.priority_x = 0
	self.priority_y = 0
	self._prior_x = 0
	self._prior_y = 0
	self.bounce_x = 0
	self.bounce_y = 0

	self.mass = 0

	self.ignoreMap = nil
	self.grounded = nil
	self.solid = true
	self.dead = nil

	return self
end

function Ent_update(self)
	if not self.dead then
		Rect_clone(self.last, self)
		self._prior_x = self.priority_x
		self._prior_y = self.priority_y

		self.velocity_y = self.velocity_y + self.mass
		self.velocity_y = min(5, self.velocity_y)

		self.x = self.x + self.velocity_x
		self.y = self.y + self.velocity_y

		if not self.ignoreMap then
			Ent_resolveMapCollision(self)
		end

		if self.velocity_x ~= 0 then
			self.flip_x = self.velocity_x < 0
		end

		Spr_update(self)
	end
end


function Ent_resolveMapCollision(self)
	--I feel like this can be optimized. Not sure how much it would save kb wise though
	if self.x - self.last.x > 0 then
		if getWOP(self.x + self.width-1, self.y) and not getWOP(self.last.x + self.width-1, self.y) then
			Ent_hitMapRight(self)
		elseif getWOP(self.x + self.width-1, self.y + self.height-1) and not getWOP(self.last.x + self.width-1, self.y + self.height-1) then
			Ent_hitMapRight(self)
		end
	else
		if getWOP(self.x, self.y) and not getWOP(self.last.x, self.y) then
			Ent_hitMapLeft(self)
		elseif getWOP(self.x, self.y + self.height-1) and not getWOP(self.last.x, self.y + self.height-1) then
			Ent_hitMapLeft(self)
		end
	end

	if self.y - self.last.y > 0 then
		if getWOP(self.x, self.y + self.height-1) and not getWOP(self.x, self.last.y + self.height-1) then
			Ent_hitMapBottom(self)
		elseif getWOP(self.x + self.width-1, self.y + self.height-1) and not getWOP(self.x + self.width-1, self.last.y + self.height-1) then
			Ent_hitMapBottom(self)
		end
	else
		if getWOP(self.x, self.y) and not getWOP(self.x, self.last.y) then
			Ent_hitMapTop(self)
		elseif getWOP(self.x + self.width-1, self.y) and not getWOP(self.x + self.width-1, self.last.y) then
			Ent_hitMapTop(self)
		end
	end
end

function Ent_overlaps(self, e)
	return self ~= e and not self.dead
	and not e.dead
	and Rect_overlaps(self, e)
end

function Ent_resolveCollision(self, e)
	if self.simplified or e.simplified then return end
	if Ent_overlaps(self, e) then
		Ent_onOverlap(self, e)
	end
end

function Ent_onOverlap(self, e)
	if self.type == "Plr" then
		Plr_onOverlap(self, e)
	elseif self.type == "Crate" then
		Crate_onOverlap(self, e)
	elseif self.type == "Button" then
		Btn_onOverlap(self, e)
	elseif self.type == "Switch" then
		Stc_onOverlap(self, e)
	elseif self.type == "Bat" then
		Bat_onOverlap(self, e)
	elseif self.type == "Spider" then
		Spd_onOverlap(self, e)
	elseif self.type == "Wzrd" then
		Wzrd_onOverlap(self, e)
	else
		Ent_onOverlap_real(self)
	end
end

function Ent_onOverlap_real(self, e)
	if self.solid and e.solid then
		Ent_separate(self, e)
	end
end

function Ent_separate(self, e)
	Ent_separateAxis(self, e, Rect_overlapsY(self.last, e.last) and "x" or "y")
end

function Ent_separateAxis(self, e, a)
	local s = a == "x" and "width" or "height"
	if self["_prior_" .. a] >= e["_prior_" .. a] then
		if (e.last[a] + e.last[s] / 2) < (self.last[a] + self.last[s] / 2) then
			e[a] = self[a] - e[s]
		else
			e[a] = self[a] + self[s]
		end
		e["velocity_" .. a] = e["velocity_" .. a] * -e["bounce_" .. a]
		e["_prior_" .. a] = self["_prior_" .. a]
	else
		Ent_separateAxis(e, self, a)
	end
	Ent_resolveMapCollision(e)
end

function Ent_hitMapBottom(self)
	if self.type == "Plr" then
		Plr_hitMapBottom(self)
	elseif self.type == "Crate" then
		Crate_hitMapBottom(self)
	elseif self.type == "Spider" then
		Spd_hitMapBottom(self)
	elseif self.type == "Crown" then
		Crown_hitMapBottom(self)
	elseif self.type == "Spear" then
		Spear_hitMapBottom(self)
	else
		Ent_hitMapBottom_real(self)
	end
end

function Ent_hitMapTop(self)
	if self.type == "Bat" then
		Bat_hitMapTop(self)
	elseif self.type == "Spider" then
 		Spd_hitMapTop(self)
	elseif self.type == "Spear" then
		Spear_hitMapTop(self)
	else
		Ent_hitMapTop_real(self)
	end
end

function Ent_hitMapLeft(self)
	if self.type == "Crate" then
		Crate_hitMapLeft(self)
	else
		Ent_hitMapLeft_real(self)
	end
end

function Ent_hitMapRight(self)
	if self.type == "Crate" then
		Crate_hitMapRight(self)
	else
		Ent_hitMapRight_real(self)
	end
end

function Ent_hitMapLeft_real(self)
	self.velocity_x = self.velocity_x * -self.bounce_x
	self.x = toGrid(self.x + self.width)*8
	self._prior_x = 10000
end

function Ent_hitMapTop_real(self)
	self.velocity_y = self.velocity_y * -self.bounce_y
	self.y = toGrid(self.y + self.height)*8
	self._prior_y = 10000
end

function Ent_hitMapRight_real(self)
	self.velocity_x = self.velocity_x * -self.bounce_x
	self.x = toGrid(self.x + self.width)*8 - self.width
	self._prior_x = 10000
end

function Ent_hitMapBottom_real(self)
	self.velocity_y = self.velocity_y * -self.bounce_y
	self.y = toGrid(self.y + self.height)*8 - self.height
	self._prior_y = 10000
	self.grounded = true
end


-----------------------------
--UTILS
-----------------------------
function ceil(a)
	local b = flr(a)
	return b < a and b + 1 or a
end

function round(a)
	local b = flr(a)
	return a - b < 0.5 and b or b + 1
end

function sign(a)
	return a > 0 and 1 or -1
end

function random(a, b)
	if not b then b = a a = 0 end
	return a + flr(rand() * (b-a+1))
end

function frandom(a, b)
	if not b then b = a a = 0 end
	return a + rand() * (b-a+1)
end

function toGrid(x, y)
	if y then
		return flr(round(x) / 8), flr(round(y) / 8)
	else
		return flr(round(x) / 8)
	end
end

function puts(t, a)
	for i,v in ipairs(a) do
		put(t, v)
	end
end

--get Map On Position
function getWOP(x, y)
	return isWall(mget(toGrid(x, y)))
end

function isWall(a)
	return a >= 29 and a <= 63
end

function simple(v)
	return v.simplified and not Spr_renew(v)
end

function has(t, val)
	for i,v in ipairs(t) do
		if v == val then
			return true
		end
	end
	return nil
end

function find(t, val)
	for i,v in ipairs(t) do
		if v == val then
			return i
		end
	end
	return -1
end

function data(class, a)
	if class == "Bat" then
		return a and Bat_new or bats
	elseif class == "Spider" then
		return a and Spd_new or spiders 
	elseif class == "Torch" then
		return a and Torch_new or torches 
	elseif class == "Crate" then
		return a and Crate_new or crates 
	elseif class == "Door" then
		return a and Door_new or doors 
	elseif class == "Button" then
		return a and Btn_new or buttons 
	elseif class == "Switch" then
		return a and Stc_new or switches 
	elseif class == "Key" then
		return a and Key_new or keys 
	elseif class == "Coin" then
		return a and Coin_new or coins 
	elseif class == "Spring" then
		return a and Spring_new or springs 
	elseif class == "Spikes" then
		return a and Spk_new or spikes 
	elseif class == "Lava" then
		return a and Lava_new or lavas 
	elseif class == "Platform" then
		return a and Platform_new or platforms 
	elseif class == "Spear" then
		return a and Spear_new or spears 
	elseif class == "Window" then
		return a and Window_new or windows 
	end
end


voice = 0
function sfx(b, c, d, e, f, g)
	if MENU then return end
	voice = (voice + 1) % 3
	play(voice, b, c, d, e ,f ,g)
end

-----------------------------
-----------------------------
-----------GAME--------------
-----------------------------
-----------------------------

function init()
	LEVEL = random(1, 6)
	BOSS = 8
	CREDITS = 9
	CONGRATS = 11
	-- MENU = LEVEL == 1
	MENU = true
	SPECIAL = 0
	SPEEDRUN = false

	cam_x, cam_y = 0, 0
	cam_width, cam_height = 128, 128
	cam_scene = nil
	cam_sceneTo = {x = 0, y = 0, width = 1, height = 1}

	lightsTimer = 0
	speed_timer = 0
	restart_timer = 90
	
	level_init()
end

	
function update(s)
	if fadeDir ~= 0 then
		fadeTimer = fadeTimer + fadeDir
		if fadeTimer >= 20 then
			fadeDir = 0
			if Plr.dead then
				level_reset()
			elseif Plr.onStairs then
				LEVEL = LEVEL + 1
				level_reset()
				return
			elseif MENU then
				LEVEL = 1
				MENU = nil
				level_reset()
			end
		elseif fadeTimer <= 0 then
			fadeDir = 0
		end
	end
	
	if LEVEL == CONGRATS then 
		cam_x = level.x
		cam_y = level.y - 32
		camera(cam_x, cam_y)
		if button(4, true) then init() end
		return 
	end

	Plr_update(Plr)
	if crown then Ent_resolveCollision(Plr, crown) end

	if stairs and not MENU then
		Stairs_update(stairs)
		Ent_resolveCollision(Plr, stairs)
	end


	lightsTimer = (lightsTimer + 0.2)
	if lightsTimer >= 13 then lightsTimer = lightsTimer - 14 end

	if #eyes > 6 then 
		del(eyes, 1)
		del(eyes, 1)
	end

	if LEVEL == BOSS then
		if crown then Ent_update(crown) end

		Wzrd_update(Wzrd)

		for i,v in ipairs(bolts) do
			if Bolt_update(v) then
				del(bolts, i)
			else
				Ent_resolveCollision(Wzrd, v)
				Ent_resolveCollision(Plr, v)
			end
		end
		for i,v in ipairs(light_clouds) do
			Cloud.update(v)
		end
		for i,v in ipairs(dark_clouds) do
			Cloud.update(v)
		end
	end

	if scene then
		scene_update()
	end

	for i,v in ipairs(platforms) do
		if not simple(v) then
			for i=1,4 do
				Ent_resolveCollision(Plr, v)
				for j,w in ipairs(platforms) do
					Ent_resolveCollision(v, w)
				end
			end
			Ent_update(v)
		end
	end
	
	for i,v in ipairs(eyes) do
		if not simple(v) then
			Eye_update(v)
		end
	end

	for i,v in ipairs(coins) do
		if not simple(v) then
			Coin_update(v)
			if v.dead then del(coins, i) end
		end
	end

	for i,v in ipairs(keys) do
		if not simple(v) then
			Key_update(v)
			for j,w in ipairs(doors) do
				Ent_resolveCollision(v, w)
			end
			if v.dead then del(keys, i) end
		end
	end

	for i,v in ipairs(doors) do
		if not simple(v) then
			Door_update(v)
			Ent_resolveCollision(Plr, v)
		end
	end

	for i,v in ipairs(springs) do
		if not simple(v) then
			Spring_update(v)
			Ent_resolveCollision(Plr, v)
		end
	end

	for i,v in ipairs(crates) do
		if not simple(v) then
			Crate_update(v)
			for i=1,4 do
				Ent_resolveCollision(Plr, v)
				for j,w in ipairs(crates) do
					Ent_resolveCollision(v, w)	
				end
				for j,w in ipairs(doors) do
					Ent_resolveCollision(v, w)	
				end
			end
		end
	end

	for i,v in ipairs(buttons) do
		if not simple(v) then
			Btn_update(v)
			for i=1,4 do
				Ent_resolveCollision(v, Plr)
				for j,w in ipairs(crates) do
					Ent_resolveCollision(v, w)	
				end
			end
		end
	end

	for i,v in ipairs(switches) do
		if not simple(v) then
			Stc_update(v)
			Ent_resolveCollision(v, Plr)
		end
	end


	for i,v in ipairs(bats) do
		if not simple(v) then
			Bat_update(v)
			Ent_resolveCollision(Plr, v)
			for i=1,4 do
				for j,w in ipairs(doors) do
					Ent_resolveCollision(v, w)	
				end
			end
			if LEVEL == BOSS and v.anim == "sleeping" then
				del(bats, i)
			end
		end
	end

	for i,v in ipairs(spiders) do
		if not simple(v) then
			Spd_update(v)
			Ent_resolveCollision(Plr, v)
			for i=1,4 do
				for j,w in ipairs(doors) do
					Ent_resolveCollision(v, w)	
				end
			end
			if LEVEL == BOSS and v.anim == "sleeping" then
				del(spiders, i)
			end
		end
	end

	for i,v in ipairs(spikes) do
		if not simple(v) then
			Spk_update(v)
			Ent_resolveCollision(Plr, v)
		end
	end

	for i,v in ipairs(torches) do
		if not simple(v) then
			Spr_update(v)
		end
	end

	for i,v in ipairs(spears) do
		if not simple(v) then
			Spear_update(v)
			Ent_resolveCollision(Plr, v)
		end
	end

	for i,v in ipairs(lavas) do
		if not simple(v) then
			Ent_update(v)
			Ent_resolveCollision(Plr, v)
		end
	end

	for i,v in ipairs(windows) do
		if not simple(v) then
			Spr_update(v)
		end
	end

	if LEVEL == CREDITS then
		credit_x = credit_x - 1 
		if Plr.x >= level.x + level.width + 140 then
			if button(4, true) then
				level_reset(true)
				return
			end
		end
	end

	cam_update()

	if music.play then
		playMusic(music.play)
	end

	if tune then
		playMusic(tune, true)
	end


	if MENU then
		cam_x = level.x + level.width / 2 - 64
		cam_y = level.y + level.height / 2 - 64
		camera(cam_x, cam_y)
		if button(4, true) or button(0, true) then
			fadeDir = 1
		elseif button(5, true) then
			SPEEDRUN = true
			fadeDir = 1
		end
	elseif LEVEL ~= CREDITS then
		if button(5) then
			restart_timer = restart_timer - 1
			if restart_timer <= 0 then
				level_reset(true)
			end
		else
			restart_timer = 90
		end
	end


end

function draw()
	color(0)
	clear()

	if LEVEL == BOSS then
		for i,v in ipairs(light_clouds) do
			Cloud.draw(v)
		end
	end

	if LEVEL == CONGRATS then
		color(3)
		rect(level.x, level.y, level.width, level.height)
		mblit()
		color(1)
		rect(level.x, level.y-32, level.width, 32)
		rect(level.x, level.y+56, level.width, 64)
		color(2)
		print("CONGRATULATIONS!", level.x + 33, level.y - 16)
		print("THOU ART WONDROUS", level.x + 33, level.y + 70)
		if SPEEDRUN then
			print("Time: " .. flr(speed_timer/30), level.x + 40, level.y + 85)
		end
		return
	end

	for i,v in ipairs(torches) do
		if not simple(v) then
			Torch_draw(v)
		end
	end

	for i,v in ipairs(windows) do
		if not simple(v) then
			Window_draw(v)
		end
	end

	if stairs then Stairs_draw(stairs) end

	for i,v in ipairs(coins) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(keys) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(springs) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(crates) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(platforms) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(bats) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(doors) do
		if not simple(v) then
			Door_draw(v)
		end
	end

	for i,v in ipairs(spiders) do
		if not simple(v) then
			Spd_draw(v)
		end
	end

	if LEVEL == BOSS or LEVEL == BOSS - 1 then
		Wzrd_draw(Wzrd)
	end

	Plr_draw(Plr)

	if crown then Spr_draw(crown) end

	mblit()

	if LEVEL == BOSS then
		for i,v in ipairs(bolts) do
			Bolt_draw(v)
		end
		for i,v in ipairs(dark_clouds) do
			Cloud.draw(v, true)
		end
		for i,v in ipairs(dark_clouds) do
			Cloud.draw(v)
		end
	end

	-- for i,v in ipairs(walls) do
	-- 	blit(v.img, v.x, v.y)		
	-- end

	for i,v in ipairs(secrets) do
		Spr_draw(v)
	end

	for i,v in ipairs(eyes) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(buttons) do
		if not simple(v) then
			Btn_draw(v)
		end
	end

	for i,v in ipairs(switches) do
		if not simple(v) then
			Stc_draw(v)
		end
	end

	for i,v in ipairs(spikes) do
		if not simple(v) then
			Spr_draw(v)
		end
	end

	for i,v in ipairs(spears) do
		if not simple(v) then
			Spear_draw(v)
		end
	end

	for i,v in ipairs(lavas) do
		if not simple(v) then
			Lava_draw(v)
		end
	end

	color(1)
	rect(level.x-128, level.y-128, level.width + 128 + 8, 128)
	rect(level.x-128, level.y + level.height + 8, level.width + 128 + 8, 128)
	rect(level.x + level.width + 8, level.y - 128,  128, level.height + 256)
	rect(level.x-128, level.y - 128, 128, level.height + 256)
	color(2)

	if scene then
		if scene.text1 then
			print(scene.text1, cam_x + 64 - #scene.text1*2, cam_y + 20)
		end
		if scene.text2 then
			print(scene.text2, cam_x + 64 - #scene.text2*2, cam_y + 30)
		end	
	end

	if LEVEL ~= CREDITS and not MENU then
		for i=0,2 do
			blit(i < Plr.health and 160 or 161, cam_x + 1 + 9 * i, cam_y)
		end
		if SPEEDRUN then
			color(2)
			print("Time: " .. flr(speed_timer/30), cam_x, cam_y + 120)
		end
		if button(5) then
			color(2)
			print("Hold to restart game", cam_x + 45, cam_y + 2)
			rect(cam_x + 45, cam_y + 8, restart_timer / 1.2, 1)
		end
	elseif SPEEDRUN and LEVEL == CREDITS then
		color(2)
		print("Time: " .. flr(speed_timer/30), cam_x, cam_y + 120)
	end

	if MENU then
		color(2)
		rect(cam_x + 31, cam_y + 47, 66, 34)
		rect(cam_x + 29, cam_y + 45, 5, 5)
		rect(cam_x + 94, cam_y + 45, 5, 5)
		rect(cam_x + 94, cam_y + 78, 5, 5)
		rect(cam_x + 29, cam_y + 78, 5, 5)
		color(1)
		rect(cam_x + 33, cam_y + 49, 62, 30)
		color(2)
		local xprove, yprove = 53, 53
		local xworth, yworth = 33, 66
		for i=-1,1 do
			for j=-1,1 do
				blit(125, cam_x + xprove + i, cam_y + yprove + j, 3)
				blit(153, cam_x + xworth + i, cam_y + yworth + j, 7)
			end
		end
		blit(122, cam_x + xprove, cam_y + yprove, 3)
		blit(137, cam_x + xworth, cam_y + yworth, 7)
		
		color(1)
		for i=-1,1 do
			for j=-1,1 do
				print("Press JUMP to start", cam_x + 27 + i, cam_y + 90 + j)
			end
		end
		color(2)
		print("Press JUMP to start", cam_x + 27, cam_y + 90)

		color(1)
		for i=-1,1 do
			for j=-1,1 do
				print("Made by Sheepolution", cam_x + 25 + i, cam_y + 115 + j)
			end
		end
		color(2)
		print("Made by Sheepolution", cam_x + 25, cam_y + 115)
	end

	color(1)
	--SAVE! Merge with borders?
	rect(cam_x, cam_y, cam_width, fadeTimer * 4)
	rect(cam_x, cam_y + cam_height - fadeTimer * 4, cam_width, cam_height)
	rect(cam_x, cam_y, fadeTimer * 4, cam_height)
	rect(cam_x + cam_width - fadeTimer * 4, cam_y, cam_width, cam_height)

	if LEVEL == CREDITS then
		color(2)
		for i,v in ipairs(credits) do
			print(v, cam_x + credit_x + 128 * i, cam_y + 100)
		end
	end
end


function level_init(RESET)
	local levels = {
	{--1
		x = 0,
		y = 0,
		width = 59,
		height = 8,
		doors_locked = {nil, nil, true, true},
		doors_solidWhenOn = {true},
		Btn_targets = {{2}},
		Stc_targets = {{1}},
		coins = 6
	},
	{ --2
		x = 0,
		y = 8,
		width = 59,
		height = 12,
		doors_locked = {nil, nil, true, nil, true},
		doors_solidWhenOn = {},
		Btn_targets = {{1},{4}},
		Stc_targets = {{2}},
		coins = 6
	},
	{--3
		x = 0,
		y = 33,
		width = 30,
		height = 15,
		doors_locked = {true, nil, nil, nil},
		doors_solidWhenOn = {nil, true, nil, true},
		Btn_targets = {{3}},
		Stc_targets = {{4},{2}},
		coins = 3
	},
	{--4
		x = 30,
		y = 33,
		width = 30,
		height = 15,
		doors_locked = {true, nil, nil, nil},
		doors_solidWhenOn = {nil, nil, true, false},
		Btn_targets = {{2}},
		Stc_targets = {{3,4}},
		coins = 4
	},
	{--5
		x = 28,
		y = 20,
		width = 31,
		height = 13,
		doors_locked = {true, true, nil, true, true},
		doors_solidWhenOn = {},
		Btn_targets = {{3}},
		Stc_targets = {},
		coins = 0
	},
	{--6
		x = 0,
		y = 20,
		width = 28,
		height = 13,
		doors_locked = {nil, nil, nil, true, true},
		doors_solidWhenOn = {},
		Btn_targets = {{1},{2},{3}},
		coins = 3
	},
	{--BOSS ENTRANCE
		x = 85,
		y = 0,
		width = 43,
		height = 4,
		coins = 1
	},
	{--BOSS FIGHT
		x = 60,
		y = 0,
		width = 24,
		height = 17,
		doors_locked = {true},
		doors_solidWhenOn = {},
	},
	{--CREDITS
		x = 85,
		y = 0,
		width = 43,
		height = 4,
	},
	{--SPECIAL
		x = 59,
		y = 16,
		width = 100,
		height = 100,
		coins = 18
	},
	{--CONGRATS
		x = 97,
		y = 8,
		width = 16,
		height = 6
	}
	}

	local self = levels[LEVEL]
	level = self

	inventory = {}
	inventory.coins = 0
	inventory.keys = 0

	--Lots of tables, but that's for the sake of drawing order mostly.
	--Maybe different tables for each layer? But not sure how much that would save.
	eyes = {}
	coins = {}
	torches = {}
	keys = {}
	doors = {}
	crates = {}
	springs = {}
	platforms = {}
	buttons = {}
	switches = {}
	lavas = {}
	bats = {}
	windows = {}
	spiders = {}
	spikes = {}
	secrets = {}
	spears = {}

	level_save = {}

	if LEVEL == BOSS then
		dark_clouds = {}
		light_clouds = {}
		bolts = {}
		for i=1,20 do
			put(light_clouds, Cloud_new((level.x * 8) + i * 20, level.y + 66 + random(0, 20), 1))
			put(dark_clouds, Cloud_new((level.x * 8) + i * 20, level.y - 14 + random(0, 20), 2))
		end
	end

	local wall =  {{29,30,31},
					{45,46,47},
					{61,62,63}}

	local fakewall = 
					{{77,78,79},
					{93,94,95},
					{109,110,111}}

	Plr = {x = 0, y = 0}



	for i=self.x, self.x + self.width do
		for j=self.y, self.y + self.height do
			local obj
			local a = mget(i, j)
			local x = i * 8
			local y = j * 8
			local del = true
			if a == 29 then
				mset(i,j,wall[(j % 3) + 1][(i % 3) + 1])
				del = nil
			elseif a == 28 then
				mset(i,j,fakewall[(j % 3) + 1][(i % 3) + 1])
				del = nil
			elseif a == 99 then
				del = nil
				-- mset(i,j,0)
				-- put(walls, {x = i*8, y = j*8, img = wall[(j % 3) + 1][(i % 3) + 1]})
			elseif a == 224 then
				Plr = Plr_new({}, x, y)
			elseif a == 225 then
				obj = Coin_new({}, x, y)
			elseif a == 226 then
				obj = Torch_new({}, x, y)
			elseif a == 227 then
				obj = Key_new({}, x, y)
			elseif a == 228 then
				obj = Door_new({}, x, y, self.doors_locked[#doors + 1], self.doors_solidWhenOn[#doors + 1])
			elseif a == 229 then
				obj = Crate_new({}, x, y)
			elseif a == 230 then
				obj = Platform_new({}, x, y)
			elseif a == 231 then
				obj = Btn_new({}, x, y + 3, self.Btn_targets[#buttons+1])
			elseif a == 232 then
				obj = Bat_new({}, x, y)
			elseif a == 233 then
				obj = Stc_new({}, x, y, self.Stc_targets[#switches+1])
			elseif a == 234 then
				obj = Lava_new({}, x, y)
			elseif a == 235 then
				obj = Window_new({}, x, y)
			elseif a == 236 then
				obj = Spd_new({}, x, y)
			elseif a == 237 then
				obj = Spk_new({}, x+1, y+5)
			elseif a == 238 then
				obj = Spring_new({}, x, y)
			elseif a == 239 then
				stairs = Stairs_new({}, x, y, LEVEL == CREDITS)
			elseif a == 240 then
				Wzrd = Wzrd_new({}, x, y)
			elseif a == 241 then
				obj = Coin_new({}, x, y, true)
				put(level_save, {i, j, a})
				mset(i,j,fakewall[(j % 3) + 1][(i % 3) + 1])
				del = nil
			elseif a == 242 then
				put(spears, Spear_new({}, x, y))
			end

			if obj then
				put(data(obj.type), obj)
				Spr_simplify(obj)
			end
				
			if del and a >= 224 then
				mset(i, j, 0)
				put(level_save, {i, j, a})
			end
		end
	end

	if Plr.width then
		cam_x = Plr.x + Plr.width/2 - 64
		cam_y = Plr.y + Plr.height/2 - 64
		cam_update()
	end
	self.x = self.x * 8
	self.y = self.y * 8
	self.width = self.width * 8
	self.height = self.height * 8
	fadeTimer = 16
	fadeDir = -1

	if LEVEL == BOSS - 1 then
		scene = {step = 0, timer = 0}
		Wzrd.x = Wzrd.x + 16
		music.play = nil
	end

	if LEVEL == BOSS then
		scene = {step = 0, timer = 0}
		music.play = "boss"
	end

	if LEVEL == CREDITS then
		stairs = Stairs_new({}, stairs.x-16, stairs.y-5, true)
		coins = {}
		Wzrd = nil
		Plr.crown = true
		credits = {"Made by Sheepolution",
		"Special thanks to",
		"rxi for creating the framework", "    The Ludum Dare Community",
		"Thank you for playing!"}
		mset(127, 1, 0)
		mset(127, 2, 0)
		mset(127, 3, 0)
		credit_x = 50
		music.play = "main"
	end


end

function level_reset(full)
	for i,v in ipairs(level_save) do
		mset(v[1],v[2],v[3])
	end
	scene = nil
	stairs = nil
	
	level.x = level.x / 8
	level.y = level.y / 8
	level.width = level.width / 8
	level.height = level.height / 8
	if full then
		init()
	else
		level_init()
	end
end

-----------------------------
-----------------------------
-----------------------------
--Plr
-----------------------------
function Plr_new(self, x, y)
	Ent_new(self, x, y+2, 0)
	self.type = "Plr"
	Spr_addAnim(self,"idle",{1})
	Spr_addAnim(self,"jump",{2})
	Spr_addAnim(self,"walk",{3, 1, 2}, 3)
	Spr_addAnim(self,"explode",{14, 15, 16}, 2.5, "once")
	self.anim = "idle"
	self.width = 6
	self.height = 6
	self.offset_y = -2
	self.offset_x = -1

	self.idleTimer = 0
	self.deadTimer = 50
	self.invisTimer = 0
	self.groundTimer = 3
	self.grounded = true
	self.walkSpeed = 1.3

	self.mass = 0.2

	self.health = 3
	-- self.jumpPower = 2.65
	self.jumpPower = 3.2
	self.dead = nil
	self.exploding = nil

	self.onPlatform = nil
	self.platformOffset = 0

	self.start = {x = x, y = y}
	self.onStairs = nil
	self.crown = LEVEL >= CREDITS

	return self
end

function Plr_update(self)
	if not dead and not self.onStairs then
		if not self.exploding then
			if self.invisTimer > 0 then
				self.invisTimer = self.invisTimer - 1
				if self.invisTimer == 0 then
					self.visible = true
				else
					self.visible = self.invisTimer % 6 > 3
				end
			end
			if self.anim == "idle" then
				if self.idleTimer < 25 then
					self.idleTimer = self.idleTimer + 1

					if self.idleTimer == 25 then
						if rand() < 0.5 then
							Spr_addAnim(self,"idle",{4, 5, 6, 7, 8, 8, 7, 6, 5, 4}, 3)
						else
							Spr_addAnim(self,"idle",{9, 10, 11, 12, 13, 13, 12, 11, 10, 9}, 3)
						end
					end
				end
			else 
				if self.idleTimer == 25 then
					Spr_addAnim(self,"idle",{1})
				end
				self.idleTimer = 0
			end

			if not cam_scene and not MENU then
				if SPEEDRUN and LEVEL ~= CREDITS then
					speed_timer = speed_timer + 1
				end
				if button(3) then
					self.velocity_x = self.walkSpeed
				elseif button(2) then
					self.velocity_x = -self.walkSpeed
				else
					if not self.onPlatform then
						self.velocity_x = 0
					else
						if self.anim ~= "idle" then
							self.velocity_x = 0
						end
					end
				end

				if self.grounded then
					if button(4, true) or button(0, true) then
						self.velocity_y = -self.jumpPower
						self.grounded = nil
						self.onPlatform = nil
						sfx(10 + 5, 0.4, 3, 120, -200)
					else
						self.groundTimer = self.groundTimer - 1
						if self.groundTimer < 0 then
							self.grounded = nil
						end
					end
				end
			end

			if LEVEL == CREDITS then
				if stairs.anim == "open" then
					self.velocity_x = 0
				elseif not cam_scene then
					self.velocity_x = 1
				end
				if credit_x > -600 then
					if self.x >= level.x + 170 then
						self.x = self.x - 48
					end
				end
				if self.x > level.x + level.width then
					-- init()
					self.y = self.start.y + 2
					self.velocity_y = 0
					self.mass = 0
				end
			end

			if self.grounded then
				Spr_setAnim(self,self.velocity_x == 0 and "idle" or "walk")
			else
				Spr_setAnim(self,"jump")
			end
		end

		if self.anim == "explode" and self.animEnded then
			self.dead = true
			self.deadTimer = self.deadTimer - 1
			if self.deadTimer <= 0 then
				self.dead = true
				fadeDir = 1
			end
		end

		if LAST_SPEECH then
			if (not Wzrd.flip_x and self.x < Wzrd.x + 25) or (Wzrd.flip_x and self.x > Wzrd.x - 17) then
				self.velocity_x = 1 * (Wzrd.flip_x and -1 or 1)
			elseif Rect_distanceCenterX(self, Wzrd) > 27  then
				self.velocity_x = -1 * (Wzrd.flip_x and -1 or 1)
			else
				self.velocity_x = 0
				self.flip_x = not Wzrd.flip_x
			end
		end

		if LEVEL == BOSS and self.x > level.x + level.width-8 then
			LEVEL = LEVEL + 1
			level_reset()
		end

		Ent_update(self)
	end
end

function Plr_draw(self)
	if MENU then return end
	if self.visible then
		Spr_draw(self)
		if self.crown then
			local x, y = self.x - 1, self.y - 8
			local frame = self["anim__" .. self.anim][self.frame]
			if frame >= 9 and frame <= 13 then
				y = y - 1
			elseif frame >= 4 and frame <= 8 then
				y = y + 2
			elseif frame == 2 then
				y = y - 1
			end
			blit(162, x, y, 1, 1, self.flip_x)
		end
	end
end

function Plr_hitMapBottom(self)
	self.groundTimer = 2
	Ent_hitMapBottom_real(self)
end

function Plr_kill(self)
	if not self.exploding then
		sfx(frandom(5), 0.4, 4, 180, -1800 + frandom(400))
		self.velocity_x = 0
		self.velocity_y = 0
		self.mass = 0
		Spr_setAnim(self, "explode")
		self.exploding = true
		local a = self.flip_x and 0 or 5
		put(eyes, Eye_new({}, self.x + a, self.y, true))
		put(eyes, Eye_new({}, self.x+2 + a, self.y))

		if LEVEL == BOSS then
			for i=1,12 do
				if i % 4 == 0 then
					mset(level.x/8 + 4 + i, level.y/8 + 7, 0)
				end
			end
		end
	end
end

function Plr_damage(self)
	if self.invisTimer <= 0 then
		self.health = self.health -1
		if self.health <= 0 then
			Plr_kill(self)
		end
		self.invisTimer = 30
		sfx(20, 0.6, 4, 140, -400)
	end
end

function Plr_onOverlap(self, e)
	if e.type == "Stairs" then
		if e.anim == "idle_open" then
			self.visible = nil
			tune = "complete"
			Spr_setAnim(e,"climb")
			self.onStairs = true
			return
		end
	end

	if e.type == "Spring" then
		if not self.grounded and self.velocity_y ~= 0  and e.anim == "idle" then
			Spr_setAnim(e, "jump")
			self.velocity_y = -5
			sfx(40, 0.4, 1, 250, -300)
			self.y = e.y - self.height
			-- sfx(40, 0.8, 3, 200, -200)
		end
	end

	if e.type == "Crate" then
		if Rect_top(self.last) > Rect_bottom(e.last) then
			if self.grounded then
				Plr_kill(self)
			end
		elseif not Rect_overlapsY(self.last, e.last) then
			Plr_hitMapBottom(self)
		else
			Crate_playMove(e)
		end
	end

	if e.type == "Platform" then
		if not Rect_overlapsY(self.last, e.last) then
			self.grounded = true
			self.onPlatform = true
			if not (button(3) or button(2)) then
				Spr_setAnim(self, "idle")
				self.velocity_x = e.velocity_x
				self.flip_x = self.velocity_x < 0
			end
		end
	end

	if e.type == "Door" then
		if e.solid then
			self.grounded = true
			Spr_setAnim(self, self.velocity_x == 0 and "idle" or "walk")
		end
	end

	if not cam_scene then
		if e.type == "Bat" then
			if e.anim == "flying" then
				Plr_damage(self)
			end
			return
		end

		if e.type == "Spider" then
			if e.anim ~= "sleeping" and e.anim ~= "sleeping_eyes" then
				Plr_damage(self)
			end
			return
		end

		if e.type == "Lava" then
			Plr_damage(self)
			return
		end

		if e.type == "Spikes" then
			Plr_damage(self)
			return
		end

		if e.type == "Bolt" then
			if e.timer > 0 then
				Plr_damage(self)
			end
			return
		end

		if e.type == "Spear" then
			Plr_damage(self)
			return
		end

		if e == crown then
			self.crown = true
			crown = nil
			cam_backToPlr(true)
			self.scene = true
			tune = "crown"
			mset(80, 9, 0)
		end
	end

	Ent_onOverlap_real(self, e)
end

function Plr_canSimplify(self)
	return nil
end


-----------------------------
--EYE
-----------------------------
function Eye_new(self, x, y, left)
	Ent_new(self, x, y, 112)
	self.type = "Eye"
	self.width = 1
	self.height = 1
	self.bounce_y = 2
	self.mass = 0.4
	self.velocity_y = -1 - (left and 0.4 or 0)
	self.left = left
	self.sleep = nil
	return self
end

function Eye_update(self)
	self.grounded = nil
	Ent_update(self)
	if self.simplified then return end
	if self.grounded then
		if not self.sleep and self.left then
			sfx(64, 0.4, 3, 120, -200)
		end
		if self.bounce_y == 0 then
			self.sleep = true
		elseif self.bounce_y > 0 then
			self.velocity_y = -self.bounce_y
			self.bounce_y = 0
		end
	end
end

function Eye_simplify(self)
	if Spr_canSimplify(self) then
		self.dead = true
	end
end


-----------------------------
--COIN
-----------------------------
function Coin_new(self, x, y, secret)
	Ent_new(self, x, y, secret and 70 or 64)
	self.type = "Coin"
	self.__save = {"img"}
	Spr_addAnim(self,"idle",{1, 2, 3, 4, 5, 6}, 2.4)
	Spr_addAnim(self,"vanish",{1,1,1,1,1,1,1,1,1,1,1,2,3,4}, 1)
	self.anim = "idle"
	self.start = {x = self.x, y = self.y} 
	return self
end

function Coin_update(self)
	if not self.dead then
		if self.anim ~= "vanish" then
			if Ent_overlaps(self, Plr) then
				Spr_setAnim(self, "vanish")
				if self.img == 70 then
					put(secrets, self)
					tune = "coin"
					SPECIAL = SPECIAL + 1
					for i,v in ipairs(level_save) do
						if v[3] == 241 then
							del(level_save, i)
							KAAS = "POEP"
						end
					end
				else
					sfx(60, 0.4, 3)
				end
				self.ignoreMap = true
			end
		end
		Ent_update(self)
		if self.anim == "vanish" then
			self.velocity_y = -4
			if self.y < self.start.y - 8 then
				self.y = self.start.y - 8
				if self.animEnded then
					if self.img == 64 then
						inventory.coins = inventory.coins + 1
					end
					self.dead = true
				end
			end
		end
	end
end

-----------------------------
--TORCH
-----------------------------
function Torch_new(self, x, y)
	Spr_new(self, x, y, 80)
	Spr_addAnim(self,"idle",{3, 2, 1, 2}, 2)
	self.type = "Torch"
	self.anim = "idle"
	self.imgHeight = 2
	self.width = 23
	self.height = 23

	self.bckgr = Light_new({}, self.x + 4, self.y + 4)
	return self
end

function Torch_draw(self)
	Light_draw(self.bckgr)
	Spr_draw(self)
end

function Torch_canSimplify(self)
	if Spr_canSimplify_real(self) then
		if self.x - 23 > cam_x + cam_width then
			return true
		end
	end
end

-----------------------------
--LIGHT
-----------------------------
function Light_new(self, x, y)
	self.x = x
	self.y = y
	self.size = 20
	self.maxSize = 23
	self.defSize = 20
	self.minSize = 17
	self.growDir = 1
	self.growSpeed = 0.3
	return self
end

function Light_draw(self)
	color(3)
	circ(self.x, self.y, round(self.minSize + (lightsTimer > 6 and 12 - lightsTimer or lightsTimer)))
end


-----------------------------
--KEY
-----------------------------
function Key_new(self, x, y)
	Ent_new(self, x, y, 128)
	self.type = "Key"
	self.start = {x = self.x, y = self.y}
	self.pickedUp = nil
	self.deadTimer = 0
	-- self.mass = 0.3
	return self
end

function Key_update(self)
	if not self.dead then
		if not self.pickedUp then
			if Ent_overlaps(self, Plr) then
				sfx(64, 0.4, 3)
				self.start.y = self.y
				self.ignoreMap = true
				self.pickedUp = true
				inventory.keys = inventory.keys + 1
			end
		end
		Ent_update(self)
		if self.pickedUp then
			self.deadTimer = self.deadTimer + 1
			self.velocity_y = -4
			if self.y < self.start.y - 8 then
				self.y = self.start.y - 8
			end
			if self.deadTimer > 20 then
				self.dead = true
			end
		end
	end
end


-----------------------------
--DOOR
-----------------------------
function Door_new(self, x, y, locked, on)
	Ent_new(self, x, y, locked and 132 or 131)
	self.type = "Door"
	self.__save = {"locked", "solidWhenOn", "solid", "img"}
	self.locked = locked
	self.priority_x = 100
	self.priority_y = 100
	self.solidWhenOn = on
	self.solid = not on or locked
	Rect_clone(self.last, self)
	self._prior_x = self.priority_x
	self._prior_y = self.priority_y
	return self
end

function Door_update(self)
	if not self.dead then
		if self.locked then
			if inventory.keys > 0 then
				if Ent_overlaps(self, Plr) then
					sfx(60, 0.4, 3)
					self.dead = true
					inventory.keys = inventory.keys - 1
				end
			end
		end
	end
end

function Door_draw(self)
	if self.locked or self.solid then
		Spr_draw(self)
	end
end

function Door_stateOff(self)
	local old = self.solid
	self.solid = not self.solidWhenOn
	if self.solid ~= old then
		if self.solid then
			Door_playClosed(self)
		else
			Door_playOpen(self)
		end
	end
end

function Door_stateOn(self)
	local old = self.solid
	self.solid = self.solidWhenOn
	if self.solid ~= old then
		if self.solid then
			Door_playClosed(self)
		else
			Door_playOpen(self)
		end
	end
end

function Door_playOpen()
	sfx(10 + 5, 0.4, 4, 120, 200)
end

function Door_playClosed()
	sfx(10 + 5, 0.4, 4, 120, -200)
end

-----------------------------
--CRATE
-----------------------------
function Crate_new(self, x, y)
	Ent_new(self, x, y, 144)
	self.type = "Crate"
	self.mass = 0.8
	self.priority_y = 99
	self.playTimer = 10
	self.wallTimer = 3
	self.solidTimer = 10
	return self
end

function Crate_update(self)
	self.playTimer = self.playTimer - 1
	self.wallTimer = self.wallTimer + 0.1
	self.wallTimer = min(self.wallTimer, 3)
	if not self.solid then
		self.solidTimer = self.solidTimer - 1
		if self.solidTimer < 0 then
			self.solid = true
			self.solidTimer = 10
		end
	end

	if getWOP(self.x - 2, self.y + self.height + 1) and getWOP(self.x + self.width + 2, self.y + self.height + 1) and not getWOP(self.x + self.width/2, self.y + self.height + 1) then
		self.x = toGrid(self.x - self.width/2, self.y + self.height + 1)*8 + 8
		self.wallTimer = 3
		-- self.y = self.y + 1
	end
	Ent_update(self)
end

function Crate_hitMapRight(self)
	if getWOP(self.x, self.y + self.height) ~= 0 then
		self.wallTimer = self.wallTimer - 1
		if self.wallTimer <= 0 then
			self.x = self.x - 8
			self.solid = nil
			self.wallTimer = 5
		end
	end
	Ent_hitMapRight_real(self)
end

function Crate_hitMapLeft(self)
	if getWOP(self.x, self.y + self.height) ~= 0 then
		self.wallTimer = self.wallTimer - 1
		if self.wallTimer < 0 then
			self.x = self.x + 8
			self.solid = nil
			self.wallTimer = 5
		end
	end
	Ent_hitMapLeft_real(self)
end

function Crate_hitMapBottom(self)
	Ent_hitMapBottom_real(self)
	if self.last.y < self.y then
		sfx(0, 0.4, 4, 200, -4000)
	end
end

function Crate_onOverlap(self, e)
	if e.type == "Door" then
		if e.solid then
			if Rect_overlapsY(self.last, e.last) then
				if self.last.x < e.last.x then
					Crate_hitMapRight(self)
					return
				else
					self.x = self.x - 1
					Crate_hitMapLeft(self)
					return
				end
			end
		end
	end

	Ent_onOverlap_real(self, e)
end

function Crate_playMove(self)
	if self.playTimer < 0 then
		self.playTimer = 10
		sfx(0, 0.4, 4, 200, -1000)
	end
end

-----------------------------
--PLATFORM
-----------------------------
function Platform_new(self, x, y)
	Ent_new(self, x, y, 150)
	self.type = "Platform"

	self.priority_x = 99
	self.priority_y = 99

	self.velocity_x = 1
	self.bounce_x = 1

	return self
end

-----------------------------
--SPRING
-----------------------------
function Spring_new(self, x, y)
	Spr_new(self, x, y, 145)
	self.type = "Spring"

	Spr_addAnim(self, "idle", {1})
	Spr_addAnim(self, "jump", {2,3,4,5,3,2,3,5,4,5,4}, 1, "once")
	Spr_addAnim(self, "revert", {3, 2, 1}, 3, "once")
	Spr_setAnim(self, "idle")

	self.timer = 0

	return self
end

function Spring_update(self, x, y)
	if self.animEnded then
		if self.anim == "jump"then
			self.timer = self.timer + 1
			if self.timer > 10 then
				self.timer = 0
				Spr_setAnim(self, "revert")
			end
		elseif self.anim == "revert" then
			Spr_setAnim(self, "idle")
		end
	end

	Spr_update(self)
end

-----------------------------
--BUTTON
-----------------------------
function Btn_new(self, x, y, targets)
	Ent_new(self, x, y, 129)
	self.type = "Button"
	self.__save = {"targets"}
	self.offset_y = -3
	self.solid = nil
	self.pushed = nil
	self.pushTimer = 3
	self.targets = targets

	Spr_addAnim(self, "idle", {1})
	Spr_addAnim(self, "pushed", {2})

	return self
end

function Btn_update(self)
	self.pushTimer = max(0, self.pushTimer - 1)
	if self.pushTimer == 0 then
		Btn_unpush(self)
	end
	Ent_update(self)
end

function Btn_draw(self)
	if not self.dead then
		Spr_draw(self)
	end
end

function Btn_onOverlap(self, e)
	if e.type == "Plr" or e.type == "Crate" then
		-- if abs((self.x + self.width / 2) - (e.x + e.width / 2)) < 4 then
			Btn_push(self)
		-- end
	end
end

function Btn_push(self)
	if not self.pushed then
		self.pushed = true
		Spr_setAnim(self, "pushed")
		for i,v in ipairs(self.targets) do
			Door_stateOn(doors[v])
		end
	end
	self.pushTimer = 3
end

function Btn_unpush(self)
	if self.pushed then
		self.pushed = nil
		Spr_setAnim(self, "idle")
		for i,v in ipairs(self.targets) do
			Door_stateOff(doors[v])
		end
	end
end

-- function Btn_simplify(self)

-- end

-----------------------------
--SWITCH
-----------------------------
function Stc_new(self, x, y, targets)
	Ent_new(self, x+2, y+1, 133)
	self.type = "Switch"
	self.__save = {"targets","active"}
	self.solid = nil
	self.switchTimer = 4
	self.active = nil
	self.targets = targets
	self.width = 4

	Spr_addAnim(self, "idle", {1})
	Spr_addAnim(self, "active", {2})
	Spr_setAnim(self, "idle")

	return self
end

function Stc_update(self)
	self.switchTimer = self.switchTimer - 1

	if self.active then
		Spr_setAnim(self, "active")
		for i,v in ipairs(self.targets) do
			Door_stateOn(doors[v])
		end
	else
		Spr_setAnim(self, "idle")
		for i,v in ipairs(self.targets) do
			Door_stateOff(doors[v])
		end
	end

	Ent_update(self)
end

function Stc_draw(self)
	if not self.dead then
		Spr_draw(self)
	end
end

function Stc_onOverlap(self, e)
	if abs((self.x + self.width / 2) - (e.x + e.width / 2)) < 2 then
		if self.switchTimer < 0 then
			Stc_trigger(self)
		end
		self.switchTimer = 1
	end
end

function Stc_trigger(self)
	self.active = not self.active

	if self.active then
		Spr_setAnim(self, "active")
		for i,v in ipairs(self.targets) do
			Door_stateOn(doors[v])
		end
	else
		Spr_setAnim(self, "idle")
		for i,v in ipairs(self.targets) do
			Door_stateOff(doors[v])
		end
	end
end

-----------------------------
--BAT
-----------------------------
function Bat_new(self, x, y)
	Ent_new(self, x, y, 113)
	self.type = "Bat"
	
	Spr_addAnim(self, "sleeping", {1})
	Spr_addAnim(self, "sleeping_eyes", {2})
	Spr_addAnim(self, "flying", {3,4},2.5)
	Spr_setAnim(self, "sleeping")

	self.__save = {"anim"}

	self.width = 3
	self.height = 6
	self.offset_x = -2

	self.sleepTimer = 0
	self.bounce_x = 1
	self.bounce_y = 1
	self.hspeed = 0.4
	self.vspeed = 1

	self.solid = true
	return self
end

function Bat_update(self)
	if cam_scene then return end
	self.sleepTimer = self.sleepTimer - 1
	if self.sleepTimer < 0 then
		if self.anim ~= "flying" then
			if Rect_distanceCenterX(self, Plr) < 27 and Rect_distanceCenterY(self, Plr) < 26 and self.y < Plr.y + 8 then
				Bat_startFlying(self)
			elseif Rect_distance(self, Plr) < 45 then
				Spr_setAnim(self, "sleeping_eyes")
			else
				Spr_setAnim(self, "sleeping")
			end
		end
	end
	Ent_update(self)
end

function Bat_startFlying(self)
	sfx(55, 0.4, 0, 200 , -100 - frandom(300))
	self.velocity_x = self.hspeed * sign(Rect_centerX(Plr) - Rect_centerX(self))
	self.velocity_y = self.vspeed
	Spr_setAnim(self, "flying")
end

function Bat_hitMapTop(self)
	Spr_setAnim(self, "sleeping")
	Ent_hitMapTop_real(self)
	self.velocity_x = 0
	self.velocity_y = 0
	self.sleepTimer = 40
end

function Bat_onOverlap(self, e)
	if e.type == "Door" then
		if not Rect_overlapsY(self.last, e.last) then
			if self.y > e.y then
				Bat_hitMapTop(self)
			else
				Bat_hitMapBottom(self)
			end
		end
	end
	Ent_onOverlap_real(self, e)
end

function Bat_canSimplify(self)
	return Spr_canSimplify_real(self) and self.anim == "sleeping" and LEVEL ~= BOSS
end

-----------------------------
--LAVA
-----------------------------
function Lava_new(self, x, y)
	Ent_new(self, x, y+4, 176)
	self.offset_y = -4
	self.height = 4
	Spr_addAnim(self, "idle", {1,2,3,3,4,4,3,3,5},6)
	Spr_setAnim(self, "idle")
	self.type = "Lava"

	self.__save = {"width"}

	local i = 0
	local a = 0
	while true do
		a = a + 1
		if a > 2000 then
			break
		end
		i = i + 1
		local a = mget(x/8 + i, y/8)
		if isWall(a) then
			i = i -1 
			break
		end
	end
	self.length = i
	self.width = i * 8 + 8
	return self
end

function Lava_draw(self)
	for i=0,self.length do
		blit(self.img  + (self.anim and self["anim__" .. self.anim][self.frame] * self.imgWidth - 1 or 0), self.x + self.offset_x + 8 * i, self.y + self.offset_y, self.imgWidth, self.imgHeight, self.flip_x, self.flip_y)
	end
end

function Lava_canSimplify(self)
	local s = false
	self.y = self.y - 4
	self.height = 8
	s = Spr_canSimplify_real(self)
	self.y = self.y + 4
	self.height = 4
	return s
end

-----------------------------
--WINDOW
-----------------------------
function Window_new(self, x, y)
	Spr_new(self, x-8, y, 83)
	Spr_addAnim(self, "idle", {1},3)
	Spr_setAnim(self, "idle")
	self.type = "Window"
	self.offset_x = 8
	self.width = 24
	self.__save = {"width"}
	return self
end

function Window_draw(self)
	blit(84, self.x, self.y, 3, 2)
	Spr_draw(self)
	color(0)
	line(self.x+7, self.y, self.x+7, self.y+7)
end

-----------------------------
--SPIDER
-----------------------------
function Spd_new(self, x, y)
	Ent_new(self, x, y, 117)
	self.type = "Spider"
	
	Spr_addAnim(self, "sleeping", {1})
	Spr_addAnim(self, "sleeping_eyes", {2})
	Spr_addAnim(self, "walking", {2, 3}, 10)
	Spr_addAnim(self, "falling", {4})
	Spr_addAnim(self, "walking_floor", {4, 5}, 4)
	Spr_setAnim("sleeping")

	self.start = {x = self.x, y = self.y}

	self.width = 5
	self.height = 3

	self.sleepTimer = 0
	self.soundTimer = 0

	self.fallSpeed = 0.6

	self.solid = true
	self.onground = nil
	return self
end

function Spd_update(self)
	self.sleepTimer = self.sleepTimer - 1
	if self.sleepTimer < 0 then
		if not self.onground then
			if self.anim ~= "falling" then
				if Rect_distanceCenterX(self, Plr) < 18 and Rect_distanceCenterY(self, Plr) < 28 and self.y < Plr.y + 8 then
					Spd_startFalling(self)
				elseif Rect_distance(self, Plr) < 45 then
					Spr_setAnim(self, "sleeping_eyes")
				else
					Spr_setAnim(self, "sleeping")
				end
			end
		else
			self.soundTimer = self.soundTimer - 1
			if self.soundTimer < 0 then
				self.soundTimer = 4
				sfx(40, 0.4, 0, 40, -100)
			end
			if Rect_distanceCenterX(self, Plr) < 2 then
				Spd_startClimbing(self)
			end
			if not getWOP(self.x + 4 + 4 * sign(self.velocity_x), self.y + self.height) then
				Spd_startClimbing(self)
			end
			if getWOP(self.x + 4 + 5 * sign(self.velocity_x), self.y + 2) then
				Spd_startClimbing(self)
			end
		end
	end
	self.flip_x = true
	Ent_update(self)
end

function Spd_draw(self)
	if self.anim == "falling" then
		color(4)
		line(self.x + 4, self.start.y, self.x+4, self.y)
	end
	Spr_draw(self)
end

function Spd_startFalling(self)
	sfx(40, 0.4, 0, nil, -100)
	self.falling = true
	self.velocity_y = self.fallSpeed
	self.velocity_x = 0
	Spr_setAnim(self, "falling")
end

function Spd_startClimbing(self)
	sfx(20, 0.4, 0, nil, -100)
	-- sfx(10, 0.4, 0, 200 , 400 - frandom(300))
	local i = 0
	while true do
		if getWOP(self.x, self.y - i * 8) then
			break
		end
		i = i + 1
	end
	self.start.y = self.y - i * 8
	self.velocity_y = -1
	self.velocity_x = 0
	self.onground = nil
	self.x = round(self.x)
	Spr_setAnim(self, "falling")
end

function Spd_hitMapTop(self)
	Spr_setAnim(self, "sleeping")
	Ent_hitMapTop_real(self)
	self.velocity_x = 0
	self.velocity_y = 0
	self.sleepTimer = 40
end

function Spd_hitMapBottom(self)
	Ent_hitMapBottom_real(self)
	if self.anim == "falling" then
		self.velocity_x = 1.8 * sign(Rect_centerX(Plr) - Rect_centerX(self))
		Spr_setAnim(self, "walking_floor")
		self.velocity_y = 0
		self.onground = true
	end
end

function Spd_onOverlap(self, e)
	if e.type == "Door" and e.solid then
		if not Rect_overlapsY(self.last, e.last) then
			if self.y > e.y then
				Spd_hitMapTop(self)
			else
				Spd_hitMapBottom(self)
			end
		else
			Spd_startClimbing(self)
		end
	end
	Ent_onOverlap_real(self, e)
end

function Spd_canSimplify(self)
	return Spr_canSimplify_real(self) and self.anim == "sleeping" and LEVEL ~= BOSS
end

-----------------------------
--SPIKES
-----------------------------
function Spk_new(self, x, y)
	Ent_new(self, x, y, 181)
	self.type = "Spikes"
	self.offset_y = -4
	self.offset_x = -1
	self.width = 7
	self.height = 5

	Spr_addAnim(self, "idle", {1})
	Spr_addAnim(self, "close", {2, 3}, 2, "once")
	Spr_addAnim(self, "active", {4,5,6,7}, 1, "once")
	Spr_addAnim(self, "back", {7,6,5,4,3,2,1}, 1, "once")
	Spr_setAnim(self, "idle")

	self.activeTimer = 0
	
	return self
end

function Spk_update(self)
	-- if abs(self.x - Plr.x) >= 64 then
	-- 	Ent_simplify(self)
	-- 	return
	-- end
	self.activeTimer = self.activeTimer - 1
	if self.activeTimer > 0 then
		Spr_setAnim(self, "active")
	elseif self.activeTimer == 0 then
		Spr_setAnim(self, "back")
	elseif self.anim ~= "back" then
		if Rect_distanceCenterX(self, Plr) < 30 and Rect_distanceCenterY(self, Plr) < 24 and self.y > Plr.y then
			if Rect_distanceCenterX(self, Plr) < 8 then
				Spr_setAnim(self, "active")
				sfx(50, 0.4, 0, 100, -2000)
				self.activeTimer = 30
			else
				Spr_setAnim(self, "close")
			end
		else
			Spr_setAnim(self, "idle")
		end
	end

	if self.animEnded and self.anim == "back" then
		Spr_setAnim(self, "idle")
	end
	Ent_update(self)
end

-----------------------------
--Spear
-----------------------------
function Spear_new(self, x, y)
	Ent_new(self, x, y, 135)
	self.type = "Spear"
	self.__save = {"start_y"}
	self.state = "up"
	self.timer = 0
	self.height = 4
	self.start_y = self.y

	return self
end

function Spear_update(self)
	if self.state == "up" then
		if Rect_distanceCenterX(self, Plr) < 40 and Rect_distanceCenterY(self, Plr) < 30 and Plr.y > self.y then
			if self.timer <= 0 then
				self.velocity_y = 4
			else
				self.timer = self.timer - 1
			end
		end
	end

	if self.state == "down" then
		if self.timer <= 0 then
			self.velocity_y = -4
		else
			self.timer = self.timer - 1
		end
	end

	Ent_update(self)
end

function Spear_draw(self)
	color(4)
	rect(self.x+2, self.start_y, 2, self.y - self.start_y)
	Spr_draw(self)
end

function Spear_hitMapBottom(self)
	self.state = "down"
	self.timer = 2
	sfx(0, 0.5, 4, 150, -100)
	Ent_hitMapBottom_real(self)
end

function Spear_hitMapTop(self)
	self.state = "up"
	self.timer = 20
	Ent_hitMapTop_real(self)
end

function Spear_canSimplify(self)
	return Spr_canSimplify_real(self) and self.state == "up"
end

-----------------------------
--STAIRS
-----------------------------
function Stairs_new(self, x, y, special)
	Spr_new(self, x+8, y+5, 15)
	self.type = "Stairs"
	Spr_addAnim(self, "idle", {1})
	Spr_addAnim(self, "idle_open", {6})
	Spr_addAnim(self, "climb", {6,6,6,6,6,6,6,6,6,6,6}, 6, "once")
	Spr_addAnim(self, "open", {2,3,4,5,6,6,6,6}, 4, "once")
	Spr_setAnim(self, "idle")
	self.imgWidth = 2
	self.imgHeight = 2
	self.offset_x = -8
	self.offset_y = -13
	self.width = 4
	self.height = 3
	self.special = special
	return self
end

function Stairs_update(self)
	if self.anim == "idle" then
		-- (not self.special and self.x - Plr.x < 50) or
		if self.special and self.x - Plr.x < 50 then
			if SPECIAL == 6 then
				if cam_arrived then
					Spr_setAnim(self, "open")
					sfx(0, 0.8, 4, 1100, nil)
				else
					cam_toScene(self)
				end
			end
		elseif inventory.coins == level.coins then
			if cam_arrived then
				Spr_setAnim(self, "open")
				sfx(0, 0.8, 4, 1100, nil)
			else
				cam_toScene(self)
			end
		end
	elseif self.anim == "open" and self.animEnded then
		Spr_setAnim(self, "idle_open")
		cam_backToPlr()
	elseif self.anim == "climb" and self.animEnded then
		fadeDir = 1
	end
	Spr_update(self)
end

function Stairs_draw(self)
	Spr_draw(self)
	if self.anim == "idle" then
		color(2)
		print(self.special and 6 - SPECIAL or level.coins - inventory.coins, self.x-2, self.y - 12)
		if self.special then
			blit(70, self.x - 4, self.y - 6)
		end
	elseif self.anim == "climb" then
		local y = self.y + self.offset_y
		if self.frame == 1 then
			blit(Plr.crown and 58 or 48, self.x - 4, y + 8, 1, 1)
		elseif self.frame == 2 then
			blit(Plr.crown and 59 or 49, self.x - 2, y + 6, 1, 1)
		elseif self.frame == 3 then
			blit(50, self.x - 2, y + 4, 1, 1)
		elseif self.frame == 4 then
			blit(51, self.x - 2, y + 2, 1, 1)
		end
	end
end

function Stairs_simplify(self)
end

-----------------------------
---------BOSSFIGHT-----------
-----------------------------
--CLOUD
-----------------------------
Cloud = {}
function Cloud_new(x, y, type)
	local self = {}
	self.x = x
	self.y = y
	self.type = type
	return self
end

function Cloud.update(self)
	self.x = self.x - (self.type == 1 and 1.2 or 0.6)
	if self.x < level.x - 20 then
		self.x = flr(level.x + level.width) + 20
		if self.type == 1 then
			self.y = level.y + 66 + random(0, 20)
		else
			self.y = level.y - 14 + random(0, 20)
		end
	end
end

function Cloud.draw(self, a)
	if not a then
		color(self.type == 1 and 3 or 0)
		circ(flr(self.x), flr(self.y), 20)
	else
		color(4)
		circ(flr(self.x), flr(self.y), 22)
	end
end

-----------------------------
--BOLT
-----------------------------
function Bolt_new(x, y)
	local self = Spr_new({}, x, y)
	self.x = x
	self.y = y
	self.imgs = {}
	self.type = "Bolt"

	for i=1,10 do
		if i > 1 then
			local r
			repeat
				r = random(0,4)
			until r ~= self.imgs[i-1]
			self.imgs[i] = r
		else
			self.imgs[i] = random(0, 4)
		end
	end
	self.timer = -60
	self.striked = nil
	self.height = 11 * 8
	self.start = nil

	return self
end

function Bolt_update(self)
	self.timer = self.timer + 3
	if self.timer > 16 then
		if not self.striked then
			sfx(20, 0.8, 4, 800, -100)
		end
		self.striked = true
		
		if self.timer > 30 then
			return true
		end
	end
end

function Bolt_draw(self)
	if self.timer > 0 then
		for i,v in ipairs(self.imgs) do
			if self.striked then
				if i + 16 > self.timer then 
					blit(52 + self.imgs[i], self.x, self.y + 8 * i)
				end
			else
				if i <= self.timer then
					blit(52 + self.imgs[i], self.x, self.y + 8 * i)
				end
			end
		end
	else
		blit(57, self.x, self.y + 8 * 10)
	end
end

-----------------------------
--Wzrd
-----------------------------
function Wzrd_new(self, x, y)
	Ent_new(self, x-8, y, 192)
	self.type = "Wzrd"
	self.starty = y
	self.height = 16
	self.imgHeight = 2
	Spr_addAnim(self, "idle", {1})
	Spr_addAnim(self, "outfade", {2,3,10}, 3, "once")
	Spr_addAnim(self, "infade", {3,2,1}, 3, "once")
	Spr_addAnim(self, "chant", {4,6,5,7,6,7,5,7,6,7,5,7,6,7,5,7,6,7,5,7,6,7,5,4,1}, 5, "once")
	Spr_addAnim(self, "shock", {8,9,8,9,8,9,8,9,8,9,8,9,8,9}, 2, "once")
	Spr_addAnim(self, "tired", {6})
	Spr_addAnim(self, "dissapear", {6,6,6,5,6,6,5,6,5,6,5,5,5,5,5,5}, 3, "once")
	Spr_setAnim(self, "idle")
	self.chantTimer = 70
	self.spawnTimer = 10
	self.spawn = "bat"
	self.life = 3
	self.flip_x = true
	return self
end

function Wzrd_update(self)
	if self.anim == "idle" then
		if abs(self.x - Plr.x) < 10 then
			Spr_setAnim(self, "outfade")
			sfx(20, 0.4, 1, 300, -2000)
		else
			self.chantTimer = self.chantTimer - 1
			if self.chantTimer < 0 then
				sfx(3, 0.4, 1, 1000, -100)
				Spr_setAnim(self, "chant")
				self.chantTimer = 45
			end
		end
	elseif self.anim == "chant" then
		self.spawnTimer = self.spawnTimer - 1
		if self.spawnTimer < 0 then
			if self.spawn == "bat" then
				local bt = Bat_new({}, level.x + 60 + random(0, 70), level.y + 8)
				bt.sleepTimer = -1
				Bat_startFlying(bt)
				bt.velocity_x = 2.5 * sign(-0.5 + rand())
				put(bats, bt)
				self.spawnTimer = 30
			elseif self.spawn == "spider" then
				local sp = Spd_new({}, level.x + 40 + random(0, 110), level.y + 8)
				sp.fallSpeed = 2
				sp.sleepTimer = -1
				Spd_startFalling(sp)
				put(spiders, sp)
				self.spawnTimer = 30
			elseif self.spawn == "bolt" then
				put(bolts, Bolt_new(Plr.x, level.y - 8))
				self.spawnTimer = 20
			elseif self.spawn == "lava" then
				if #lavas == 0 then
					put(lavas, Lava_new({}, 520 , 72))
				end
			end
		else
			if self.spawn == "lava" then
				if self.y <= level.y + 40 then
					self.y = level.y + 40
					self.velocity_y = 0
					for i=1,12 do
						if i % 4 == 0 then
							mset(level.x/8 + 4 + i, level.y/8 + 7, 29)
						end
					end
				else
					self.velocity_y = -0.8
				end
			end
		end
	end
	if self.animEnded then
		if self.anim == "outfade" then
			if self.flip_x then
				self.x = self.x - 64
				self.y = self.starty
				self.flip_x = nil
			else
				self.x = self.x + 64
				self.y = self.starty
				self.flip_x = true
			end
			Spr_setAnim(self, "infade")
		elseif self.anim == "infade" then
			Spr_setAnim(self, "idle")
		elseif self.anim == "chant" then
			Spr_setAnim(self, "idle")
			if self.spawn == "bat" then
				self.spawn = "spider"
			elseif self.spawn == "spider" then
				self.spawn = "bolt"
			elseif self.spawn == "bolt" then
				self.spawn = "lava"
				self.spawnTimer = 60
			elseif self.spawn == "lava" then
				lavas = {}
				for i=1,12 do
					if i % 4 == 0 then
						mset(level.x/8 + 4 + i, level.y/8 + 7, 0)
					end
				end
				Spr_setAnim(self, "outfade")
				sfx(20, 0.4, 1, 300, -2000)
				self.spawn = "bat"
			end
		elseif self.anim == "shock" then
			if self.life == 0 then
				Spr_setAnim(self, "tired")
				crown = Crown_new({}, self.x + (self.flip_x and -1 or 7), self.y+4, self.flip_x)
			else
				Spr_setAnim(self, "idle")
			end
		elseif self.anim == "dissapear" then
			scene.step = scene.step + 1
		end
	end
	Ent_update(self)
end

function Wzrd_draw(self)
	if self.anim == "tired" or self.anim == "dissapear" then
		self.imgWidth = 2
	else
		self.imgWidth = 1
	end
	Spr_draw(self)
end

function Wzrd_onOverlap(self, e)
	if e.timer > 0 and self.anim ~= "shock" and self.life > 0 then
		Spr_setAnim(self, "shock")
		if e ~= #bolts then del(bolts, #bolts) end
		self.spawn = "lava"
		self.spawnTimer = 60
		self.life = self.life - 1
		if self.life == 0 then
			LAST_SPEECH = true
			music.play = nil
			cam_toScene(self.x + 15 * (self.flip_x and -1 or 1), self.y + 13)
		end
	end
end

function Wzrd_canSimplify(self)
	return nil
end
-----------------------------
--CROWN
-----------------------------
function Crown_new(self, x, y, flip)
	Ent_new(self, x + 4, y, 162)
	self.type = "Crown"
	self.velocity_x = 0.8 * (flip and -1 or 1)
	self.mass = 0.1
	self.flip_x = flip
	self.bounce_y = 0.8
	Spr_addAnim(self, "rotate", {2,3,4,5,6,7,1}, 6, "once")
	Spr_setAnim(self, "rotate")
	self.solid = nil
	self.offset_x = -4
	self.width = 4
	return self
end

function Crown_hitMapBottom(self)
	Ent_hitMapBottom_real(self)
	if self.velocity_y > -0.6 and not Rect_overlaps(self, Plr) and self.velocity_x ~= 0 then
		self.velocity_y = 0
		self.velocity_x = 0
		self.mass = 0
		scene.step = scene.step + 1
		sfx(60, 0.5, 3, 50)
	elseif self.velocity_x ~= 0 then
		 sfx(60, 0.5, 3, 50)
	end
end

-----------------------------
--MUSIC
-----------------------------
CHANNELS = { 12, 14, 17, 19, 21, 24, 27, 29, 31, 34, 36, 39, 41, 43}

music = {}
music.play = "main"
music.main = {
	speed = 8,
	tick = -1,
	play = function(n) play(3, n, 1, 3, nil, 20) end,
	seq = 
	"123200000100000000000000123200000100000000000000123200000100000000000000" ..
	"1232000001000000000000001232000001000000000000001234040413030302" ..
	"1234040413030302"
}

music.boss = {
	speed = 5,
	tick = -1,
	play = function(n) play(3, n, .6, 1, 110) end,
	seq = 
	"1000100010001000100010001000100013031303130313131303130313031313" ..
	"4242423414143432424242341414343292827274746464629282727474646462" ..
	"928272747464646292827274746464629887998aa9bbcabc9282727474646462" ..
	"9282727474646462928272747464646292827274746464629887998aa9bbca75" ..
	"9282727474646462928272747464646292827274746464629282727474646462" ..
	"98a79acb9cb9cb98928272981768646492827298176864649282729807686020"
}

music.complete = {
	speed = 5,
	tick = -1,
	play = function(n) sfx(20 + n, 0.4, 1) end,
	seq = 
	"56034132314670000000000000000000000"
}

music.coin = {
	speed = 5,
	tick = -1,
	play = function(n) sfx(40 + n, 0.4, 3) end,
	seq = 
	"1357"
}

music.crown = {
	speed = 5,
	tick = -1,
	play = function(n) sfx(20 + n, 0.8, 3) end,
	seq = 
	"123456789abc"
}

function playMusic(play, t)
	local self = music[play]
	self.tick = self.tick + 1
	if self.tick % round(self.speed) == 0 then
		local step = self.tick / self.speed
		if t and step >= #self.seq then tune = nil self.tick = -1 return end 
		local c = ord(self.seq, 1 + step % #self.seq)
		c = (c >= ord("a")) and (c - ord("a") + 10) or (c - ord("0"))
		if c > 0 then
			self.play(CHANNELS[c])
		end
	end
end

-----------------------
--CAMERA
-----------------------
function cam_update()
	if not cam_scene then
		cam_x = flr(Plr.x + Plr.width/2) - 64
		cam_y = flr(Plr.y + Plr.height/2) - 64
	else
		local c = {x = cam_x, y = cam_y, width = cam_width, height = cam_height}
		local xdis = Rect_distanceCenterX(c, cam_sceneTo)
		local ydis = Rect_distanceCenterY(c, cam_sceneTo)
		if xdis < 2 then
			Rect_centerX(c, cam_sceneTo.x)
		else
			cam_x = cam_x + (xdis/7) * sign(cam_sceneTo.x - (cam_x+cam_width/2))
		end
		if ydis < 2 then
			Rect_centerY(c, cam_sceneTo.y)
		else
			cam_y = cam_y + (ydis/7) * sign(cam_sceneTo.y - (cam_y+cam_height/2))
		end
		if xdis < 2 and ydis < 2 then
			cam_arrived = true
			if cam_toPlr then
				cam_arrived = nil
				cam_scene = nil
				cam_toPlr = nil
			end
		end
			-- cam_y = cam_y + 1 * sign((cam_y+cam_height/2) - cam_sceneTo.y )
	end
	camera(cam_x, cam_y)
end

function cam_toScene(x, y)
	cam_arrived = nil
	cam_scene = true
	cam_toPlr = nil
	Plr.velocity_x = 0
	if not y then
		cam_sceneTo.x = x.x + x.width/2
		cam_sceneTo.y = x.y + x.height/2
	else
		cam_sceneTo.x = x
		cam_sceneTo.y = y
	end
end

function cam_backToPlr(t)
	cam_toScene(Plr)
	cam_toPlr = t and nil or true
end
----
--scene SCENE
----
function scene_update()
	local self = scene
	if LEVEL == BOSS - 1 then
		if self.step < 14 then
			if self.timer <= 0 then
				if self.step == 0 then
					if abs(Plr.x - Wzrd.x) < 50 and Plr.grounded then
						cam_toScene(Wzrd)
						self.step = self.step + 1
						Spr_setAnim(Plr,"idle")
					end
				elseif self.step == 1 then
					if cam_arrived then
						self.step = self.step + 1
						self.timer = 25
					end
				elseif self.step == 2 then
					Wzrd.flip_x = true
					self.step = self.step + 1
					self.timer = 20
				elseif self.step == 3 then
					self.text1 = "How didst thou escape"
					self.text2 = "the dungeon?"
				elseif self.step == 4 then
					self.text1 = "Yes, I hadst thou"
					self.text2 = "thrown in there"
				elseif self.step == 5 then
					self.text1 = "Why? Thou knoweth why"
					self.text2 = "Thou started learning the truth"
				elseif self.step == 6 then
					self.text1 = "Indeed, I am not thine father"
					self.text2 = "I murdered him 5 years ago"
				elseif self.step == 7 then
					self.text1 = "Alloweth me to telleth thou"
					self.text2 = "what hath happened that day"
				elseif self.step == 8 then
					self.text1 = "He banished me for using"
					self.text2 = "the power of black magic"
				elseif self.step == 9 then
					self.text1 = "Enraged I murdered him"
					self.text2 = "and took his place"
				elseif self.step == 10 then
					self.text1 = "It took thou 5 years"
					self.text2 = "to learn the truth"
				elseif self.step == 11 then
					self.text1 = "And now thou wants to stop me?"
					self.text2 = "Thou maketh me laugh, boy"
				elseif self.step == 12 then
					self.text1 = "Come forth to the roof"
					self.text2 = "and prove thine worth"
					Wzrd.y = Wzrd.y - 0.5
					Spr_setAnim(Wzrd, "chant")
					if (button(4, true) or button(0, true)) and Wzrd.y + Wzrd.height < level.y then
						self.step = self.step + 1
					end
				elseif self.step == 13 then
					self.text1 = nil
					self.text2 = nil
					cam_backToPlr()
					self.step = self.step + 1
				end
				if self.step >= 3 and self.step <=11 then
					if button(4, true) or button(0, true) then
						self.step = self.step + 1
					end
				end
			else
				self.timer = self.timer - 1
			end
		end
	elseif LEVEL == BOSS then
		if self.step == 1 then
			self.text1 = "Thou didst defeat me.."
			self.text2 = "How..?"
		elseif self.step == 2 then
			self.text1 = "Perhaps I should've ceased"
			self.text2 = "using mine lightning attack.."
		elseif self.step == 3 then
			self.text1 = "But twas a wonderous attack"
			self.text2 = ""
		elseif self.step == 4 then
			self.text1 = "..."
		elseif self.step == 5 then
			self.text1 = "You know.."
			self.text2 = "I love this kingdom"
		elseif self.step == 6 then
			self.text1 = "I love its people"
			self.text2 = "I liked living here"
		elseif self.step == 7 then
			self.text1 = "When I killed thine father"
			self.text2 = "I feared the kingdom would fall"
		elseif self.step == 8 then
			self.text1 = "I took thine father's place"
			self.text2 = "Not for mine own good"
		elseif self.step == 9 then
			self.text1 = "But for the people"
			self.text2 = ""
		elseif self.step == 10 then
			self.text1 = "I hath tried to be a good king"
		elseif self.step == 11 then
			self.text1 = "And a great father"
			self.text2 = ""
		elseif self.step == 12 then
			self.text1 = "Twas mine pleasure to call"
			self.text2 = "thou mine son these past 5 years"
		elseif self.step == 13 then
			self.text1 = "Son.."
			self.text2 = "Pick up that crown"
		elseif self.step == 14 then
			self.text1 = "And become the best king"
			self.text2 = "this kingdom hath ever seen"
		elseif self.step == 15 then
			self.text1 = "Farewell.."
			self.text2 = "Son.."
			Spr_setAnim(Wzrd, "dissapear")
		elseif self.step == 16 then
			self.text1 = nil
			self.text2 = nil
			cam_backToPlr()
			LAST_SPEECH = nil
		end
		if self.step >= 1 and (button(4, true) or button(0, true)) then
			self.step = self.step + 1
		end
	end
end