class Recommendlist
  class << self
    def recent_content(user,title)
    query = question_content_sql(user)
    contents = Content.from("(#{query}) as contents")
     .distinct
    @result = get_recommended_list(contents, title, 3)
    end

    private

    def question_content_sql(user)
      Content.select("contents.* ")
       .where('content_type' => 'question')
       .where.not('user_id' => user.id)
       .to_sql
    end

    def get_recommended_list(contents, title, number)
        list = Array.new
        contents.each do |content|
          num = levenshtein(content.title.to_s , title)
          cnt = Comment.where('content_id' => content.id).count
          list << {:title => content.title, :distance => num, :sender => content.user_id, :user => content.user, :count => cnt}
        end
        list = list.sort_by{|e| e[:distance]}
        list = list.sort_by{|e| -e[:count]}
        return list
    end
    
    def levenshtein(first, second)
      matrix = [(0..first.length).to_a]
      (1..second.length).each do |j|
        matrix << [j] + [0] * (first.length)
      end

      (1..second.length).each do |i|
        (1..first.length).each do |j|
          if first[j-1] == second[i-1]
            matrix[i][j] = matrix[i-1][j-1]
          else
            matrix[i][j] = [
              matrix[i-1][j],
              matrix[i][j-1],
              matrix[i-1][j-1],
            ].min + 1
          end
        end
      end
      return matrix.last.last
    end
  end
end
