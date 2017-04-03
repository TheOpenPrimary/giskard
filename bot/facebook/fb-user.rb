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

# implement a user for facebook

module Giskard
    module FB
    	class User < Giskard::Core::User

            attr_accessor :id   # id in the database = id in Facebook
            attr_accessor :mail
            attr_accessor :last_msg_time


def initialize(id)
    @id = id
    @last_msg_time = 0
    super()
end

# look at the database whether the user has already been created
# return the user in this case
# return a nil if the user does not exist
def load
    params = [
        @id,
    ]
    res = Bot.db.query("fb_user_select", params)
    if res.num_tuples.zero? then
        return false
    end
    @last_name = res[0]['last_name']
    @first_name = res[0]['first_name']
    @mail = res[0]['mail']
    @id = res[0]['id'].to_i
    @last_msg_time = DateTime.parse(res[0]['last_msg_time']).strftime('%s').to_i
    @messenger = FB_BOT_NAME
    super
    return true
end

# create a user in the database
def create
    # get info from facebook
    res              = URI.parse("https://graph.facebook.com/v2.8/#{@id}?fields=first_name,last_name&access_token=#{FB_PAGEACCTOKEN}").read
    r_user           = JSON.parse(res)
    r_user           = JSON.parse(JSON.dump(r_user), object_class: OpenStruct)
    @first_name  = r_user.first_name
    @last_name   = r_user.last_name
    @last_msg_time = 1000000
    # @mail        = r_user.email
    # @gender		 = (r_user.gender == "male")? 'm': "f"
    # @timezone	 = r_user.timezone
    # @locale		 = r_user.locale
    Bot.log.debug("New user : #{@first_name} #{@last_name}")

    # save in database
    params = [
        @id,
        @first_name,
        @last_name,
        DateTime.strptime(@last_msg_time.to_s,'%s')
    ]
    Bot.db.query("fb_user_insert", params)
    @messenger = FB_BOT_NAME
    super
end

# save in the database the user with its fsm
def save
    params = [
        @id,
        @first_name,
        @last_name,
        @mail,
        DateTime.strptime(@last_msg_time.to_s,'%s')
    ]
    # TODO update timestamp
    Bot.db.query("fb_user_update", params)
    super
end


# check if the message has already been answered
def already_answered?(msg)
    return false if msg.seq ==-1 # external command
    if @last_msg_time > 0 and @last_msg_time >= msg.timestamp then
        Bot.log.debug "Message already answered: last msg time: #{@last_msg_time} and this msg time: #{msg.timestamp}"
        return true
    else
        @last_msg_time = msg.timestamp
        return false
    end
end


# database queries to prepare
def self.load_queries
    queries={
        "fb_user_select" => "SELECT * FROM fb_users where id=$1",
        "fb_user_insert"  => "INSERT INTO fb_users (id, first_name, last_name, last_msg_time) VALUES ($1, $2, $3, $4);",
        "fb_user_update"  => "UPDATE fb_users SET
                first_name=$2,
                last_name=$3,
                email=$4,
                last_msg_time=$5
                WHERE id=$1"
    }
    queries.each { |k,v| Bot.db.prepare(k,v) }
end



        end # end class
    end # end module FB
end # Giskard
