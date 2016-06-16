require 'yaml'
require 'fileutils'

require 'supermodel'

# Zygote container
module Zygote
  # A simple means of persistence
  # This can easily be swapped out for redis, but file-based is simpler and good enough for now
  # https://github.com/maccman/supermodel/blob/master/README
  module Memory
    extend self
    DATABASE_PATH = (ENV['DATABASE_PATH'] || File.expand_path('../data/memory.db', $PROGRAM_NAME)).freeze
    SuperModel::Marshal.path = DATABASE_PATH

    def save
      FileUtils.mkdir_p(File.dirname(DATABASE_PATH)) # FIXME: - don't make if it already exists
      SuperModel::Marshal.dump
    end

    def load
      SuperModel::Marshal.load
    end
  end

  at_exit do
    Memory.save
  end
end
