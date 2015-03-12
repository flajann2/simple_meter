# -*- coding: utf-8 -*-
=begin rdoc
= Gun for Redis
=end
module SimpleMeter
  module Gun
    RETRY_DELAY = 0.010
    class << self
      include Simple::Metrics
      def connection(host: (env.host || 'localhost'), port: (env.port || 6379), **opts)
        measure :redis_conn do
          @@redis = redis = Redis.new(driver: :hiredis, host: host, port: port)                                      
        end
      end
    
      def conn ; @@redis ; end

      def open_target
        connection
      end
      
      def blast(json, primary, secondary, update, sample=nil)
        sjson = nil

        unless update
          measure :json_key do
            json, @@update_field = Key.set_keys(json, primary, secondary, update)
          end
        else
          measure :redis_upread do
            sjson = conn[primary.to_s]
            raise "Redis retrived null to #{primary}" if json.nil?
          end

          measure :json_upload do
            json = MultiJson.load sjson
          end

          measure :json_upkey do
            json, @@update_field = Key.set_keys(json, primary, secondary, update)
          end
        end

        measure :redis_2json do
          sjson = MultiJson.dump json
        end

        measure :redis_set do
          delay_factor = 1
          begin
            conn[primary.to_s] = sjson
          rescue Exception => e
            #puts "(df #{delay_factor}) #{e}"
            #sleep RETRY_DELAY * delay_factor
            #delay_factor *= 2
            puts e
          end
        end
      end
      
      def close_target
      end
    end
  end
end
