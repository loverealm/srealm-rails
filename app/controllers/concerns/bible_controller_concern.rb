module BibleControllerConcern extend ActiveSupport::Concern
  def books
    render json: Verse.english.group(:book_id, :translation_id).select('verses.book_id,  max(chapter) as chapters, MAX(book) as book_name, max(book_num) as book_number').order('book_number ASC').to_json(only: [:book_id, :chapters, :book_name])
  end
  
  def verses
    render inline: Verse.english.where(book_id: params[:book_id], chapter: params[:chapter]).maximum(:verse).to_s
  end
  
  def passage
    verses = params[:verse_numbers].split('-')
    verses = verses.size == 1 ? verses.first : verses.first..verses.last
    data = Verse.english.where(book_id: params[:book_id], chapter: params[:chapter], verse: verses)
    if params[:format_type] == 'json'
      render json: data.select(:verse, :text).to_json(only: [:verse, :text])
    else
      res = data.to_a
      html = ''
      if res.any?
        passages = []
        res.each{|_verse| passages << "#{_verse.verse}) #{_verse.text.gsub(/\\n/, '')}" }
        html = "<blockquote class=\"quote\">#{res.first.book} (#{params[:chapter]}: #{params[:verse_numbers]})<footer>#{passages.join(' ')}</footer></blockquote>"
      end
      render inline: html
    end
  end
end