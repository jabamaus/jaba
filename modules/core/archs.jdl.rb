SUPPORTED_ARCHS = [:x86, :x86_64, :arm64].freeze

define :arch do
  
  title 'Target architecture'

  SUPPORTED_ARCHS.each do |a|
    attr "#{a}?", type: :bool do
      title "Returns true if current architecture is #{a}"
      example %Q{
        if #{a}?
          ...
        end
      }
      example "src ['arch_#{a}.cpp'] if #{a}?"
      flags :expose
    end
  end

end

# x86 arch instance for use in definitions
#
arch :x86 do
  x86? true
end

# x86_64 arch instance for use in definitions
#
arch :x86_64 do
  x86_64? true
end

# arm64 arch instance for use in definitions
#
arch :arm64 do
  arm64? true
end
