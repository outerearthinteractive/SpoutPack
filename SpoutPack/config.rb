# Server permissions:
# spoutpack.reload - reload this config file w/ /spreload
# spoutpack.title.self - set their own title
# spoutpack.title.other - set someone else's title.



class Config < ConfigBase
	attr_accessor :motd, :default_texture_pack, :default_gamemode, :regions
	
	def initialize
		# Change the settings below here.
		@motd = "Welcome to the OEI Developement Server! \nThis server is using SpoutCraft. \nThe server auto downloads texturepacks."
		@default_texture_pack = ""
		@default_gamemode = GameMode::SURVIVAL
		@password = "test"
		
		# To define a region you just fill it out with the below. The id is the WorldGuard region id that you setup ingame. No regions have to be defined.
		# region( <id>, <creative_mode>, <texture_pack> )
		region(
			"test",
			GameMode::CREATIVE,
			"http://www.retributiongames.com/quandary/files/Quandary_4.2_3_Djeran.zip"
				)
	end
end
