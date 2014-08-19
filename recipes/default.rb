#
# Cookbook Name:: dynamic-dynamodb
# Recipe:: default
#
# Copyright 2013, Space Ape Games
#
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
#

include_recipe "git"
include_recipe "python"

#### going to populate the table setup from the databag
begin
    tables_databag = data_bag_item('dynamic-dynamodb', 'tables').raw_data
rescue
	log 'you have no tables in your databag!'
	tables_databag = {}
end

#### going to grab your aws keys from the databag
begin
    aws_creds = data_bag_item('aws', 'dynamic-dynamodb').to_hash
rescue
    log 'you have no aws creds in your databag! we are ging to use the ones in your cookbook, or .boto file if nil'
    aws_creds = {}
    aws_creds['aws_access_key_id'] = node['dynamic-dynamodb']['config']['global']['aws_access_key_id']
    aws_creds['aws_secret_access_key_id'] = node['dynamic-dynamodb']['config']['global']['aws_secret_access_key_id']
end

#Create directory at compile time for git resource below
directory "#{node['dynamic-dynamodb']['base_path']}/dynamic-dynamodb" do
    owner node['dynamic-dynamodb']['user']
    group node['dynamic-dynamodb']['group']
    mode 00755
    action :nothing
end.run_action(:create)

# Sync git repo at compile time so we can create necessary package resources for required Python modules
git "#{node['dynamic-dynamodb']['base_path']}/dynamic-dynamodb" do
    repository "git://github.com/sebdah/dynamic-dynamodb.git"
    reference "master"
    user node['dynamic-dynamodb']['user']
    group node['dynamic-dynamodb']['group']
    action :nothing
end.run_action(:sync)

#Install required Python modules
mods = File.new("#{node['dynamic-dynamodb']['base_path']}/dynamic-dynamodb/requirements.txt").read.split("\n").map! { |mod| { mod.split(/[!=<>]+/)[0] => mod.split(/[!=<>]+/)[1] } }
modules = Hash.new
mods.each {|mod| modules.merge!(mod)}
modules.each do |k, v|
  python_pip k do
    version v
  end
end

directory "#{node['dynamic-dynamodb']['log_path']}/dynamic-dynamodb" do
    owner node['dynamic-dynamodb']['user']
    group node['dynamic-dynamodb']['group']
    mode 00755
    action :create
end

template "#{node['dynamic-dynamodb']['base_path']}/dynamic-dynamodb/dynamic-dynamodb.conf" do
	source "dynamic-dynamodb.conf.erb"
	user node['dynamic-dynamodb']['user']
    group node['dynamic-dynamodb']['group']
    variables(
    	:aws_access_key_id => aws_creds['aws_access_key_id'],
    	:aws_secret_access_key_id => aws_creds['aws_secret_access_key'],
    	:region => node['dynamic-dynamodb']['config']['global']['region'],
    	:check_interval => node['dynamic-dynamodb']['config']['global']['check_interval'],
        :log_level => node['dynamic-dynamodb']['log_level'],
        :log_file => "#{node['dynamic-dynamodb']['log_path']}/dynamic-dynamodb/#{node['dynamic-dynamodb']['log_file']}",
    	:circuit_breaker_url => node['dynamic-dynamodb']['config']['global']['circuit_breaker_url'],
    	:circuit_breaker_timeout => node['dynamic-dynamodb']['config']['global']['circuit_breaker_timeout'],
    	:tables => tables_databag
    	)
    notifies :restart, "service[dynamic-dynamodb]", :delayed
	mode 00644
end

options = []
if node['dynamic-dynamodb']['dry_run'] == true
    options << '--dry-run'
end 

template "/etc/init.d/dynamic-dynamodb" do
    source "dynamic-dynamodb.erb"
    owner "root"
    group "root"
    mode 0755
    variables(
        :command => "#{node['dynamic-dynamodb']['base_path']}/dynamic-dynamodb/dynamic-dynamodb -c #{node['dynamic-dynamodb']['base_path']}/dynamic-dynamodb/#{node['dynamic-dynamodb']['config_file']} #{options.join(' ')}"
        )
end

service "dynamic-dynamodb" do
  supports :restart => true, :stop => true, :start => true
  action :enable
  subscribes :restart, "template[/etc/init.d/dynamic-dynamodb]", :immediately
end

