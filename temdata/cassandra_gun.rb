# -*- coding: utf-8 -*-
=begin rdoc
= Gun for Cassandra
=end
module SimpleMeter
  module Gun
    RETRY_DELAY = 0.010
    KEYSPACE = 'blaster'
    class << self
      include Simple::Metrics
      def connection(host: (env.host || 'localhost'), port: (env.port || 9042))
        measure :cas_conn do
          @@cluster = Cassandra.cluster port: port, hosts: [host] #, username: env.user, password: env.pass
          @@session = @@cluster.connect(KEYSPACE) 
        end
      end

      def sess ; @@session ; end

      def prepare_target
        connection
        Key::Cassandra.create_schema sess
      end

      def cleanup_target
      end

      def open_target
        connection
      end

      def blast(json, primary, secondary, update, sample=nil)
        sjson = nil

        unless update
          #measure :json_key do
          #  json, @@update_field = Key.set_keys(json, primary, secondary, update)
          #end

          measure :cas_2json do
            sjson = MultiJson.dump json
          end

          measure :cas_insert do
            Key::Cassandra.insert_data sess, json, primary, secondary
          end
        else
          measure :json_upkey do
            json, @@update_field = Key.set_keys(json, primary, secondary, update)
          end

          measure :cas_update do
            Key::Cassandra.update_data sess, json, primary, secondary, update
          end
        end
      end

      def close_target
        @@cluster.close
      end
    end
  end
end
