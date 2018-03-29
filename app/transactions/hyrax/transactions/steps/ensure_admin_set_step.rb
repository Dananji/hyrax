require "dry/transaction/operation"

module Hyrax
  module Transactions
    module Steps
      class EnsureAdminSetStep
        include Dry::Transaction::Operation

        def call(work)
          work.admin_set_id ? Success(work) : Failure(:no_admin_set_id)
        end
      end
    end
  end
end