# Copyright 2009 Sidu Ponnappa

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require File.expand_path(File.dirname(__FILE__) + "/../lib/wrest")
require 'digest/md5'

Wrest.logger = Logger.new(STDOUT)
Wrest.logger.level = Logger::DEBUG  # Set this to Logger::INFO or higher to disable request logging
# Wrest.use_curl

include Wrest

# This example demonstrates fetching a Facebook user's public profile
# given his or her Facebook UID. It also shows how strings in the 
# deserialised response can be easily converted into other objects 
# using Wrest's typecast feature.

module Facebook
  # This key and secret are both fake. To get your own key and secret, create a
  # Facebook application at http://www.facebook.com/developers/apps.php
  Config ={
    :key => 'b1f9bdc9c0ccf5e57a6920a257ffdbc2',
    :secret => '8b4890b5ba395a8602e11d5eba764141',
    :restserver => 'http://api.facebook.com/restserver.php'
  }
    
  module API
    Defaults = {
      'v' => '1.0',
      'format' => 'XML',
      'api_key' => Config[:key]
    }
    
    def self.signature_for(params)
      # http://wiki.developers.facebook.com/index.php/How_Facebook_Authenticates_Your_Application
      request_str = params.keys.sort.map{|k| "#{k}=#{params[k]}" }.join
      Digest::MD5.hexdigest(request_str + Config[:secret])
    end
    
    def self.invoke(args)
      args = API::Defaults.merge(args)
      Config[:restserver].to_uri.post_form(args.merge('sig' => Facebook::API.signature_for(args))).deserialise
    end
  end
  
  class Profile
    include Components::Container
    typecast  :uid        => as_integer,
              :pic_square => lambda{|pic_square| pic_square.to_uri}

    Fields = %w(
      uid
      first_name
      last_name
      name
      pic_square
    ).join(', ')
    
    def self.get_stream(user)
      hash = Facebook::API.invoke({
        'method' => 'facebook.stream.get', 
        'session_key' => user.session_key,
        'limit' => '100',
        'metadata' => "[\"photo_tags\", \"profiles\", \"albums\", \"events\"]"
      })
      
      #hash = Facebook::API.invoke({
      #  'method' => 'facebook.stream.get', 
      #  'session_key' => user.session_key,
      #  'limit' => '100',
      #  'start_time' => Time.parse("5/29").to_i.to_s,
      #  'end_time' => Time.parse("6/1").to_i.to_s,
      #  'metadata' => "[\"photo_tags\", \"profiles\", \"albums\", \"events\"]"
      #})
      
      if hash['error_response']
        Facebook::Error.new hash['error_response']
      else
        #self.new hash["friends_get_response"]
        hash
      end
    end
    
    def self.get_friends(user, facebook_uid)
      hash = Facebook::API.invoke({
        'method' => 'facebook.friends.get', 
        'session_key' => user.session_key,
        'uid' => facebook_uid
      })
      
      if hash['error_response']
        Facebook::Error.new hash['error_response']
      else
        #self.new hash["friends_get_response"]
        hash
      end
    end
    
    def self.find(fcbk_uid)
      hash = Facebook::API.invoke({
        'method' => 'facebook.users.getInfo', 
        'fields' => Profile::Fields,
        'uids' => fcbk_uid
      })
      
      if hash['error_response']
        Facebook::Error.new hash['error_response']
      else
        self.new hash["users_getInfo_response"]["user"]
      end
    end
  end
  
  class Error
    include Components::Container
    typecast :error_code => as_integer
  end
end
