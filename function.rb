require './db.rb'
require './rakutan.rb'

GetRakutanResult = Struct.new(:result, :rakutan)

Response = {
  1001 => ->(kid) {"講義ID「%d」の検索で接続エラーが発生しました" % kid },
  1404 => ->(kid) {"講義ID「%d」は存在しません" % kid},
  2001 => ->(kid) {"「%s」の検索で接続エラーが発生しました" % kid},
  2404 => ->(kid) {"「%s」は見つかりませんでした" % kid},
  3001 => "ユーザー「{0}」のお気に入りの取得で接続エラーが発生しました",
  3404 => "ユーザー「{0}」のお気に入りはまだありません。",
  4001 => "{0}おみくじで接続エラーが発生しました",
  4002 => "{0}おみくじは存在しません",
  4404 => "{0}おみくじに該当する講義が見つかりませんでした"
}

def get_lecture_by_id(kid)
  db = Database.new
  dr = db.find("rakutan", {id: kid}, nil)
  res = GetRakutanResult.new
  
  if dr.result == :success then
    if dr.count == 0 then
      res.result = Response[1404].call(kid)
    else
      res.result = "success"
      res.rakutan = Rakutan.from_dict(dr.query_result.each.next)
    end
  else
    res.result = Response[1001].call(kid)
  end

  db.close
  res
end

GetRakutansResult = Struct.new(:result, :count, :rakutan_list)

def get_lecture_by_search_word(search_word)
  db = Database.new

  if search_word[0] == "%" then
    query = {"lecturename": {"$regex": search_word[1..-1], "$options": "i"}}
  else
    query = {"lecturename": {"$regex": "^%s" % search_word, "$options": "i"}}
  end

  dr = db.find("rakutan", query, {_id: false})

  res = GetRakutansResult.new
  if dr.result == :success then
    if dr.count == 0 then
      res.result = Response[2404].call(search_word)
    else
      res.result = "success"
      res.count = dr.count
      res.rakutan_list = Rakutan.from_list(dr.query_result.each)
    end
  else
    res.result = Response[2001].call(search_word)
  end

  db.close
  res
end
