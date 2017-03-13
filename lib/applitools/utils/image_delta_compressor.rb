module Applitools::Utils
  module ImageDeltaCompressor
    extend self

    BLOCK_SIZE = 10

    # Compresses the target image based on the source image.
    #
    # +target+:: +ChunkyPNG::Canvas+ The image to compress based on the source image.
    # +target_encoded+:: +Array+ The uncompressed image as binary string.
    # +source+:: +ChunkyPNG::Canvas+ The source image used as a base for compressing the target image.
    # +block_size+:: +Integer+ The width/height of each block.
    #
    # Returns +String+ The binary result (either the compressed image, or the uncompressed image if the compression
    # is greater in length).
    def compress_by_raw_blocks(target, target_encoded, source, block_size = BLOCK_SIZE)
      # If we can't compress for any reason, return the target image as is.
      if source.nil? || (source.height != target.height) || (source.width != target.width)
        # Returning a COPY of the target binary string.
        return String.new(target_encoded)
      end

      # Preparing the variables we need.
      target_pixels = target.to_rgb_stream.unpack('C*')
      source_pixels = source.to_rgb_stream.unpack('C*')
      image_size = Dimension.new(target.width, target.height)
      block_columns_count = (target.width / block_size) + ((target.width % block_size).zero? ? 0 : 1)
      block_rows_count = (target.height / block_size) + ((target.height % block_size).zero? ? 0 : 1)

      # IMPORTANT: The "-Zlib::MAX_WBITS" tells ZLib to create raw deflate compression, without the
      # "Zlib headers" (this isn't documented in the Zlib page, I found this in some internet forum).
      compressor = Zlib::Deflate.new(Zlib::BEST_COMPRESSION, -Zlib::MAX_WBITS)

      compression_result = ''

      # Writing the data header.
      compression_result += PREAMBLE.encode('UTF-8')
      compression_result += [FORMAT_RAW_BLOCKS].pack('C')
      compression_result += [0].pack('S>') # Source id, Big Endian
      compression_result += [block_size].pack('S>') # Big Endian

      # We perform the compression for each channel.
      3.times do |channel|
        block_number = 0
        block_rows_count.times do |block_row|
          block_columns_count.times do |block_column|
            actual_channel_index = 2 - channel # Since the image bytes are BGR and the server expects RGB...
            compare_result = compare_and_copy_block_channel_data(source_pixels, target_pixels, image_size, 3,
              block_size, block_column, block_row, actual_channel_index)

            unless compare_result.identical
              channel_bytes = compare_result.channel_bytes
              string_to_compress = [channel].pack('C')
              string_to_compress += [block_number].pack('L>')
              string_to_compress += channel_bytes.pack('C*')

              compression_result += compressor.deflate(string_to_compress)

              # If the compressed data so far is greater than the uncompressed representation of the target, just return
              # the target.
              if compression_result.length > target_encoded.length
                compressor.finish
                compressor.close
                # Returning a copy of the target bytes.
                return String.new(target_encoded)
              end
            end

            block_number += 1
          end
        end
      end

      # Compress and flush any remaining uncompressed data in the input buffer.
      compression_result += compressor.finish
      compressor.close

      # Returning the compressed result as a byte array.
      compression_result
    end

    private

    PREAMBLE = 'applitools'.freeze
    FORMAT_RAW_BLOCKS = 3

    Dimension = Struct.new(:width, :height)
    CompareAndCopyBlockChannelDataResult = Struct.new(:identical, :channel_bytes)

    # Computes the width and height of the image data contained in the block at the input column and row.
    # +image_size+:: +Dimension+ The image size in pixels.
    # +block_size+:: The block size for which we would like to compute the image data width and height.
    # +block_column+:: The block column index.
    # +block_row+:: The block row index.
    # ++
    # Returns the width and height of the image data contained in the block are returned as a +Dimension+.
    def get_actual_block_size(image_size, block_size, block_column, block_row)
      actual_width = [image_size.width - (block_column * block_size), block_size].min
      actual_height = [image_size.height - (block_row * block_size), block_size].min
      Dimension.new(actual_width, actual_height)
    end

    # Compares a block of pixels between the source and target and copies the target's block bytes to the result.
    # +source_pixels+:: +Array+ of bytes, representing the pixels of the source image.
    # +target_pixels+:: +Array+ of bytes, representing the pixels of the target image.
    # +image_size+:: +Dimension+ The size of the source/target image (remember they must be the same size).
    # +pixel_length+:: +Integer+ The number of bytes composing a pixel
    # +block_size+:: +Integer+ The width/height of the block (block is a square, theoretically).
    # +block_column+:: +Integer+ The block column index (when looking at the images as a grid of blocks).
    # +block_row+:: +Integer+ The block row index (when looking at the images as a grid of blocks).
    # +channel+:: +Integer+ The index of the channel we're comparing.
    # ++
    # Returns +CompareAndCopyBlockChannelDataResult+ object containing a flag saying whether the blocks are identical
    # and a copy of the target block's bytes.
    def compare_and_copy_block_channel_data(source_pixels, target_pixels, image_size, pixel_length, block_size,
      block_column, block_row, channel)
      identical = true

      actual_block_size = get_actual_block_size(image_size, block_size, block_column, block_row)

      # Getting the actual amount of data in the block we wish to copy.
      actual_block_height = actual_block_size.height
      actual_block_width = actual_block_size.width

      stride = image_size.width * pixel_length

      # Iterating the block's pixels and comparing the source and target.
      channel_bytes = []
      actual_block_height.times do |h|
        offset = (((block_size * block_row) + h) * stride) + (block_size * block_column * pixel_length) + channel
        actual_block_width.times do |_w|
          source_byte = source_pixels[offset]
          target_byte = target_pixels[offset]
          identical = false if source_byte != target_byte
          channel_bytes << target_byte
          offset += pixel_length
        end
      end

      # Returning the compare-and-copy result.
      CompareAndCopyBlockChannelDataResult.new(identical, channel_bytes)
    end

    include Applitools::MethodTracer
  end
end
