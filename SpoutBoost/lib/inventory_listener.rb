class BoostListener < SpoutListener
	def onInventoryOpen event
		debug "Player onInventoryOpen"
	end
	def onPlayerInventoryOpen event
		debug "Player open inventory."
		if event.getPlayer.getGameMode == GameMode::CREATIVE
			event.setCancelled true
		end																                   
	end
end
