namespace :test do
  desc "tests the puppet configuration on the test server"
  task :puppet_noop => :sync_files do
    apply_changes(false)
  end

  desc "applies the puppet configuration on the test server"
  task :puppet_apply => :sync_files do
    apply_changes
  end

  desc "tests the deployment agent on the test server"
  task :deploy, :war_url, :needs => :puppet_apply do |task, args|
    fail "no war url specified" if args[:war_url].nil?
    puts "restarting mcollective".white
    ssh("service mcollective restart")
    Rake::Task["mc:deploy"].invoke("test", args[:war_url])
  end

  task :test_server_address => "#{BUILD_DIR}/test_server" do
    ENV['TEST_SERVER'] = File.read("#{BUILD_DIR}/test_server")
  end

  task :sync_files => ["aws:package", :test_server_address] do
    scp("#{BUILD_DIR}/bootstrap.tar.gz", "/tmp")
    ssh("mv /tmp/bootstrap.tar.gz /tmp/bootstrap/bootstrap.tar.gz")
    puts "file sync successful".white
  end

  def apply_changes(really = true)
    apply = really ? "" : "PUPPET_OPTS=--noop"
    results = ssh("TEST_RUN=true #{apply} /var/lib/cloud/data/scripts/part-000")
    if results =~ /(err:|warn:|error|Could not find)/
      puts results.red
      fail "errors found in puppet execution"
    else
      puts results
      puts "puppet changes ok".green
    end
  end

  def ssh(cmd)
    %x{ssh -i #{SETTINGS["aws_ssh_key_file"]} -t ec2-user@#{ENV['TEST_SERVER']} 'sudo #{cmd}'}
  end

  def scp(from, to)
    %x{scp -i #{SETTINGS["aws_ssh_key_file"]} #{from} ec2-user@#{ENV['TEST_SERVER']}:#{to}}
  end
end
