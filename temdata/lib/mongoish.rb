# -*- coding: utf-8 -*-

=begin rdoc
= Common ops for Tokumx and MongoDB

== Document Growth issues NOTE WELL

At issue here is how we grow the document during updates.
Since we are running 16 processes a lot, each growing its
own document, we need to control the in-memory growth, which,
in the case, we need to drop all but the last entry, which
we don't wish to be fluming back to Mongo/TokuMX anyway,
so we lub off all but the last

=end

module SimpleMeter
  module Gun
    class << self
      include Simple::Metrics
      BULK_SZ=1000

      def connection(host: (env.host || 'localhost'), port: (env.port || 27017), **opts)
        @@conn = Mongo::MongoClient.new host, port, opts
      end
    
      def database(dbname)
        @@database = conn.db(dbname.to_s)
      end
      
      def collection(collname)
        @@coll = db.collection(collname)
        @@bulk = @@coll.initialize_unordered_bulk_op
      end

      def conn ; @@conn     ; end
      def db   ; @@database ; end
      def coll ; @@coll     ; end
      def bulk ; @@bulk     ; end

      def open_target
        connection op_timeout: 1800.0, pool_size: 10, pool_timeout: 1800.0
        database "blasted"
        collection "testdata"
        @@count = 0
      end

      def blast(json, primary, secondary, update, sample=nil)
        @@count += 1

        measure :json_key do
          json, @@update_field = Key.set_keys(json, primary, secondary, update)
          json[@@update_field] = [json[@@update_field].last] if update # to prevent excessive in-memory growth.
        end

        if env.debug and env.verbose
          puts "<< JSON=#{json} >>"
        end
        
        # specifics to tokumx or mongodb or whatever
        json = blast_special json, primary, secondary, update

        if update
          measure :moish_update do
            bulk.find({_id: primary}).update({'$addToSet' => 
                                               { @@update_field => 
                                                 { '$each' =>
                                                   json[@@update_field]
                                                 }}})        
          end
        else
          measure :moish_insert do
            bulk.insert(json)        
          end
        end

        bulk_execute
      end

      def close_target
        bulk_execute closing: true
      end

      def bulk_execute(closing: false)
        begin
          r = nil
          measure :moish_bulk do
            r = bulk.execute
            @@count = 0
          end if @@count > BULK_SZ || (closing && @@count > 0)
          pp r unless r.nil? or not env.debug
        rescue Mongo::BulkWriteError => e
          pp e.result
          raise e unless env.skipfail
        end
      end
    end
  end
end
