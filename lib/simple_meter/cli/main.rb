require 'simple_meter'

module SimpleMeter
  module Cli

    class Main < Thor
      include SimpleMeter
      include SimpleMeter::Meter
      include Simple::Metrics

      desc 'run <data> [<data> <data> ...]', 'Run SimpleMeter data'
      option :verbose,   type: :boolean, default: false, aliases: '-v'
      option :debug,     type: :boolean, default: false, aliases: '-d'
      
      option :forks,     type: :numeric, default: 10, aliases: '-f', desc: 'forks to run. A value of zero runs it in the same thread for debugging.'
      option :iter,      type: :numeric, default: 100000, aliases: '-i', desc: 'iterations per fork'

      option :primary,   type: :numeric, default: 100_000_000, aliases: '-P', desc: 'Upper range of primary key'
      option :secondary, type: :numeric, default: 1_000_000,   aliases: '-S', desc: 'Upper range of secondary key'
      option :seed,      type: :numeric, default: Random.new_seed, aliases: '-S', desc: 'Upper range of secondary key'
      option :update,    type: :string,  default: nil, aliases: '-u', desc: 'Update documents per interation by the given number bytes, like 100kb (requires documents to be written already, byte units MUST be given)' 
      
      option :gun,       type: :string,  default: :mongodb,  desc: 'Gun to blast target DB'
      option :gunhost,   type: :string,  default: nil, aliases: '-h', desc: 'Server to shoot, overrides setting in gun'
      option :gunport,   type: :numeric, default: nil, aliases: '-p', desc: 'Port on server to shoot, overrides setting in gun'
      option :gunuser,   type: :string,  default: nil, aliases: '-U', desc: 'Username to use on server, overrides gun'
      option :gunpass,   type: :string,  default: nil, aliases: '-P', desc: 'Password to use on server, overrides gun'

      option :timeout,   type: :numeric, default: 1800,  desc: 'Timeout for waiting for child forks'
      option :skip,      type: :boolean, default: false, desc: 'Skip timeout failures'
      option :skipfail,  type: :boolean, default: true,  desc: 'Skip DB failures'
    
      def blast(*samples)
        env.verbose   = options[:verbose]
        env.dateiter  = options[:dateiter]
        env.debug     = options[:debug]

        env.forks     = options[:forks]
        env.iter      = options[:iter]

        env.gun       = options[:gun]
        env.host      = options[:gunhost]
        env.port      = options[:gunpost]
        env.user      = options[:gunuser]
        env.pass      = options[:gunpass]

        env.primary   = options[:primary]
        env.secondary = options[:secondary]
        env.rng = Random.new options[:seed]
        env.update    = Filesize.from(options[:update]).to_i unless options[:update].nil? 

        env.timeout   = options[:timeout]
        env.skip      = options[:skip]
        env.skipfail  = options[:skipfail]

        init_report_database

        samples.map do |sample|
          [sample, SAMPLEDIR + '/' + sample + SAMPLESUFFIX]
        end.each do |sample, file|
          process sample.to_sym, file
        end
      end
      map run: :blast

      desc 'list', 'List available chutes'
      def list
        Dir.glob(DATAGLOB).sort.each do |sample|
          puts 'blaster run ' + File.basename(sample).gsub(DATAGSUB, '')
        end

        Dir.glob(GUNGLOB).sort.each do |bl|
          puts '  Gun:' + File.basename(bl).gsub(GUNGSUB, '')
        end
      end

      no_commands {
      }
    end
  end
end
