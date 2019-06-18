module Hyrax
  class ResourceFinder
    attr_reader :query_service

    def initialize(query_service: )
      self.query_service = query_service
    end

    ##
    # @param id [String]
    # @return [Valkyrie::Resource]
    def find(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end
  end
end
