Plugin.is {
    name "SpoutPack"
    version "0.3"
    author "d4l3k"
    description "A pack of useful tools for any Spout Server."
    #commands :list => {
    #    :description => "Show online players.",
    #    :usage => "/list",
    #    :aliases => [ :players, :online ]
    #}
}

import 'org.bukkit.event.Event'
import 'org.getspout.spoutapi.gui.Widget'
import 'org.getspout.spoutapi.gui.GenericPopup'
import 'org.getspout.spoutapi.gui.GenericLabel'
import 'org.getspout.spoutapi.SpoutManager'
import 'org.getspout.spoutapi.player.SpoutPlayer'
import 'org.bukkit.configuration.file.FileConfiguration'

class SpoutPack < RubyPlugin
	def debug msg
		#Uses bash escape codes for pretty colors.
		print "\e[36m[\e[32mSpoutCraft\e[36m] #{msg}\e[0m"
	end
   	def onEnable
   		#Housekeeping.
		@conf = self.getConfig()
		@regions = @conf.get("regions",[])
		getConfig
		
      	@pm = getServer.getPluginManager
      	registerEvent(Event::Type::PLAYER_LOGIN, Event::Priority::Normal) do |loginEvent|
      		scheduleSyncDelayedTask(20) do
		  		print "after 20 ticks." 
				player = SpoutManager::getPlayer(loginEvent.getPlayer)
				popup = GenericPopup.new
				text = GenericLabel.new "MOTD:"
				popup.attachWidget(self, text)
				player.getMainScreen().attachPopupScreen(popup)
				debug "Created popup for #{player.getDisplayName()}"
			end
		end
		debug "Enabled."
   	end
   	def onDisable
   		@conf.set("regions",@regions)
		saveConfig
   		debug "Saved Regions. Disabled."
	end
end
