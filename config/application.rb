$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'api'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

TYPINGSPEED= DEBUG ? 200 : 120
TYPINGSPEED_SLOW= DEBUG ? 200 : 80
RESET_WORDS=['/start','start','/accueil','accueil','/reset','reset','/retour','retour','/sortir','sortir','/menu','menu']
IGNORE_CONTEXT=["api","help"]

Bundler.require :default, ENV['RACK_ENV']
Dir[File.expand_path('../../bot/*.rb', __FILE__)].each do |f|
	require f
end
