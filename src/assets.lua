local Assets = class('Assets')

function Assets:initialize()
	
	self.images = {}
	self.fonts = {}
	self.jsons = {}
	self.music = {}
	self.sfx = {
		footsteps = {
			city = {},
			forest = {}
		},
		misc = {}
	}
	
end

function Assets:load()

	local city_footsteps = {
		"walk-stone-1.wav",
		"walk-stone-2.wav",
		"walk-stone-3.wav",
		"walk-stone-4.wav",
		"walk-stone-5.wav",
		"walk-stone-6.wav",
		"walk-stone-7.wav"
	}
	
	for i = 1, #city_footsteps do
		table.insert(self.sfx.footsteps.city, love.audio.newSource("files/sfx/movement/"..city_footsteps[i], "static"))
	end
	
	local forest_footsteps = {
		"walk-grass-1.wav",
		"walk-grass-2.wav",
		"walk-grass-3.wav",
		"walk-grass-4.wav",
		"walk-grass-5.wav",
		"walk-grass-6.wav",
		"walk-grass-7.wav"
	}	

	for i = 1, #forest_footsteps do
		table.insert(self.sfx.footsteps.forest, love.audio.newSource("files/sfx/movement/"..forest_footsteps[i], "static"))
	end

	-- load all sounds in the files/sfx/misc/ directory

	self.sfx.misc = {}

	local files = love.filesystem.getDirectoryItems("files/sfx/misc/")
	
	for k, file in ipairs(files) do
		local shortname = file:gsub("%.wav", "")
		self.sfx.misc[shortname] = love.audio.newSource("files/sfx/misc/"..file, "static")
	end

	-- images

	self.images["opening-image"] = love.graphics.newImage("files/opening-image.png")
	self.images["pointer"] = love.graphics.newImage("files/pointer.png")
	self.images["sky"] = love.graphics.newImage("files/sky.png")

	self.images["enemy-hit-bar-1"] = love.graphics.newImage("files/ui/enemy-hit-bar-1.png")
	self.images["enemy-hit-bar-2"] = love.graphics.newImage("files/ui/enemy-hit-bar-2.png")

	-- music

	self.music["forest"] = love.audio.newSource("files/music/It_Came_from_the_Forest.mp3", "stream")
	self.music["forest"]:setLooping(true)

	--self.music["city"] = love.audio.newSource("files/music/It_Came_from_the_Forest.mp3", "stream")
	--self.music["city"]:setLooping(true)

	-- font

	self.fonts["main"] = love.graphics.newFont("files/fonts/Berry Rotunda.ttf", 16, "none", love.graphics.getDPIScale())
	
end

function Assets:playMusic(id)

	if not self.music[id] then
		return
	end

	self.music[id]:setVolume(settings.musicVolume)
	self.music[id]:play()

end

function Assets:stopMusic(id)

	if not self.music[id] then
		return
	end

	self.music[id]:stop()

end

function Assets:playSound(value)

	if type(value) == 'string' then
		local sound = self.sfx.misc[value]
		if sound then
			sound:setVolume(settings.sfxVolume)
			sound:play()
		end
	elseif type(value) == 'userdata' then
		value:setVolume(settings.sfxVolume)
		value:play()
	end
	
end

return Assets
