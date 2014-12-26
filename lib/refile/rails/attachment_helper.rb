module Refile
  module AttachmentHelper
    def attachment_url(record, name, *args, filename: nil, format: nil, host: nil)
      file = record.send(name)
      return unless file

      filename ||= name.to_s

      backend_name = Refile.backends.key(file.backend)
      host = host || Refile.host || request.base_url

      filename = filename.parameterize("_")
      filename << "." << format.to_s if format

      ::File.join(host, main_app.refile_app_path, backend_name, *args.map(&:to_s), file.id.to_s, filename)
    end

    def attachment_image_tag(record, name, *args, fallback: nil, format: nil, host: nil, **options)
      file = record.send(name)
      classes = ["attachment", record.class.model_name.singular, name, *options[:class]]

      if file
        image_tag(attachment_url(record, name, *args, format: format, host: host), options.merge(class: classes))
      elsif fallback
        classes << "fallback"
        image_tag(fallback, options.merge(class: classes))
      end
    end

    # @ignore
    #   rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def attachment_field(object_name, method, object:, **options)
      options[:data] ||= {}

      attacher = object.send(:"#{method}_attacher")
      options[:accept] = attacher.accept

      if options[:direct]
        host = options[:host] || Refile.host || request.base_url
        backend_name = Refile.backends.key(attacher.cache)

        url = ::File.join(host, main_app.refile_app_path, backend_name)
        options[:data].merge!(direct: true, as: "file", url: url)
      end

      if options[:presigned] and attacher.cache.respond_to?(:presign)
        options[:data].merge!(direct: true).merge!(attacher.cache.presign.as_json)
      end

      html = file_field(object_name, method, options)
      [:cache_id, :filename, :size, :content_type].each do |field|
        if object.respond_to?(:"#{method}_#{field}") and object.respond_to?(:"#{method}_#{field}=")
          html << hidden_field(object_name, :"#{method}_#{field}", object: object)
        end
      end
      html
    end
  end
end
