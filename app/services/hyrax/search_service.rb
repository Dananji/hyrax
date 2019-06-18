module Hyrax
  class SearchService
    def query(*args)
      ActiveFedora::SolrService.query(*args)
    end
  end
end
