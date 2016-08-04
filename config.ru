require File.expand_path('../config/environment', __FILE__)

use Rack::Cors do
	allow do
		origins '*'
		resource '*', headers: :any, methods: :get
	end
end

Giskard::TelegramBot.client=Telegram::Bot::Client.new(TGTOKEN)
Bot.log=Bot::Log.new()
Bot::Navigation.load_addons()
Bot.nav=Bot::Navigation.new()

run Giskard::TelegramBot
