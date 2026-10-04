module Api
  class BinaryBlobsController < BaseController
    MAX_UPLOAD_SIZE = 10.megabytes

    # GET /api/binary_blobs/*blob_path
    def show
      blob = find_blob!
      response.headers["Content-Length"] = blob.size.to_s
      render :body => blob.binary, :content_type => blob.content_type.presence || "application/octet-stream"
    end

    # PUT /api/binary_blobs/*blob_path
    def update
      raise BadRequestError, "Payload exceeds maximum allowed size of #{MAX_UPLOAD_SIZE} bytes" if request.content_length.to_i > MAX_UPLOAD_SIZE

      data = request.body.read(MAX_UPLOAD_SIZE + 1)
      raise BadRequestError, "Payload exceeds maximum allowed size of #{MAX_UPLOAD_SIZE} bytes" if data.bytesize > MAX_UPLOAD_SIZE

      blob = BinaryBlob.find_by(:path => blob_path) || BinaryBlob.new(:path => blob_path)
      blob.content_type = request.content_type.presence || "application/octet-stream"
      blob.binary       = data
      blob.save!

      head 200
    end

    # DELETE /api/binary_blobs/*blob_path
    def destroy
      find_blob!.destroy!
      head 204
    end

    private

    def blob_path
      @req.c_suffix
    end

    def find_blob!
      BinaryBlob.find_by!(:path => blob_path)
    end
  end
end
