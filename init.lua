-- Helpers and libs
local C = minetest.colorize
local F = minetest.formspec_escape
local PATH = minetest.get_modpath("skinmaker")
local HISTORY = 100

-- PNG Libs
local png = {}
png = dofile(PATH .. "/png_decode.lua")
png.encode = dofile(PATH .. "/png_encode.lua")

-- Image map
local images = {}
minetest.register_on_mods_loaded(function()
	local mods = minetest.get_modnames()
	local function process_dir(path)
		local files = minetest.get_dir_list(path, false)
		for _, file in pairs(files) do
			images[file] = path .. "/" .. file
		end
		local dirs = minetest.get_dir_list(path, true)
		for _, dir in pairs(dirs) do
			process_dir(path .. "/" .. dir)
		end
	end
	for _, mod in pairs(mods) do
		local path = minetest.get_modpath(mod)
		process_dir(path)
	end
end)

-- Alpha space in skins
local empty = {}
local ranges = {
	{{1, 1}, {8, 8}},
	{{25, 1}, {40, 8}},
	{{57, 1}, {64, 8}},
	{{1, 17}, {4, 20}},
	{{13, 17}, {20, 20}},
	{{37, 17}, {44, 20}},
	{{53, 17}, {64, 20}},
	{{57, 21}, {64, 32}},
}

for _, range in pairs(ranges) do
	for x = range[1][1], range[2][1] do
		for y = range[1][2], range[2][2] do
			empty[x .. "," .. y] = 1
		end
	end
end

local function isEmpty(x, y)
	return empty[x..","..y] ~= nil
end

-- Create texture from data
local function generateSkin(data)
	local width = #data[1]
	local str = "[combine:" .. width .. "x" .. #data

	for y, row in ipairs(data) do
		for x, color in ipairs(row) do
			if not isEmpty(x, y) and color:match("^%x%x%x%x%x%x$") then
				str = str .. (":%s,%s=%s"):format(x - 1, y - 1, "(px.png\\^[colorize\\:#" .. color:gsub("#", "") .. ")")
			end
		end
	end

	return str
end

-- Blank base
local base_image = {}
for y = 1, 32 do
	base_image[y] = {}
	for x = 1, 64 do
			base_image[y][x] = "000000"
	end
end

-- Reverse core.rgba (Hex -> RGBA)
function core.hex(hex)
	hex = hex:gsub("#","")
	local r = tonumber("0x"..hex:sub(1,2))
	local g = tonumber("0x"..hex:sub(3,4))
	local b = tonumber("0x"..hex:sub(5,6))
	local a
	if hex:len() > 6 then
		a = tonumber("0x"..hex:sub(7,8))
	end
	return r, g, b, a
end

-- Get child entity (This could use some work)
local function get_ent(pos, offset, name)
	for _, obj in pairs(minetest.get_objects_inside_radius(vector.add(pos, offset), 1)) do
		if not obj:is_player() and obj:get_luaentity().name == name then
			return obj
		end
	end
end

-- Preview anim map
local preview_anims = {
	"None",
	"Idle",
	"Lay",
	"Walk",
	"Mine",
	"Walk-Mine",
	"Sit",
}

local anim_map = {
	["None"] = {x = 0, y = 0},
	["Idle"] = {x = 0, y = 79},
	["Lay"] = {x = 162, y = 166},
	["Walk"] = {x = 168, y = 187},
	["Mine"] = {x = 189, y = 198},
	["Walk-Mine"] = {x = 200, y = 219},
	["Sit"] = {x = 81, y = 160},
}

