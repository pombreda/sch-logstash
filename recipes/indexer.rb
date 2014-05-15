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

# set the number of workers threads to the number of cpus
node.normal['logstash']['instance'][name]['workers'] = node['cpu']['total']

# fetch our licensed version of MaxMind city DB
src_url = "https://download.maxmind.com/app/geoip_download?edition_id=133&suffix=tar.gz&license_key=#{node['logstash']['instance'][name]['maxmind_license_key']}"
src_filename = "GeoIPCity.tar.gz"
src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
extract_path = "/opt/logstash/#{name}/vendor/geoip/MaxMind"

remote_file src_filepath do
  source src_url
  owner 'root'
  group 'root'
  mode 00644
end

bash 'extract_module' do
  cwd ::File.dirname(src_filepath)
  code <<-EOH
    mkdir -p #{extract_path}
    tar xzf #{src_filename} -C #{extract_path}
    chown -R logstash:logstash #{extract_path}
    mv #{extract_path}/*/* #{extract_path}/..
    EOH
  not_if { ::File.exists?(extract_path) }
end

# create the server instance
logstash_instance name do
  action            :create
end

es_ip = ::Logstash.service_ip(node, name, 'elasticsearch')
my_config_templates = {
    'input_redis' => 'config/input_redis.conf.erb',
    'filter_sidewinder' => 'config/filter_sidewinder.conf.erb',
    'filter_metrics' => 'config/filter_metrics.conf.erb',
    'output_elasticsearch' => 'config/output_elasticsearch.conf.erb',
    'output_graphite' => 'config/output_graphite.conf.erb'
}

# create our configuration files from the provided templates
logstash_config name do
  Chef::Log.debug("config vars: #{node['logstash']['instance'].inspect}")
  templates my_config_templates
  action [:create]
  variables(
      elasticsearch_ip: 			"10.0.0.41",
      elasticsearch_embedded: false,
      elasticsearch_template: "/opt/logstash/#{name}/etc/elasticsearch_template.json",
      elasticsearch_cluster: "elkrun",
      elasticsearch_protocol: "http",
      elasticsearch_workers:	node['cpu']['total'],
      logstash_host:					node['hostname'],
      input_redis_host: 			"10.0.0.21",
      input_redis_datatype: 	"list",
      input_redis_type: 			"sidewinder",
      output_graphite_host: 	"10.0.0.51",
      redis_workers:					1,
      geoip_database:					"/opt/logstash/#{name}/vendor/geoip/GeoIPCity.dat"

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


# enable and start the service
logstash_service name do
  action      [:enable, :start]
end
