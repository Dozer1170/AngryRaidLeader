function SetFrameAnchor(frame, anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
	-- Set the anchor for the frame
	frame:ClearAllPoints() -- Clear any existing anchors
	frame:SetPoint(anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
end
