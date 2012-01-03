# SpoutBoost
# A list of useful functions and tools for any server running spout.

#### Plugin Info ####
Plugin.is {
    name "SpoutBoost"
    version "0.3"
    author "d4l3k"
    description "A pack of useful tools for any Spout Server."
    commands :title => {
        :description => "Sets a title for a player.",
        :usage => "/title <player> <title>\n/title <title>",
        :aliases => [ :settitle]
    }
    commands :boost => {
        :description => "Controls SpoutBoost.",
        :usage => "/boost <options>",
    }
}
#### Requires ####
# Adds default jruby libraries to path so you can easily require them. 
# (This should be done by default, but requires more than just the jruby.jar.)
# TODO: Fix this in RubyBukkit source & push the changes.
# This plugin requires 1.9 for easy Psych compatibility.
#file = File.join(File.dirname(__FILE__),"./jruby-1.6.5/lib/ruby/1.9/")
#$: << file unless $:.include? file

#### Imports ####
# Java Imports
import 'java.util.logging.Logger'
import 'java.util.logging.Level'
# Spout imports
import 'org.getspout.spoutapi.gui.Widget'
import 'org.getspout.spoutapi.gui.WidgetAnchor'
import 'org.getspout.spoutapi.gui.GenericPopup'
import 'org.getspout.spoutapi.gui.GenericLabel'
import 'org.getspout.spoutapi.SpoutManager'
import 'org.getspout.spoutapi.player.SpoutPlayer'
import 'org.getspout.spoutapi.event.spout.SpoutListener'

# Bukkit imports
import 'org.bukkit.Location'
import 'org.bukkit.event.Event'
import 'org.bukkit.event.player.PlayerMoveEvent'
import 'org.bukkit.GameMode'
import 'org.bukkit.inventory.ItemStack'
import 'org.bukkit.Material'

# WorldGuard imports
import 'com.sk89q.worldguard.protection.managers.RegionManager'
import 'com.sk89q.worldguard.protection.ApplicableRegionSet'
import 'com.sk89q.worldguard.bukkit.BukkitUtil'

# Ruby Libraries
require 'yaml'

# Libraries
require 'SpoutBoost/lib/data'
require 'SpoutBoost/lib/permissions'
require 'SpoutBoost/lib/inventory_listener'

