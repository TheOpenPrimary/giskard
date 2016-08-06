require File.expand_path('../config/environment', __FILE__)

use Rack::Cors do
	allow do
		origins '*'
		resource '*', headers: :any, methods: :get
	end
end

Bot.log=Bot::Log.new()
Bot::Navigation.load_addons()
Bot.nav=Bot::Navigation.new()
bots=[]
if TELEGRAM then
	Giskard::TelegramBot.client=Telegram::Bot::Client.new(TG_TOKEN)
	bots.push(Giskard::TelegramBot)
end
if FBMESSENGER then
	Giskard::FBMessengerBot.init()
	bots.push(Giskard::FBMessengerBot)
end	

run Rack::Cascade.new bots
