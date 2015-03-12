=begin rdoc
= Null gun
=end
require 'socket'

module SimpleMeter
  NULLPORT=22222
  module Gun
    class << self
      include Simple::Metrics

      def connection(host: (env.host || 'localhost'), port: (env.port || NULLPORT), **opts)
        @@conn = TCPSocket.new host, port
      end
    
      def database(dbname)
        @@database = conn.db(dbname.to_s)
      end
      
      def conn ; @@conn     ; end

      def open_target
        connection 
        @@count = 0
      end

      def blast(json, primary, secondary, update, sample=nil)
        @@count += 1

        measure :json_key do
          json, @@update_field = Key.set_keys(json, primary, secondary, update)
        end

        if env.debug and env.verbose
          puts "<< JSON=#{json} >>"
        end

        sj = nil
        if update
          measure :null_2json do
            sj = MultiJson.dump({'$addToSet' => 
                                  { @@update_field => 
                                    { '$each' =>
                                      json[@@update_field]
                                    }}})
          end
          measure :null_update do
            conn.send(sj)        
          end
        else
          measure :null_2json do
            sj = MultiJson.dump({"$set" => json})
          end
          measure :null_insert do
            conn.send(sj)        
          end
        end
      end

      def close_target
      end
    end
    
    # to be run on the server
    module Target
      def self.run
        server = TCPServer.open(NULLPORT)
        while client = server.accept
          puts "accepted a connection"
          fork do
            begin
              loop { 
                msg, sinfo = client.recvfrom(1_000_000)
                break if msg.size == 0
              } # just toss the data, we don't fucking care about it.
            ensure
              client.close
              puts "closed a connection"
            end
          end
          client.close
        end
      end
    end
  end
end