#### Main Plugin ####
# Pretty much everything happens here.
class SpoutBoost < RubyPlugin
	#### I/O to Console ####
	# TODO: Set logger prefix & use @log.info, @log.debug, etc.
	def info msg # Standard output to console.
		# Uses bash escape codes for pretty colors.
		@logger.info "\e[36m[\e[32mSpoutCraft\e[36m] #{msg}\e[0m"
	end
	def debug msg # Debug output to console.
		# Uses bash escape codes for pretty colors.
		@logger.info "\e[33m[\e[32mSpoutCraft\e[33m] #{msg}\e[0m"
	end
	def err msg # Used for error messages.
		# Uses bash escape codes for pretty colors.
		@logger.log Level::WARNING, "\e[31m[\e[32mSpoutCraft\e[31m] #{msg}\e[0m"
	end

	# Housekeeping for directories.
	def check_dirs
		files = ["./SpoutBoost","./SpoutBoost/inventory","./SpoutBoost/inventory/creative","./SpoutBoost/inventory/survival"]
		files.each do |object|
			file_path = File.join(File.dirname(__FILE__),object)
			if !File.exists?(file_path)
				info "Mkdir: #{file_path}"
				Dir.mkdir(file_path)
			end
		end
	end
	def load_config
		config_file = File.join(File.dirname(__FILE__),"./SpoutBoost/config.yml")
		if File.exists?(config_file)
			File.open(config_file, "r") do |object|
				debug "loading config"
				@conf = YAML::load(object)
			end
			debug "Config loaded."
		else
			@conf = ConfigBase.new
			debug "Created new config file."
			save_config
		end
	end
	def save_config
		config_file = File.join(File.dirname(__FILE__),"./SpoutBoost/config.yml")
		File.open(config_file, "w") do |file|
			file.print YAML::dump(@conf)
		end
	end
	def save_inv player, dir
		inv_file = File.join(File.dirname(__FILE__),"./SpoutBoost/inventory/#{dir}/#{player.getName}.yml")
		File.open(inv_file, "w") do |file|
			file.print YAML::dump(PlayerInv.new(player.getInventory.getContents))
		end
	end
	def load_inv player, dir
		config_file = File.join(File.dirname(__FILE__),"./SpoutBoost/inventory/#{dir}/#{player.getName}.yml")
		if File.exists?(config_file)
	        	File.open(config_file, "r") do |object|
	                	debug "loading config"
	                	player.getInventory.setContents YAML::load(object).get_inv.to_java(ItemStack)
	        	end
	        	debug "Inventory loaded."
	    	else
	        	debug "No inventory found! Setting to blank."
	        	player.getInventory.clear
		end
	end
   	def onEnable
   		@logger = Logger.getLogger("Minecraft")
		check_dirs
		load_config
		@pm = getServer.getPluginManager
		# TODO: Add password security. Below is a method stub.
		if false
			info "Password enabled."
			registerEvent(Event::Type::PLAYER_LOGIN, Event::Priority::Normal) do |infoinEvent|
				scheduleSyncDelayedTask(1) do
					player = SpoutManager::getPlayer(infoinEvent.getPlayer)
					popup = GenericPopup.new
					text = GenericLabel.new @conf.motd
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
					info "Created MOTD for #{player.getDisplayName()}"
				end
			end
		end
		# MOTD handling code.
		# TODO: Add close button or Rules Accept/Deny button.
		if @conf.motd
      		info "MOTD enabled."
		  	registerEvent(Event::Type::PLAYER_JOIN, Event::Priority::Normal) do |infoinEvent|
		  		scheduleSyncDelayedTask(1) do
					player = SpoutManager::getPlayer(infoinEvent.getPlayer)
					popup = GenericPopup.new
					text = GenericLabel.new @conf.motd
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
					info "Created MOTD for #{player.getDisplayName()}"
				end
			end
		end
		# Extra player data handling code. 
	  	registerEvent(Event::Type::PLAYER_JOIN, Event::Priority::Normal) do |event|
	  		scheduleSyncDelayedTask(1) do
				player = SpoutManager::getPlayer(event.getPlayer)
				player_data = PlayerData.new player
				@players.store(player,player_data) 
				player_data.set_texture_pack(@conf.default_texture_pack)
				info "Set texture pack for #{player.getDisplayName()}"
				update_region player
			end
		end
		# Region move events. 
		# TODO: Region persistence via YAML w/ ingame commands.
		if @conf.regions
			info "Regions are enabled."
			registerEvent(Event::Type::PLAYER_MOVE, Event::Priority::Normal) do |event|
				player = SpoutManager::getPlayer(event.getPlayer)
				update_region player
			end
			registerEvent(Event::Type::PLAYER_DROP_ITEM, Event::Priority::Normal) do |event|
				if event.getPlayer.getGameMode == GameMode::CREATIVE
					event.getItemDrop.remove
					event.setCancelled(true)
				end
			end
			registerEvent(Event::Type::BLOCK_PLACE, Event::Priority::Normal) do |event|
				if event.getPlayer.getGameMode == GameMode::CREATIVE
					player = event.getPlayer
					pt = BukkitUtil.toVector(event.getBlockPlaced.getLocation)
					rm = @wg.getRegionManager(player.getWorld)
					set = rm.getApplicableRegions(pt).iterator
					player_data = @players[player]
					in_region = false
					while set.hasNext
						elem = set.next
						region = @conf.regions[elem.getId]
						if region
							in_region = true
							# Player entered/switched region.
							if region.id!=player_data.region
								if !region.creative
									event.setCancelled true
								end
							end
						end
					end
					if !in_region && !@conf.default_creative
						event.setCancelled true
					end
				end
			end
			#@pm.registerEvent(Event::Type::CUSTOM_EVENT, BoostListener.new, Event::Priority::Normal, self)
			registerEvent(Event::Type::PLAYER_INVENTORY, Event::Priority::Normal) do |event|
				debug "inventory!!!"
				if event.getPlayer.getGameMode == GameMode::CREATIVE
					debug "creative"
					if event.getInventory.getName
						debug event.getInventory.getName
						debug "Chest canceled."
						event.setCancelled true
					end
				end
			end
		end
		# Attempt to find worldguard. May later pop errors if worldguard is reloaded. (Spout doesn't like being reloaded.)
		# TODO: Better error handling (may not need it).
		@wg = @pm.getPlugin("WorldGuard")
		if !@wg
			err "Worldguard not found. Errors will probably occur!"
		end
		@players = {}
		info "Enabled."
   	end
   	def onDisable
		save_config
   		info "Disabled."
	end
	def onCommand(sender, cmd, label, args)
		# TODO: Region commands.
		player = SpoutManager::getPlayer(sender.getPlayer)
		if cmd.getName.downcase=="boost"&&sender.hasPermission("SpoutBoost.region")
			arg0 = args[0].downcase
			if arg0 == "reload"
				load_config
				sender.sendMessage("SpoutBoost config reloaded")
				return true
			elsif arg0 == "add" && args.length==3
				creative = false
				arg2 = args[2].downcase
				if arg2=="1"||arg2=="true"||arg2=="creative"
					creative = true
				end
				@conf.region args[1], creative, ""
				save_config
				sender.sendMessage("#{args[1]} added")
				return true
			elsif arg0 == "remove" && args.length==2
				@conf.regions.delete args[1] do |reg|
					sender.sendMessage("#{reg} not found to delete.")
					return false
				end
				sender.sendMessage("#{args[1]} deleted.")
				save_config
				return true
			end
		elsif cmd.getName().downcase=="title"||cmd.getName().downcase=="settitle" 
	   		if args.length==1&&sender.hasPermission("SpoutBoost.title.self")
	   			player.setTitle args[0]
	   			info "Set #{player.getDisplayName}'s title."
	   			return true
	   		elsif args.length==2&&sender.hasPermission("SpoutBoost.title.other")
	   			player.setTitle args[0]
	   			info "#{sender.getPlayer.getDisplayName} set #{player.getDisplayName}'s title."
	   			return true
	   		end
	   	end
	   	return false
	end
	# Easy method to update region info (used during move events & player join)
	def update_region player
		if !@conf.regions
			return
		end
		# TODO: Consider switching from event driven to time driven for less server impact.
		pt = BukkitUtil.toVector(player.getLocation)
		
		rm = @wg.getRegionManager(player.getWorld)
		set = rm.getApplicableRegions(pt).iterator
		player_data = @players[player]
		in_region = false
		while set.hasNext
			elem = set.next
			region = @conf.regions[elem.getId]
			if region
				in_region = true
				# Player entered/switched region.
				if region.id!=player_data.region
					if player_data.region==""
						info "#{player.getDisplayName} has entered region: #{region.id}."
						player.sendMessage("You have entered region: #{region.id}.")
					elsif
						info "#{player.getDisplayName} has left region: #{player_data.region}; to enter region: #{region.id}."
						player.sendMessage "You have left region #{player_data.region}; to enter region: #{region.id}."
					end
					player_data.region = region.id
					region_mode = GameMode::SURVIVAL
					if region.creative
						region_mode = GameMode::CREATIVE
					end
					mode = player.getGameMode
					if region_mode != mode
						set_gamemode player, region_mode
					end
					player_data.set_texture_pack region.texture_pack
				end
			end
		end
		# Player left region.
		if !in_region && player_data.region!=""
			info "#{player.getDisplayName} has left region: #{player_data.region}."
			player.sendMessage("You have left region: #{player_data.region}.")
			player_data.region = ""
			default_mode = GameMode::SURVIVAL
			if @conf.default_creative
                		default_mode = GameMode::CREATIVE
            		end
			if default_mode != player.getGameMode
				set_gamemode player, default_mode
			end
			player_data.set_texture_pack @conf.default_texture_pack
		end
	end
	def set_gamemode player, gamemode
		old_dir = "creative"
		dir = "survival"
		if gamemode == GameMode::CREATIVE
			dir = "creative"
			old_dir = "survival"
		end
		save_inv player, old_dir
		load_inv player, dir
		player.setGameMode gamemode
	end
end
