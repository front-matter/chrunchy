require 'crunchy/runtime/version'

module Crunchy
  module Runtime
    def self.version
      Crunchy.current[:crunchy_runtime_version] ||= Version.new(Crunchy.client.info['version']['number'])
    end
  end
end
