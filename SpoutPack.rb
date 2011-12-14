# SpoutPack
# A list of useful functions and tools for any server running spout.

#### Plugin Info ####
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
    commands :spreload => {
        :description => "Reloads the Spoutpack.",
        :usage => "/spreload",
    }
}
#### Requires ####
# Adds default jruby libraries to path so you can easily require them. 
# (This should be done by default, but requires more than just the jruby.jar.)
# TODO: Fix this in RubyBukkit source & push the changes.
# This plugin requires 1.9 for easy Psych compatibility.
file = "/usr/share/ruby-rvm/rubies/jruby-1.6.1/lib/ruby/1.9/"
$: << file unless $:.include? file

# Ruby Libraries
require 'yaml'

#### Imports ####
# Java Imports
import 'java.util.logging.Logger'

# Spout imports
import 'org.getspout.spoutapi.gui.Widget'
import 'org.getspout.spoutapi.gui.WidgetAnchor'
import 'org.getspout.spoutapi.gui.GenericPopup'
import 'org.getspout.spoutapi.gui.GenericLabel'
import 'org.getspout.spoutapi.SpoutManager'
import 'org.getspout.spoutapi.player.SpoutPlayer'

# Bukkit imports
import 'org.bukkit.Location'
import 'org.bukkit.event.Event'
import 'org.bukkit.event.player.PlayerMoveEvent'
import 'org.bukkit.GameMode'

# WorldGuard imports
import 'com.sk89q.worldguard.protection.managers.RegionManager'
import 'com.sk89q.worldguard.protection.ApplicableRegionSet'
import 'com.sk89q.worldguard.bukkit.BukkitUtil'

#### Main Plugin ####
# Pretty much everything happens here.
class SpoutPack < RubyPlugin
	#### I/O to Console ####
	# TODO: Set logger prefix & use @log.info, @log.debug, etc.
	def info msg # Standard output to console.
		# Uses bash escape codes for pretty colors.
		@logger.info "\e[36m[\e[32mSpoutCraft\e[36m] #{msg}\e[0m"
	end
	def debug msg # Debug output to console.
		# Uses bash escape codes for pretty colors.
		@logger.debug "\e[33m[\e[32mSpoutCraft\e[33m] #{msg}\e[0m"
	end
	def err msg # Used for error messages.
		# Uses bash escape codes for pretty colors.
		@logger.error "\e[31m[\e[32mSpoutCraft\e[31m] #{msg}\e[0m"
	end

	# Easy method to load/reload the config file.
	def load_config
		load "SpoutPack/config.rb"
		@conf = Config.new
		#TODO: Convert to yaml based config. Should be able to keep same file format.
	end
   	def onEnable
   		@logger = Logger.getLogger("Minecraft")
   		load_config
      		@pm = getServer.getPluginManager
      	
		# Change this to if @conf.password to work. Has errors.
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
		# TODO: Persist player data (inventory is a must).
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
		# TODO: Save yamls for players/regions (seperate function?).
   		info "Disabled."
	end
	def onCommand(sender, cmd, label, args)
		# TODO: Region commands.
		player = SpoutManager::getPlayer(sender.getPlayer)
	   	if cmd.getName()=="title"||cmd.getName()=="settitle" 
	   		if args.length==1&&player.has("spoutpack.title.self")
	   			player.setTitle args[0]
	   			info "Set #{player.getDisplayName}'s title."
	   			return true
	   		elsif args.length==2&&player.has("spoutpack.title.other")
	   			player.setTitle args[0]
	   			info "#{sender.getPlayer.getDisplayName} set #{player.getDisplayName}'s title."
	   			return true
	   		end
	   	end
	   	if cmd.getName()=="spreload"&&player.has("spoutpack.reload")
	   		load_config
	   		return true
	   	end
	   	return false
	end
	# Easy method to update region info (used during move events & player join)
	def update_region player
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
					elsif
						info "#{player.getDisplayName} has left region: #{player_data.region}, to enter region: #{region.id}."
					end
					player_data.region = region.id
					mode = player.getGameMode
					if region.creative != mode
						# TODO: Setup item persistence.
						player.setGameMode region.creative
					end
					player_data.set_texture_pack region.texture_pack
				end
			end
		end
		# Player left region.
		if !in_region && player_data.region!=""
			info "#{player.getDisplayName} has left region: #{player_data.region}."
			player_data.region = ""
			player.setGameMode @conf.default_gamemode
			player_data.set_texture_pack @conf.default_texture_pack
		end
	end
end

#### Data Types/Utils ####
class ConfigBase
	# TODO: Implement Config variables to switch to YAML.
	def region id, creative, texture_pack
		if !@regions
			@regions = {}
		end
		@regions.store(id,Region.new(id,creative,texture_pack))
	end
end

class PlayerData
	# TODO: Player inventory + persistence.
	attr_accessor :player, :region, :texture_pack
	def initialize player
		@player = player
		@region = ""
		@texture_pack = ""
		@authed = true
	end
	def set_texture_pack texture_pack
		if texture_pack!=@texture_pack
			@texture_pack = texture_pack
			if @texture_pack == ""
				@player.resetTexturePack
			elsif
				@player.setTexturePack @texture_pack
			end
		end
	end
end

class Region
	# TODO: Passwords/User/Group Access
	attr_accessor :id, :creative, :texture_pack
	def initialize id, creative, texture_pack
		@id = id
		@creative = creative
		@texture_pack = texture_pack
	end
end

#### Other Included Libraries ####
# TODO: Get rid of everthing below here.
# ================== EVERYTHING BELOW THIS LINE BELONG TO THEIR RESPECTIVE OWNERS ==================

# Ruby permissions library 0.2
#
# Supports: Permissions, PermissionEx, GroupManager
#
# Usage:
# player.has("permission.node")
# - or -
# Permissions.playerHas(player, "permissons.node")
#
# Setup:
# require 'lib/permissions'
#
# @author Zeerix

class Permissions
    # singleton
    def self.instance
        @permissions = Permissions.new if @permissions == nil
        @permissions
    end
    
    def self.playerHas(player, perm, default); instance.playerHas(player, perm, default); end
    def self.plugin; instance.plugin; end

    def self.pluginName
        plugin.getDescription.getFullName if plugin != nil
    end
        
    # the handler
    attr_reader :plugin
    
    def initialize
        server = org.bukkit.Bukkit.getServer
        gm = server.getPluginManager.getPlugin("GroupManager")
        pex = server.getPluginManager.getPlugin("PermissionsEx")
        pm = server.getPluginManager.getPlugin("Permissions")

        if gm != nil then
            @plugin = gm
            @handler = proc { |player, perm, default| gm.getWorldsHolder.getWorldPermissions(player).has(player, perm) }
        elsif pex != nil then
            @plugin = pex
            @handler = proc { |player, perm, default| pex.has(player, perm) }
        elsif pm != nil then
            @plugin = pm
            @handler = proc { |player, perm, default| pm.getHandler.has(player, perm) }
        else
            @handler = proc { |player, perm, default| default }
        end
    end
    
    def playerHas(player, perm, default)
        @handler.call(player, perm, default)
    end
end

module PlayerPermissions
    def has(name, default = false)
        Permissions.playerHas(self, name, default)
    end
end

JavaUtilities.extend_proxy("org.bukkit.entity.Player") {
    include PlayerPermissions
}
