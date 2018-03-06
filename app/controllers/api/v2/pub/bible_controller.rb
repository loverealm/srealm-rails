class Api::V2::Pub::BibleController < Api::V1::BaseController
  swagger_controller :bible, 'Bible'
  include BibleControllerConcern

  swagger_api :books do
    summary 'Return list of books with including chapter numbers for each one'
  end
  
  swagger_api :verses do
    summary 'Return quantity of verses of a specific book and chapter'
    param :path, :book_id, :string, :required, 'Book code, sample: Gen'
    param :path, :chapter, :integer, :required, 'Chapter number'
  end
  
  swagger_api :passage do
    summary 'Return html verses format ready to be included in content description (html format)'
    param :path, :book_id, :string, :required, 'Book code, sample: Gen'
    param :path, :chapter, :integer, :required, 'Chapter number'
    param :path, :verse_numbers, :string, :required, 'Range of verses to recover, sample: 2-5'
  end
end