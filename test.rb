require 'clouddrive'
require 'json'

account = CloudDrive::Account.new("ahp118@gmail.com")
# account.clear_cache
# account.sync
node = CloudDrive::Node.new(account)
puts node.upload_dir("~/Dropbox/Programming/www/clouddrive-sdk/test_dir", "test_dir").inspect
exit
# if node.find_by_path("failed_delivery.json")
#   puts "found file"
# else
#   puts "did not find file"
# end

result = node.upload_file('/Users/alexphillips/tmp/mylog.log', 'ruby/test/folder/')
puts result.inspect
