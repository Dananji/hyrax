require 'wings/services/file_node_builder'

module Hyrax
  module Actors
    # Actions for a file identified by file_set and relation (maps to use predicate)
    # @note Spawns asynchronous jobs
    class FileActor
      attr_reader :file_set, :relation, :user

      # @param [FileSet] file_set the parent FileSet
      # @param [Symbol, #to_sym] relation the type/use for the file
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user, use_valkyrie: true)
        @file_set = file_set
        @relation = normalize_relation(relation, use_valkyrie: use_valkyrie)
        @user = user
        @use_valkyrie = use_valkyrie
      end

      # Persists file as part of file_set and spawns async job to characterize and create derivatives.
      # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      # @note Instead of calling this method, use IngestJob to avoid synchronous execution cost
      # @see IngestJob
      # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
      def ingest_file(io)
        perform_ingest_file(io, use_valkyrie: @use_valkyrie)
      end

      # Reverts file and spawns async job to characterize and create derivatives.
      # @param [String] revision_id
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      def revert_to(revision_id)
        repository_file = related_file
        repository_file.restore_version(revision_id)
        return false unless file_set.save
        Hyrax::VersioningService.create(repository_file, user)
        CharacterizeJob.perform_later(file_set, repository_file.id)
      end

      # @note FileSet comparison is limited to IDs, but this should be sufficient, given that
      #   most operations here are on the other side of async retrieval in Jobs (based solely on ID).
      def ==(other)
        return false unless other.is_a?(self.class)
        file_set.id == other.file_set.id && relation == other.relation && user == other.user
      end

      private

        # @return [Hydra::PCDM::File] the file referenced by relation
        def related_file
          file_set.public_send(normalize_relation(relation)) || raise("No #{relation} returned for FileSet #{file_set.id}")
        end

        # Persists file as part of file_set and records a new version.
        # Also spawns an async job to characterize and create derivatives.
        # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
        # @return [FileNode, FalseClass] the created file node on success, false on failure
        # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
        def perform_ingest_file(io, use_valkyrie: false)
          use_valkyrie ? perform_ingest_file_through_valkyrie(io) : perform_ingest_file_through_active_fedora(io)
        end

        def perform_ingest_file_through_active_fedora(io)
          # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
          Hydra::Works::AddFileToFileSet.call(file_set,
                                              io,
                                              relation,
                                              versioning: false)
          return false unless file_set.save
          repository_file = related_file
          Hyrax::VersioningService.create(repository_file, user)
          pathhint = io.uploaded_file.uploader.path if io.uploaded_file # in case next worker is on same filesystem
          CharacterizeJob.perform_later(file_set, repository_file.id, pathhint || io.path)
        end

        def perform_ingest_file_through_valkyrie(io)
          # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
          storage_adapter = Valkyrie.config.storage_adapter
          persister = Valkyrie.config.metadata_adapter.persister # TODO: Explore why valkyrie6 branch used indexing_persister adapter for this
          node_builder = Wings::FileNodeBuilder.new(storage_adapter: storage_adapter,
                                                    persister: persister)
          unsaved_node = io.to_file_node
          unsaved_node.use = relation
          begin
            saved_node = node_builder.create(io_wrapper: io, node: unsaved_node, file_set: file_set)
          rescue StandardError => e # Handle error persisting file node
            # Rails.logger.error("Failed to save file_node through valkyrie: #{e.message}")
            Rails.logger.error("\n\n****************\n\nFailed to save file_node through valkyrie: #{e.message}\n\n****************\n\n")
            return false
          end
          Hyrax::VersioningService.create(saved_node, user)
          saved_node
        end

        def normalize_relation(relation, use_valkyrie: false)
          use_valkyrie ? normalize_relation_for_valkyrie(relation) : normalize_relation_for_active_fedora(relation)
        end

        def normalize_relation_for_active_fedora(relation)
          return relation if relation.is_a? Symbol
          return relation.to_sym if relation.respond_to? :to_sym

          # TODO: whereever these are set, they should use Valkyrie::Vocab::PCDMUse... making the casecmp unnecessary
          return :original_file if relation.to_s.casecmp(Valkyrie::Vocab::PCDMUse.original_file.to_s)
          return :extracted_file if relation.to_s.casecmp(Valkyrie::Vocab::PCDMUse.extracted_file.to_s)
          return :thumbnail_file if relation.to_s.casecmp(Valkyrie::Vocab::PCDMUse.thumbnail_file.to_s)
          :original_file # TODO: This should never happen.  What should be done if none of the other conditions are met?
        end

        def normalize_relation_for_valkyrie(relation)
          return relation if relation.is_a? RDF::URI

          relation = relation.to_sym
          return Valkyrie::Vocab::PCDMUse.original_file if relation == :original_file
          return Valkyrie::Vocab::PCDMUse.extracted_file if relation == :extracted_file
          return Valkyrie::Vocab::PCDMUse.thumbnail_file if relation == :thumbnail_file
          Valkyrie::Vocab::PCDMUse.original_file # TODO: This should never happen.  What should be done if none of the other conditions are met?
        end
    end
  end
end