-- Maker node form
local function maker_form(pos)
	local meta = minetest.get_meta(pos)

	if not meta:get("preview") then
		meta:set_string("preview", "false")
		meta:set_int("rotation", 0)
		meta:set_string("animation", "None")
	end

	local skin = generateSkin(minetest.deserialize(meta:get_string("data")))
	local function button(image)
		return "skinmaker_maker_button.png^"..image
	end

	local selected = 1
	local animlist = ""
	for idx, anim in ipairs(preview_anims) do
		animlist = animlist .. "," .. anim
		if meta:get_string("animation") == anim then
			selected = idx
		end
	end

	local filepath = minetest.get_worldpath().."/skinmaker/skin_"..meta:get_string("player")..".png"

	local form = "size[12,8]"..
		"no_prepend[]"..
		"background[0,-2;12,12;skinmaker_maker_form.png]"..
		"bgcolor[#ffffff00]"..
		"image[2.15,1.7;5.15,2.575;skinmaker_bg.png^".. F(skin) .."]"..

		-- Buttons
		"image_button[2.15,4.31;0.96,0.96;"..button("skinmaker_maker_save.png")..";save;;;false;"..F("(".. button("skinmaker_maker_save.png") ..")^[multiply:grey").."]"..
		"image_button[3.28,4.31;0.96,0.96;"..button("skinmaker_maker_open.png")..";open;;;false;"..F("(".. button("skinmaker_maker_open.png") ..")^[multiply:grey").."]"..
		"image_button[4.41,4.31;0.96,0.96;"..button("skinmaker_maker_apply.png")..";apply;;;false;"..F("(".. button("skinmaker_maker_apply.png") ..")^[multiply:grey").."]"..
		"image_button[5.53,4.31;0.96,0.96;"..button("skinmaker_maker_clear.png")..";clear;;;false;"..F("(".. button("skinmaker_maker_clear.png") ..")^[multiply:grey").."]"..
		"image_button[2.15,5.31;0.96,0.96;"..button("skinmaker_maker_tools.png")..";tools;;;false;"..F("(".. button("skinmaker_maker_tools.png") ..")^[multiply:grey").."]"..
		"image_button[3.28,5.31;0.96,0.96;"..button("skinmaker_maker_button.png")..";;;;false;"..F("(".. button("skinmaker_maker_button.png") ..")^[multiply:grey").."]"..
		"image_button[4.41,5.31;0.96,0.96;"..button("skinmaker_maker_button.png")..";;;;false;"..F("(".. button("skinmaker_maker_button.png") ..")^[multiply:grey").."]"..
		"image_button[5.53,5.31;0.96,0.96;"..button("skinmaker_maker_button.png")..";;;;false;"..F("(".. button("skinmaker_maker_button.png") ..")^[multiply:grey").."]"..
		"tooltip[save;Save Skin to File\n(Overwrites existing file!);#532614;white]"..
		"tooltip[open;Load Current Skin;#532614;white]"..
		"tooltip[apply;Apply Skin to Player;#532614;white]"..
		"tooltip[clear;Clear Skin Canvas\n"..C("red", "This cannot be undone!")..";#532614;white]"..
		"tooltip[tools;Get Tools;#532614;white]"..

		"label[2.15,6.1;Filepath: "..filepath.."]"..
		"tooltip[2.15,6.2;".. (filepath:len() + 10) * 0.09 ..",0.2;This cannot be changed.;#532614;white]"..

		-- Preview Settings
		"label[7.8,2.2;Preview]"..
		"checkbox[7.3,2.5;preview;Enabled;"..meta:get_string("preview").."]"..

		"label[7.3,3.2;Rotation:]"..
		"button[7.3,3.8;0.5,0.4;rotate_dec;<]"..
		"label[7.7,3.7;"..meta:get_int("rotation").."]"..
		"button[8,3.8;0.5,0.4;rotate_inc;>]"..

		"label[7.3,4.4;Animation:]"..
		"dropdown[7.3,4.8;2;animation;"..animlist:sub(2)..";"..selected.."]"

	return form
end

-- Wrapper to set canvas texture and save to node meta
local function setCanvas(entity, data)
	local texture = generateSkin(data)
	entity.object:set_properties({textures = {"skinmaker_bg.png", "skinmaker_bg.png^"..texture}})
	entity.object:set_armor_groups({immortal = 1})

	-- Save data and update
	entity.data = data
	local pos = minetest.string_to_pos(entity.parent)
	local meta = minetest.get_meta(pos)
	meta:set_string("data", minetest.serialize(data))
	meta:set_string("formspec", maker_form(pos))
	if meta:get_string("preview") == "true" then
		local preview = get_ent(pos, {x = 0, y = 0, z = -1}, "skinmaker:preview")
		if preview then
			preview:set_properties({textures = {texture}})
		end
	end
end

-- Set individual pixel
local function setPixel(data, x, y, color)
	if not color or color == "" then
		color = "ffffff"
	end
	if data[y] and data[y][x] and not isEmpty(x, y) then
		data[y][x] = color:gsub("#", "")
	end
	return data
end

-- Get pointed pixel (This needs some adjustment)
local function pointedPixel(player, canvas)
	local pos = canvas.object:get_pos()
	local ppos = player:get_pos()
	local eye = table.copy(ppos)
	eye.y = eye.y + player:get_properties().eye_height
	local ray = Raycast(eye, vector.add(eye, vector.multiply(player:get_look_dir(), vector.distance(ppos, pos))))
	for pointed_thing in ray do
		if pointed_thing.type == "object" and pointed_thing.ref == canvas.object then
			local int = pointed_thing.intersection_point
			int.x = int.x - 1
			int.y = int.y + 0.5
			local offset = vector.subtract(pos, int)
			local scale = canvas.visual_size.y
			local coord = vector.apply(offset, function(v) return math.floor((math.abs(v) + 0.025 * scale) * 32 * scale) end)
			local pixel = {x = 65 - coord.x, y = 33 - coord.y}
			return pixel
		end
	end
end

