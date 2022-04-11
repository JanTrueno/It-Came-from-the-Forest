local Renderer = class('Renderer')

local direction_names = {[0] = "North", [1] = "East", [2] = "South", [3] = "West"}

function Renderer:initialize()
	
end

function Renderer:init(caller)
	
	
	self.caller = caller
	self.canvas = caller.canvas
	self.dungeonDepth = 6
	self.dungeonWidth = 4
	self.backgroundIndex = 1
	self.skyIndex = 1
	self.currentNPC = nil
	self.currentVendor = nil
	self.doShowSystemMenu = false
	self.doShowAutomapper = false
	self.doShowInventory = false
	self.currentHoverItem = nil
	self.currentHoverSpell = nil
	self.showSpellEffect = false
	
	self.popupText = ""
	
	self.buttons = {}
	
	local button = Button:new()
	button.id = "close-inventory"
	button.x = settings.inventoryX+363
	button.y = settings.inventoryY+200
	button.width = 32
	button.height = 32
	button.normal = "button-close-1"
	button.over = "button-close-2"
	button.trigger = self.onCloseButtonClick

	self.buttons[button.id] = button
	
	local button = Button:new()
	button.id = "close-vendor"
	button.x = 441
	button.y = 226
	button.width = 32
	button.height = 32
	button.normal = "button-close-1"
	button.over = "button-close-2"
	button.trigger = self.onCloseVendorButtonClick

	self.buttons[button.id] = button

	self.menuitemsOffsetX = 512
	self.menuitemsOffsetY = 120
	self.menuitems = {
		{ caption = "New game", trigger = self.onStartButtonClick},
		{ caption = "Continue", trigger = self.onContinueButtonClick},
		{ caption = "Credits", trigger = self.onCreditsButtonClick},
		{ caption = "About", trigger = self.onAboutButtonClick},
		{ caption = "Quit", trigger = self.onQuitButtonClick}
	}	

	self.systemmenuOffsetY = 65
	self.systemmenuitemsOffsetY = 130
	self.systemmenuitems = {
		{ caption = "Exit to main menu", trigger = function() self:onBackToMenuButtonClick() end},
		{ caption = "Quit to desktop", trigger = self.onQuitButtonClick},
	}	
	
end

function Renderer:drawImage(x, y, id, center)

	if assets.images[id] then

		if center and center == true then
			x = math.floor(screen.width/2 - assets.images[id]:getWidth()/2)
		end

		love.graphics.draw(assets.images[id], x, y)	

	end

end

function Renderer:update(dt)

	love.graphics.setCanvas(self.canvas)
	love.graphics.clear()
	love.graphics.setColor(1,1,1,1)
	love.graphics.setFont(assets.fonts["main"]);
	love.graphics.setLineStyle("rough")
	love.graphics.setShader(highlightshader)
	
	if gameState == GameStates.EXPLORING then
	
		self:drawViewport()

		-- Enemy in front of player?

		local enemy = level:getFacingEnemy()
		
		if enemy and enemy.properties.state == 1 then
			self:drawEnemyStats(enemy)
		end

		if self.doShowAutomapper then
			self:drawAutomapper()
		end

		if self.doShowInventory then
			self:drawInventory()
			self:showPlayerStats()
		end
		
		if subState == SubStates.SELECT_SPELL then
			self:drawSpellList()
		end

		self:drawUI()
	
	end

	if gameState == GameStates.BUILDUP1 then
		love.graphics.draw(assets.images["zoopersoft-games"], 0, 0)
	end
	
	if gameState == GameStates.BUILDUP2 then
		self:drawWrappedText(0,170, "AN UNSPEAKABLE EVIL HAS FALLEN UPON US", screen.width, {1,1,1,1}, "center")
	end
	
	if gameState == GameStates.BUILDUP3 then
		self:drawWrappedText(0,170, "IT IS NOT KNOWN WHO OR WHAT IS BEHIND IT", screen.width, {1,1,1,1}, "center")
	end
	
	if gameState == GameStates.BUILDUP4 then
		self:drawWrappedText(0,170, "ALL WE KNOW IS...", screen.width, {1,1,1,1}, "center")
	end
	
	if gameState == GameStates.MAIN_MENU then
		self:drawMainmenu()
	end
	
	if gameState == GameStates.CREDITS then
		self:drawCredits()
	end	
	
	if gameState == GameStates.ABOUT then
		self:drawAbout()
	end		

	if gameState == GameStates.SETTINGS then
		self:drawSettings()
	end		
	
	if subState == SubStates.VENDOR then
		self:drawVendor()
	end
	
	if subState == SubStates.POPUP then
		self:drawPopup()
	end

	if subState == SubStates.NPC then
		if self.currentNPC then
			self:drawNPC()
		end
	end
	
	
	if subState == SubStates.FOUND_LOOT then
		self:drawFoundLoot()
	end
	
	if subState == SubStates.VENDOR_ANTSACS then
		self:drawAntsacsVendor()
	end	

	if self.doShowSystemMenu then
		self:drawSystemMenu()
	end
	
	if self.showSpellEffect then
		self:drawImage(320, 170, self.currentSpell.imageid, true)
	end
	
	if gameState == GameStates.EXPLORING or gameState == GameStates.MAIN_MENU or gameState == GameStates.CREDITS then
		self:drawPointer()	
	end
	
	if self.currentHoverItem then
		self:showItemHoverStats(self.currentHoverItem)
	end
	
	if self.currentHoverSpell then
		self:showSpellHoverStats(self.currentHoverSpell)
	end	


	if settings.debug then
		local mx, my = love.mouse.getPosition()
		self:drawText(20, 20, mx .. "/" .. my, {1,1,1,1}, "left")
		
		self:drawText(20, 40, tostring(love.timer.getFPS()), {1,1,1,1})
	end
	
	love.graphics.setCanvas()

end

function Renderer:handleMousePressed(x, y, button)
	
	if button == 1 then

		if subState == SubStates.INVENTORY then
			if self.doShowInventory then
				self:clickOnInventory(x, y)
				return
			end
		end
		
		if subState == SubStates.VENDOR then
			self:clickOnVendor(x, y)
			return
		end		
		
		if subState == SubStates.SELECT_SPELL then
			self:clickOnSpellList(x, y)
			return
		end
		
		if subState == SubStates.POPUP or subState == SubStates.NPC or subState == SubStates.FOUND_LOOT then
			subState = SubStates.IDLE
		end
		
		if subState == SubStates.VENDOR_ANTSACS then
			subState = SubStates.IDLE
			if party.antsacs > 0 then
				party.gold = party.gold + party.antsacs * settings.prices.antsacs
				party.antsacs = 0
			end
		end
		
		if subState == SubStates.AUTOMAPPER then
			if intersect(x, y, 541, 321, 34, 34) then
				self:showAutomapper(false)
			end
		end
		
		if subState == SubStates.SYSTEM_MENU then
		
			if intersect(x, y, 587, 321, 34, 34) then
				self:showSystemMenu(false)
			end	
			for i = 1, #self.systemmenuitems do
				if intersect(x, y, 247, self.systemmenuOffsetY + self.systemmenuitemsOffsetY + ((i-1)*25), 150, 20) then
					self.systemmenuitems[i].trigger()
				end
			end	
			return
		end
		
		if gameState == GameStates.MAIN_MENU and subState == SubStates.IDLE then
		
			local canContinue = Game:canContinue()
			local adjustY = canContinue and -15 or 0
			local index = 0
			
			for i = 1, #self.menuitems do
			
				if not canContinue and i == 2 then
					-- skip this menuitem
				else
					if intersect(x, y, self.menuitemsOffsetX, self.menuitemsOffsetY + adjustY + (index*30), 100, 20) then
						self.menuitems[i].trigger()
					end
					index = index + 1
				end
			
			end		
			return
				
		end
		
		if gameState == GameStates.CREDITS or gameState == GameStates.ABOUT then
			gameState = GameStates.MAIN_MENU
			return
		end

		if gameState == GameStates.SETTINGS then
			gameState = GameStates.MAIN_MENU
			return
		end
		
	end
	
