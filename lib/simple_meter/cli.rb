require 'thor'

SIMETER = File.join [Dir.pwd, "temdata"]
SIMETERGLOB = SIMETER + '/*_gun.rb' #TODO: DRY this!!!

require_relative 'cli/main'
require 'simple_meter'
