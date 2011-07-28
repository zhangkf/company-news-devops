module MCollective
  module Agent
    class Deploy < RPC::Agent
      metadata :name        => "Deploy",
               :description => "Deployment agent",
               :author      => "Anonymous",
               :version     => "0.1",
               :license     => "private",
               :url         => "http://cn.com",
               :timeout     => 600

      action "war" do
        validate :source, String
        require 'net/http'
                require 'uri'
                require 'fileutils'
                war_url = URI.parse(request[:source])
                war_name = war_url.path.split("/").last
                Net::HTTP.start(war_url.host, war_url.port) do |http|
                    resp = http.get(war_url.path)
                    open("/tmp/#{war_name}", "wb") do |file|
                        file.write(resp.body)
                    end
                end

                system("/sbin/service tomcat6 stop")
                Dir.glob("/var/lib/tomcat6/webapps/*"){ |file|
                  FileUtils.rm_rf(file)
                }
                system("cp /tmp/#{war_name} /var/lib/tomcat6/webapps/")
                system("/sbin/service tomcat6 start")

      end
    end
  end
end
