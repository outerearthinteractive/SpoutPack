Plugin.is {
    name "SpoutPack"
    version "0.3"
    author "d4l3k"
    description "A pack of useful tools for any Spout Server."
    commands :title => {
        :description => "Sets a title for a player.",
        :usage => "/title <player> <title>\n/title <title>",
        :aliases => [ :settitle]
    }
}

import 'org.getspout.spoutapi.gui.Widget'
import 'org.getspout.spoutapi.gui.WidgetAnchor'
import 'org.getspout.spoutapi.gui.GenericPopup'
import 'org.getspout.spoutapi.gui.GenericLabel'
import 'org.getspout.spoutapi.SpoutManager'
import 'org.getspout.spoutapi.player.SpoutPlayer'
import 'org.bukkit.configuration.file.FileConfiguration'
import 'org.bukkit.Location'
import 'org.bukkit.event.Event'
import 'org.bukkit.event.player.PlayerInteractEvent'

class SpoutPack < RubyPlugin
	def debug msg
		#Uses bash escape codes for pretty colors.
		print "\e[36m[\e[32mSpoutCraft\e[36m] #{msg}\e[0m"
	end
   	def onEnable
   		#Housekeeping.
		@conf = self.getConfig()
		@conf.set("motd",@conf.get("motd",""))
		@conf.set("default_texture_pack",@conf.get("default_texture_pack",""))
		@conf.set("select_tool",@conf.get("select_tool",294))
		@conf.set("regions",@conf.get("regions",[]))
      	@pm = getServer.getPluginManager
      	
      	if @conf.get("motd","")!=""
      		debug "MOTD Enabled"
		  	registerEvent(Event::Type::PLAYER_LOGIN, Event::Priority::Normal) do |loginEvent|
		  		scheduleSyncDelayedTask(1) do
					player = SpoutManager::getPlayer(loginEvent.getPlayer)
					popup = GenericPopup.new
					text = GenericLabel.new @conf.get("motd")
					text.setAuto(true)
					text.setResize(true)
					text.setFixed(false)
					text.setAlign(WidgetAnchor::TOP_CENTER)
					text.setAnchor(WidgetAnchor::TOP_CENTER)
					text.doResize()
					esc = GenericLabel.new "Press ESC to close"
					esc.setAlign(WidgetAnchor::BOTTOM_CENTER)
					esc.setAnchor(WidgetAnchor::BOTTOM_CENTER)
					esc.setFixed(false)
					esc.setResize(true)
					esc.doResize()
					popup.attachWidget(self, text)
					popup.attachWidget(self, esc)
					player.getMainScreen().attachPopupScreen(popup)
					debug "Created MOTD for #{player.getDisplayName()}"
				end
			end
		end
		if @conf.get("default_texture_pack","")!=""
      		debug "Default Texture Pack Enabled"
		  	registerEvent(Event::Type::PLAYER_LOGIN, Event::Priority::Normal) do |loginEvent|
		  		scheduleSyncDelayedTask(1) do
					player = SpoutManager::getPlayer(loginEvent.getPlayer)
					player.setTexturePack(@conf.get("default_texture_pack",""))
					debug "Set texture pack for #{player.getDisplayName()}"
				end
			end
		end
		registerEvent(Event::Type::PLAYER_MOVE, Event::Priority::Normal) do |event|
			player = SpoutManager::getPlayer(event.getPlayer)
			@conf.get("regions",{}).each do |region|
				debug "Player is in region #{region.name}: #{region.playerWithin player}"
			end
		end
		registerEvent(Event::Type::PLAYER_INTERACT, Event::Priority::Normal) do |event|
			player = SpoutManager::getPlayer(event.getPlayer)
			block = event.getClickedBlock
			if event.getAction==Event::Action::LEFT_CLICK_BLOCK
				
			elsif event.getAction==Event::Action::RIGHT_CLICK_BLOCK
			
			end
		end
		debug "Enabled."
   	end
   	def onDisable
		saveConfig
   		debug "Save complete. Disabled."
	end
	def onCommand(sender, command, label, args)
	   	if cmd.getName().equalsIgnoreCase("title")||cmd.getName().equalsIgnoreCase("settitle")
	   		if args.length==1
	   			player = SpoutManager::getPlayer(sender.getPlayer)
	   			player.setTitle args[0]
	   			debug "Set #{player.getDisplayName}'s title."
	   			return true
	   		elsif args.length==2
	   			player = SpoutManager::getPlayer(getServer.getPlayer(args[0]))
	   			player.setTitle args[0]
	   			debug "#{sender.getPlayer.getDisplayName} set #{player.getDisplayName}'s title."
	   			return true
	   		end
	   	end
	   	return false
	end
end

class Region
	def initialize name, loc1, loc2
		@name = name
		@loc1 = loc1
		@loc2 = loc2
	end
	def playerWithin player
		loc = player.getLocation
		if loc1<loc&&loc<loc2 || loc1>loc&&loc>loc2
			return true
		end
		return false
	end
end