end

function Renderer:handleInput(key)

	if inventoryDragSource.item ~= nil then
		return
	end

	if subState == SubStates.INVENTORY then
	
		if key == 'i' then
			self:showInventory(false)
			return
		end

	end
	
	if subState == SubStates.AUTOMAPPER then
	
		if key == 'm' then
			self:showAutomapper(false)
			return
		end

	end	
	
	if subState == SubStates.SYSTEM_MENU then
	
		if key == 'escape' then
			self:showSystemMenu(false)
			return
		end

	end		
	
end

function Renderer:flipGround()

	self.backgroundIndex = self.backgroundIndex + 1
	if self.backgroundIndex > 2 then
		self.backgroundIndex = 1
	end
	
end

function Renderer:flipSky()

	self.skyIndex = self.skyIndex + 1
	if self.skyIndex > 2 then
		self.skyIndex = 1
	end
	
end

function Renderer:getPlayerDirectionVectorOffsets(x, z)

    if party.direction == 0 then
        return { x = party.x + x, y = party.y + z };
	elseif party.direction == 1 then
		return { x = party.x - z, y = party.y + x };
	elseif party.direction == 2 then
		return { x = party.x - x, y = party.y - z };
	elseif party.direction == 3 then
		return { x = party.x + z, y = party.y - x };
	end
	

end

function Renderer:getObjectDirectionID(prefix, direction)

	local result = nil
	
	if direction == -1 then
		return prefix
	end
	
	
	if direction == 0 then
		if party.direction == 2 then
			result = prefix.."-1"
		end
		if party.direction == 0 then
			result = prefix.."-2"
		end
		if party.direction == 1 then
			result = prefix.."-4"
		end			
		if party.direction == 3 then
			result = prefix.."-3"
		end	
	elseif direction == 1 then
		if party.direction == 2 then
			result = prefix.."-4"
		end
		if party.direction == 0 then
			result = prefix.."-3"
		end
		if party.direction == 1 then
			result = prefix.."-2"
		end			
		if party.direction == 3 then
			result = prefix.."-1"
		end					
	elseif direction == 2 then
		if party.direction == 2 then
			result = prefix.."-2"
		end
		if party.direction == 0 then
			result = prefix.."-1"
		end
		if party.direction == 1 then
			result = prefix.."-3"
		end			
		if party.direction == 3 then
			result = prefix.."-4"
		end	
	elseif direction == 3 then
		if party.direction == 2 then
			result = prefix.."-3"
		end
		if party.direction == 0 then
			result = prefix.."-4"
		end
		if party.direction == 1 then
			result = prefix.."-1"
		end			
		if party.direction == 3 then
			result = prefix.."-2"
		end	
	end
		
	return result
		
end



function Renderer:getTile(atlasId, layerId, tileType, x, z)

	if not atlases.jsondata[atlasId].layer[layerId] then
		return nil
	end

	local layer = atlases.jsondata[atlasId].layer[layerId]
	
	if not layer then return false end
	
	for i = 1, #layer.tiles do
		local tile = layer.tiles[i]
		if tile.type == tileType and tile.tile.x == x and tile.tile.y == z then
			return tile
		end
	end

	return nil
	
end

function Renderer:drawText(x, y, text, color, align)

	align = align and align or "left"

	love.graphics.setColor(0,0,0,1)
	love.graphics.printf(text, x+1, y+1, 640, align)
	love.graphics.setColor(color)
	love.graphics.printf(text, x, y, 640, align)
	love.graphics.setColor(1,1,1,1)
	
end

function Renderer:drawCenteredText(x, y, text, color)


	local strlen = assets.fonts["main"]:getWidth(text)

	local offsetx = math.floor(strlen/2)

	love.graphics.setColor(0,0,0,1)
	love.graphics.printf(text, (x+1)-offsetx, y+1, strlen*2, "left")
	love.graphics.setColor(color)
	love.graphics.printf(text, x-offsetx, y, strlen*2, "left")
	love.graphics.setColor(1,1,1,1)
	
end
function Renderer:drawWrappedText(x, y, text, wrapAt, color, align)

	align = align and align or "left"

	love.graphics.setColor(0,0,0,1)
	love.graphics.printf(text, x+1, y+1, wrapAt, align)
	love.graphics.setColor(color)
	love.graphics.printf(text, x, y, wrapAt, align)
	love.graphics.setColor(1,1,1,1)
	
end

function Renderer:drawPointer()

	local x, y = love.mouse.getPosition()

	if love.mouse.isGrabbed() then

		if x > screen.width then
			love.mouse.setPosition(screen.width,love.mouse.getY())
		end
		
		if y > screen.height then
			love.mouse.setPosition(love.mouse.getX(), screen.height)
		end	
	
	end
	
	local x, y = love.mouse.getPosition()
	
	if inventoryDragSource.item and assets.images[inventoryDragSource.item.id] then
		love.graphics.draw(assets.images[inventoryDragSource.item.id], x-16, y-16)
	else
		love.graphics.draw(assets.images["pointer"], x, y)
	end
	
end

