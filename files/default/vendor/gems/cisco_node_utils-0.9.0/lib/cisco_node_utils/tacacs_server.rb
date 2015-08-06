# TacacsServer provider class
#
# Mike Wiebe, January 2015
#
# Copyright (c) 2015 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(File.dirname(__FILE__), 'node')

module Cisco
TACACS_SERVER_ENC_NONE = 0
TACACS_SERVER_ENC_CISCO_TYPE_7 = 7
TACACS_SERVER_ENC_UNKNOWN = 8

class TacacsServer
  @@node = Cisco::Node.instance

  def initialize(instantiate=true)
    enable if instantiate and not TacacsServer.enabled
  end

  # Check feature enablement
  def TacacsServer.enabled
    feat = @@node.config_get("tacacs_server", "feature")
    return (!feat.nil? and !feat.empty?)
  rescue Cisco::CliError => e
    # cmd will syntax reject when feature is not enabled
    raise unless e.clierror =~ /Syntax error/
    return false
  end

  # Enable tacacs_server feature
  def enable
    @@node.config_set("tacacs_server", "feature", "")
  end

  # Disable tacacs_server feature
  def destroy
    @@node.config_set("tacacs_server", "feature", "no")
  end

  # --------------------
  # Getters and Setters
  # --------------------

  # Set timeout
  def timeout=(timeout)
    # 'no tacacs timeout' will fail, just set it to the requested timeout value.
    @@node.config_set("tacacs_server", "timeout", "", timeout)
  end

  # Get timeout
  def timeout
    match = @@node.config_get("tacacs_server", "timeout")
    match.nil? ? TacacsServer.default_timeout : match.first.to_i
  end

  # Get default timeout
  def TacacsServer.default_timeout
    @@node.config_get_default("tacacs_server", "timeout")
  end

  # Set deadtime
  def deadtime=(deadtime)
    # 'no tacacs deadtime' will fail, just set it to the requested timeout value.
    @@node.config_set("tacacs_server", "deadtime", "", deadtime)
  end

  # Get deadtime
  def deadtime
    match = @@node.config_get("tacacs_server", "deadtime")
    match.nil? ? TacacsServer.default_deadtime : match.first.to_i
  end

  # Get default deadtime
  def TacacsServer.default_deadtime
    @@node.config_get_default("tacacs_server", "deadtime")
  end

  # Set directed_request
  def directed_request=(state)
    raise TypeError unless state == true || state == false
    state == TacacsServer.default_directed_request ?
      @@node.config_set("tacacs_server", "directed_request", "no") :
      @@node.config_set("tacacs_server", "directed_request", "")
  end

  # Check if directed request is enabled
  def directed_request?
    match = @@node.config_get("tacacs_server", "directed_request")
    return TacacsServer.default_directed_request if match.nil?
    match.first[/^no/] ? false : true
  end

  # Get default directed_request
  def TacacsServer.default_directed_request
    @@node.config_get_default("tacacs_server", "directed_request")
  end

  # Set source interface
  def source_interface=(name)
    raise TypeError unless name.is_a? String
    name.empty? ?
      @@node.config_set("tacacs_server", "source_interface", "no", "") :
      @@node.config_set("tacacs_server", "source_interface", "", name)
  end

  # Get source interface
  def source_interface
    # Sample output
    # ip tacacs source-interface Ethernet1/1
    # no tacacs source-interface
    match = @@node.config_get("tacacs_server", "source_interface")
    return TacacsServer.default_source_interface if match.nil?
    # match_data will contain one of the following
    # [nil, " Ethernet1/1"] or ["no", nil]
    match[0][0] == "no" ? TacacsServer.default_source_interface : match[0][1]
  end

  # Get default source interface
  def TacacsServer.default_source_interface
    @@node.config_get_default("tacacs_server", "source_interface")
  end

  # Get encryption type used for the key
  def encryption_type
    match = @@node.config_get("tacacs_server", "encryption_type")
    match.nil? ? TACACS_SERVER_ENC_UNKNOWN : match[0][0].to_i
  end

  # Get default encryption type
  def TacacsServer.default_encryption_type
    @@node.config_get_default("tacacs_server", "encryption_type")
  end

  # Get encryption password
  def encryption_password
    match = @@node.config_get("tacacs_server", "encryption_password")
    match.nil? ? TacacsServer.default_encryption_password : match[0][1]
  end

  # Get default encryption password
  def TacacsServer.default_encryption_password
    @@node.config_get_default("tacacs_server", "encryption_password")
  end

  # Set encryption type and password
  def encryption_key_set(enctype, password)
    # if enctype is TACACS_SERVER_ENC_UNKNOWN, we will unset the key
    if enctype == TACACS_SERVER_ENC_UNKNOWN
       # if current encryption type is not TACACS_SERVER_ENC_UNKNOWN, we
       # need to unset it. Otherwise the box is not configured with key, we
       # don't need to do anything
       if encryption_type != TACACS_SERVER_ENC_UNKNOWN
          @@node.config_set("tacacs_server", "encryption", "no",
                      encryption_type,
                      encryption_password)
       end
    else
       @@node.config_set("tacacs_server", "encryption", "", enctype, password)
    end
  end
end
end