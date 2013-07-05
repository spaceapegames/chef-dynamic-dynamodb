#
# Cookbook Name:: chef-dynamic-dynamo
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

supervisor_service service['name'] do
    command "./dynamic-dynamo.py -c #{node['dynamic-dynamo']['config_file']}"
	directory node['dynamic-dynamo']['base_path']}/dynamic-dynamo
	action :enable
	supports :status => true, :start => true, :stop => true, :restart => true
	user node['dynamic-dynamo']['user']
	startretries 2
	startsecs 5
	stdout_logfile "#{node['dynamic-dynamo']['log_path']}dynamic-dynamo_stdout.log"
	stderr_logfile "#{node['dynamic-dynamo']['log_path']}dynamic-dynamo_stderr.log"  
end 
