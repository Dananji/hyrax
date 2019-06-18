module Hyrax
  class ActiveFedoraFinder
    attr_reader :query_service

    def initialize(query_service: )
      self.query_service = query_service
      @resource_finder = ResourceFinder.new(query_service)
    end

    ##
    # @param id [#to_s]
    # @return [ActiveFedora::Base]
    def find(id)
      @resource_finder.find(id.to_s)&.convert
    end
  end
end
