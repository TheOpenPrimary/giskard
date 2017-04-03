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

# implement a user for telegram
# TODO all

module Giskard
module TG
    	class User < Giskard::Core::User

            attr_accessor :id   # id in the database = id in Facebook
            attr_accessor :username


def self.initialize(message)
    @id = message.from.id
    @username   = message.from.username
    @last_name  = message.from.last_name
    @first_name = message.from.first_name
    super()
end

# look at the database whether the user has already been created
# return the user in this case
# return a nil if the user does not exist
def self.load
    params = [
        @id,
    ]
    res = Bot.db.query("tg_user_select", params)
    if res.nil?
        return False
    end
    @last_name = res[0]['last_name']
    @first_name = res[0]['first_name']
    @id = res[0]['id']
    @username = res[0]['user_name']
    @messenger = TG_BOT_NAME
    return True
end

# create a user in the database
def self.create
    Bot.log.debug("New user : #{@first_name} #{@last_name}")

    # save in database
    params = [
        @id,
        self.first_name,
        self.last_name,
        self.username
    ]
    Bot.db.query("tg_user_insert", params)
    @messenger = TG_BOT_NAME
end

# save in the database the user with its fsm
def self.save
    params = [
        @id,
        @first_name,
        @last_name,
        @username
    ]
    # TODO update timestamp
    res = Bot.db.query("tg_user_update", params)
end



# database queries to prepare
def self.load_queries
    queries={
        "tg_user_select" => "SELECT * FROM tg_users where id=$1",
        "tg_user_insert"  => "INSERT INTO tg_users (id, first_name, last_name, username) VALUES ($1, $2, $3, $4);",
        "tg_user_update"  => "UPDATE TG_users SET
                first_name=$2,
                last_name=$3,
                user_name=$4
                WHERE id=$1"
    }
    queries.each { |k,v| Bot.db.prepare(k,v) }
end



        end # end class
    end # end module Telegram
end # Giskard
