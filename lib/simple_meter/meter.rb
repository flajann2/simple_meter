=begin rdoc

=end

module SimpleMeter
  # Main tools to shoot the shit out of your target DB.
  module Meter
    include Erubis
    include Simple::Metrics
    
    def forkable(sample, fnum, rng, json)
      measure :open_target do
        Gun::open_target
      end
      
      env.iter.times do |iteration|
        primary   = rng.rand(env.primary)
        secondary = rng.rand(env.secondary)
        measure "samp_#{sample}".to_sym do
          Gun::blast json, primary, secondary, env.update, sample
        end
      end
      
      measure :close_target do
        Gun::close_target
      end
      update_report_database     
    end
    

    def process(sample, file)
      pp env if env.debug
      puts file
      load "#{SIMETERDIR}/#{env.gun}#{SIMETERSUFFIX}"
      load "#{SIMETERDIR}/#{sample}#{SAMPKEYSUFFIX}"
      er = TinyEruby.new(File.read(file))
      json = JSON.parse er.result(binding)

      Gun::prepare_target
      unless env.forks == 0
        children = []
        env.forks.times do |fnum|
          rng = Random.new(env.rng.rand(env.primary) * fnum)
          children << fork {
            forkable sample, fnum, rng, json
          }
        end
        Process.waitall
      else # for debugging
        forkable sample, 0, env.rng, json
      end
      render_report ((env.forks==0) ? 1 : env.forks), env.timeout, env.skip
      Gun::cleanup_target
    end
  end
end

