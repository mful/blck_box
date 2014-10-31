class ContentImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::ImageOptimizer

  process convert: "jpg"
  process :optimize

  version :v_375x667 do
    process resize_to_fill: [375, 667]
  end

  version :v_540x960 do
    process resize_to_fill: [540, 960]
  end
end