class Logo
  BASE_PATH = "media/images/logos/".freeze

  def initialize(name)
    @name = name
  end

  def path(preferred_formats = [])
    return if available_formats.empty?

    format = preferred_formats.any? ? preferred_formats.find { |f| f.in?(available_formats) } : available_formats.first
    return if format.nil?

    "#{BASE_PATH}#{@name}.#{format}"
  end

  def available_formats
    %w[svg png jpg].select do |format|
      Webpacker.manifest.lookup("#{BASE_PATH}#{@name}.#{format}")
    end
  end
end
