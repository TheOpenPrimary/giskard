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
    module FB
    	class Message < Giskard::Core::Message

            attr_accessor :seq   # id in the database = id in Facebook
            attr_accessor :postback

def initialize(messaging)
    self.id   = nil
    self.seq  = nil
    self.messenger = FB_BOT_NAME
    self.timestamp = messaging.timestamp
    if not messaging.message.nil? then
        self.id   = messaging.message.mid
        self.seq  = messaging.message.seq
        self.text = messaging.message.text
    elsif not messaging.postback.nil? then
        self.text = messaging.postback.payload
        self.postback  = Giskard::FB::Postback.new(messaging.postback)
    end

end

def initialize(id, text, seq)
    self.id   = id
    self.seq  = seq
    self.text = text
end

class Postback
    attr_accessor :payload           # payload parameter that was defined with the button
    attr_accessor :referral          # Comes only with Get Started postback and if an optional ref param was passed from the entry point, such as m.me link
    attr_accessor :source            # shortlink
    attr_accessor :type         	 # open thread

    def initialize(postback)
        @payload   = postback.payload
        @ref       = postback.referral.nil? ? nil : postback.referral.ref
        @source    = postback.referral.nil? ? nil : postback.referral.source
        @type      = postback.referral.nil? ? nil : postback.referral.type
    end
end


        end # end class
    end # end module FB
end # module Bot
