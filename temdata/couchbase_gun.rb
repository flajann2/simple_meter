# -*- coding: utf-8 -*-
=begin rdoc
= Gun for Couchbase
=end
module SimpleMeter
  module Gun
    RETRY_DELAY = 0.010
    class << self
      include Simple::Metrics
      def connection(host: (env.host || 'localhost'), port: (env.port || 8091), **opts)
        measure :cb_conn do
          @@conn = Couchbase.connect(hostname: host, 
                                     port: port,
                                     #username: (env.user || 'admin'),
                                     #password: (env.pass || 'password'),
                                     bucket: 'default')
        end
      end
    
      def conn ; @@conn ; end

      def open_target
        connection
      end
      
      def blast(json, primary, secondary, update, sample=nil)
        unless update
          measure :json_key do
            json, @@update_field = Key.set_keys(json, primary, secondary, update)
          end
        else
          measure :cb_upread do
            json = conn[primary.to_s]
          end
          measure :json_upkey do
            json, @@update_field = Key.set_keys(json, primary, secondary, update)
          end
        end

        measure :cb_set do
          delay_factor = 1
          begin
            conn[primary.to_s] = json
          rescue Couchbase::Error::TemporaryFail => e
            puts "(df #{delay_factor}) #{e}"
            sleep RETRY_DELAY * delay_factor
            delay_factor *= 2
            retry
          end
        end
      end
      
      def close_target
      end
    end
  end
end
