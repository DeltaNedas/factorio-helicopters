playerSelectionGui =
{
	prefix = "heli_playerSelectionGui_",

	new = function(mgr, p)
		obj = 
		{
			valid = true,
			manager = mgr,
			player = p,

			guiElems = 
			{
				parent = p.gui.left,
			},
		}

		for k,v in pairs(playerSelectionGui) do
			obj[k] = v
		end

		obj:buildGui()

		return obj
	end,

	destroy = function(self)
		self.valid = false
	
		if self.guiElems.root then
			self.guiElems.root.destroy()
		end
	end,

	OnTick = function(self)
	end,

	buildGui = function(self)
		self.guiElems.root = self.guiElems.parent.add
		{
			type = "frame",
			name = self.prefix .. "rootFrame",
			caption = "Select player to fly to",
			style = "frame_style",
		}

		self.guiElems.scroller = self.guiElems.root.add
		{
			type = "scroll-pane",
			name = self.prefix .. "scroller",
		}

		self.guiElems.scroller.style.maximal_width = 1000
		self.guiElems.scroller.style.maximal_height = 600

		self.guiElems.flow = self.guiElems.scroller.add
		{
			type = "flow",
			name = self.prefix .. "flow",
			style = "achievements_flow_style",
			direction = "vertical",
		}

		for i, curPlayer in pairs(game.players) do	
			local btn = self.guiElems.flow.add
			{
				type = "button",
				name = self.prefix .. "btn_" .. curPlayer.name,
				style = "listbox_button_style",
				caption = curPlayer.name,
			}
			btn.style.minimal_width = 290
		end
		
	end,
}