# SpoutPack
# A list of useful functions and tools for any server running spout.

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
#import 'org.bukkit.configuration.file.FileConfiguration'

# WorldGuard imports
import 'com.sk89q.worldguard.protection.managers.RegionManager'
import 'com.sk89q.worldguard.protection.ApplicableRegionSet'
import 'com.sk89q.worldguard.bukkit.BukkitUtil'

class SpoutPack < RubyPlugin
	def log msg
		#Uses bash escape codes for pretty colors.
		print "\e[36m[\e[32mSpoutCraft\e[36m] #{msg}\e[0m"
	end
	def err msg
		#Uses bash escape codes for pretty colors.
		print "\e[31m[\e[32mSpoutCraft\e[31m] #{msg}\e[0m"
	end
	def load_config
		load "SpoutPack/config.rb"
		@conf = Config.new
	end
   	def onEnable
   		#Housekeeping.
   		load_config
      	@pm = getServer.getPluginManager
      	
      	if @conf.motd
      		log "MOTD Enabled"
		  	registerEvent(Event::Type::PLAYER_LOGIN, Event::Priority::Normal) do |loginEvent|
		  		scheduleSyncDelayedTask(1) do
					player = SpoutManager::getPlayer(loginEvent.getPlayer)
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
					log "Created MOTD for #{player.getDisplayName()}"
				end
			end
		end
		if @conf.default_texture_pack
      		log "Default Texture Pack enabled."
		  	registerEvent(Event::Type::PLAYER_LOGIN, Event::Priority::Normal) do |loginEvent|
		  		scheduleSyncDelayedTask(20) do
					player = SpoutManager::getPlayer(loginEvent.getPlayer)
					player_data = PlayerData.new player
					@players.store(player,player_data) 
					player_data.set_texture_pack(@conf.default_texture_pack)
					log "Set texture pack for #{player.getDisplayName()}"
					update_region player
				end
			end
		end
		if @conf.regions
			log "Regions are enabled."
			registerEvent(Event::Type::PLAYER_MOVE, Event::Priority::Normal) do |event|
				player = SpoutManager::getPlayer(event.getPlayer)
				update_region player
			end
		end
		@wg = @pm.getPlugin("WorldGuard")
		if !@wg
			err "Worldguard not found. Errors will probably occur!"
		end
		@players = {}
		log "Enabled."
   	end
   	def onDisable
   		log "Disabled."
	end
	def onCommand(sender, cmd, label, args)
		player = SpoutManager::getPlayer(sender.getPlayer)
	   	if cmd.getName()=="title"||cmd.getName()=="settitle"
	   		if args.length==1&&player.has("spoutpack.title.self")
	   			player.setTitle args[0]
	   			log "Set #{player.getDisplayName}'s title."
	   			return true
	   		elsif args.length==2&&player.has("spoutpack.title.other")
	   			player.setTitle args[0]
	   			log "#{sender.getPlayer.getDisplayName} set #{player.getDisplayName}'s title."
	   			return true
	   		end
	   	end
	   	if cmd.getName()=="spreload"&&player.has("spoutpack.reload")
	   		load_config
	   		return true
	   	end
	   	return false
	end
	def update_region player
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
				if region.id!=player_data.region
					if player_data.region==""
						log "#{player.getDisplayName} has entered region: #{region.id}."
					elsif
						log "#{player.getDisplayName} has left region: #{player_data.region}, to enter region: #{region.id}."
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
		if !in_region && player_data.region!=""
			log "#{player.getDisplayName} has left region: #{player_data.region}."
			player_data.region = ""
			player.setGameMode @conf.default_gamemode
			player_data.set_texture_pack @conf.default_texture_pack
		end
	end
end

# Data Types
class ConfigBase
	def region id, creative, texture_pack
		if !@regions
			@regions = {}
		end
		@regions.store(id,Region.new(id,creative,texture_pack))
	end
end

class PlayerData
	attr_accessor :player, :region, :texture_pack
	def initialize player
		@player = player
		@region = ""
		@texture_pack = ""
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
	attr_accessor :id, :creative, :texture_pack
	def initialize id, creative, texture_pack
		@id = id
		@creative = creative
		@texture_pack = texture_pack
	end
end

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
