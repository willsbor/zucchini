# FIXME: This needs to be refactored into a class (@vaskas).

module Zucchini
  module Device

    private

    def device_params(device)
      if is_simulator?(device)
        stop_active_simulator()
        "-w \"#{device[:simulator]}\""
      else
        "-w #{device[:udid]}"
      end
    end

    def stop_active_simulator()
      simulator_pid = `ps ax|awk '/[i]Phone Simulator.app\\/Contents\\/MacOS\\/iPhone Simulator/{print $1}'`.chomp
      Process.kill('INT', simulator_pid.to_i) unless simulator_pid.empty?
    end

    def is_simulator?(device)
      device[:name] == 'iOS Simulator' || device[:simulator]
    end
  end
end