-- Bresenham Line Plotter (Source: http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Lua)
local function bresenham(x1, y1, x2, y2, plot)
	local delta_x = x2 - x1
	local ix = delta_x > 0 and 1 or -1
	delta_x = 2 * math.abs(delta_x)

	local delta_y = y2 - y1
	local iy = delta_y > 0 and 1 or -1
	delta_y = 2 * math.abs(delta_y)

	plot(x1, y1)

	if delta_x >= delta_y then
		local error = delta_y - delta_x / 2
		while x1 ~= x2 do
			if (error > 0) or ((error == 0) and (ix > 0)) then
				error = error - delta_x
				y1 = y1 + iy
			end

			error = error + delta_y
			x1 = x1 + ix

			plot(x1, y1)
		end
	else
		local error = delta_x - delta_y / 2
		while y1 ~= y2 do
			if (error > 0) or ((error == 0) and (iy > 0)) then
				error = error - delta_y
				x1 = x1 + ix
			end

			error = error + delta_x
			y1 = y1 + iy

			plot(x1, y1)
		end
	end
end

-- History handler
local function addHistory(entity, pixels)
	entity.history[entity.current] = pixels
	entity.current = entity.current + 1
	if entity.history[entity.current] then
		for i = entity.current, #entity.history do
			entity.history[i] = nil
		end
	end
	-- Cap history steps
	if #entity.history > HISTORY then
		entity.current = entity.current - 1
		table.remove(entity.history, 1)
	end
end

-- Mini player preview
minetest.register_entity("skinmaker:preview", {
	visual = "mesh",
	mesh = "character.b3d",
	visual_size = {x = 0.5, y = 0.5},
	selectionbox = {-0.15, 0, -0.15, 0.15, 0.85, 0.15},
	on_activate = function(self, staticdata)
		local props = minetest.deserialize(staticdata)
		self.object:set_properties(props)
		self.object:set_armor_groups({immortal = 1})
		self.object:set_yaw(math.rad(180))

		-- Remove if no maker
		local node = minetest.get_node(props.parent)
		if node.name ~= "skinmaker:maker" then
			self.object:remove()
			return
		end
		self.parent = minetest.pos_to_string(props.parent)
	end,
	get_staticdata = function(self)
		local props = self.object:get_properties()
		props.parent = minetest.string_to_pos(self.parent)
		return minetest.serialize(props)
	end
})

-- Canvas entity
minetest.register_entity("skinmaker:canvas", {
	visual = "upright_sprite",
	visual_size = {x = 2, y = 1},
	selectionbox = {-1, -0.5, -0.02, 1, 0.5, 0.02},
	data = table.copy(base_image),
	history = {},
	current = 1,
	on_activate = function(self, strpos)
		local pos = minetest.string_to_pos(strpos)
		local node = minetest.get_node(pos)
		if node.name ~= "skinmaker:maker" then
			self.object:remove()
			return
		end
		self.parent = strpos
		self.player = minetest.get_meta(pos):get_string("player")
		setCanvas(self, minetest.deserialize(minetest.get_meta(pos):get_string("data")))
	end,
	on_rightclick = function(self, clicker)
		local stack = clicker:get_wielded_item()
		local item = stack:get_name()
		-- Eyedropper
		if minetest.get_item_group(item, "color") ~= 0 then
			local pixel = pointedPixel(clicker, self)
			if not pixel or pixel.x < 1 or pixel.x > 64 or pixel.y < 1 or pixel.y > 32 then
				return
			end

			local color = self.data[pixel.y][pixel.x]
			if not isEmpty(pixel.x, pixel.y) and color ~= "transparent" then
				stack:get_meta():set_string("color", "#"..color:gsub("#", ""))
				clicker:set_wielded_item(stack)
				return
			elseif minetest.get_item_group(item, "color") == 2 then
				stack:get_meta():set_string("color", color)
				clicker:set_wielded_item(stack)
				return
			end
		end
	end,
	on_punch = function(self, puncher)
		if puncher:get_player_name() ~= self.player then
			return
		end
		local stack = puncher:get_wielded_item()
		local name = stack:get_name()
		if minetest.get_item_group(name, "brush") ~= 0 then
			local color = stack:get_meta():get_string("color")
			local pixel = pointedPixel(puncher, self)
			if not pixel or pixel.x < 1 or pixel.x > 64 or pixel.y < 1 or pixel.y > 32 then
				return
			end

			if not isEmpty(pixel.x, pixel.y) then
				addHistory(self, {{x = pixel.x, y = pixel.y, old = self.data[pixel.y][pixel.x], new = color}})

				setCanvas(self, setPixel(self.data, pixel.x, pixel.y, color))
			end
		elseif minetest.registered_items[name].canvas then
			minetest.registered_items[name].canvas(self, puncher, stack)
		end
	end,
	get_staticdata = function(self)
		return self.parent
	end,
})

