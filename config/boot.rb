require 'rubygems'
require 'bundler/setup'
require_relative 'keys.local.rb'
require 'unicorn'
require 'rack/cors'
require 'grape'
require 'json'
require 'time'
require 'net/http'
require 'uri'
require 'open-uri'
require 'telegram/bot' if TELEGRAM
require 'logger'
require 'ostruct' if FBMESSENGER
require 'rest_client' if FBMESSENGER
