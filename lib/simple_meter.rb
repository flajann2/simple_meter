require 'date'
require 'set'
require 'pp'
require 'ostruct'
require 'forwardable'
require 'logger'
require 'filesize'
require 'json/ext'
require 'aquarium'
require 'erubis/tiny'
require 'oj'
require 'multi_json'
require 'simple_benchmarks'

# DBs under testing
require 'mongo'
require 'couchbase'
require 'cassandra'

# Internal code
require_relative 'simple_meter/meter'
require_relative 'simple_meter/cli'
require_relative 'simple_meter/helpers'

module SimpleMeter
  include Mongo
  include Simple::Metrics
  
  DATADIR       = 'temdata'
  SIMETERDIR    = DATADIR
  DATASUFFIX    = '_data.json'
  KEYSUFFIX     = '_key.rb'
  GUNSUFFIX     = '_gun.rb'
  DATAGSUB      = %r{_data\.json}
  KEYGSUB       = %r{_key\.rb}
  GUNGSUB       = %r{_gun\.rb}
  DATAGLOB      = DATADIR + '/*' + DATASUFFIX
  KEYGLOB       = DATADIR + '/*' + KEYSUFFIX
  GUNGLOB       = DATADIR + '/*' + GUNSUFFIX

  # General environment
  def env
    @@env ||= OpenStruct.new
  end

  def self.env ; @@env ; end

  module Gun
    class << self
      include SimpleMeter

      def prepare_target ;  end
      def cleanup_target ;  end

      def open_target
        raise "open_target must be chosen (defined)."
      end

      def blast(json, primary, secondary, update)
        raise "nothing to blast -- where's your aim?"
      end

      def close_target
        raise "You should tidy up behind yourself. Really."
      end
    end
  end

  # Every sample json needs a key to inject the keys
  module Key
    class << self
      def set_keys(json, primary, secondary, update)
        raise 'You must implement a Key handler for your sample Json (..._key.rb)'
      end
    end
  end
end
