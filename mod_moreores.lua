for i,v in ipairs({"bronze","copper","gold","mithril","silver","tin"}) do
	materials_add_node("moreores:"..v.."_block", 
		string.gsub(v, "^%l", string.upper).." Block", 
		"moreores_"..v.."_block.png", 
		{cracky = 1,level= 2})
end