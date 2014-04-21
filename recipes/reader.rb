#
# Cookbook Name:: wrapper-logstash
# Recipe:: reader
#
# Copyright (C) 2014 David F. Severski
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

name = 'server'

#clear out the default config templates
attributes = node['logstash']['instance'][name]
node.normal['logstash']['instance'][name]['config_templates'].keys.each do |k|
  node.normal['logstash']['instance'][name]['config_templates'].delete(k)
end

node.force_override['logstash']['instance']['server']['config_templates'] = {
  'input_file' => 'config/input_file.conf.erb',
  'output_redis' => 'config/output_redis.conf.erb'
}

# create the server instance
logstash_instance name do
  action            :create
end

# enable and start the service
logstash_service name do
  action      [:enable, :start]
end

es_ip = service_ip(name, 'elasticsearch')

# create our configuration files from the provided templates
logstash_config name do
  #Chef::Log.info("config vars: #{node['logstash']['instance']['server'].inspect}")
  action [:create]
  variables(
    elasticsearch_ip: es_ip,
    elasticsearch_embedded: false,
    input_file_exclude: "*.gz",
    input_file_name: "/vagrant/logs/13*",
    input_file_type: "sidewinder",
    input_file_position: "beginning",
    output_redis_datatype: "list",
    output_redis_host: "10.0.0.21"
  )
end

# create our custom patterns
logstash_pattern name do
  action [:create]
end