function Renderer:drawFoundLoot()

	love.graphics.draw(assets.images["popup-background-small"], 194, 100)	

	love.graphics.setFont(assets.fonts["mainmenu"]);

	self:drawText(0,110, "You find", {1,1,1,1}, "center")

	local loot = {}
	
	if self.foundloot.gold > 0 then
		table.insert(loot, "coins")
	end

	for i = 1, #self.foundloot.items do
		table.insert(loot, self.foundloot.items[i])
	end

	local offsetx = math.floor(320 - (#loot * 40)/2) + 4

	for i = 1, #loot do
		love.graphics.draw(assets.images[loot[i]], offsetx + (i-1)*40, 136)	
	end

	if self.foundloot.gold > 0 then
		self:drawDigits(self.foundloot.gold, offsetx+23, 136+22)
	end

end

function Renderer:drawPopup()

	if #self.popupText < 120 then
		self:drawSmallPopup(self.popupText)
	else
		self:drawLargePopup(self.popupText)
	end

end

function Renderer:drawSmallPopup(text)

	love.graphics.draw(assets.images["popup-background-small"], 194, 100)	

	love.graphics.setFont(assets.fonts["mainmenu"]);

	width, wrappedtext = assets.fonts["mainmenu"]:getWrap(text, 232)

	local offsety = 143

	if #wrappedtext > 1 then
		offsety = offsety - math.floor((#wrappedtext*16)/2)
	else
		offsety = offsety - 8
	end

	for i = 1, #wrappedtext do
		self:drawText(0,offsety + (i-1)*16, wrappedtext[i], {1,1,1,1}, "center")
	end

	love.graphics.setFont(assets.fonts["main"]);

end
function Renderer:drawLargePopup(text)

	love.graphics.draw(assets.images["popup-background-large"], 160, 50)	

	love.graphics.setFont(assets.fonts["mainmenu"]);

	width, wrappedtext = assets.fonts["mainmenu"]:getWrap(text, 300)

	local offsety = 150

	if #wrappedtext > 1 then
		offsety = offsety - math.floor((#wrappedtext*16)/2)
	else
		offsety = offsety - 8
	end

	for i = 1, #wrappedtext do
		self:drawText(0,offsety + (i-1)*16, wrappedtext[i], {1,1,1,1}, "center")
	end

	love.graphics.setFont(assets.fonts["main"]);

end

function Renderer:drawCredits()

	love.graphics.draw(assets.images["credits-background"], 0, 0)	

	love.graphics.setFont(assets.fonts["mainmenu"]);

	self:drawText(152,24, "Code & Art*", {1,1,1,1})
	self:drawText(414,24, "Music", {1,1,1,1})

	self:drawText(98,174, "Dan Thoresen (zooperdan)", {1,1,1,1})
	self:drawText(355,174, "Travis Sullivan (travsul)", {1,1,1,1})

	self:drawText(140,224, "zooperdan", {1,1,1,1})
	self:drawText(140,256, "zooperdan.itch.io", {1,1,1,1})
	self:drawText(140,288, "dungeoncrawlers.org", {1,1,1,1})

	self:drawText(378,224, "SullyMusic", {1,1,1,1})
	self:drawText(378,256, "travisoraziosullivan", {1,1,1,1})
	self:drawText(378,288, "travissullivan.com/composer/", {1,1,1,1})

	self:drawText(0,340, "* Refer to attribution.txt for more information", {1,1,1,.25}, "center")

	love.graphics.setFont(assets.fonts["main"]);

end

function Renderer:drawAbout()

	self:drawText(0, 40, "- ABOUT -", {1,1,1,1}, "center")

end

function Renderer:drawSettings()

	self:drawText(0, 40, "- SETTINGS -", {1,1,1,1}, "center")

end

function Renderer:drawSpellList()

	local mx, my = love.mouse.getPosition()

	local offsetx = 328
	local offsety = 284

	self.currentHoverSpell = nil

	for i = 1, #party.spells do
	
		local spell = spelltemplates:get(party.spells[i])
		local y = offsety - (i-1)*34
		self:drawImage(offsetx, y, spell.id, false) 
		if intersect(mx, my, offsetx, y, 32, 32) then
			self.currentHoverSpell = spell
			love.graphics.draw(assets.images["inventory-slot-highlight"], offsetx-1, y-1)
		end
	
	end

end

function Renderer:clickOnSpellList(x, y)

	if y > 316 then
		return
	end	

	local offsetx = 328
	local offsety = 284

	for i = 1, #party.spells do
		local yy = offsety - (i-1)*34
		if intersect(x, y, offsetx, yy, 32, 32) then
			if party:castSpell(party.spells[i]) then
				subState = SubStates.IDLE
				local spell = spelltemplates:get(party.spells[i])
				self.currentSpell = spell
				self.showSpellEffect = true
				Timer.script(function(wait)
					wait(0.1)
					renderer.showSpellEffect = false
				end)				
			end
			self.currentHoverSpell = nil
			return true
		end
	end

	self.currentHoverSpell = nil
	subState = SubStates.IDLE

	return false

end

function Renderer:drawNPC()

	local text
	local offsety
	local imageid
	local portraitid = self.currentNPC.properties.imageid

	if self.currentNPC.properties.state == 1 then
		text = self.currentNPC.properties.text
	elseif self.currentNPC.properties.state == 2 then
		text = self.currentNPC.properties.questdelivertext
	elseif self.currentNPC.properties.state == 3 then
		text = self.currentNPC.properties.questdonetext
	end
	
	local width, wrappedtext = assets.fonts["mainmenu"]:getWrap(text, 227)

	if #wrappedtext <= 3 then
		offsety = 100
		imageid = "npc-background-small"
	else
		offsety = 65
		imageid = "npc-background-large"
	end

	love.graphics.draw(assets.images[imageid], 160, offsety)	
	love.graphics.draw(assets.images[portraitid], 160+9, offsety+9)	
	love.graphics.setFont(assets.fonts["mainmenu"]);
	self:drawText(244,offsety + 8, self.currentNPC.properties.name, {1,1,1,1}, "left")

	for i = 1, #wrappedtext do
		self:drawText(244,offsety + 37 + (i-1)*14, wrappedtext[i], {1,1,1,1}, "left")
	end

	love.graphics.setFont(assets.fonts["main"]);

end

function Renderer:drawVendor() 

	local mx, my = love.mouse.getPosition()
	
	local text = self.currentVendor.text
	local name = self.currentVendor.name
	local offsetx = 244
	local offsety = 65
	local portraitid = self.currentVendor.imageid

	local width, wrappedtext = assets.fonts["mainmenu"]:getWrap(text, 227)

	self.buttons["close-vendor"]:isOver(mx, my)

	love.graphics.draw(assets.images["npc-background-large"], 160, offsety)	
	love.graphics.draw(assets.images[portraitid], 160+9, offsety+9)	
	love.graphics.setFont(assets.fonts["mainmenu"]);
	self:drawText(244,offsety + 8, name, {1,1,1,1}, "left")

	for i = 1, #wrappedtext do
		self:drawText(244,offsety + 37 + (i-1)*14, wrappedtext[i], {1,1,1,1}, "left")
	end

	-- draw items in stock
	
	self.currentHoverItem = nil
	
	for i = 1, #self.currentVendor.stock do
		local item
		if self.currentVendor.id == "alchemist" then
			item = itemtemplates:get(self.currentVendor.stock[i])
		elseif self.currentVendor.id == "magicshop" then
			item = spelltemplates:get(self.currentVendor.stock[i])
		end
		local x = offsetx + (i-1)*34
		local y = 188
		love.graphics.draw(assets.images[item.id], x, y)	
		if intersect(mx, my, x, y, 32, 32) then
			self.currentHoverItem = item
			love.graphics.draw(assets.images["inventory-slot-highlight"], x-1, y-1)
		end
		self:drawCenteredText(x+16, y+34, self.currentVendor.prices[i], {1,1,1,1})		
	end

	love.graphics.draw(self.buttons["close-vendor"]:getImage(),  self.buttons["close-vendor"].x, self.buttons["close-vendor"].y)

	love.graphics.draw(assets.images["coins"], 167, 228)
	self:drawDigits(party.gold, 190,250)
	love.graphics.setFont(assets.fonts["main"]);

end

function Renderer:clickOnVendor(x, y)

	if self.buttons["close-vendor"]:isOver(x, y) then
		self.buttons["close-vendor"].trigger()
		return
	end		

	local offsetx = 244

	for i = 1, #self.currentVendor.stock do
		local xx = offsetx + (i-1)*34
		local yy = 188
		if intersect(x, y, xx, yy, 32, 32) then
			
			if party.gold >= self.currentVendor.prices[i] then
				party.gold = party.gold - self.currentVendor.prices[i]
				
				if self.currentVendor.stock[i] == "healing-potion" then
					party.healing_potions = party.healing_potions + 1
				elseif self.currentVendor.stock[i] == "mana-potion" then
					party.mana_potions = party.mana_potions + 1
				else
					party:addSpell(self.currentVendor.stock[i])
				end
				
			end
		end
	end	

end

function Renderer:drawAntsacsVendor() 

	local text = ""
	local name = "Gurik Masiv"
	local offsety
	local imageid
	local portraitid = "npc-sorcerer-1"

	if party.antsacs == 0 then
		text = "Hey, listen! If you ever manage to kill one of those giant ants in the forest, could you please bring me their ant sac? It's vile I know, but it's a sought after ingredient among potion makers.\n\nI will give you some coins for the trouble."
	else
		local str = party.antsacs == 1 and "this ant sac!" or "these ant sacs!"
		text = "Excellent!\n\nThank you for bringing me " .. str .. "\n\nAs promised, here are some coins."
	end

	local width, wrappedtext = assets.fonts["mainmenu"]:getWrap(text, 227)

	if #wrappedtext <= 3 then
		offsety = 100
		imageid = "npc-background-small"
	else
		offsety = 65
		imageid = "npc-background-large"
	end

	love.graphics.draw(assets.images[imageid], 160, offsety)	
	love.graphics.draw(assets.images[portraitid], 160+9, offsety+9)	
	love.graphics.setFont(assets.fonts["mainmenu"]);
	self:drawText(244,offsety + 8, name, {1,1,1,1}, "left")

	for i = 1, #wrappedtext do
		self:drawText(244,offsety + 37 + (i-1)*14, wrappedtext[i], {1,1,1,1}, "left")
	end

	love.graphics.setFont(assets.fonts["main"]);

end

function Renderer:drawInventory()

	local mx, my = love.mouse.getPosition()

	love.graphics.setColor(1,1,1,1)

	love.graphics.draw(assets.images["inventory-ui"],  settings.inventoryX, settings.inventoryY)

	if not inventoryDragSource.item then
		self.buttons["close-inventory"]:isOver(mx, my)
	end
	
	love.graphics.draw(self.buttons["close-inventory"]:getImage(),  self.buttons["close-inventory"].x, self.buttons["close-inventory"].y)

	local slotsize = 33
	local hovercell = nil
	local showingItemStats = false

	self.currentHoverItem = nil

	-- trash icon

	local x = settings.inventoryX + 325
	local y = settings.inventoryY + 200
	
	if intersect(mx, my, x, y, slotsize, slotsize) then
		if inventoryDragSource.item then
			local item = itemtemplates:get(inventoryDragSource.item.id)
			if item.slot ~= "key" then
				love.graphics.draw(assets.images["inventory-slot-highlight"], x, y)
			end
		end
	end	

	-- equipment slots
	
	for i = 1, #party.equipmentslots do
	
		local x = settings.inventoryX + party.equipmentslots[i].x
		local y = settings.inventoryY + party.equipmentslots[i].y
		
		-- draw slot highlight
		
		if intersect(mx, my, x, y, slotsize, slotsize) then
			if inventoryDragSource.item then
				love.graphics.draw(assets.images["inventory-slot-highlight"], x, y)
			else
				if party.equipmentslots[i].id ~= "" then
					love.graphics.draw(assets.images["inventory-slot-highlight"], x, y)
					self.currentHoverItem = itemtemplates:get(party.equipmentslots[i].id)
				end
			end
			hovercell = {index = i}
		end
		
		-- draw slot highlight for matching slot type
		
		if inventoryDragSource.item then
		
			local item = itemtemplates:get(inventoryDragSource.item.id)
			
			if party.equipmentslots[i].type == item.slot then
				love.graphics.draw(assets.images["inventory-slot-highlight"], x, y)
			end
		
		end
		
		-- draw item icons
		
		if party.equipmentslots[i].id ~= "" then
		
			local item = itemtemplates:get(party.equipmentslots[i].id)

			if item and assets.images[item.id] then
				love.graphics.draw(assets.images[item.id], x+1, y+1)
			end
			
		end
		
	end	

	if hovercell and not inventoryDragSource.item and party.equipmentslots[hovercell.index].id ~= "" then
		showingItemStats = true
		local item = itemtemplates:get(party.equipmentslots[hovercell.index].id)
	end
	
	-- inventory slots

	hovercell = nil

	for row = 1, 5 do
		for col = 1, 8 do
		
			local x = settings.inventorySlotsStartX + (col-1) * slotsize
			local y = settings.inventorySlotsStartY + (row-1) * slotsize
			
			-- draw slot highlight
			
			if intersect(mx, my, x, y, slotsize, slotsize) then
				if inventoryDragSource.item then
					love.graphics.draw(assets.images["inventory-slot-highlight"], x, y)
				else
					if party.inventory[row][col] ~= "" then
						love.graphics.draw(assets.images["inventory-slot-highlight"], x, y)
						self.currentHoverItem = itemtemplates:get(party.inventory[row][col])
					end
				end
				hovercell = {row = row, col = col}
			end
			
			-- draw item icons
			
			if party.inventory[row][col] ~= "" then
			
				local item = itemtemplates:get(party.inventory[row][col])
	
				if item and assets.images[item.id] then
					love.graphics.draw(assets.images[item.id], x+1, y+1)
				end
				
			end
			
		end
	end
	
	if hovercell and not inventoryDragSource.item and party.inventory[hovercell.row][hovercell.col] ~= "" then
		showingItemStats = true
		local item = itemtemplates:get(party.inventory[hovercell.row][hovercell.col])
	end
	
end

function Renderer:clickOnInventory(mx, my)

	if not inventoryDragSource.item then
		if self.buttons["close-inventory"]:isOver(mx, my) then
			self.buttons["close-inventory"].trigger()
		end
	end

	local slotsize = 33

	-- inventory button in main ui
	
	if not inventoryDragSource.item and intersect(mx, my, 19, 321, 34, 34) then
		if not self:inventoryShowing() then
			self:showInventory(true)
			return
		else
			self:showInventory(false)
			return
		end
	end		

	-- trash icon

	local x = settings.inventoryX + 325
	local y = settings.inventoryY + 200
	
	if intersect(mx, my, x, y, slotsize, slotsize) then
		if inventoryDragSource.item then
			local item = itemtemplates:get(inventoryDragSource.item.id)
			if item.slot ~= "key" then
				inventoryDragSource = {}
				assets:playSound("trash")
			end
		end
	end
	
	-- equipment slots
	
	for i = 1, #party.equipmentslots do
	
		local x = settings.inventoryX + party.equipmentslots[i].x
		local y = settings.inventoryY + party.equipmentslots[i].y
		
		if intersect(mx, my, x, y, slotsize, slotsize) then
	
			if inventoryDragSource.item then
	
				if party.equipmentslots[i].type == inventoryDragSource.item.slot then
	
					if party.equipmentslots[i].id == "" then
		
						party.equipmentslots[i].id = inventoryDragSource.item.id
			
						inventoryDragSource = {}

						assets:playSound("click-2")

					else
					
						local item = itemtemplates:get(party.equipmentslots[i].id)
						
						party.equipmentslots[i].id = inventoryDragSource.item.id

						inventoryDragSource = {
							source = "equipment",
							item = item,
							src_row = row,
							src_col = col,
						}

						assets:playSound("click-2")

					end

				end
				
			else
			
				if party.equipmentslots[i].id ~= "" then

					local item = itemtemplates:get(party.equipmentslots[i].id)
					
					inventoryDragSource = {
						source = "equipment",
						item = item,
						src_row = row,
						src_col = col,
					}
					
					party.equipmentslots[i].id = ""
					assets:playSound("click-2")
				else 
					inventoryDragSource = {}
					assets:playSound("click-2")
				end				
			
			end
	
		end
		
	end

	-- inventory slots

	if intersect(mx, my, settings.inventorySlotsStartX, settings.inventorySlotsStartY, 295, 184) then

		local col = math.floor((mx - settings.inventorySlotsStartX) / slotsize)+1
		local row = math.floor((my - settings.inventorySlotsStartY) / slotsize)+1
		
		col = math.clamp(col, 1, 8)
		row = math.clamp(row, 1, 5)

		if inventoryDragSource.item then
		
			if party.inventory[row][col] == "" then

				party.inventory[row][col] = inventoryDragSource.item.id
			
				inventoryDragSource = {}
				assets:playSound("click-2")

			else

				local item = itemtemplates:get(party.inventory[row][col])
				
				party.inventory[row][col] = inventoryDragSource.item.id

				inventoryDragSource = {
					source = "inventory",
					item = item,
					src_row = row,
					src_col = col,
				}				
				assets:playSound("click-2")

			end
		
		else

			if party.inventory[row][col] ~= "" then

				local item = itemtemplates:get(party.inventory[row][col])
				
				inventoryDragSource = {
					source = "inventory",
					item = item,
					src_row = row,
					src_col = col,
				}
				
				party.inventory[row][col] = ""
				assets:playSound("click-2")
				
			else 
				inventoryDragSource = {}
			end
			
		end
	
	end
	
	party:updateStats()
	
end

function Renderer:box(x, y, w, h, color, filled)
	
	r, g, b, a = love.graphics.getColor()
	 
	local oldColor = {r, g, b, a} 

	local f = filled and filled == true and "fill" or "line"

	love.graphics.setColor(color)
	love.graphics.rectangle(f, x, y, w, h)

	love.graphics.setColor(oldColor)

end

function Renderer:drawSystemMenu()

	local mx, my = love.mouse.getPosition()

	love.graphics.setFont(assets.fonts["mainmenu"]);

	local offsety =  self.systemmenuOffsetY

	self:box(230,offsety,182,185,{0,0,0,1},true)
	self:box(230,offsety,182,185,settings.frameColor,false)

	local index = 0
	
	for i = 1, #self.systemmenuitems do
	
		local x = 247
		local y = self.systemmenuitemsOffsetY + offsety + (index*25)
	
		if intersect(mx, my, x, y, 145, 20) then
			self:drawText(0, y, self.systemmenuitems[i].caption, {1,1,1,1}, "center")
		else
			self:drawText(0, y, self.systemmenuitems[i].caption, {1.0,.85,.75,1}, "center")
		end
		index = index + 1
	
	end	

	self:drawText(0, offsety + 15, "System menu", {1,1,1,1}, "center")

	love.graphics.setFont(assets.fonts["main"]);

end

function Renderer:drawMainmenu()

	local mx, my = love.mouse.getPosition()

	love.graphics.draw(assets.images["mainmenu-background"], 0, 0)	

	love.graphics.setFont(assets.fonts["mainmenu"]);

	local index = 0
	local canContinue = Game:canContinue()
	local adjustY = canContinue and -15 or 0
	
	for i = 1, #self.menuitems do
	
		if not canContinue and i == 2 then
			-- skip this menuitem
		else

			local x = self.menuitemsOffsetX
			local y = self.menuitemsOffsetY + adjustY + (index*30)
		
			if not self.doShowSystemMenu and intersect(mx, my, x, y, 100, 20) then
				self:drawText(x, y, self.menuitems[i].caption, {1,1,1,1})
			else
				self:drawText(x, y, self.menuitems[i].caption, {1.0,.85,.75,1})
			end
			index = index + 1
		end
	
	end

	love.graphics.setFont(assets.fonts["main"]);

	love.graphics.setColor(1,1,1,1)

end

function Renderer:showPlayerStats()
	
	love.graphics.draw(assets.images["coins"], settings.inventoryX+8, settings.inventoryY+164)
	love.graphics.draw(assets.images["antsac"], settings.inventoryX+86, settings.inventoryY+164)

	self:drawDigits(party.gold, 150, 236)
	self:drawDigits(party.antsacs, 228, 236)

	self:drawText(251, 228, "HEALTH", {1,1,1,1})
	self:drawText(251, 228+14, "MANA", {1,1,1,1})

	self:drawText(251, 228+28, "ATK", {1,1,1,1})
	self:drawText(251, 228+42, "DEF", {1,1,1,1})
	
	self:drawText(298, 228, ":", {1,1,1,1})
	self:drawText(298, 228+14, ":", {1,1,1,1})
	self:drawText(298, 228+28, ":", {1,1,1,1})
	self:drawText(298, 228+42, ":", {1,1,1,1})

	local r = 248/255
	local g = 197/255
	local b = 58/255

	self:drawText(304, 228, party.stats.health, {r,g,b,1})
	self:drawText(304, 228+14, party.stats.mana, {r,g,b,1})
	self:drawText(304, 228+28, party.stats.attack, {r,g,b,1})
	self:drawText(304, 228+42, party.stats.defence, {r,g,b,1})
	
end

function Renderer:showItemHoverStats(item)
		
	if item and assets.images[item.id] then

		local mx, my = love.mouse.getPosition()

		local str = ""
		for key,value in pairs(item.modifiers) do
			local mod = item.modifiers[key]
			if key == "health" or key == "mana" then
				str = str .. key:upper() .. ": " .. value .. "%  "
			else
				str = str .. key:upper() .. ": " .. value .. "   "
			end
		end

		local boxheight = str ~= "" and 40 or 25

		local statslen = assets.fonts["main"]:getWidth(str.trim(str))+10
		local namelen = assets.fonts["main"]:getWidth(item.name.trim(item.name))+10

		local l = namelen

		if namelen < statslen then
			l = statslen
		end

		if mx + l + 15 > screen.width then
			mx = screen.width - (l + 15)
		end
		
		love.graphics.setColor(0,0,0,0.75)
		love.graphics.rectangle("fill",mx+10,my-40, l, boxheight)
		love.graphics.setColor(1,1,1,.5)
		love.graphics.rectangle("line",mx+10,my-40, l, boxheight)
		love.graphics.setColor(1,1,1,1)
		
		self:drawText(mx+15, my-35, item.name, {255/255,240/255,137/255,1})
		
		if str ~= "" then
			self:drawText(mx+15, my-20, str, {1,1,1,1})
		end
		
	end
	
end

function Renderer:showSpellHoverStats(item)
		
	if item and assets.images[item.id] then

		local mx, my = love.mouse.getPosition()

		local str = ""
		for key,value in pairs(item.modifiers) do
			local mod = item.modifiers[key]
			if key == "health" or key == "mana" then
				str = str .. key:upper() .. ": " .. value .. "%  "
			else
				str = str .. key:upper() .. ": " .. value .. "   "
			end
		end

		str = str .. "MANA COST: " .. item.manacost

		local boxheight = str ~= "" and 40 or 25

		local statslen = assets.fonts["main"]:getWidth(str.trim(str))+10
		local namelen = assets.fonts["main"]:getWidth(item.name.trim(item.name))+10

		local l = namelen

		if namelen < statslen then
			l = statslen
		end

		if mx + l + 15 > screen.width then
			mx = screen.width - (l + 15)
		end
		
		love.graphics.setColor(0,0,0,0.75)
		love.graphics.rectangle("fill",mx+10,my-40, l, boxheight)
		love.graphics.setColor(1,1,1,.5)
		love.graphics.rectangle("line",mx+10,my-40, l, boxheight)
		love.graphics.setColor(1,1,1,1)
		
		self:drawText(mx+15, my-35, item.name, {255/255,240/255,137/255,1})
		
		if str ~= "" then
			self:drawText(mx+15, my-20, str, {1,1,1,1})
		end
		
	end
	
end

function Renderer:drawAutomapper()

	love.graphics.setColor(1,1,1,1)

	local cellsize = 6
	local offsetx = 222+2
	local offsety = 39+2

	love.graphics.draw(assets.images["automapper-background"], 222, 39)
	
	for y = 1, level.data.mapSize do
		for x = 1, level.data.mapSize do
		
			local dx = offsetx + ((x-1) * cellsize)
			local dy = offsety + ((y-1) * cellsize)
		
			if level.data.walls[x] and level.data.walls[x][y] then
				love.graphics.setColor(1,1,1,1)
				love.graphics.rectangle("fill", dx, dy, cellsize, cellsize)
			end

			if level.data.boundarywalls[x] and level.data.boundarywalls[x][y] then
				love.graphics.setColor(1,1,1,1)
				love.graphics.rectangle("fill", dx, dy, cellsize, cellsize)
			end
		
		end
	end

	-- doors

	for key,value in pairs(level.data.doors) do
		local door = level.data.doors[key]
		local dx = offsetx + (door.x * cellsize)
		local dy = offsety + (door.y * cellsize)
		love.graphics.setColor(1,0.5,0,1)
		love.graphics.rectangle("fill", dx, dy, cellsize, cellsize)
	end
	
	-- wells

	for key,value in pairs(level.data.wells) do
		local well = level.data.wells[key]
		local dx = offsetx + (well.x * cellsize)
		local dy = offsety + (well.y * cellsize)
		love.graphics.setColor(0,0.5,1,1)
		love.graphics.rectangle("fill", dx, dy, cellsize, cellsize)
	end
	
	-- enemies

	for key,value in pairs(level.data.enemies) do
		local enemy = level.data.enemies[key]
		if enemy.properties.state == 1 then
			local dx = offsetx + (enemy.x * cellsize)
			local dy = offsety + (enemy.y * cellsize)
			love.graphics.setColor(1,0,0,1)
			love.graphics.rectangle("fill", dx, dy, cellsize, cellsize)
		end
	end
		
	-- player
	
	local dx = offsetx + (party.x * cellsize)
	local dy = offsety + (party.y * cellsize)
	love.graphics.setColor(0,1,0,1)
	love.graphics.rectangle("fill", dx, dy, cellsize, cellsize)
	

	love.graphics.setColor(1,1,1,1)
	
end

function Renderer:drawUI()

	love.graphics.setColor(1,1,1,1)

	-- main ui

	love.graphics.draw(assets.images["main-ui"], 0,0)
	
	-- compass
	
	love.graphics.draw(assets.images["compass"], assets.compass_quads[party.direction], 318, 7)

	
	-- left hand

	local leftHand = party:getLeftHand()
	
	if leftHand then
		love.graphics.draw(assets.images[leftHand.id], 282,321)
	else
		love.graphics.draw(assets.images["lefthand-background"], 282,321)
	end
	
	if party:hasCooldown(1) then
		love.graphics.draw(assets.images["cooldown-overlay"], 283,322)
	end
	
	-- right hand
	
	local rightHand = party:getrightHand()

	if rightHand then
		love.graphics.draw(assets.images[rightHand.id], 329,321)
	else
		love.graphics.draw(assets.images["spellbook-background"], 329,321)
	end

	if party:hasCooldown(2) then
		love.graphics.draw(assets.images["cooldown-overlay"], 330,322)
	end

	-- healing potions

	if party.healing_potions > 0 then
		love.graphics.draw(assets.images["healing-potion"], 239,325)
		local x,y = 262, 347
		if party.healing_potions < 10 then
			love.graphics.draw(assets.images["digits"], assets.digit_quads[party.healing_potions], x, y)
		else
			self:drawDigits(party.healing_potions, 262, 347)
		end
		
		if party:hasCooldown(3) then
			love.graphics.draw(assets.images["cooldown-overlay"], 240,326)
		end
		
	end

	-- mana potions

	if party.mana_potions > 0 then
		love.graphics.draw(assets.images["mana-potion"], 372,325)
		local x,y = 395, 347
		if party.mana_potions < 10 then
			love.graphics.draw(assets.images["digits"], assets.digit_quads[party.mana_potions], x, y)
		else
			local str = tostring(party.mana_potions)
			local x,y = 395 - (#str*6), 347
			for i = 1, #str do
				local c = tonumber(string.sub(str,i,i))
				love.graphics.draw(assets.images["digits"], assets.digit_quads[c], x + (i*6), y)
			end
		end
		
		if party:hasCooldown(4) then
			love.graphics.draw(assets.images["cooldown-overlay"], 373,326)
		end
		
	end

	-- health and mana bars
	
	self:drawBar(164-2, 348-2, party.stats.health, party.stats.health_max, 62, 1)
	self:drawBar(413-2, 348-2, party.stats.mana, party.stats.mana_max, 62, 2)
	

end

function Renderer:drawEnemyStats(enemy)

	self:drawText(0, 10+50, enemy.properties.name, {1,1,1,1}, "center")
	
	local x = math.floor(screen.width/2 - assets.images["enemy-hit-bar-background"]:getWidth()/2)
	local y = 30+50
	
	love.graphics.draw(assets.images["enemy-hit-bar-background"], x, y)

	if enemy.properties.health > 0 then
		self:drawBar(x, y, enemy.properties.health, enemy.properties.health_max, 143, 1)
	end

end

function Renderer:drawDigits(value, x, y)

	local str = tostring(value)
	local x,y = x - (#str*6), y
	for i = 1, #str do
		local c = tonumber(string.sub(str,i,i))
		love.graphics.draw(assets.images["digits"], assets.digit_quads[c], x + (i*6), y)
	end

end

function Renderer:drawBar(x, y, maxval, minval, maxbarsize, bartype)

	local f = maxval/minval
	local barsize = maxbarsize * f
	local quad = nil

	local offs = 3

	local img = assets.images["bar-type-1"]

	if bartype == 2 then
		img = assets.images["bar-type-2"]
	end

	-- bar body
	quad = love.graphics.newQuad(1, 0, 1, 5, img:getWidth(), img:getHeight())
	love.graphics.draw(img, quad, x + offs, y + offs, 0, barsize, 1)

	-- left edge
	
	quad = love.graphics.newQuad(0, 0, 1, 5, img:getWidth(), img:getHeight())
	love.graphics.draw(img, quad, x + offs, y + offs)

	-- right edge
	
	quad = love.graphics.newQuad(2, 2, 1, 5, img:getWidth(), img:getHeight())
	love.graphics.draw(img, quad, (x + offs) + (barsize-1), y + offs)
	
end

function Renderer:drawObject(atlasId, layerId, x, z)

	local bothsides = atlases.jsondata[atlasId].layer[layerId] and atlases.jsondata[atlasId].layer[layerId].mode == 2
	
	local xx = bothsides and x - (x * 2) or 0
	local tile = self:getTile(atlasId, layerId, "object", xx, z);

	if tile then

		local quad = love.graphics.newQuad(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h, atlases.images[atlasId]:getWidth(), atlases.images[atlasId]:getHeight())

		if bothsides then
			love.graphics.draw(atlases.images[atlasId], quad, tile.screen.x, tile.screen.y)
		else
			local tx = tile.screen.x + (x * tile.coords.w)
			love.graphics.draw(atlases.images[atlasId], quad, tx, tile.screen.y)
		end

	end
	
end

function Renderer:drawDecal(atlasId, layerId, x, z)

	local bothsides = atlases.jsondata[atlasId].layer[layerId] and atlases.jsondata[atlasId].layer[layerId].mode == 2
	
	local xx = bothsides and x - (x * 2) or 0
	
	-- front
	
	if x > 0 then
	
		local tile = self:getTile(atlasId, layerId, "decal-front", x, z);
		
		if tile then
			local quad = love.graphics.newQuad(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h, atlases.images[atlasId]:getWidth(), atlases.images[atlasId]:getHeight())
			love.graphics.draw(atlases.images[atlasId], quad, screen.width - tile.screen.x, tile.screen.y, math.pi, 1, -1)
		end

	end
	
	if x <= 0 then
	
		local tile = self:getTile(atlasId, layerId, "decal-front", x - (x * 2), z);
		
		if tile then
			local quad = love.graphics.newQuad(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h, atlases.images[atlasId]:getWidth(), atlases.images[atlasId]:getHeight())
			love.graphics.draw(atlases.images[atlasId], quad, tile.screen.x , tile.screen.y)
		end

	end
	
	-- side
	
	if x >= 0 then
	
		local tile = self:getTile(atlasId, layerId, "decal-side", x, z);
		
		if tile then
			local quad = love.graphics.newQuad(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h, atlases.images[atlasId]:getWidth(), atlases.images[atlasId]:getHeight())
			local tx = tile.screen.x + (x * tile.coords.w)
			love.graphics.draw(atlases.images[atlasId], quad, screen.width - tile.screen.x, tile.screen.y, math.pi, 1, -1)
		end	

	end	
	
	-- side

	if x <= 0 then
	
		local tile = self:getTile(atlasId, layerId, "decal-side", x - (x * 2), z);
		
		if tile then
			local quad = love.graphics.newQuad(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h, atlases.images[atlasId]:getWidth(), atlases.images[atlasId]:getHeight())
			love.graphics.draw(atlases.images[atlasId], quad, tile.screen.x , tile.screen.y)
		end		

	end
		
end

function Renderer:drawGround()
	

	local atlasId = level.data.tileset .. "-environment"

    for z = -self.dungeonDepth, 0 do
		
		for x = -self.dungeonWidth, self.dungeonWidth do

			local p = self:getPlayerDirectionVectorOffsets(x, z);

			if p.x >= 1 and p.y >= 1 and p.x <= level.data.mapSize and p.y <= level.data.mapSize then
			
				local layerId = self.backgroundIndex == 1 and level.data.tileset.."-ground-1" or level.data.tileset.."-ground-2"
				local bothsides = atlases.jsondata[atlasId].layer[layerId] and atlases.jsondata[atlasId].layer[layerId].mode == 2
				local xx = bothsides and x - (x * 2) or 0
				local tile = self:getTile(atlasId, layerId, "ground", xx, z);
				
				if tile then

					local quad = love.graphics.newQuad(tile.coords.x, tile.coords.y, tile.coords.w, tile.coords.h, atlases.images[atlasId]:getWidth(), atlases.images[atlasId]:getHeight())

					if bothsides then
						love.graphics.draw(atlases.images[atlasId], quad, tile.screen.x, tile.screen.y)
					else
						local tx = tile.screen.x + (x * tile.coords.w)
						love.graphics.draw(atlases.images[atlasId], quad, tx, tile.screen.y)
					end

				end		
				
			end
			
		end		

	end
	
end

function Renderer:drawSky()

	if self.skyIndex == 1 then
		love.graphics.draw(assets.images["sky"], 0, 0)
	else
		love.graphics.draw(assets.images["sky"], 640, 0, 0, -1, 1)
	end
	
end

function Renderer:drawSquare(x, z)

    local p = self:getPlayerDirectionVectorOffsets(x, z);

    if p.x >= 1 and p.y >= 1 and p.x <= level.data.mapSize and p.y <= level.data.mapSize then

		if level.data.walls[p.x] and level.data.walls[p.x][p.y] then
			local wall = level.data.walls[p.x][p.y]
			if wall.type ~= 3 then
				self:drawObject(level.data.tileset .. "-environment", "walls", x, z)
			end
		end
		
		if level.data.boundarywalls[p.x] and level.data.boundarywalls[p.x][p.y] then
			local wall = level.data.boundarywalls[p.x][p.y]
			if wall.type == 3 then
				self:drawObject(level.data.tileset .. "-environment", "boundarywalls", x, z)
			end
		end
		
		for key,value in pairs(level.data.staticprops) do
			local prop = level.data.staticprops[key]
			if prop.x == p.x and prop.y == p.y then
				self:drawObject(prop.properties.atlasid, self:getObjectDirectionID(prop.properties.name, prop.properties.direction), x, z)
			end
		end
		
		for key,value in pairs(level.data.enemies) do
			local enemy = level.data.enemies[key]
			if enemy.x == p.x and enemy.y == p.y then
				if enemy.highlight and enemy.highlight == 1 then
					highlightshader:send("WhiteFactor", 0.5)
				end
				if enemy.properties.state == 1 then
					if enemy.properties.attacking == 1 then
						self:drawObject("enemies", self:getObjectDirectionID("ant-attack", enemy.properties.direction), x, z)
					else 
						self:drawObject("enemies", self:getObjectDirectionID("ant", enemy.properties.direction), x, z)
					end
				elseif enemy.properties.state == 3 then
					self:drawObject("enemies", self:getObjectDirectionID("ant-dead", enemy.properties.direction), x, z)
				end			
				highlightshader:send("WhiteFactor", 0)
			end
		end
		
		for key,value in pairs(level.data.npcs) do
			local npc = level.data.npcs[key]
			if npc.x == p.x and npc.y == p.y then
				self:drawObject("npc", npc.properties.imageid, x, z)			
			end
		end		

		for key,value in pairs(level.data.chests) do
			local chest = level.data.chests[key]
			if chest.x == p.x and chest.y == p.y then
				local imageid = chest.properties.state == 1 and "chest-closed" or "chest-open"
				self:drawObject("common-props", imageid, x, z)			
			end
		end

		for key,value in pairs(level.data.wells) do
			local well = level.data.wells[key]
			if well.x == p.x and well.y == p.y then
				self:drawObject("common-props", self:getObjectDirectionID("well", well.properties.direction), x, z)			
			end
		end
		
		for key,value in pairs(level.data.doors) do
			local door = level.data.doors[key]
			if door.x == p.x and door.y == p.y then
				if door.properties.type == 1 then
					self:drawObject(level.data.tileset .. "-environment", "door", x, z)			
				elseif door.properties.type == 2 then
					local objId = self:getObjectDirectionID("gate", door.properties.direction)
					self:drawObject(level.data.tileset .. "-environment", objId and objId or "gate", x, z)			
				end
			end
		end
		
		for key,value in pairs(level.data.portals) do
			local portal = level.data.portals[key]
			if portal.x == p.x and portal.y == p.y then
				self:drawObject(level.data.tileset .. "-props", self:getObjectDirectionID("portal", portal.properties.direction), x, z)			
			end
		end	

		for key,value in pairs(level.data.buttons) do
			local button = level.data.buttons[key]
			if button.x == p.x and button.y == p.y then
				if button.properties.state == 1 then
					self:drawDecal(level.data.tileset .. "-props", "secret-button-1", x, z)			
				else
					self:drawDecal(level.data.tileset .. "-props", "secret-button-2", x, z)			
				end
			end
		end	
		
	end

end

function Renderer:drawViewport()

	if not level.loaded then 
		return
	end	

	self:drawSky()
	self:drawGround()
	
    for z = -self.dungeonDepth, 0 do
		
		for x = -self.dungeonWidth, -1 do
			self:drawSquare(x, z)
		end		

		for x = self.dungeonWidth, 1, -1 do
			self:drawSquare(x, z)
		end		
		
		self:drawSquare(0, z)
	
	end

end

function Renderer:isDraggingItem()

	return inventoryDragSource.item ~= nil
	
end

function Renderer:showInventory(value)

	assets:playSound("window-open")

	self.currentHoverItem = nuil

	inventoryDragSource = {}

	self.doShowInventory = value

	if not value then
		subState = SubStates.IDLE
	else
		subState = SubStates.INVENTORY
	end
	
end

function Renderer:showAutomapper(value)

	assets:playSound("window-open")

	self.doShowAutomapper = value

	if not value then
		subState = SubStates.IDLE
	else
		subState = SubStates.AUTOMAPPER
	end
					
end

function Renderer:showSystemMenu(value)

	assets:playSound("window-open")

	self.currentHoverItem = nuil

	self.doShowSystemMenu = value

	if not value then
		subState = SubStates.IDLE
	else
		subState = SubStates.SYSTEM_MENU
	end
	
end

function Renderer:inventoryShowing()

	return self.doShowInventory

end

function Renderer:systemMenuShowing()

	return self.doShowSystemMenu

end

function Renderer:automapperShowing()

	return self.doShowAutomapper

end

function Renderer:onCloseButtonClick()

	renderer:showInventory(false)

end

function Renderer:onStartButtonClick()
	Game:startGame()
end

function Renderer:onContinueButtonClick()

end

function Renderer:onSettingsButtonClick()

--	gameState = GameStates.SETTINGS
	self:showSystemMenu(true)

end

function Renderer:onCreditsButtonClick()

	gameState = GameStates.CREDITS

end

function Renderer:onAboutButtonClick()

	gameState = GameStates.ABOUT

end

function Renderer:onQuitButtonClick()

	love.event.quit()

end

function Renderer:onBackToMenuButtonClick()

	self:showSystemMenu(false)

	assets:stopMusic(level.data.tileset)
	assets.music["mainmenu"]:setVolume(settings.musicVolume)
	assets:playMusic("mainmenu")
	
	gameState = GameStates.MAIN_MENU
	subState = SubStates.IDLE

end

function Renderer:onCloseVendorButtonClick()

	subState = SubStates.IDLE

end

function Renderer:showPopup(text, sound)
	
	if sound or sound == nil then
		assets:playSound("popup")
	end

	self.popupText = text
	subState = SubStates.POPUP
	
end

function Renderer:showSpellList()

	subState = SubStates.SELECT_SPELL

end

function Renderer:showNPC(npc)

	assets:playSound(npc.properties.sound)
	self.currentNPC = npc
	subState = SubStates.NPC

end

function Renderer:showVendor(id)

	if id == "antsacs" then
		if party.antsacs > 0 then
			assets:playSound("gold-coins")
		else
			assets:playSound("vendor-"..id)
		end
		subState = SubStates.VENDOR_ANTSACS
	else
		self.currentVendor = vendors.vendor[id]
		subState = SubStates.VENDOR
	end

end

function Renderer:showFoundLoot(gold, items)

	self.foundloot = {gold = gold, items = items}
	
	subState = SubStates.FOUND_LOOT

end

return Renderer
