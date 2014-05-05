#
# Cookbook Name:: sch-logstash
# Recipe:: indexer
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
#attributes = node['logstash']['instance'][name]
#node.normal['logstash']['instance'][name]['config_templates'].keys.each do |k|
#  node.normal['logstash']['instance'][name]['config_templates'].delete(k)
#end

#node.force_override['logstash']['instance']['server']['config_templates'] = {
#  'input_redis' => 'config/input_redis.conf.erb',
#  'filter_sidewinder' => 'config/filter_sidewinder.conf.erb',
#  'output_elasticsearch' => 'config/output_elasticsearch.conf.erb'
#}

# create the server instance
logstash_instance name do
  action            :create
end

es_ip = service_ip(name, 'elasticsearch')
my_config_templates =  = {
    'input_redis' => 'config/input_redis.conf.erb',
    'filter_sidewinder' => 'config/filter_sidewinder.conf.erb',
    'output_elasticsearch' => 'config/output_elasticsearch.conf.erb'
}


# enable and start the service
logstash_service name do
  action      [:enable, :start]
end

# create our configuration files from the provided templates
logstash_config name do
  Chef::Log.debug("config vars: #{node['logstash']['instance'].inspect}")
  templates my_config_templates
  action [:create]
  variables(
      elasticsearch_ip: "10.0.0.41",
      elasticsearch_embedded: false,
      elasticsearch_template: "/opt/logstash/server/etc/elasticsearch_template.json",
      elasticsearch_cluster: "elkrun",
      elasticsearch_protocol: "http",
      input_redis_host: "10.0.0.21",
      input_redis_datatype: "list",
      input_redis_type: "sidewinder"
  )
end

# create custom ES index template
template "/opt/logstash/server/etc/elasticsearch_template.json" do
  source "elasticsearch_template.json.erb"
  owner "logstash"
  group "logstash"
end

# create our custom patterns
logstash_pattern name do
  action [:create]
end