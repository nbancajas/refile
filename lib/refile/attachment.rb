module Refile
  module Attachment
    # Macro which generates accessors for the given column which make it
    # possible to upload and retrieve previously uploaded files through the
    # generated accessors.
    #
    # The +raise_errors+ option controls whether assigning an invalid file
    # should immediately raise an error, or save the error and defer handling
    # it until later.
    #
    # @param [String] name                              Name of the column which accessor are generated for
    # @param [#to_s] cache                              Name of a backend in +Refile.backends+ to use as transient cache
    # @param [#to_s] store                              Name of a backend in +Refile.backends+ to use as permanent store
    # @param [true, false] raise_errors                 Whether to raise errors in case an invalid file is assigned
    # @param [:image, nil] type                         The type of file that can be uploaded, currently +:image+ is the
    #                                                   only valid value and restricts uploads to JPEG, PNG and GIF images
    # @param [String, Array<String>, nil] extension     Limit the uploaded file to the given extension or list of extensions
    # @param [String, Array<String>, nil] content_type  Limit the uploaded file to the given content type or list of content types
    # @ignore
    #   rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def attachment(name, cache: :cache, store: :store, raise_errors: true, type: nil, extension: nil, content_type: nil)
      mod = Module.new do
        attacher = :"#{name}_attacher"

        define_method attacher do
          ivar = :"@#{attacher}"
          instance_variable_get(ivar) or begin
            instance_variable_set(ivar, Attacher.new(self, name,
              cache: cache,
              store: store,
              raise_errors: raise_errors,
              type: type,
              extension: extension,
              content_type: content_type
            ))
          end
        end

        define_method "#{name}=" do |uploadable|
          send(attacher).cache!(uploadable)
        end

        define_method name do
          send(attacher).get
        end

        define_method "#{name}_cache_id=" do |cache_id|
          send(attacher).cache_id = cache_id
        end

        define_method "#{name}_cache_id" do
          send(attacher).cache_id
        end

        define_method "remove_#{name}=" do |remove|
          send(attacher).remove = remove
        end

        define_method "remove_#{name}" do
          send(attacher).remove
        end

        define_method "remote_#{name}_url=" do |url|
          send(attacher).download(url)
        end

        define_method "remote_#{name}_url" do
        end
      end

      include mod
    end
  end
end
