# encoding: utf-8

=begin
   Copyright 2016 Telegraph-ai

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
=end

module Giskard
  class Message
    attr_accessor :id                # unique id of the message 
    attr_accessor :seq               # id of the message in the conversation
    attr_accessor :text              # content of the message
    attr_accessor :timestamp         # when was the message sent?
    attr_accessor :id_user           # id of the sender
    attr_accessor :user              # class User for the sender
    attr_accessor :bot               # name of the bot
    
    def initialize(id_message, text, seq, bot)
      @id         = id_message
      @text       = text
      @seq        = seq
      @bot        = bot
    end 
    
    
  end
end
