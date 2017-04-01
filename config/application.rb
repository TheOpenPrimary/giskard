$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'api'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

Bundler.require :default, ENV['RACK_ENV']
Dir[File.expand_path('../../bot/*.rb', __FILE__)].each do |f|
	require f
end
Dir[File.expand_path('../../bot/facebook/*.rb', __FILE__)].each do |f|
	require f
end
Dir[File.expand_path('../../bot/telegram/*.rb', __FILE__)].each do |f|
	require f
end
