#
# Cookbook Name:: chef-dynamic-dynamodb
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

#### going to populate the table setup from the databag
begin
    tables_databag = data_bag_item('dynamic-dynamo', 'tables')
rescue
	log 'you have no tables in your databag!'
	tables_databag = {}
end

#### going to grab your aws keys from the databag
begin
    aws_creds = data_bag_item('aws', 'dynamic-dynamo')
rescue
    log 'you have no aws creds in your databag! we are ging to use the ones in your cookbook, or .boto file if nil'
    aws_creds['aws_access_key_id'] = node['dynamic-dynamo']['config']['global']['aws_access_key_id']
    aws_creds['aws_secret_access_key_id'] = node['dynamic-dynamo']['config']['global']['aws_secret_access_key_id']
end

directory "#{node['dynamic-dynamo']['base_path']}/dynamic-dynamo" do
    owner node['dynamic-dynamo']['user']
    group node['dynamic-dynamo']['group']
    mode 00755
    action :create
end

directory "#{node['dynamic-dynamo']['log_path']}/dynamic-dynamo" do
    owner node['dynamic-dynamo']['user']
    group node['dynamic-dynamo']['group']
    mode 00755
    action :create
end


git "#{node['dynamic-dynamo']['base_path']}/dynamic-dynamo" do
    repository "git@github.com:elasticsearch/kibana.git"
    reference "master"
    user node['dynamic-dynamo']['user']
    group node['dynamic-dynamo']['group']
    action :sync
end

template "#{node['dynamic-dynamo']['base_path']}/dynamic-dynamo/dynamic-dynamo.conf" do
	source "dynamic-dynamo.erb"
	user node['dynamic-dynamo']['user']
    group node['dynamic-dynamo']['group']
    variables(
    	:aws_access_key_id => aws_creds['aws_access_key_id'],
    	:aws_secret_access_key_id => aws_creds['aws_secret_access_key_id'],
    	:region => node['dynamic-dynamo']['config']['global']['region'],
    	:check_interval => node['dynamic-dynamo']['config']['global']['check_interval'],
    	:circuit_breaker_url => node['dynamic-dynamo']['config']['global']['circuit_breaker_url'],
    	:circuit_breaker_timeout => node['dynamic-dynamo']['config']['global']['circuit_breaker_timeout'],
    	:tables => tables_databag
    	)
	mode 00644
    notifies :restart, "supervisor_service[dynamic-dynamo]"
end


supervisor_service 'dynamic-dynamo' do
    command "./dynamic-dynamo.py -c #{node['dynamic-dynamo']['config_file']}"
    directory "#{node['dynamic-dynamo']['base_path']}/dynamic-dynamo"
    action :enable
    supports :status => true, :start => true, :stop => true, :restart => true
    user node['dynamic-dynamo']['user']
    startretries 2
    startsecs 5
    stdout_logfile "#{node['dynamic-dynamo']['log_path']}dynamic-dynamo_stdout.log"
    stderr_logfile "#{node['dynamic-dynamo']['log_path']}dynamic-dynamo_stderr.log"  
end 
