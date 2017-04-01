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
	module Core
		class Message
			attr_accessor :id                # unique id of the message
			attr_accessor :text              # content of the message
			attr_accessor :timestamp         # when was the message sent?
			attr_accessor :messenger         # name of the messenger

			def initialize(id)
				@id = id
			end

		end
	end
end
