# Server permissions:
# spoutpack.reload - reload this config file w/ /spreload
# spoutpack.title.self - set their own title
# spoutpack.title.other - set someone else's title.



class Config
	attr_accessor :motd, :default_creative, :default_texture_pack, :regions, :password
	
	def initialize
		# Change the settings below here.
		@motd = "Welcome to the OEI Developement Server! \nThis server is using SpoutCraft. \nThe server auto downloads texturepacks."
		@default_texture_pack = ""
		@default_creative = false
		@password = "test"
		
		# To define a region you just fill it out with the below. The id is the WorldGuard region id that you setup ingame. No regions have to be defined.
		# region( <id>, <creative_mode>, <texture_pack> )
		region(
			"test",
			true,
			"http://www.retributiongames.com/quandary/files/Quandary_4.2_3_Djeran.zip"
				)
	end
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
