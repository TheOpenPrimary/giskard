require File.expand_path('../config/environment', __FILE__)

use Rack::Cors do
	allow do
		origins '*'
		resource '*', headers: :any, methods: :get
	end
end

Bot.log=Giskard::Log.new()
Bot.db=Giskard::Db.new()
Giskard::Navigation.load_addons()
Bot.nav=Giskard::Navigation.new()

bots=[]
if TELEGRAM then
	Giskard::TG::Messenger.client=Telegram::Bot::Client.new(TG_TOKEN)
	bots.push(Giskard::TG::Messenger)
end
if FBMESSENGER then
	Giskard::FB::Messenger.init()
	bots.push(Giskard::FB::Messenger)
end

run Rack::Cascade.new bots
