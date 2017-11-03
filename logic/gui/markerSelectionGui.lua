markerSelectionGui =
{
	prefix = "heli_markerSelectionGui_",
	refreshCooldown = 20,

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

			curRefreshCooldown = markerSelectionGui.refreshCooldown,
		}

		for k,v in pairs(markerSelectionGui) do
			obj[k] = v
		end

		obj:buildGui()

		return obj
	end,

	destroy = function(self)
		self.valid = false
	
		if self.guiElems.root and self.guiElems.root.valid then
			self.guiElems.root.destroy()
		end
	end,

	OnTick = function(self)
		self.curRefreshCooldown = self.curRefreshCooldown - 1

		if self.curRefreshCooldown == 0 then
			self.curRefreshCooldown = self.refreshCooldown
			self:refreshList()
		end
	end,

	OnPlayerChangedForce = function(self, player)
		if player == self.player then
			self.guiElems.root.destroy()
			self.guiElems = {parent = self.guiElems.parent}
			self:buildGui()
		end
	end,

	OnGuiClick = function(self, e)
		local name = e.element.name

		if name:match("^" .. self.prefix .. "btn_%d+$") then
			local ID = tonumber(e.element.name:match("%d+"))

			for k, curBtn in pairs(self.guiElems.btns) do
				if curBtn.tag.tag_number == ID then
					if curBtn.tag.valid then
						self.manager:OnChildEvent(self, "selectedPosition", curBtn.tag.position)
					end
					break
				end
			end

		elseif name == self.prefix .. "rootFrame" and e.button == defines.mouse_button_type.right then
			self.manager:OnChildEvent(self, "cancel")
		end
	end,

	refreshList = function(self)
		local newTags = self.player.force.find_chart_tags(self.player.surface)

		for i = #self.guiElems.btns, 1, -1 do --iterate backwards so table.remove doesnt mess up the indices
			local curBtn = self.guiElems.btns[i]

			if not curBtn.tag.valid then
				curBtn.btn.destroy()
				table.remove(self.guiElems.btns, i)
			
			else
				for i, curTag in ipairs(newTags) do
					if curTag == curBtn.tag then
						table.remove(newTags, i)
						break
					end
				end

				if curBtn.text ~= curBtn.tag.text then
					curBtn.text = curBtn.tag.text
					curBtn.btn.caption = "                " .. curBtn.tag.text
				end

				if not curBtn.icon and curBtn.tag.icon then
					curBtn.icon, curBtn.iconType, curBtn.iconName = self:buildIconFromTag(curBtn.btn, curBtn.tag)
				
				elseif curBtn.icon and not curBtn.tag.icon then
					curBtn.icon.destroy()
					curBtn.icon, curBtn.iconType, curBtn.iconName = nil, nil, nil

				elseif curBtn.icon and (curBtn.iconType ~= curBtn.tag.icon.type or curBtn.iconName ~= curBtn.tag.icon.name) then
					curBtn.icon.destroy()
					curBtn.icon, curBtn.iconType, curBtn.iconName = self:buildIconFromTag(curBtn.btn, curBtn.tag)
				end
			end
		end

		for k, curTag in pairs(newTags) do
			table.insert(self.guiElems.btns, self:buildBtnFromTag(self.guiElems.table, curTag))
		end

		self:setNothingAvailableIfNecessary()
	end,

	setNothingAvailableIfNecessary = function(self)
		local els = self.guiElems
		local nec = #els.btns == 0

		if nec and not els.nothingAvailable then
			els.nothingAvailable = els.table.add
			{
				type = "label",
				name = self.prefix .. "nothingAvailable",
				caption = "NO MAP MARKERS AVAILABLE",
			}
			els.nothingAvailable.style.font = "default-bold"
			els.nothingAvailable.style.font_color = {r = 1, g = 0, b = 0}

		elseif not nec and els.nothingAvailable then
			els.nothingAvailable.destroy()
			els.nothingAvailable = nil
		end
	end,

	buildIconFromTag = function(self, parent, tag)
		local sprite
		if tag.icon.type == "virtual" then
			sprite = "virtual-signal" .. "/" .. tag.icon.name
		else
			sprite = tag.icon.type .. "/" .. tag.icon.name
		end

		local icon = parent.add
		{
			type = "sprite",
			name = self.prefix .. "icon",
			sprite = sprite,
		}

		return icon, tag.icon.type, tag.icon.name
	end,

	buildBtnFromTag = function(self, parent, tag)
		local btn = parent.add
		{
			type = "button",
			name = self.prefix .. "btn_" .. tostring(tag.tag_number),
			style = "listbox_button_style",
			caption = "                " .. tag.text,
		}
		btn.style.minimal_height = 38
		btn.style.minimal_width = 290

		local icon, iconType, iconName = nil, nil, nil
		if tag.icon then
			icon, iconType, iconName = self:buildIconFromTag(btn, tag)
		end

		return {
			btn = btn,
			icon = icon,

			tag = tag,
			
			text = tag.text,		
			iconType = iconType,
			iconName = iconName,
		}
	end,

	tagCompareCB = function(a, b)
		if a.text ~= "" and b.text ~= "" then
			if a.text == b.text and a.icon and not b.icon then
				return true
			end

			return a.text < b.text

		elseif a.text ~= "" then
			return true

		elseif a.icon and not b.icon then
			return true
		end

		return false
	end,

	buildGui = function(self)
		self.guiElems.root = self.guiElems.parent.add
		{
			type = "frame",
			name = self.prefix .. "rootFrame",
			caption = "Select map marker to fly to",
			style = "frame_style",
		}

		self.guiElems.scroller = self.guiElems.root.add
		{
			type = "scroll-pane",
			name = self.prefix .. "scroller",
		}

		self.guiElems.scroller.style.maximal_width = 1000
		self.guiElems.scroller.style.maximal_height = 600

		self.guiElems.table = self.guiElems.scroller.add
		{
			type = "flow",
			name = self.prefix .. "flow",
			style = "achievements_flow_style",
			direction = "vertical",
		}

		local tagList = self.player.force.find_chart_tags(self.player.surface)
		quickSort(tagList, self.tagCompareCB)

		self.guiElems.btns = {}
		for k, curTag in pairs(tagList) do
			table.insert(self.guiElems.btns, self:buildBtnFromTag(self.guiElems.table, curTag))
		end
		
		self:setNothingAvailableIfNecessary()
	end,
}