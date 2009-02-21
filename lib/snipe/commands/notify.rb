module Snipe::Commands_command
  class Notify < Snipe::Command
    def run
      puts options.inspect
    end
  end
end