-- Maker node
minetest.register_node("skinmaker:maker", {
	description = "Skin Maker",
	tiles = {"skinmaker_maker_top.png", "skinmaker_maker_top.png", "skinmaker_maker_side.png"},
	groups = {cracky = 3, oddly_breakable_by_hand = 1},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("data", minetest.serialize(base_image))
		meta:set_string("formspec", maker_form(pos))
	end,
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("player", placer:get_player_name())
		meta:set_string("infotext", ("Skin Maker working on skin for %s"):format(placer:get_player_name()))
		minetest.add_entity(vector.add(pos, {x = 0, y = 1, z = 0}), "skinmaker:canvas", minetest.pos_to_string(pos))
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		local meta = minetest.get_meta(pos)
		local inv = sender:get_inventory()
		if name ~= meta:get_string("player") then
			return
		end
		if not fields.quit then
			-- Buttons
			if fields.save then
				local image = png.encode(64, 32, true)
				local data = minetest.deserialize(meta:get_string("data"))
				local pixels = {}
				for y = 1, 32 do
					for x = 1, 64 do
						local a = 255
						local hex = data[y][x]
						if hex == "transparent" or isEmpty(x, y) then
							hex = "#ffffff"
							a = 0
						end
						local r, g, b = minetest.hex(hex)
						pixels[#pixels + 1] = r
						pixels[#pixels + 1] = g
						pixels[#pixels + 1] = b
						pixels[#pixels + 1] = a
					end
				end
				image:write(pixels)
				local filepath = minetest.get_worldpath() .. "/skinmaker"
				minetest.mkdir(filepath)
				minetest.safe_file_write(filepath .. "/skin_"..name..".png", table.concat(image.output))
			end
			if fields.open then
				local skin = sender:get_properties().textures[1]
				if not images[skin] then
					return
				end
				local image = png.load_from_file(images[skin])
				local data = {}
				for pixel, x, y in png.pixels(image) do
					x = x + 1
					y = y + 1
					data[y] = data[y] or {}
					data[y][x] = minetest.rgba(pixel.r, pixel.g, pixel.b):gsub("#", "")
					if pixel.a == 0 then
						data[y][x] = "transparent"
					end
				end
				meta:set_string("data", minetest.serialize(data))
				local canvas = get_ent(pos, {x = 0, y = 0, z = 0}, "skinmaker:canvas")
				if canvas then
					canvas = canvas:get_luaentity()
					setCanvas(canvas, data)
				end
			end
			if fields.apply then
				sender:set_properties({textures = {
					generateSkin(minetest.deserialize(meta:get_string("data")))
				}})
			end
			if fields.clear then
				meta:set_string("data", minetest.serialize(base_image))
				local canvas = get_ent(pos, {x = 0, y = 0, z = 0}, "skinmaker:canvas")
				if canvas then
					canvas = canvas:get_luaentity()
					setCanvas(canvas, table.copy(base_image))
					canvas.history = {}
					canvas.current = 1
				end
			end
			if fields.tools then
				local items = {
					ItemStack("skinmaker:eraser"),
					ItemStack("skinmaker:undo"),
					ItemStack("skinmaker:brush"),
					ItemStack("skinmaker:redo"),
					ItemStack("skinmaker:bucket"),
					ItemStack("skinmaker:line"),
					ItemStack("skinmaker:rectangle"),
				}

				items[1]:get_meta():set_string("color", "transparent")
				items[3]:get_meta():set_string("color", "#ffffff")
				items[4]:get_meta():set_string("color", "#ffffff")
				items[5]:get_meta():set_string("color", "#ffffff")
				items[6]:get_meta():set_string("color", "#ffffff")

				for _, stack in ipairs(items) do
					if inv:room_for_item("main", stack) then
						inv:add_item("main", stack)
					end
				end
			end

			-- Preview
			if fields.preview then
				meta:set_string("preview", fields.preview)
			end
			if fields.rotate_dec then
				local rot = meta:get_int("rotation")
				if rot > -90 then
					meta:set_int("rotation", rot - 10)
				end
			end
			if fields.rotate_inc then
				local rot = meta:get_int("rotation")
				if rot < 90 then
					meta:set_int("rotation", rot + 10)
				end
			end
			if fields.animation then
				meta:set_string("animation", fields.animation)
			end
			meta:set_string("formspec", maker_form(pos))

			local preview = meta:get_string("preview")
			if preview == "true" then
				local ent = get_ent(pos, {x = 0, y = 0, z = -1}, "skinmaker:preview") or minetest.add_entity(vector.add(pos, {x = 0, y = -0.5, z = -1}), "skinmaker:preview", minetest.serialize({parent = pos}))
				local rot = meta:get_int("rotation")
				if rot == 0 then
					ent:set_rotation({x = 0, y = math.rad(-180), z = 0})
				end
				ent:set_properties({
					textures = {generateSkin(minetest.deserialize(meta:get_string("data")))},
					automatic_rotate = math.rad(rot)
				})
				ent:set_animation(anim_map[meta:get_string("animation")], 30)
			else
				if fields.preview then
					local obj = get_ent(pos, {x = 0, y = 0, z = -1}, "skinmaker:preview")
					if obj then
						obj:remove()
					end
				end
			end
		end
	end,
	on_destruct = function(pos)
		local preview = get_ent(pos, {x = 0, y = 0, z = -1}, "skinmaker:preview")
		if preview then
			preview:remove()
		end
		local canvas = get_ent(pos, {x = 0, y = 0, z = 0}, "skinmaker:canvas")
		if canvas then
			canvas:remove()
		end
	end,
})

-- HSV -> RGB and RGB -> HSV conversions
-- Taken from: https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
-- License info for hsl_rgb and rgb_hsl: CC-BY 3.0
-- Alpha channel removed

local function hsv_rgb(h, s, v)
	local r, g, b

	local i = math.floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);

	i = i % 6

	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end

	return r * 255, g * 255, b * 255
  end

local function rgb_hsv(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then s = 0 else s = d / max end

	if max == min then
	  h = 0 -- achromatic
	else
	  if max == r then
	  h = (g - b) / d
	  if g < b then h = h + 6 end
	  elseif max == g then h = (b - r) / d + 2
	  elseif max == b then h = (r - g) / d + 4
	  end
	  h = h / 6
	end

	return h, s, v
end

-- Builtin palettes
local palettes = {
	Rainbow = {
		"ff0000",
		"ff8000",
		"ffff00",
		"008000",
		"00ffff",
		"0000ff",
		"800080"
	},
	Pastel ={
		"ff6565",
		"ffa560",
		"dfe592",
		"6bff63",
		"65c4ff",
		"656bff",
		"ad65ff"
	},
	Tans = {
		"c68a39",
		"cf9a54",
		"d8ab70",
		"e0bc8c",
		"e8cda9",
		"f0dec5",
		"f8eee2",
	},
	Greys = {
		"000000",
		"2f2f2f",
		"5f5f5f",
		"7f7f7f",
		"a7a7a7",
		"d7d7d7",
		"ffffff",
	},
	Pinks = {
		"f90631",
		"fa294e",
		"fc4c6b",
		"fd6f88",
		"fe93a6",
		"feb7c3",
		"ffdbe1",
	},
	Reds = {
		"7c0303",
		"a00404",
		"c50404",
		"e90303",
		"fc1515",
		"fe3838",
		"fe5c5c",
	},
	Oranges = {
		"7c2403",
		"a02e04",
		"c53804",
		"e94203",
		"fc5315",
		"fe6e38",
		"fe885c",
	},
	Yellows = {
		"976504",
		"bb7d04",
		"df9504",
		"fbaa0c",
		"fdb72f",
		"fec453",
		"ffd077",
	},
	Limes = {
		"037c03",
		"04a004",
		"04c504",
		"03e903",
		"15fc15",
		"38fe38",
		"5cfe5c",
	},
	Greens = {
		"032e03",
		"065006",
		"087308",
		"099509",
		"0bb80b",
		"0cdc0c",
		"19f319",
	},
	Cyans = {
		"037c7c",
		"04a0a0",
		"04c5c5",
		"03e9e9",
		"15fcfc",
		"38fefe",
		"5cfefe",
	},
	Blues = {
		"0537c6",
		"0540ea",
		"1953fb",
		"3c6dfc",
		"5f88fd",
		"83a3fe",
		"a7bdff",
	},
	["Dark Blues"] = {
		"010130",
		"020254",
		"020278",
		"02029c",
		"0202c1",
		"0202e6",
		"0e0efe",
	},
	Turqoises = {
		"18887d",
		"1da89a",
		"22c8b7",
		"31ddcc",
		"4fe3d4",
		"6ee9dc",
		"8deee4",
	},
	Indigos = {
		"1c0130",
		"310254",
		"460278",
		"5b029c",
		"7002c1",
		"8502e6",
		"980efe",
	},
	Violets = {
		"390139",
		"5d025d",
		"810281",
		"a502a5",
		"ca02ca",
		"ef02ef",
		"fe17fe",
	},
	Magentas = {
		"7c037c",
		"a004a0",
		"c504c5",
		"e903e9",
		"fc15fc",
		"fe38fe",
		"fe5cfe",
	},
	Neapolitan = {
		"c5e0dc",
		"f29191",
		"f2a999",
		"f2e1ac",
		"a68c6d",
		"735851",
	},
	["Skin Tones"] = {
		"8d5524",
		"c68642",
		"e0ac69",
		"f1c27d",
		"ffdbac",
	},
	Beach = {
		"96ceb4",
		"ffeead",
		"ff6f69",
		"ffcc5c",
		"88d8b0",
	},
	Chocolates = {
		"492e12",
		"563d23",
		"675038",
		"725b42",
		"7c654d",
	},
}

-- Get palettes from inventory
local function get_all_palettes(player)
	local pcopy = table.copy(palettes)
	local inv = player:get_inventory()
	for _, stack in ipairs(inv:get_list("main")) do
		if stack:get_name() == "skinmaker:palette" then
			local meta = stack:get_meta()
			local name = meta:get_string("description")
			if name ~= "" then
				local colors = {}
				for i = 1, 7 do
					if meta:get("palette_"..i) then
						colors[i] = meta:get_string("palette_"..i):gsub("#", "")
					end
				end
				if next(colors) then
					local int = 2
					local new = false
					while pcopy[name] do
						if new then
							name = name:gsub(" %(%d+%)$", "")
						end
						name = name .. " (" .. int .. ")"
						int = int + 1
						new = true
					end
					pcopy[name] = colors
				end
			end
		end
	end
	return pcopy
end

-- Palette color sliders
local function palette_base(color)
	-- Sliders modified from modified version of my colortag mod
	-- Gradient images credit: Jordach
	local r, g, b = minetest.hex(color)
	local h, s, v = rgb_hsv(r, g, b)
	local curr_rgb = minetest.rgba(r, g, b)

	local min_sat = minetest.rgba(hsv_rgb(h, 0, v))
	local max_sat = minetest.rgba(hsv_rgb(h, 1, v))

	local min_val = minetest.rgba(hsv_rgb(h, s, 0))
	local max_val = minetest.rgba(hsv_rgb(h, s, 1))

	return (
		-- Init formspec
		"size[20,8]"..
		"position[0.5,0.55]"..
		"no_prepend[]"..
		"bgcolor[#00000000]"..
		"background[2,-4;16,16;skinmaker_palette_form.png]"..
		"listcolors[#00000000;#00000000]"..

		-- HSV sliders
		"image[14.2,1.74;0.15,5.16;skinmaker_palette_hsv.png^[transformR270]"..
		"scrollbar[14.31,1.44;0.3,5;vertical;h;"..tostring(h * 1000).."]"..
		"label[14.1,1;"..C("black", "Hue").."]"..
		"label[14.2,6.5;"..C("black", string.format("%.2f", tostring(h))).."]"..

		"image[15.1,1.74;0.15,5.16;"..
			"((skinmaker_palette_gradient.png^[multiply:"..min_sat..")^"..
			"(skinmaker_palette_gradient_flip.png^[multiply:"..max_sat.."))^[transformR270]"..
		"scrollbar[15.21,1.44;0.3,5;vertical;s;"..tostring(s * 1000).."]"..
		"label[14.7,1;"..C("black", "Saturation").."]"..
		"label[15.1,6.5;"..C("black", string.format("%.2f", tostring(s))).."]"..

		"image[16,1.74;0.15,5.16;"..
			"((skinmaker_palette_gradient.png^[multiply:"..min_val..")^"..
			"(skinmaker_palette_gradient_flip.png^[multiply:"..max_val.."))^[transformR270]"..
		"scrollbar[16.11,1.44;0.3,5;vertical;v;"..tostring(v * 1000).."]"..
		"label[16,1;"..C("black", "Value").."]"..
		"label[15.8,6.5;"..C("black", string.format("%.2f", tostring(v))).."]"
	)
end

-- Color swatches
local function get_swatches(palette, tooltip, tooltip_empty)
	local swatches = {
		"image_button[7.9,4.9;1.2,1.2;%s;swatch_1;;;false]",
		"image_button[7.4,3.4;1.2,1.2;%s;swatch_2;;;false]",
		"image_button[7.9,1.9;1.2,1.2;%s;swatch_3;;;false]",
		"image_button[9.9,1.4;1.2,1.2;%s;swatch_4;;;false]",
		"image_button[11.4,2.4;1.2,1.2;%s;swatch_5;;;false]",
		"image_button[11.4,3.9;1.2,1.2;%s;swatch_6;;;false]",
		"image_button[10.9,5.4;1.2,1.2;%s;swatch_7;;;false]"
	}
	local str = ""
	tooltip = tooltip or "Click to Set"
	tooltip_empty = tooltip_empty or tooltip
	for i = 1, 7 do
		if palette[i] then
			str = str .. swatches[i]:format(F("skinmaker_palette_swatch.png^[colorize:#"..palette[i]:gsub("#", "")..":200"))
			str = str .. "tooltip[swatch_"..i..";"..tooltip..";#efefef;black]"
		else
			str = str .. swatches[i]:format("skinmaker_palette_empty.png")
			str = str .. "tooltip[swatch_"..i..";"..tooltip_empty..";#efefef;black]"
		end
	end
	return str
end

-- Item coloring form
local function color_form(stack, player)
	local name = player:get_player_name()
	local meta = stack:get_meta()
	local all_palettes = get_all_palettes(player)

	local palette = "Rainbow"
	if meta:get("palette") and all_palettes[meta:get_string("palette")] then
		palette = meta:get_string("palette")
	end

	local pcopy = {}
	for name in pairs(all_palettes) do
		pcopy[#pcopy + 1] = name
	end
	table.sort(pcopy, function(a, b) return a < b end)

	local selected = 1
	for idx, p in ipairs(pcopy) do
		if p == palette then
			selected = idx
			break
		end
	end

	palette = all_palettes[palette]

	local color = meta:get_string("color")
	if color == "" or color == "transparent" then
		color = "#ffffff"
	end

	local form = palette_base(color)
	form = form .. "list[current_player;main;9.5,4;1,1;".. player:get_wield_index() - 1 .."]"..

	get_swatches(palette, "Click to Set Brush Color", "Empty")..

	-- Palette Selector
	"dropdown[2.9,1.7;2.7;palette;"..table.concat(pcopy, ",")..";"..selected.."]"..
	"label[2.9,1.3;"..C("black", "Palette:").."]"

	minetest.show_formspec(name, "skinmaker:color", form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "skinmaker:color" and not fields.quit then
		local stack = player:get_wielded_item()
		local meta = stack:get_meta()
		if fields.palette or fields.h or fields.s or fields.v then
			local function sval(value)
				return tonumber(tostring(value):gsub("%D", ""), _) / 1000
			end
			local h, s, v =
				sval(fields.h),
				sval(fields.s),
				sval(fields.v)

			r, g, b = hsv_rgb(h, s, v)
			meta:set_string("color", minetest.rgba(r, g, b))
			meta:set_string("palette", fields.palette)
			player:set_wielded_item(stack)
		end
		for i = 1, 7 do
			if fields["swatch_"..i] then
				meta:set_string("color", "#"..get_all_palettes(player)[fields.palette][i])
				player:set_wielded_item(stack)
				break
			end
		end
		color_form(stack, player)
	end
end)

-- Palette customization
local function palette_form(stack, player, color)
	local name = player:get_player_name()
	local meta = stack:get_meta()
	local description = minetest.registered_items[stack:get_name()].description
	if meta:get("description") then
		description = meta:get_string("description")
	end

	if not color or type(color) ~= "string" then
		color = "ffffff"
	end

	local palette = {}
	for i = 1, 7 do
		if meta:get("palette_"..i) then
			palette[i] = meta:get_string("palette_"..i)
		end
	end

	local form = palette_base(color)
	form = form .. get_swatches(palette, "Click to Set", "Click to Set") ..
		"field[3.1,1.8;2.8,1;name;"..C("black", "Palette Name")..";"..description.."]"..
		"field_close_on_enter[name;false]"..

		-- Preview
		"image[9.5,4;1,1;".. F("skinmaker_palette_swatch.png^[colorize:#"..color:gsub("#", "")..":200") .."]"

	minetest.show_formspec(name, "skinmaker:palette", form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "skinmaker:palette" and not fields.quit then
		local color
		local stack = player:get_wielded_item()
		local meta = stack:get_meta()

		if fields.h or fields.s or fields.v then
			local function sval(value)
				return tonumber(tostring(value):gsub("%D", ""), _) / 1000
			end
			local h, s, v =
				sval(fields.h),
				sval(fields.s),
				sval(fields.v)

			r, g, b = hsv_rgb(h, s, v)
			color = minetest.rgba(r, g, b)
		end

		for i = 1, 7 do
			if fields["swatch_"..i] then
				meta:set_string("palette_"..i, color)
			end
		end

		if fields.name and fields.name ~= meta:get_string("description") then
			meta:set_string("description", fields.name)
		end

		player:set_wielded_item(stack)
		palette_form(stack, player, color)
	end
end)

-- Register tools
minetest.register_node("skinmaker:brush", {
	description = "Paintbrush",
	drawtype = "plantlike",
	tiles = {"skinmaker_tool_brush_paint.png"},
	overlay_tiles = {{name = "skinmaker_tool_brush_handle.png", color = "white"}},
	color = "#bbaa66",
	groups = {brush = 1, color = 1},
	node_placement_prediction = "",
	on_place = color_form,
	on_secondary_use = color_form,
})

minetest.register_node("skinmaker:palette", {
	description = "Empty Palette",
	drawtype = "mesh",
	mesh = "palette.obj",
	tiles = {
		"skinmaker_palette.png",
	},
	node_placement_prediction = "",
	on_place = palette_form,
	on_secondary_use = palette_form,
})

minetest.register_craftitem("skinmaker:eraser", {
	description = "Eraser",
	inventory_image = "skinmaker_tool_eraser.png",
	groups = {brush = 1},
})

minetest.register_craftitem("skinmaker:undo", {
	description = "Undo",
	inventory_image = "skinmaker_tool_undo.png",
	canvas = function(entity, player, stack)
		if entity.current == 1 then
			return
		end
		entity.current = entity.current - 1
		local pixels = entity.history[entity.current]
		local data = entity.data
		for _, pixel in pairs(pixels) do
			data = setPixel(data, pixel.x, pixel.y, pixel.old)
		end
		setCanvas(entity, data)
	end,
})

minetest.register_craftitem("skinmaker:redo", {
	description = "Redo",
	inventory_image = "skinmaker_tool_redo.png",
	canvas = function(entity, player, stack)
		if entity.current > #entity.history then
			return
		end
		local pixels = entity.history[entity.current]
		local data = entity.data
		for _, pixel in pairs(pixels) do
			setPixel(data, pixel.x, pixel.y, pixel.new)
		end
		setCanvas(entity, data)
		entity.current = entity.current + 1
	end,
})

minetest.register_craftitem("skinmaker:line", {
	description = "Line",
	inventory_image = "skinmaker_tool_line.png",
	groups = {color = 1},
	on_place = color_form,
	on_secondary_use = color_form,
	canvas = function(entity, player, stack)
		local meta = stack:get_meta()
		local color = meta:get_string("color")
		local pixel = pointedPixel(player, entity)
		if not meta:get("p1") then
			meta:set_string("p1", pixel.x..","..pixel.y)
			player:set_wielded_item(stack)
		else
			local data = entity.data
			local p = meta:get_string("p1"):split(",")
			meta:set_string("p1", "")
			local pos = {x = p[1], y = p[2]}
			local history = {}
			bresenham(pos.x, pos.y, pixel.x, pixel.y, function(x, y)
				history[#history + 1] = {x = x, y = math.floor(y), old = entity.data[math.floor(y)][x], new = color}
				data = setPixel(data, x, math.floor(y), color)
			end)
			setCanvas(entity, data)
			addHistory(entity, history)
			player:set_wielded_item(stack)
		end
	end,
})

minetest.register_craftitem("skinmaker:rectangle", {
	description = "Rectangle",
	inventory_image = "skinmaker_tool_rectangle.png",
	groups = {color = 1},
	on_place = color_form,
	on_secondary_use = color_form,
	canvas = function(entity, player, stack)
		local meta = stack:get_meta()
		local color = meta:get_string("color")
		local pos2 = pointedPixel(player, entity)
		if not meta:get("p1") then
			meta:set_string("p1", pos2.x..","..pos2.y)
			player:set_wielded_item(stack)
		else
			local data = entity.data
			local p = meta:get_string("p1"):split(",")
			meta:set_string("p1", "")
			local pos1 = {x = p[1], y = p[2]}
			local minx = math.min(pos1.x, pos2.x)
			local maxx = math.max(pos1.x, pos2.x)
			local miny = math.min(pos1.y, pos2.y)
			local maxy = math.max(pos1.y, pos2.y)
			local history = {}
			for x = minx, maxx do
				for y = miny, maxy do
					history[#history + 1] = {x = x, y = y, old = entity.data[y][x], new = color}
					data = setPixel(data, x, y, color)
				end
			end
			addHistory(entity, history)
			setCanvas(entity, data)
			player:set_wielded_item(stack)
		end
	end,
})

minetest.register_node("skinmaker:bucket", {
	description = "Bucket",
	drawtype = "plantlike",
	tiles = {"skinmaker_tool_bucket_paint.png"},
	overlay_tiles = {{name = "skinmaker_tool_bucket.png", color = "white"}},
	groups = {color = 2},
	node_placement_prediction = "",
	on_place = color_form,
	on_secondary_use = color_form,
	canvas = function(entity, player, stack)
		local meta = stack:get_meta()
		local pixel = pointedPixel(player, entity)
		local color = entity.data[pixel.y][pixel.x]
		local fillcolor = meta:get_string("color")
		if color:gsub("#", "") == fillcolor:gsub("#", "") then
			return
		end
		local data = entity.data
		local offsets = {
			{x = 0, y = 1},
			{x = 1, y = 0},
			{x = 0, y = -1},
			{x = -1, y = 0}
		}
		local history = {}
		local function fill(x, y)
			if not isEmpty(x, y) then
				if data[y] and data[y][x] and data[y][x] == color then
					data = setPixel(data, x, y, fillcolor)
					for _, offset in pairs(offsets) do
						history[#history + 1] = {x = x, y = y, old = color, new = fillcolor}
						fill(x + offset.x, y + offset.y)
					end
				end
			end
		end
		fill(pixel.x, pixel.y)
		addHistory(entity, history)
		setCanvas(entity, data)
	end,
})
