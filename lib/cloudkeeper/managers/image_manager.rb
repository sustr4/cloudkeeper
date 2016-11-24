module Cloudkeeper
  module Managers
    class ImageManager
      extend Cloudkeeper::Entities::ImageFormats::Ova

      FORMATS = {
        qcow2: /qemu qcow image/i,
        ova: /posix tar archive/i,
        vmdk: /vmware4 disk image/i,
        raw: /boot sector/i
      }.freeze

      class << self
        def format(file)
          check_file!(file)
          recognize_format(file)
        rescue Cloudkeeper::Errors::CommandExecutionError, Cloudkeeper::Errors::NoSuchFileError,
               Cloudkeeper::Errors::PermissionDeniedError, Cloudkeeper::Errors::ImageFormat::NoFormatRecognizedError,
               Cloudkeeper::Errors::ImageFormat::Ova::OvaFormatError => ex
          raise Cloudkeeper::Errors::ImageFormat::RecognitionError, ex, "Cannot recognize image format for file #{file.inspect}"
        end

        def file_description(file)
          Cloudkeeper::CommandExecutioner.execute('file', '-b', file)
        end

        def check_file!(file)
          raise Cloudkeeper::Errors::NoSuchFileError, "No such file #{file.inspect}" unless File.exist?(file)
          raise Cloudkeeper::Errors::PermissionDeniedError, "Cannot read file #{file.inspect}" unless File.readable?(file)
        end

        def recognize_format(file)
          file_format_string = file_description(file)
          FORMATS.each do |format, regex|
            next unless regex =~ file_format_string

            format_test_method = "#{format}?".to_sym
            additional_test_result = respond_to?(format_test_method) ? send(format_test_method, file) : true

            return format if additional_test_result
          end

          raise Cloudkeeper::Errors::ImageFormat::NoFormatRecognizedError, "No image format recognized for file #{file.inspect}"
        end
      end
    end
  end
end
