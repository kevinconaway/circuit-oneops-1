require 'rubygems'
require 'net/https'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
keywhiz_cloud_service = node[:workorder][:services][:keywhiz][cloud_name][:ciAttributes]
mgmt_domain = node[:mgmt_domain]
node.set[:oneops_server] = mgmt_domain.split(".")[0]
Chef::Log.info("oneops server: " + node[:oneops_server])

keywhiz_service_host = keywhiz_cloud_service[:host]
keywhiz_service_port = keywhiz_cloud_service[:port]
node.set[:keywhiz_sync_download_url] = keywhiz_cloud_service[:keysync_download_url]
meta_params = JSON.parse(keywhiz_cloud_service[:sync_cert_params])
node.set[:keywhiz_sync_cert_owner_dl] = meta_params["owner_email"]
node.set[:keywhiz_sync_cert_domain] = meta_params["cert_domain"]
node.set[:keywhiz_service_host] = keywhiz_service_host
node.set[:keywhiz_service_port] = keywhiz_service_port

node.set[:sync_cert_passphrase] = Array.new(4){[*("A".."Z"), *(0..9), *("a".."z")].sample}.join.to_s +
 "-" + Array.new(4){[*("A".."Z"), *(0..9), *("a".."z")].sample}.join.to_s +
"@" + Array.new(4){[*(0..9)].sample}.join.to_s
#keywhiz_cloud_service[:sync_cert_passphrase]

client_cert = keywhiz_cloud_service[:client_cert]

ca_file = '/opt/oneops/keywhiz/kw-client.cert'

Chef::Log.info("keywhiz service config => host: " + keywhiz_service_host + " port: " + keywhiz_service_port);

https=Net::HTTP.new(keywhiz_service_host, keywhiz_service_port)
https.use_ssl = true
https.ssl_timeout = 4
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.cert = OpenSSL::X509::Certificate.new(client_cert)
https.key = OpenSSL::PKey::RSA.new(client_cert)

File.open(ca_file, 'w') {|file| file.write(client_cert)}
https.ca_file = ca_file
https.verify_depth = 3

node.set[:kw_https] = https 

#now set the org, assembly
ns_parts = node.workorder.rfcCi.nsPath.split("/")
org = ns_parts[1]
assembly = ns_parts[2]
env = ns_parts[3]

node.set[:org] = org
node.set[:assembly] = assembly
node.set[:env] = env

