#
# Cookbook Name:: sch-logstash
# Recipe:: shipper
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

# set the number of workers threads to the number of cpus
node.normal['logstash']['instance'][name]['workers'] = node['cpu']['total']

# create the server instance
logstash_instance name do
  action            :create
end

# enable and start the service
logstash_service name do
  action      [:enable, :start]
end

# set the templates we want to use, for either cloud or local mode
if node.attribute?('cloud') && node['cloud']['provider'] == "ec2"
  my_config_templates = {
    'input_s3' => 'config/input_s3.conf.erb',
    'filter_metrics' => 'config/filter_metrics.conf.erb',
    'output_redis' => 'config/output_redis.conf.erb',
    'output_graphite' => 'config/output_graphite.conf.erb'
  }
else
  my_config_templates = {
    'input_file' => 'config/input_file.conf.erb',
    'filter_metrics' => 'config/filter_metrics.conf.erb',
    'output_redis' => 'config/output_redis.conf.erb',
    'output_graphite' => 'config/output_graphite.conf.erb'
  }
end

# create our configuration files from the provided templates
logstash_config name do
  Chef::Log.debug("config vars: #{node['logstash']['instance']['server'].inspect}")
  templates my_config_templates
  action [:create]
  variables(
    elasticsearch_ip: 								::Logstash.service_ip(node, name, 'elasticsearch'),
    elasticsearch_embedded: 					false,
    logstash_host:										node['hostname'],
    input_file_exclude: 							"*.gz",
    input_file_name: 									"/vagrant_data/13*",
    input_file_type: 									"sidewinder",
    input_file_position: 							"beginning",
    input_s3_bucket: 									"log-inbox.elk.sch",
    input_s3_delete_after_read: 			true,
    input_s3_region: 									"us-west-2",
    input_s3_bucket_access_key_id: 		node['logstash']['instance']['server']['aws_access_key_id'],
    input_s3_bucket_secret_access_key: node['logstash']['instance']['server']['aws_secret_access_key'],
    output_redis_datatype: 						"list",
    output_redis_host: 								"10.0.0.21",
    output_graphite_host: 						"10.0.0.51",
    redis_workers:										node['cpu']['total'] * 2
  )
end

# create our custom patterns
logstash_pattern name do
  action [:create]
end