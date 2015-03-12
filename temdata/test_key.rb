# -*- coding: utf-8 -*-
module SimpleMeter
  module Key
    class << self
      include Helpers
      UPDATE_FIELD='daily'

      def set_keys(json, primary, secondary, update)
        json = json.clone
        json['id'] = primary
        json['sec'] = secondary
        json[UPDATE_FIELD] ||= []
        #json[UPDATE_FIELD] = [random_string(update)] unless update.nil?
        [json, UPDATE_FIELD]
      end
    end

    # Specifics for generating a schema for Cassandra
    module Cassandra
      class << self
        include Helpers
        include Simple::Metrics
        DAYRANGE = Date.today.upto(Date.today + 365).map{ |d|
          d.strftime("d%Y%m%d")
        }.to_a

        def create_schema(sess)
          dfs = DAYRANGE.map{ |field| 
            "#{field} text"
          }.join(',')
          [
           #%{CREATE TYPE IF NOT EXISTS daily_entries (  
           #     id bigint,
           #     #{dfs}
           #   ); },
           %{CREATE TABLE IF NOT EXISTS test (
               id bigint PRIMARY KEY,
               iter bigint,
               sec bigint,
               #{dfs}
               ); }]
            .each { |ex| sess.execute ex }
          sleep 2
        end
        
        def insert_data(sess, json, primary, secondary)
          sess.execute (ex = %{ 
                  INSERT INTO test (id, iter, sec) 
                  VALUES (#{primary}, #{json['iter']}, #{json['sec']}); 
                })
        end

        def update_data(sess, json, primary, secondary, update)
          dailydata = nil

          measure :test_daily do
            dailydata = random_string(update)
          end

          measure :test_key_2j do
            newcrap = MultiJson.dump(json['newcrap']).gsub('"', "'")
          end
          tag = DAYRANGE[rand(DAYRANGE.size)]
          sess.execute (ex = %{
                  UPDATE test
                  SET #{tag}=  '#{dailydata}'
                  WHERE id = #{primary}
                })
        end
      end
    end
  end
end
