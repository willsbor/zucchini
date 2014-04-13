# FIXME: This needs to be refactored into a class (@vaskas).

module Zucchini
  module Device

    private

    def device_params(device)
      if is_simulator?(device)
        "-w \"#{device[:simulator]}\""
      else
        "-w #{device[:udid]}"
      end
    end

    def is_simulator?(device)
      device[:name] == 'iOS Simulator' || device[:simulator]
    end
  end
end
